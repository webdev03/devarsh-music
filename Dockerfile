# Use the official Bun image
FROM oven/bun:1

# Set working directory
WORKDIR /app

# Copy root-level files
COPY package.json bun.lockb ./

# Copy workspace directories
COPY backend ./backend
COPY frontend ./frontend

# Debug: Verify directory structure
RUN ls -la && ls -la frontend && ls -la backend

# Install dependencies
RUN bun install --frozen-lockfile

# Copy the rest of the application
COPY . .

# Build stage
ENV NODE_ENV=production
RUN bun run build

# Set the entrypoint to run the backend
CMD ["bun", "run", "backend/src/index.ts"]