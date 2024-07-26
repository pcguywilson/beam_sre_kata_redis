variable "aws_region" {
  default = "us-east-2"
}

variable "vpc_id" {
  description = "The ID of the VPC"
  default     = "vpc-dfd0c3b7"
}

variable "redis_node_type" {
  default = "cache.t2.micro"
}

variable "redis_engine_version" {
  default = "3.2.10"
}

variable "docker_image" {
  description = "Docker image to deploy"
  default     = "beamdental/sre-kata-app:latest"
}
