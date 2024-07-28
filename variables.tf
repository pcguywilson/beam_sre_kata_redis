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
  default = "3.2.10"
}

variable "docker_image" {
  description = "Docker image to deploy"
  default     = "beamdental/sre-kata-app:latest"
}
