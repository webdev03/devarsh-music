# Use the official Bun image
FROM oven/bun:1 AS base
WORKDIR /usr/src/app

# Install dependencies into temp directory
FROM base AS install
RUN mkdir -p /temp/dev/frontend /temp/dev/backend
COPY package.json bun.lockb /temp/dev/
COPY frontend/package.json /temp/dev/frontend/
COPY backend/package.json /temp/dev/backend/

WORKDIR /temp/dev
RUN bun install --frozen-lockfile

# Install with --production (exclude devDependencies)
FROM base AS install-prod
RUN mkdir -p /temp/prod/frontend /temp/prod/backend
COPY package.json bun.lockb /temp/prod/
COPY frontend/package.json /temp/prod/frontend/
COPY backend/package.json /temp/prod/backend/

WORKDIR /temp/prod
RUN bun install --frozen-lockfile --production


# Copy node_modules and project files
FROM base AS prerelease
COPY --from=install /temp/dev/node_modules node_modules
COPY --from=install /temp/dev/frontend/node_modules frontend/node_modules
COPY --from=install /temp/dev/backend/node_modules backend/node_modules
COPY . .

# Build stage
ENV NODE_ENV=production
RUN bun run build

# Final release image
FROM base AS release
# Copy root node_modules
COPY --from=install-prod /temp/prod/node_modules node_modules

# Create directories
RUN mkdir -p frontend/node_modules backend/node_modules

# Copy workspace node_modules
COPY --from=install-prod /temp/prod/frontend/node_modules frontend/node_modules
COPY --from=install-prod /temp/prod/backend/node_modules backend/node_modules

# Copy project files
COPY --from=prerelease /usr/src/app/backend ./backend
COPY --from=prerelease /usr/src/app/frontend/dist ./frontend/dist
COPY --from=prerelease /usr/src/app/package.json .

USER bun
EXPOSE 3000
ENTRYPOINT [ "bun", "run", "backend/src/index.ts" ]
