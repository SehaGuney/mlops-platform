terraform {
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
}
