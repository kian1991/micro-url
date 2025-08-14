FROM oven/bun:latest AS base
WORKDIR /app


FROM base AS install
RUN mkdir -p /temp/dev
COPY package.json /temp/dev/
RUN cd /temp/dev && bun install

# copy node_modules from temp directory
# then copy all (non-ignored) project files into the image
FROM base AS prerelease
RUN mkdir -p ./forwarding-service
COPY --from=install /temp/dev/node_modules ./forwarding-service/node_modules
# Copy everything from monorepo root into container context
COPY ../../packages/shared ./shared
COPY ../../packages/forwarding-service ./forwarding-service
# Copy local package.json for the build script
COPY ../../packages/forwarding-service/package.json ./forwarding-service/package.json

WORKDIR /app/forwarding-service

ENV NODE_ENV=production
# RUN bun test
RUN bun run build

# copy production dependencies and source code into final image
FROM oven/bun:alpine AS release
COPY --from=prerelease /app/dist/index.js .
ENV NODE_ENV=production
# run the app
EXPOSE 3000/tcp
CMD [ "index.js" ]