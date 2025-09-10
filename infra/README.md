# Infrastructure for Micro-URL (Terraform)

This directory contains the Terraform configuration for the Micro-URL project.
The structure is modular so individual components can be developed, reused, and maintained independently.

## SSL
SSL certificates are managed through AWS Certificate Manager (ACM) to ensure secure communication over HTTPS.  
Certificates are provisioned for both the root domain and its subdomains, and validated via DNS.  

TLS termination for end-users occurs at AWS CloudFront, which fronts both the frontend (S3) and backend services (ALB).
ACM certificates are provisioned in the appropriate AWS region for CloudFront (us-east-1) and attached to the CloudFront distribution for the root domain (e.g., `murl.pw`, `*.murl.pw`).
Additional ACM certificates may be provisioned for the internal ALB only if you enable HTTPS between CloudFront and the ALB (not required in the current HTTP setup).

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
   - Optional: for encrypted traffic between CloudFront and the ALB, attach a certificate to the ALB and update the origin config to HTTPS.

4. **Configure DNS (e.g., Cloudflare):**
   - Create CNAME records for both the root domain (`murl.pw`) and any subdomains, pointing them to the CloudFront distribution domain name.
   - Enable the proxy (orange cloud) if using Cloudflare; keep ACM validation CNAME records DNS only (grey cloud).

Following these steps ensures secure, trusted SSL/TLS encryption for your Micro-URL services, with TLS terminating at CloudFront for all end-user connections.

## CloudFront Integration

CloudFront is the unified entry point for all frontend and backend traffic.

- Origins:
  - S3: Serves the frontend static site and assets via an S3 bucket with Origin Access Control (OAC).
  - ALB: Handles backend API and redirect services.

- Routing logic:
  - A Lambda@Edge function inspects the request path and routes:
    - `/shorten*` → ALB (shortening service)
    - single-segment slugs without a dot (e.g., `/abc123`) → ALB (forwarding service)
    - everything else → S3 (frontend)

- DNS:
  - Public DNS records point to the CloudFront distribution domain.
  - ACM validation CNAME records must remain DNS only.

This setup keeps TLS, caching, and request routing at CloudFront while separating frontend (S3) and backend (ALB) concerns.

## Structure
```
infra/
  main.tf          # Root configuration, wires all modules together
  variables.tf     # Global variables for the root config
  outputs.tf       # Outputs exposed from the root config
  terraform.tfvars # Default values for DEV (e.g. VPC CIDR, AWS region)

modules/
  ecs-cluster/
    main.tf        # ECS cluster + execution role
    variables.tf
    outputs.tf

  network/
    main.tf        # VPC, subnets, routing, gateways
    variables.tf   # Input variables for the network module
    outputs.tf     # Outputs like vpc_id, subnet_ids

  alb/
    main.tf        # Application Load Balancer, listeners, routing rules
    variables.tf
    outputs.tf

  ecs-services/
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

  cdn/
    main.tf        # S3 bucket (frontend), OAC, Lambda@Edge, CloudFront distribution
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

1. Define core infrastructure using network and ALB modules.
2. Add backend services with the ecs-services module (shortening, forwarding).
3. Provision a Redis instance with the redis module.
4. Expose endpoints via a CloudFront distribution (S3 + ALB) and Lambda@Edge for path-based routing.


## First Deployment (Bootstrap)

### Prerequisites
- AWS CLI configured with appropriate credentials and default region.
- Docker installed and running.
- Terraform v1.12.2+ (matches `required_version` in `main.tf`).
- Initialize Terraform in `infra/`: `terraform init`.

### 1) Provision core infra (without ECS/CloudFront)
- Temporarily comment out the ECS services and the CloudFront distribution blocks in `main.tf`.
- Run `terraform apply` to create the VPC, ALB, Redis, ECR repositories, and the S3 frontend bucket.

### 2) ECR login
- Authenticate Docker with ECR by running:
  ```
  make ecr-login
  ```
- This uses `AWS_ACCOUNT_ID` and `AWS_REGION` from the Makefile. You can override on the command line, e.g. `make AWS_REGION=us-east-1 ecr-login`.

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
- Run `terraform apply`.
- CloudFront becomes the TLS entry point for end-users.
- Lambda@Edge routes `/shorten*` and single-segment slugs to the ALB; the default goes to S3.

### 6) Smoke tests
- Check health endpoint:
  ```
  curl https://murl.pw/health
  ```
- Test shortening API:
  ```
  curl -X POST https://murl.pw/shorten -d '{"url":"https://example.com"}' -H "Content-Type: application/json"
  ```

### Frontend deploy (S3)

To publish the built frontend to the S3 bucket used by CloudFront:

```
make frontend            # uses DOMAIN from Makefile (default: murl.pw)
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

## Notes and caveats

- Secrets: do not commit `.env` files in `infra/` (or anywhere). If a token or secret was committed, rotate it immediately and remove the file from the repo history.
- Terraform state: do not commit Terraform state or `.terraform/` directories. Prefer a remote backend (e.g., S3 + DynamoDB) for production. If using the local backend for experiments, add `terraform.tfstate*` and `.terraform/` to `.gitignore`.
- Lambda@Edge origin overrides: the Lambda at `infra/lambda/index.js` currently contains hardcoded ALB and S3 domain names. Update these when infrastructure changes, or improve by wiring values from Terraform outputs (recommended) to avoid drift.
- ALB origin protocol: the ALB origin is configured for HTTP from CloudFront. For HTTPS to the ALB, enable an ACM cert on the ALB and change the CloudFront origin config accordingly.
- Certificates: CloudFront requires ACM certificates in `us-east-1`.
