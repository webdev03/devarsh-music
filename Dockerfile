# Use the official Bun image
FROM oven/bun:1 AS base
WORKDIR /usr/src/app

# install dependencies into temp directory
# this will cache them and speed up future builds
FROM base AS install
RUN mkdir -p /temp/dev
COPY bun.lockb package.json /temp/dev/
COPY backend/package.json /temp/dev/backend/
COPY frontend/package.json /temp/dev/frontend/
RUN cd /temp/dev && bun install --frozen-lockfile

# install with --production (exclude devDependencies)
RUN mkdir -p /temp/prod
COPY bun.lockb package.json /temp/prod
COPY backend/package.json /temp/prod/backend/
COPY frontend/package.json /temp/prod/frontend/
RUN cd /temp/prod && bun install --frozen-lockfile --production

# copy node_modules from temp directory
# then copy all (non-ignored) project files into the image
FROM base AS prerelease
COPY --from=install /temp/dev/node_modules node_modules
COPY . .

# build
RUN bun run build

# Final release stage
FROM base AS release
# Copy production node_modules
COPY --from=production-deps /temp/prod/node_modules node_modules

# Copy built artifacts from build stage
COPY --from=build /usr/src/app/backend ./backend
COPY --from=build /usr/src/app/frontend/dist ./frontend/dist

# Copy necessary files
COPY backend/package.json ./backend/
COPY frontend/package.json ./frontend/

# Expose the port your app runs on
EXPOSE 3000

# Run the backend
USER bun
ENTRYPOINT ["bun", "run", "backend/src/index.ts"]