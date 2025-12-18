# Infrastructure Overview

The Terraform stack under `infra/` targets AWS and pins Terraform \>=1.12.2 with a local state backend. Providers include a primary region (default `eu-central-1`) plus a `us-east-1` alias so CloudFront certificates can be queried without switching workspaces.

## Key Components
- **Networking (`modules/network`)** builds a DNS-enabled VPC with paired public/private subnets, an Internet Gateway, and a NAT gateway-backed route table for private workloads.
- **Application Load Balancer (`modules/alb`)** exposes HTTP on the public subnets. Listener rules send `/shorten*` to the shortening target group, while other paths default to the forwarding service.
- **Compute (`modules/ecs-cluster`, `modules/ecs-services`)** provisions an ECS Fargate cluster, standard execution role, and two services that pull `:latest` images from ECR. Each service injects `REDIS_URL`, `BASE_URL`, and `PORT` environment variables and optionally streams logs to CloudWatch.
- **Stateful Services (`modules/redis`)** deploys a single-node ElastiCache Redis cluster inside private subnets and restricts access to the ECS task security groups.
- **Container Registry (`modules/ecr`)** keeps separate repositories for shortening/forwarding images, enabling push-time scanning and pruning to the 10 freshest images.
- **Edge & Static Delivery (`modules/cdn`)** creates the S3 frontend bucket, CloudFront distribution, and Lambda@Edge router that examines requests and forwards either to S3 or the ALB while enforcing TLS via the ACM certificate.
- **Lambda Router (`lambda/index.js`)** hard-codes the current ALB and S3 hostnames to steer `/shorten` and single-segment slug paths toward the ALB and everything else to S3; update these hostnames when infrastructure names change.

## Topology Diagram
```mermaid
graph TD
    User((Client))
    CF[CloudFront Distribution]
    Lambda[Lambda@Edge Router]
    S3[S3 Frontend Bucket]
    ALB[Application Load Balancer]
    Shortening[ECS Service: shortening]
    Forwarding[ECS Service: forwarding]
    Redis[(ElastiCache Redis)]
    ECRShort[ECR Repo: shortening]
    ECRFwd[ECR Repo: forwarding]
    VPC[VPC + Subnets/NAT]

    User -->|HTTPS| CF
    CF -->|Origin-request| Lambda
    Lambda -->|Assets| S3
    Lambda -->|/shorten & slugs| ALB
    ALB -->|Target Group| Shortening
    ALB -->|Target Group| Forwarding
    Shortening -->|Reads/Writes| Redis
    Forwarding -->|Reads| Redis
    Shortening -->|Image :latest| ECRShort
    Forwarding -->|Image :latest| ECRFwd
    ALB --- VPC
    Redis --- VPC
    Shortening --- VPC
    Forwarding --- VPC
```

## Useful Outputs
- `terraform output alb_dns_name` reveals the public ALB endpoint used by Lambda@Edge.
- `terraform output cloudfront_domain_name` surfaces the distribution domain you should map to your public DNS.
- `terraform output s3_bucket_domain_name` is helpful for verifying static asset uploads.
