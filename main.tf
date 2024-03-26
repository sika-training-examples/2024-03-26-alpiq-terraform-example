terraform {
  backend "http" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.42.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
  }
  required_version = ">= 1.5"
}

variable "aws_access_key" {
  type = string
}
variable "aws_secret_key" {
  type = string
}
variable "prefix" {
  type = string
}

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

# resource "aws_vpc" "main" {
#   cidr_block = "10.10.0.0/16"
# }

# resource "aws_subnet" "main" {
#   count = 3

#   vpc_id     = aws_vpc.main.id
#   cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)

# }

resource "random_integer" "int" {
  count = 5

  min = 1
  max = 100
}

output "int" {
  value = [for el in random_integer.int : el.result]
}

locals {
  s3_default = {
    acl = "private"
  }
  buckets = {
    # "0" = {}
    "1" = merge(local.s3_default, {})
    # "2" = {
    #   acl = "private"
    # }
    "foo" = merge(local.s3_default, {
      acl = "private"
    })
    "bar" = merge(local.s3_default, {
      acl = "private"
    })
  }
}

resource "aws_s3_bucket" "example" {
  for_each = local.buckets

  bucket = "${var.prefix}-example-data-${each.key}"
}


resource "aws_s3_bucket_ownership_controls" "example" {
  for_each = local.buckets

  bucket = aws_s3_bucket.example[each.key].bucket
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "example" {
  for_each = local.buckets

  depends_on = [aws_s3_bucket_ownership_controls.example]
  bucket     = aws_s3_bucket.example[each.key].bucket
  acl        = each.value.acl
}

output "bucket" {
  value = [for el in aws_s3_bucket.example : el.bucket]
}


resource "aws_s3_bucket" "demo" {
  for_each = {
    "1" = {}
    "2" = {}
    "3" = {}
  }

  bucket = "${var.prefix}-demo-${each.key}"
  tags = {
    created_at = timestamp()
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

locals {
  foo_enabled = false
  foo         = local.foo_enabled ? random_string.foo[0].result : null
}

resource "random_string" "foo" {
  count = local.foo_enabled ? 1 : 0

  length  = 4
  special = false
}

output "foo" {
  value = local.foo
}


resource "aws_instance" "cloud_init_example" {
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
  user_data = <<-EOF
#cloud-config
ssh_pwauth: yes
password: asdfasdf2020
chpasswd:
  expire: false
write_files:
- path: /html/index.html
  permissions: "0755"
  owner: root:root
  content: |
    <h1>Hello from Cloud Init & AWS</h1>
runcmd:
  - |
    apt update
    apt install -y curl sudo git nginx
    curl -fsSL https://ins.oxs.cz/slu-linux-amd64.sh | sudo sh
    cp /html/index.html /var/www/html/index.html
EOF
}

output "cloud_init_example_ip" {
  value = aws_instance.cloud_init_example.public_ip
}

output "cloud_init_example_url" {
  value = "http://${aws_instance.cloud_init_example.public_ip}"
}


resource "aws_s3_bucket" "aaa" {
  bucket = "${var.prefix}-aaa"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.prefix}-xxx"
}

resource "aws_instance" "xxx" {
  ami           = local.DEBIAN_AMI
  instance_type = local.DEFAULT_INSTANCE_TYPE
  key_name      = aws_key_pair.lab.key_name
  security_groups = [
    aws_security_group.default.name,
  ]
  subnet_id = "subnet-075223b7b5686846f"
  tags = {
    Name = "xxx"
  }
  vpc_security_group_ids = ["sg-03934e48a74f38ad5"]

  lifecycle {
    ignore_changes = [
      ami,
    ]
  }
}

resource "aws_s3_bucket" "yyy" {
  bucket = "${var.prefix}-yyy"
}


module "net-foo" {
  source = "./modules/net"

  name         = "${var.prefix}-foo"
  cidr_block   = "10.10.0.0/16"
  subnet_count = 3
}

output "net-foo-vpc-id" {
  value = module.net-foo.vpc_id
}

output "net-foo-subnet-ids" {
  value = module.net-foo.subnet_ids
}

module "net-bar" {
  source = "git::https://github.com/sika-training-examples/2024-03-26-alpiq-terraform-example.git//modules/net?ref=415e72b"

  name       = "${var.prefix}-bar"
  cidr_block = "10.20.0.0/16"
}

module "net-baz" {
  source  = "gitlab.sikademo.com/exampke/net/aws"
  version = "0.1.0"

  name         = "${var.prefix}-baz"
  cidr_block   = "10.30.0.0/16"
  subnet_count = 3
}
