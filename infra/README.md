# Infrastructure for Micro-URL (Terraform)

This directory contains the Terraform configuration for the **Micro-URL** project.  
The structure is fully modular so that individual components can be developed, reused, and maintained independently.


## Structure
```
infra/
  main.tf          # Root configuration, wires all modules together
  variables.tf     # Global variables for the root config
  outputs.tf       # Outputs exposed from the root config
  terraform.tfvars # Default values for DEV (e.g. VPC CIDR, AWS region)

modules/
  network/
    main.tf        # VPC, subnets, routing, gateways
    variables.tf   # Input variables for the network module
    outputs.tf     # Outputs like vpc_id, subnet_ids

alb/
  main.tf        # Application Load Balancer, listeners, routing rules
  variables.tf
  outputs.tf

ecs-service/
  main.tf        # ECS task definition + service (including target group binding)
  variables.tf
  outputs.tf

redis/
  main.tf        # ElastiCache Redis cluster
  variables.tf
  outputs.tf

```

## Module Overview

### `network`
- Creates a VPC
- Provisions public and private subnets
- Sets up Internet Gateway and NAT Gateway
- Outputs: `vpc_id`, `public_subnets`, `private_subnets`

### `alb`
- Creates an Application Load Balancer (ALB)
- Defines listeners and routing rules
- Connects ECS services via target groups
- Outputs: `alb_dns_name`, `listener_arn`

### `ecs-service`
- Defines an ECS Task Definition
- Deploys ECS Services (Fargate)
- Attaches services to ALB target groups
- Outputs: `service_name`, `task_definition_arn`

### `redis`
- Creates an ElastiCache Redis cluster
- Runs in private subnets for security
- Outputs: `redis_endpoint`



## Workflow

1. Define core infrastructure using **network** and **alb** modules.  
2. Add backend services with the **ecs-service** module (e.g. shortening-service, forwarding-service).  
3. Provision a Redis instance with the **redis** module.  
4. Expose service endpoints via the ALB.  


## Notes

- **State Management:**  
  For local development, the state is stored in `terraform.tfstate`.  
  For team use, configure a remote backend (e.g. S3 + DynamoDB for locking or HCP).  

- **Environments:**  
  - Start with a single `terraform.tfvars` for `dev`.  
  - Later add `staging` and `prod` either with separate workspaces or env folders.  

