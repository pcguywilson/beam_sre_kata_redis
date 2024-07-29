# Terraform AWS ECS Fargate Web Application Deployment for Beam Kata

This repository contains Terraform code to deploy a web application on AWS using ECS Fargate, ElastiCache for Redis, and Docker images from Docker Hub.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed
- AWS CLI configured with appropriate IAM permissions to create resources (IAM, VPC, ECS, ElastiCache, etc.)
- Docker image for the web application uploaded to a container registry (e.g., Amazon ECR, Docker Hub).
  

## Project Structure

- `main.tf`: Main Terraform configuration file
- `variables.tf`: Variable definitions
- `outputs.tf`: Outputs definitions

## Variables

The following variables are defined in `variables.tf`:

| Variable             | Description                             | Default                          |
|----------------------|-----------------------------------------|----------------------------------|
| `aws_region`         | AWS region to deploy resources in       | `us-east-2`                      |
| `resource_owner`     | Name used when tagging owner            | `SWilson`                        |
| `app_name`           | Name of the application                 | `beamkata`                       |
| `vpc_id`             | The ID of the VPC                       | `vpc-dfd0c3b7`                   |
| `redis_node_type`    | Instance type for Redis                 | `cache.t2.micro`                 |
| `redis_engine_version` | Version of the Redis engine            | `3.2.10`                         |
| `docker_image`       | Docker image to deploy                  | `beamdental/sre-kata-app:latest` |

## Outputs

The following outputs are defined in `outputs.tf`:

| Output              | Description                             |
|---------------------|-----------------------------------------|
| `ecs_cluster_name`  | Name of the ECS cluster                 |
| `ecs_service_name`  | Name of the ECS service                 |
| `redis_endpoint`    | Endpoint of the Redis cluster           |
| `redis_port`        | Port of the Redis cluster               |
| `load_balancer_dns` | DNS name of the load balancer           |
| `redis_url`         | Redis URL used by the web application   |

## Deployment Instructions
1. **Clone Repo:**

  ```sh
  git clone <repository-url>
  cd project-directory
  ```

2. **Initialize Terraform:**

    ```sh
    terraform init
    ```

3. **Validate the Configuration:**

    ```sh
    terraform validate
    ```

4. **Plan the Deployment:**

    ```sh
    terraform plan
    ```

5. **Apply the Configuration:**

    ```sh
    terraform apply
    ```

    Confirm the apply step by typing `yes` when prompted.

## Accessing the Web Application

After the deployment, you can access your web application using the DNS name of the load balancer. This DNS name is outputted as `load_balancer_dns`:

```sh
echo $(terraform output load_balancer_dns):4567
```

## Cleaning Up

To destroy the resources created by this Terraform configuration:


Confirm the destroy step by typing `yes` when prompted.


## Author

**SWilson**

For any questions or suggestions, feel free to contact me.
