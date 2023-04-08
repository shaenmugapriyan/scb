provider "aws" {
  region = "eu-west-2"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "custom-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-2a", "eu-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

data "aws_ami" "ubuntu_20" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
}

resource "aws_key_pair" "generated_key" {
  key_name   = "generated_key"
  public_key = tls_private_key.example.public_key_openssh
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = module.vpc.vpc_id

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

resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu_20.id
  instance_type = "t2.micro"
  subnet_id     = module.vpc.public_subnets[0]
  key_name      = aws_key_pair.generated_key.key_name

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  iam_instance_profile = aws_iam_instance_profile.s3_access_profile.name

  tags = {
    Name = "example-instance"
  }
}

resource "aws_iam_instance_profile" "s3_access_profile" {
  name = "s3-access-profile"
  role = aws_iam_role.s3_access_role.id
}

resource "aws_iam_role" "s3_access_role" {
  name = "s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.s3_access_role.name
}


output "private_key" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
}


resource "tls_private_key" "user_key" {
  for_each  = { for user in var.create_usernames : user => user }
  algorithm = "RSA"
}

resource "null_resource" "create_user" {
  for_each = { for user in var.create_usernames : user => user }

  connection {
    type        = "ssh"
    host        = aws_instance.example.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.example.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "sudo useradd ${each.key} -m",
      "sudo usermod -p '' ${each.key}",
      "sudo mkdir -p /home/${each.key}/.ssh",
      "sudo bash -c \"echo '${tls_private_key.user_key[each.key].public_key_openssh}' > /home/${each.key}/.ssh/authorized_keys\"",
      "sudo chown -R ${each.key}:${each.key} /home/${each.key}/.ssh",
      "sudo chmod 700 /home/${each.key}/.ssh",
      "sudo chmod 600 /home/${each.key}/.ssh/authorized_keys",
    ]
  }
}

resource "null_resource" "delete_user" {
depends_on = [
    null_resource.create_user
  ]
  for_each = { for user in var.delete_usernames : user => user }

  connection {
    type        = "ssh"
    host        = aws_instance.example.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.example.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "sudo userdel -r ${each.key}",
    ]
  }
}
output "user_private_keys" {
  value = {
    for user in var.create_usernames : user => tls_private_key.user_key[user].private_key_pem
  }
  sensitive = true
}


locals {
  s3_bucket_name = "my-terraform-state-bucket-hello1"
  s3_folder_name = "user_home_directories"
  region         = "eu-west-2"
}

# create S3 bucket for storing Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.s3_bucket_name
  acl    = "private"

  versioning {
    enabled = false
  }

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "dev"
  }
}

# create S3 bucket for storing user home directories
resource "aws_s3_bucket" "user_home_directories" {
  bucket = "my-user-home-directories-bucket"
  acl    = "private"

  tags = {
    Name        = "User Home Directories Bucket"
    Environment = "dev"
  }
}

# configure Terraform to use the S3 bucket for storing state

# sync home directories to S3 bucket
resource "null_resource" "sync_home_directories" {

depends_on = [
    null_resource.create_user,
    null_resource.delete_user
  ]

  connection {
    type        = "ssh"
    host        = aws_instance.example.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.example.private_key_pem
  }
provisioner "remote-exec" {
    inline = [
        "sudo apt-get update && sudo apt-get install unzip -y",
        "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'",
        "unzip awscliv2.zip",
        "sudo ./aws/install",
        "rm -rf aws awscli2.zip",
        "echo '#!/bin/bash' > /home/ubuntu/sync.sh",
        "echo 'while true' >> /home/ubuntu/sync.sh",
        "echo 'do' >> /home/ubuntu/sync.sh",
        "echo '  aws s3 sync /home/ s3://my-user-home-directories-bucket/ --delete --exclude \".ssh/*\"' >> /home/ubuntu/sync.sh",
        "echo '  sleep 60' >> /home/ubuntu/sync.sh",
        "echo 'done' >> /home/ubuntu/sync.sh",
        "chmod 777 /home/ubuntu/sync.sh",
        "/home/ubuntu/sync.sh &> /home/ubuntu/sync.log &"
    ]
}

}


