# --- Base Stage ---
FROM oven/bun:latest AS base
ARG SERVICE

# Test if service is defined by the --build-arg SERVICE=xxx
RUN test -n "$SERVICE" || (echo "SERVICE not defined!" && exit 1)
WORKDIR /app

# Copy everything from monorepo
COPY . .

# Install only the relevant workspace and its deps
# RUN bun install --filter "packages/${SERVICE}"
RUN bun install --production

# Set working directory to the selected service
WORKDIR /app/packages/${SERVICE}

# Optional: include .env if needed
# COPY .env .env

ENV NODE_ENV=production
# RUN bun test
RUN bun run build

# copy production bundled index.js
FROM oven/bun:alpine AS release
ARG SERVICE

COPY --from=base /app/packages/${SERVICE}/dist/index.js .
ENV NODE_ENV=production

# run the app
EXPOSE 3000/tcp
CMD [ "bun", "run", "index.js" ]