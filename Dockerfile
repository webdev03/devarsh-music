# Use the official Bun image
FROM oven/bun:1 AS base
WORKDIR /usr/src/app

# Stage for installing dependencies
FROM base AS install
RUN mkdir -p /temp/dev
COPY bun.lockb package.json /temp/dev/
COPY backend/package.json /temp/dev/backend/
COPY frontend/package.json /temp/dev/frontend/

# Install dependencies for the entire workspace
RUN cd /temp/dev && bun install --frozen-lockfile

# Production dependencies stage
FROM base AS production-deps
RUN mkdir -p /temp/prod
COPY bun.lockb package.json /temp/prod
COPY backend/package.json /temp/prod/backend/
COPY frontend/package.json /temp/prod/frontend/

# Install only production dependencies
RUN cd /temp/prod && bun install --frozen-lockfile --production

# Build stage
FROM base AS build
COPY --from=install /temp/dev/node_modules node_modules
COPY . .

# Build backend and frontend
RUN bun run build:backend
RUN bun run build:frontend

# Final release stage
FROM base AS release
# Copy production node_modules
COPY --from=production-deps /temp/prod/node_modules node_modules

# Copy built artifacts from build stage
COPY --from=build /usr/src/app/backend/dist ./backend
COPY --from=build /usr/src/app/frontend/dist ./frontend

# Copy necessary files
COPY backend/package.json ./backend/
COPY frontend/package.json ./frontend/

# Expose the port your app runs on
EXPOSE 3000

# Run the backend
USER bun
ENTRYPOINT ["bun", "run", "backend/src/index.ts"]