

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
```
micro-url
├─ README.md
├─ bun.lock
├─ docker-compose.dev.yml
├─ iac
├─ package.json
├─ packages
│  ├─ .DS_Store
│  ├─ forwading-service
│  │  ├─ .dockerignore
│  │  ├─ Dockerfile
│  │  ├─ README.md
│  │  ├─ package.json
│  │  ├─ src
│  │  │  ├─ index.ts
│  │  │  └─ schemas.ts
│  │  └─ tsconfig.json
│  ├─ frontend
│  │  ├─ README.md
│  │  ├─ index.html
│  │  ├─ package.json
│  │  ├─ public
│  │  │  ├─ fonts
│  │  │  │  ├─ Ephesis-Regular.ttf
│  │  │  │  └─ LeagueSpartan-VariableFont_wght.ttf
│  │  │  └─ vite.svg
│  │  ├─ src
│  │  │  ├─ App.svelte
│  │  │  ├─ app.css
│  │  │  ├─ assets
│  │  │  │  └─ murl.png
│  │  │  ├─ components
│  │  │  │  ├─ Button.svelte
│  │  │  │  └─ Input.svelte
│  │  │  ├─ lib
│  │  │  │  └─ api
│  │  │  │     └─ shorten-url.ts
│  │  │  ├─ main.ts
│  │  │  ├─ reset.css
│  │  │  └─ vite-env.d.ts
│  │  ├─ svelte.config.js
│  │  ├─ tsconfig.app.json
│  │  ├─ tsconfig.json
│  │  ├─ tsconfig.node.json
│  │  └─ vite.config.ts
│  ├─ shared
│  │  ├─ constants.ts
│  │  ├─ db.ts
│  │  ├─ env.ts
│  │  ├─ error-middleware.ts
│  │  ├─ logger.ts
│  │  ├─ slug.ts
│  │  ├─ tests
│  │  │  ├─ __mocks__
│  │  │  │  ├─ crypto.ts
│  │  │  │  └─ db.ts
│  │  │  ├─ constants.ts
│  │  │  └─ slug.test.ts
│  │  └─ types.ts
│  └─ shortening-service
│     ├─ README.md
│     ├─ package.json
│     ├─ src
│     │  ├─ index.ts
│     │  └─ schemas.ts
│     └─ tsconfig.json
└─ tsconfig.json

```