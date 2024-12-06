#!/bin/sh
# Install dependencies
bun install --frozen-lockfile

# Build the frontend
bun run build

# Start the backend
bun run start
