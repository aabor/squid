# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.42.0"
    }
  }
  required_version = ">= 0.14.5"
}
provider "aws" {
  region = var.region
}

resource "aws_security_group" "openvpn" {
  name        = "openvpn"
  description = "OpenVPN encrypted communication protocol"
  ingress {
    description = "OpenVPN default port"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "wireguard" {
  name        = "wireguard"
  description = "Wireguard encrypted communication protocol"
  ingress {
    description = "Wireguard default port"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "squid" {
  name        = "squid"
  description = "Squid proxy"
  ingress {
    description = "Squid default port"
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_security_group" "web" {
#   name        = "web"
#   description = "Web server"
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#     ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "SSH access from the VPC"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# resource "aws_ebs_volume" "vms" {
#   availability_zone = var.availability_zone
#   size              = 40
#   tags = {
#     Name = "vms"
#   }
# }
# resource "aws_volume_attachment" "vms" {
#   device_name = "/dev/sdd"
#   volume_id   = aws_ebs_volume.vms.id
#   instance_id = aws_instance.nomachine.id
#   skip_destroy = false
# }
resource "aws_instance" "vpn" {  
  # ami                         = "ami-033d1536350adc8f2" # us-east-2
  ami                         = "ami-0c1921bccbb7794ac" # eu-north-1
  availability_zone           = var.availability_zone
  instance_type               = "t4g.nano"
  vpc_security_group_ids      = [aws_security_group.ssh.id, aws_security_group.openvpn.id, aws_security_group.squid.id, aws_security_group.web.id]
  associate_public_ip_address = true
  tags = {
    Name      = "aabor@vpn"
    Protocols = "TCP, Wireguard, OpenVPN"
    Services = "Squid, Wireguard VPN, OpenVPN"
    Source = "538276064493/alpine-3.18.2-aarch64-uefi-cloudinit-r0"
    SSH = "ssh alpine@$(terraform output --raw public_ip)"
  }
}

output "public_ip" {
  value = aws_instance.vpn.public_ip
}
# output "vms_volume_id" {
#   value = aws_ebs_volume.vms.id
# }
