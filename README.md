

## Local Development

Start the redis server via docker:

```bash
docker compose -f docker-compose.dev.yml up -d
```
```
micro-url
├─ README.md
├─ bun.lock
├─ docker-compose.dev.yml
├─ iac
├─ package.json
├─ packages
│  ├─ forwading-service
│  │  ├─ README.md
│  │  ├─ package.json
│  │  ├─ src
│  │  │  └─ index.ts
│  │  └─ tsconfig.json
│  ├─ shared
│  │  ├─ db.ts
│  │  ├─ health.ts
│  │  ├─ logger.ts
│  │  ├─ slug.ts
│  │  └─ types.ts
│  └─ shortening-service
│     ├─ README.md
│     ├─ package.json
│     ├─ src
│     │  └─ index.ts
│     └─ tsconfig.json
└─ tsconfig.json

```