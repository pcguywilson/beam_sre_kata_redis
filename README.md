# beam_sre_kata

# Deploying containerized AWS web app with Redis dependency

* Redis
* ECS 
* App - beamdental/sre-kata-app


Summary of Configuration Files
* main.tf: Contains the main configuration for creating the ECS cluster, security group, ElastiCache Redis cluster, ECS task definition, ECS service, and load balancer.
* variables.tf: Defines the variables used in the Terraform configuration, including AWS region, resource owner, application name, VPC ID, Redis node type, Redis engine version, and Docker image.
* outputs.tf: Provides outputs for important resources, such as ECS cluster name, ECS service name, Redis endpoint, Redis port, load balancer DNS name, and Redis URL.