provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "base-infra-bucket-state"
    key = "test/app/1"
    region = "us-east-1"
  }
}

resource "aws_key_pair" "tf-key-pair" {
  key_name = "tf-key-pair"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "local_file" "tf-key" {
  content = tls_private_key.rsa.private_key_pem
  filename = aws_key_pair.tf-key-pair.key_name
}

resource "aws_instance" "ec2instance" {
  ami = "ami-0827c0525a410fc44"
  instance_type = "t2.micro"
  key_name = aws_key_pair.tf-key-pair.key_name

#  provisioner "file" {
#
#    source = "files/"
#    destination = "/home/ubuntu"
#
#    connection {
#      type = "ssh"
#      user = "ubuntu"
#      host = self.public_ip
#    }
#  }

#  provisioner "remote-exec" {
#
#    inline = [
#      "docker-compose -d up"
#    ]
#
#    connection {
#      type = "ssh"
#      user = "ubuntu"
#      host = self.public_ip
#    }
#  }
}

resource "null_resource" "provisioning" {
  connection {
    type = "ssh"
    host = aws_instance.ec2instance.public_ip
    user = "ubuntu"
    private_key = tls_private_key.rsa.private_key_pem
  }
  provisioner "file" {
    source = "files/"
    destination = "/home/ubuntu"
  }
  provisioner "remote-exec" {
    inline = [
      "docker-compose up -d"
    ]
  }
}