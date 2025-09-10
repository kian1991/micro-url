<h1 align="center">Murl: Your cloud native scalable URL-Shortener</h1>

Tiny URL shortener built with Bun + Hono, a Svelte frontend, Redis for storage, and Traefik as the local API gateway.

This README covers local development (Traefik in Docker) and a production outline (Terraform on AWS). See `infra/README.md` for full cloud details.

## Overview

- frontend: Svelte + Vite single-page app
- shortening-service: REST API to create short URLs
- forwarding-service: resolves slugs and redirects to the original URL
- shared: common utilities (env parsing, redis client, logger, slug generation)
- Redis: key/value store for URL<->slug mappings
- Traefik: local reverse proxy routing requests to the services
- IaC (production): Terraform on AWS (CloudFront + S3 + ALB + ECS Fargate + Redis) — see `infra/`

Routing (Traefik):
- POST http://localhost/shorten -> shortening-service (create short URL)
- GET http://localhost/<slug> -> forwarding-service (redirect)

Docs:
- Shortening service Swagger UI: http://localhost:3001/doc-ui
- Forwarding service Swagger UI: http://localhost:3002/doc-ui
- Traefik dashboard: http://localhost:8080

## Prerequisites

- Docker Desktop (Compose v2)
- Bun v1.1+ (https://bun.sh)

## 1) Start infra (Redis + Traefik)

Run from repo root:

```bash
docker compose -f docker-compose.dev.yml up -d
```

What it does:
- Starts Redis on localhost:6379 (data persisted in ./redis-data)
- Starts Traefik on ports 80 (gateway) and 8080 (dashboard)

## 2) Configure environment

Bun loads .env files automatically. Create per-service .env files:

packages/shortening-service/.env
```
REDIS_URL=redis://localhost:6379
BASE_URL=http://localhost
PORT=3001
```

packages/forwarding-service/.env
```
REDIS_URL=redis://localhost:6379
BASE_URL=http://localhost
PORT=3002
```

Frontend needs the API base exposed via Traefik:

packages/frontend/.env.local
```
VITE_API_BASE_URL=http://localhost
```

## 3) Install dependencies

From the repo root (uses workspaces):

```bash
bun install
```

## 4) Run the apps (three terminals)

Shortening API (port 3001):
```bash
cd packages/shortening-service
bun run dev
```

Forwarding API (port 3002):
```bash
cd packages/forwarding-service
bun run dev
```

Frontend (Vite dev server):
```bash
cd packages/frontend
bun run dev
```

Traefik will route:
- POST http://localhost/shorten to 3001
- GET http://localhost/<slug> to 3002

## 5) Verify

- Open Traefik dashboard: http://localhost:8080
- Call shorten API through Traefik:

```bash
curl -sS -X POST http://localhost/shorten \
	-H 'Content-Type: application/json' \
	-d '{"longUrl":"https://example.com"}'
```

Expected response:
```
{ "shortUrl": "http://localhost/abc123" }
```

Open the returned shortUrl in the browser to be redirected.

## Repository structure (simplified)

```
micro-url
├─ docker-compose.dev.yml      # Traefik + Redis for local dev
├─ traefik/
│  └─ dynamic/routes.yml       # File provider config for Traefik
├─ packages/
│  ├─ frontend/                # Svelte app
│  ├─ shortening-service/      # POST /shorten
│  ├─ forwarding-service/      # GET /{slug}
│  └─ shared/                  # common code (env, redis, logger, slug)
└─ redis-data/                 # Redis persistence
```

## Troubleshooting

- Ports 80/8080 already in use: stop other services (e.g., nginx) or change published ports in docker-compose.dev.yml.
- Linux + host.docker.internal: you may need to add an entry or adjust Traefik service URLs to target your host IP. On macOS/Windows it works out of the box.
- Redis connection issues: ensure `docker compose ... up -d` is running and REDIS_URL points to `redis://localhost:6379`.
- 404 on GET /<slug>: make sure you created a short URL first and that forwarding-service is running on port 3002.

---

## Production (AWS)

High-level flow. For details, see `infra/README.md`.

Prerequisites:
- Terraform v1.12.2+, AWS CLI configured, Docker
- AWS account with permissions for ECR, ECS, CloudFront, ACM, S3, ElastiCache

1) Provision infrastructure
- `cd infra && terraform init && terraform apply`
- Creates VPC, ALB, ECS cluster, Redis, ECR repos, S3 bucket, CloudFront, Lambda@Edge.
- Note: `infra/lambda/index.js` routes paths. If you change domain/region, update the hardcoded ALB/S3 hostnames and re-apply, or ask to template it.

2) Authenticate to ECR
- `make ecr-login` (uses `AWS_ACCOUNT_ID` and `AWS_REGION`, defaults set in Makefile)

3) Build and push backend images
- All services: `make deploy-all`
- Single service: `make SERVICE=shortening deploy` or `make SERVICE=forwarding deploy`

4) Deploy frontend to S3
- `make frontend` (uses `DOMAIN` from Makefile; uploads `packages/frontend/dist` to S3)

5) Configure DNS
- Point your domain (e.g., `murl.pw`) to the CloudFront distribution (`terraform output cloudfront_domain_name`). If using Cloudflare, enable proxy on user-facing records and keep ACM validation CNAMEs DNS-only.

6) Redeploy backend (optional)
- Force ECS to pick up latest images: `make force-aws-redeploy`

Useful outputs (`cd infra && terraform output`):
- `cloudfront_domain_name` — target for DNS
- `s3_bucket_domain_name` — frontend bucket
- `alb_dns_name` — ALB endpoint (used by Lambda@Edge and for debugging)
