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

variable "redis_node_type" {
  default = "cache.t2.micro"
}

variable "redis_engine_version" {
  default = "7.0"
}

variable "docker_image" {
  description = "Docker image to deploy"
  default     = "beamdental/sre-kata-app:latest"
}

variable "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["172.31.1.0/24", "172.31.2.0/24"]
}

variable "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["172.31.3.0/24", "172.31.4.0/24"]
}
