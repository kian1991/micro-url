# Infrastructure for Micro-URL (Terraform)

This directory contains the Terraform configuration for the **Micro-URL** project.  
The structure is fully modular so that individual components can be developed, reused, and maintained independently.

## SSL
SSL certificates are managed through AWS Certificate Manager (ACM) to ensure secure communication over HTTPS.  
Certificates are provisioned for both the root domain and its subdomains, and validated via DNS.  

**TLS termination for end-users now occurs at AWS CloudFront,** which fronts both the frontend and backend services.  
ACM certificates are provisioned in the appropriate AWS region for CloudFront (us-east-1) and attached to the CloudFront distribution for the root domain (e.g., `murl.pw`, `*.murl.pw`).  
Additional ACM certificates may be provisioned for the internal ALB, but these are only used for encrypted traffic between CloudFront and the ALB (not directly by end-users).

### Manual Steps to Request and Validate ACM Certificates:

1. **Request Certificates:**
   - Log in to the AWS Management Console and navigate to ACM.
   - Request a public certificate for your root domain (e.g., `example.com`) and wildcard domain (e.g., `*.example.com`).
   - Choose DNS validation as the method for proving domain ownership.

2. **Validate Domain Ownership:**
   - After requesting the certificates, ACM will provide DNS CNAME records.
   - Add these CNAME records to your domain’s DNS configuration.
   - Wait for ACM to validate the records automatically; this may take some time.
   - **Note:** ACM validation CNAME records must remain DNS only (grey cloud in Cloudflare) to allow proper certificate validation.

3. **Attach Certificates:**
   - For end-user HTTPS, attach the ACM certificate (in `us-east-1`) to the CloudFront distribution.
   - For internal encrypted traffic between CloudFront and the ALB (if needed), attach a certificate to the ALB as well.

4. **Configure Cloudflare DNS:**
   - In your Cloudflare dashboard, create CNAME records for both the root domain (`murl.pw`) and subdomains (e.g., `api.murl.pw`), **pointing them to the CloudFront distribution domain name**.
   - Enable the proxy (orange cloud) for these CNAME records to leverage Cloudflare's CDN and security features.
   - Ensure ACM validation CNAME records remain DNS only (grey cloud).

Following these steps ensures secure, trusted SSL/TLS encryption for your Micro-URL services, with TLS terminating at CloudFront for all end-user connections.

## CloudFront Integration

CloudFront acts as the unified entry point for all frontend and backend traffic.

- **Origins:**  
  - **Amplify**: Serves the frontend static site and assets.
  - **ALB**: Handles all backend API and redirect services.

- **Behaviors:**  
  - Requests to `/shorten*` and slug paths (e.g., `/abc123`) are routed to the ALB origin.
  - Requests to `/` and static assets (e.g., `/index.html`, `/assets/*`) are routed to the Amplify origin.

- **DNS:**  
  - Cloudflare DNS CNAME records for the root and subdomains now point to the CloudFront distribution domain.
  - ACM validation CNAME records remain DNS only (grey cloud).

This setup enables CloudFront to handle TLS termination, caching, and routing logic, while separating frontend and backend concerns at the origin level.

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

  ecr/
    main.tf        # ECR repositories for container images
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
- **Only HTTP listener and routing rules are defined** (HTTPS listener is removed for now; CloudFront handles TLS termination)
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

### `ecr`
- Creates AWS ECR repositories for storing Docker images
- Can define lifecycle policies (e.g. keep last 10 images)
- Outputs: `repository_name`, `repository_url`



## Workflow

1. Define core infrastructure using **network** and **alb** modules.  
2. Add backend services with the **ecs-service** module (e.g. shortening-service, forwarding-service).  
3. Provision a Redis instance with the **redis** module.  
4. Expose endpoints via CloudFront behaviors that route to ALB or Amplify.


## First Deployment (Bootstrap)

### Prerequisites
- AWS CLI configured with appropriate credentials and default region.
- Docker installed and running.
- Terraform initialized (`terraform init` run in the `infra/` directory).

### 1) Provision core infra (without ECS/CloudFront)
- Temporarily comment out the ECS services and CloudFront distribution blocks in `main.tf`.
- Run:
  ```
  terraform apply
  ```
- This will create the VPC, ALB, Redis, ECR repositories, and Amplify frontend.

### 2) ECR login
- Authenticate Docker with ECR by running:
  ```
  make ecr-login
  ```
- This uses `AWS_REGION` and `AWS_ACCOUNT_ID` defaults from the Makefile.
- To override, e.g. for a different region:
  ```
  make AWS_REGION=eu-central-1 ecr-login
  ```

### 3) Build & push images
- **Option A (all services):**
  ```
  make deploy-all
  ```
  This builds linux/amd64 images via Docker buildx, tags, and pushes to ECR for both `shortening` and `forwarding` services.

- **Option B (single service):**
  ```
  make SERVICE=shortening deploy
  ```
  or
  ```
  make SERVICE=forwarding deploy
  ```

### 4) Enable ECS services
- Uncomment the ECS service/module blocks in `main.tf`.
- Run:
  ```
  terraform apply
  ```
- ECS will pull the `:latest` images from ECR and start the services behind the ALB.

### 5) Enable CloudFront
- Uncomment the CloudFront distribution block in `main.tf`.
- Run:
  ```
  terraform apply
  ```
- CloudFront becomes the TLS entry point for end-users.
- Routing behaviors will be wired as follows:
  - `/shorten*` → ALB (shortening service)
  - Default `/` and static assets → Amplify frontend
  - If desired, slug paths (`/*`) can also route to ALB for forwarding.

### 6) Smoke tests
- Check health endpoint:
  ```
  curl https://murl.pw/health
  ```
- Test shortening API:
  ```
  curl -X POST https://murl.pw/shorten -d '{"url":"https://example.com"}' -H "Content-Type: application/json"
  ```

### Makefile cheatsheet

- `make ecr-login`  
  Authenticate Docker with AWS ECR.

- `make SERVICE=<name> deploy`  
  Build and push a single service Docker image to ECR.

- `make deploy-all`  
  Build and push all service images (`shortening` and `forwarding`) to ECR.

- `make force-aws-redeploy`  
  Force ECS to redeploy services using latest images.