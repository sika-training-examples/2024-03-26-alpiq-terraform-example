terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.42.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
}

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "prefix" {}

provider "aws" {
  region     = "eu-west-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

locals {
  DEFAULT_INSTANCE_TYPE = "t2.micro"
}

resource "aws_key_pair" "lab" {
  key_name   = "${var.prefix}-lab"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClalhUbYLKno7EPL8zsPj7pabTMGoyY/Ky88GK28SPVvxEy83vlv6fKlLYm8dTm4pWBtqJ0jPkmzgGFsavaV1BuX302qKa+v/Sv+ykC2k9zB0TV/2vkon8VkZoR2Tlyxp0NQ4V7CH9V1NUQxNdYhbQPeBxXwK7bgvwDHXgDKtgfsMt4Ij1r/my++5Cr3ZHtDTYb560wpIIggiZ6t/NsAjyepPc+ZbZkDzrui2A5T7g1OXtdq4nG1XDCffN3shL+hjj3AAjgNs6dVm/zAKIKGwNgOTwftLJv47JkcQe901G0eM10Ts5DpIJQPW/XTJUSj65BwjhY7Y/3YMdnxHrgcTbNKacFpgbdpFfCJ1ghdGmw+A4pp5DNB7YgEeDRJ3QIWuueif3SX2zeGi4Cm39kCUyS5ziJgePTvzGCspFvp4ox5Xm9phatyN7DsCNWvRI6w1cjcZFRn3Um6CFcXm5Sjs8wgafNVm88BzJRkQFCW04bO5qAj4x1HuZYhBNdWqOvgs= lab"
}

resource "aws_security_group" "default" {
  name = "${var.prefix}-default"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "debian_latest" {
  most_recent = true
  filter {
    name   = "name"
    values = ["debian-*-amd64-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["136693071363"] # Debian's official AWS owner ID for Buster
}

locals {
  DEBIAN_AMI = data.aws_ami.debian_latest.id
}

resource "aws_instance" "ec2" {
  lifecycle {
    ignore_changes = [
      ami,
    ]
  }

  ami           = local.DEBIAN_AMI
  instance_type = local.DEFAULT_INSTANCE_TYPE
  key_name      = aws_key_pair.lab.key_name
  security_groups = [
    aws_security_group.default.name,
  ]
}

output "ip" {
  value = aws_instance.ec2.public_ip
}

output "ssh" {
  value = "admin@${aws_instance.ec2.public_ip}"
}

output "debian-ami" {
  value = data.aws_ami.debian_latest.id
}

resource "random_password" "password" {
  length  = 16
  special = false
  upper   = false
}

output "password" {
  value     = random_password.password.result
  sensitive = true
}

output "list" {
  value = [
    "one",
    "two",
    "three",
  ]
}

output "map" {
  value = {
    foo = "bar"
    baz = "qux"
  }
}
