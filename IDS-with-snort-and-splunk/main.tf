# Vars

variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "app_subnet_az" {
  description = "Application subnet availability zone. (Must be within specified AWS region)"
  type        = string
  default     = "eu-west-2a"
}

variable "debian_ami" {
  description = "Snort instance Debian AMI."
  type        = string
  default     = "ami-048df70cfbd1df3a9"
}

# Provider Configuration

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "tls" {
}


# SGs

resource "aws_security_group" "snort_debian_sg" {
  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    },
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = -1
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "icmp"
      security_groups  = []
      self             = false
      to_port          = -1
    },
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = "Allow FTP traffic"
      from_port        = 21
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 21
    },
  ]
}

resource "aws_security_group" "splunk_debian_sg" {
  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    },
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = "Splunk Enterprise"
      from_port        = 8000
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 8000
    },
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = "Splunk input TCP port"
      from_port        = 8089
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 8089
    },
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = "Splunk input TCP port"
      from_port        = 9097
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 9097
    },
  ]
}

# EC2s

resource "tls_private_key" "snort_debian_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "snort_debian_ssh" {
  key_name   = "snort_debian_ssh"
  public_key = tls_private_key.snort_debian_ssh.public_key_openssh
}

resource "local_file" "snort_debian_ssh" {
  content         = tls_private_key.snort_debian_ssh.private_key_pem
  filename        = ".ssh/snort_debian_ssh.pub"
  file_permission = "0600"
}

resource "aws_instance" "snort_debian" {
  ami                         = var.debian_ami
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.snort_debian_sg.id]
  key_name                    = aws_key_pair.snort_debian_ssh.key_name
  associate_public_ip_address = true
}

resource "null_resource" "snort_debian" {
  provisioner "remote-exec" {
    connection {
      host        = aws_instance.snort_debian.public_dns
      type        = "ssh"
      user        = "admin"
      private_key = tls_private_key.snort_debian_ssh.private_key_pem
    }

    inline = ["echo 'snort_debian is ready.'"]
  }

  provisioner "local-exec" {
    command = "echo run the playbook!!"
  }
}

resource "tls_private_key" "splunk_debian_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "splunk_debian_ssh" {
  key_name   = "splunk_debian_ssh"
  public_key = tls_private_key.splunk_debian_ssh.public_key_openssh
}

resource "local_file" "splunk_debian_ssh" {
  content         = tls_private_key.splunk_debian_ssh.private_key_pem
  filename        = ".ssh/splunk_debian_ssh.pub"
  file_permission = "0600"
}

resource "aws_instance" "splunk_debian" {
  ami                         = var.debian_ami
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.splunk_debian_sg.id]
  key_name                    = aws_key_pair.splunk_debian_ssh.key_name
  associate_public_ip_address = true
}

resource "null_resource" "splunk_debian" {
  provisioner "remote-exec" {
    connection {
      host        = aws_instance.splunk_debian.public_dns
      type        = "ssh"
      user        = "admin"
      private_key = tls_private_key.splunk_debian_ssh.private_key_pem
    }

    inline = ["echo 'splunk_debian is ready.'"]
  }

  provisioner "local-exec" {
    command = "echo run the playbook!!"
  }
}

# Outputs

output "snort_debian_public_ip" {
  value = aws_instance.snort_debian.public_ip
}

output "splunk_debian_public_ip" {
  value = aws_instance.splunk_debian.public_ip
}
