# Use the official Bun image
FROM oven/bun:1

# Set working directory
WORKDIR /app

# Copy package.json files
COPY package.json bun.lockb ./
COPY backend/package.json ./backend
COPY frontend/package.json ./frontend

RUN ls -la

# Install dependencies
RUN bun install --frozen-lockfile

# Copy the rest of the application
COPY . .

# Build stage
ENV NODE_ENV=production
RUN bun run build

# Set the entrypoint to run pkg-a
CMD ["bun", "run", "backend/src/index.ts"]