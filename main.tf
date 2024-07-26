provider "aws" {
  region = var.aws_region
}

# Define a tag map
locals {
  common_tags = {
    Owner = var.resource_owner
    Name  = var.app_name
  }
}

# Use an existing VPC
data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "tag:Name"
    values = ["public"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "tag:Name"
    values = ["private"]
  }
}

# Get subnet IDs
locals {
  public_subnet_ids  = [for subnet in data.aws_subnets.public.ids: subnet]
  private_subnet_ids = [for subnet in data.aws_subnets.private.ids: subnet]
}

# Create an ECS cluster
resource "aws_ecs_cluster" "webapp_cluster" {
  name = "${var.app_name}-cluster"
  tags = local.common_tags
}

# Create a security group
resource "aws_security_group" "webapp_sg" {
  name        = "${var.app_name}-sg"
  description = "Allow traffic to beamkata web app"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 4567
    to_port     = 4567
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cid
