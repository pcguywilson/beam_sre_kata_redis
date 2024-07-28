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

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "172.31.0.0/16"
  tags       = local.common_tags
}

# Create public subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr_blocks)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr_blocks[count.index]
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags              = local.common_tags
}

# Create private subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr_blocks)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags              = local.common_tags
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = local.common_tags
}

# Create NAT Gateway and Elastic IP for NAT
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = local.common_tags
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = local.common_tags
}

# Create route tables for public and private subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = local.common_tags

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = local.common_tags

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}

# Associate route tables with subnets
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidr_blocks)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidr_blocks)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
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
  vpc_id      = aws_vpc.main.id

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
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# Create an ElastiCache Redis cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.app_name}-redis-cluster"
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name

  security_group_ids = [aws_security_group.webapp_sg.id]
  tags               = local.common_tags
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.app_name}-redis-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  tags       = local.common_tags
}

# Create an ECS task definition
resource "aws_ecs_task_definition" "webapp_task" {
  family                   = "${var.app_name}-webapp-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "${var.app_name}-webapp"
    image     = var.docker_image
    essential = true
    portMappings = [{
      containerPort = 4567
      hostPort      = 4567
    }]
    environment = [
      {
        name  = "REDIS_URL"
        value = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.port}"
      }
    ]
  }])

  tags = local.common_tags
}

# Create an ECS service
resource "aws_ecs_service" "webapp_service" {
  name            = "${var.app_name}-webapp-service"
  cluster         = aws_ecs_cluster.webapp_cluster.id
  task_definition = aws_ecs_task_definition.webapp_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = aws_subnet.public[*].id
    security_groups = [aws_security_group.webapp_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.webapp_tg.arn
    container_name   = "${var.app_name}-webapp"
    container_port   = 4567
  }

  tags = local.common_tags
}

# Create an Application Load Balancer
resource "aws_lb" "webapp_lb" {
  name               = "${var.app_name}-webapp-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webapp_sg.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = local.common_tags
}

# Create a target group for the load balancer
resource "aws_lb_target_group" "webapp_tg" {
  name     = "${var.app_name}-webapp-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = local.common_tags
}

# Create a listener for the load balancer
resource "aws_lb_listener" "webapp_listener" {
  load_balancer_arn = aws_lb.webapp_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp_tg.arn
  }

  tags = local.common_tags
}

# Get available availability zones
data "aws_availability_zones" "available" {}

variable "aws_region" {
  default = "us-east-2"
}

variable "resource_owner" {
  description = "Name used when tagging owner"
  default     = "SWilson"
}

variable "app_name" {
  description = "Name of app"
  default     = "beamkata"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  default     = "172.31.0.0/16"
}

variable "public_subnet_cidr_blocks" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["172.31.1.0/24", "172.31.2.0/24"]
}

variable "private_subnet_cidr_blocks" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["172.31.3.0/24", "172.31.4.0/24"]
}

variable "redis_node_type" {
  default = "cache.t2.micro"
}

variable "docker_image" {
  description = "Docker image to deploy"
  default     = "beamdental/sre-kata-app:latest"
}
