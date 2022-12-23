packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "valheim"
  instance_type = "t3a.small"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      architecture        = "x86_64"
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  name = "valheim"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo add-apt-repository -y multiverse",
      "sudo dpkg --add-architecture i386",
      "sudo apt-get update",
      "echo steam steam/question select \"I AGREE\" | sudo debconf-set-selections",
      "echo steam steam/license note '' | sudo debconf-set-selections",
      "sudo apt-get install -y steamcmd",
      "sudo useradd -m steam",
    ]
  }

  provisioner "file" {
    source = "install.sh"
    destination = "/home/ubuntu/install.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /home/ubuntu/install.sh /home/steam/install.sh",
      "sudo chown steam /home/steam/install.sh",
      "sudo chmod +x /home/steam/install.sh",
    ]
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo -u steam {{ .Path }}"
    inline = [
      "cd /home/steam",
      "./install.sh",
    ]
  }
}