terraform {
  backend "s3" {
    bucket = "mlops-platform-models-dev"
    key    = "terraform/state.tfstate"
    region = "eu-central-1"
  }

    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
      }
    }
    
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
}

# For ML models storage
resource "aws_s3_bucket" "models" {
    bucket = "${var.project_name}-models-${var.environment}"
    tags = { Name = "${var.project_name}-models" }

}

# For docker images
resource "aws_ecr_repository" "api" {
    name = "${var.project_name}-api"
    image_tag_mutability = "MUTABLE"
    tags = { Name = "${var.project_name}-ecr" }
    force_delete = true
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.project_name}-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "api" {
  vpc_id = aws_vpc.main.id
  name   = "${var.project_name}-sg"

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  tags = { Name = "${var.project_name}-sg" }
}

# SSH Key
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = file("~/.ssh/mlops_key.pub")
}

# IAM Role — EC2'nin ECR'a erişmesi için
resource "aws_iam_role" "ec2_ecr" {
  name = "${var.project_name}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.ec2_ecr.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-profile"
  role = aws_iam_role.ec2_ecr.name
}

# EC2
resource "aws_instance" "api" {
  ami                    = "ami-0a261c0e5f51090b1" # eu-central-1 Amazon Linux 2023
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.api.id]
  key_name               = aws_key_pair.deployer.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
  EOF

  tags = { Name = "${var.project_name}-api" }
}

resource "aws_eip" "api" {
  domain = "vpc"
  tags = {Name = "${var.project_name}-eip"}
}

resource "aws_eip_association" "eip_assoc" {
  instance_id = aws_instance.api.id
  allocation_id = aws_eip.api.id
}