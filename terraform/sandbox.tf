################################### Provider
provider "aws" {
  access_key = "AKIAIFUMOTVGSHZ2SHVA"
  secret_key = "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"
  region = "us-west-2"
}

################################### Variables
variable "server_type" {
  type = "map"
  default = {
    ubuntu = "ami-efd0428f"
    # redhat = "ami-6f68cf0f"
    # windows = "ami-c2c3a2a2"
  }
}
variable "project_name" {
  type = "string"
  default = "snap_home_demo"
}
variable "key" {
  type = "string"
  default = "snaphp"
}

################################### VPC et al
resource "aws_vpc" "SandboxVPC" {
  cidr_block = "10.0.0.0/16"
  tags {
    Name = "${var.project_name}"
  }
}
resource "aws_subnet" "main" {
  vpc_id = "${aws_vpc.SandboxVPC.id}"
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = "true"
  tags {
    Name = "${var.project_name}"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.SandboxVPC.id}"
  tags {
    Name = "${var.project_name}"
  }
}
resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.SandboxVPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags {
    Name = "${var.project_name}"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id = "${aws_subnet.main.id}"
  route_table_id = "${aws_route_table.r.id}"
}

################################### Servers
resource "aws_instance" "server" {
  count = 5
  ami = "${element(values(var.server_type), count.index)}"
  instance_type = "t2.micro"
  key_name = "${var.key}"
  vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
  tags {
    Name = "server-${count.index}-${element(keys(var.server_type), count.index)}"
    Project = "${var.project_name}"
  }
}

################################### Security Group
resource "aws_security_group" "allow_all" {
  name = "allow_all"
  description = "Allow all inbound traffic"
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["76.79.150.86/32"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "${var.project_name}"
  }
}

################################### Outputs
output "server_instance_id" {
  value = "${zipmap(aws_instance.server.*.tags.Name, aws_instance.server.*.id)}"
}
output "server_public_dns" {
  value = "${zipmap(aws_instance.server.*.tags.Name, aws_instance.server.*.public_dns)}"
}
