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
  parameter_group_name = "default.redis3.2"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name

  security_group_ids = [aws_security_group.webapp_sg.id]
  tags = local.common_tags
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.app_name}-redis-subnet-group"
  subnet_ids = local.private_subnet_ids
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
    subnets         = local.public_subnet_ids
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
  subnets            = local.public_subnet_ids

  enable_deletion_protection = false

  tags = local.common_tags
}

# Create a target group for the load balancer
resource "aws_lb_target_group" "webapp_tg" {
  name     = "${var.app_name}-webapp-tg"
  port     = 4567
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id

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
