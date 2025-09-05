<h1 align="center">Murl: Your cloud native scalable URL-Shortener</h1>

Tiny URL shortener built with Bun + Hono, a Svelte frontend, Redis for storage, and Traefik as the local API gateway.

This README covers local development only (Traefik in Docker). Production will be added later.

## Overview

- frontend: Svelte + Vite single-page app
- shortening-service: REST API to create short URLs
- forwarding-service: resolves slugs and redirects to the original URL
- shared: common utilities (env parsing, redis client, logger, slug generation)
- Redis: key/value store for URL<->slug mappings
- Traefik: local reverse proxy routing requests to the services
- IaC (production): Terraform on AWS (see infra/)

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

Production setup will be documented later.

## Production IaC (AWS)

This project uses Infrastructure as Code for the production cloud deployment:
- Tooling: Terraform
- Cloud provider: AWS
- Code location: `infra/` (modules for network, ALB, ECS services, and Redis)

Detailed production setup, variables, and deployment steps will be added here later.




# PROD:

```bash
aws ecr get-login-password --region eu-central-1 \
  | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com

```
