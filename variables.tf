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

variable "public_subnet_cidr_blocks" {
  type    = list(string)
  default = ["172.31.0.0/20", "172.31.16.0/20"]
}

variable "private_subnet_cidr_blocks" {
  type    = list(string)
  default = ["172.31.32.0/20", "172.31.48.0/20"]
}
