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

resource "aws_instance" "ec2instance" {
  ami = "ami-077005b1c0bc7a036"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2_22_80_8080.id]
}

resource "null_resource" "provisioning" {
  connection {
    type = "ssh"
    host = aws_instance.ec2instance.public_ip
    user = "ubuntu"
    password = "ubuntu"
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

  depends_on = [aws_instance.ec2instance]
}

resource "aws_security_group" "ec2_22_80_8080" {
  name = "22_80_8080"
  description = "Allow some traffic"

  ingress {
    from_port = 22
    protocol  = "tcp"
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    protocol  = "tcp"
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    protocol  = "tcp"
    to_port   = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}