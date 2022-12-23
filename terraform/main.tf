terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

data "aws_ami" "valheim" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["valheim"]
  }
}

resource "aws_security_group" "valheim" {
  name        = "valheim"
  description = "Allow inbound traffic to the ports for Valheim"

  ingress {
    description = "Valheim"
    from_port   = 2456
    to_port     = 2457
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Valheim"
    from_port   = 2456
    to_port     = 2457
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# TODO: lock this down
resource "aws_security_group" "ssh" {
  name        = "valheim"
  description = "Allow inbound SSH"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "valheim" {
  ami           = data.aws_ami.valheim.id
  instance_type = var.instance_type

  vpc_security_group_ids = [
    aws_security_group.valheim.id,
    aws_security_group.ssh.id,
  ]

#TODO: set this up to run as a service instead
#TODO: redirect logs somewhere
  user_data = <<EOF
#!/bin/bash
sudo -u steam -s
cd /home/steam/valheim

export templdpath=$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export SteamAppId=892970

nohup ./valheim_server.x86_64 -name "mah server" -port 2456 -world "testing" -password "tacos" -public 0 &

export LD_LIBRARY_PATH=$templdpath
  EOF
}
