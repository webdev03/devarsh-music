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
COPY bun.lockb package.json /temp/prod/
COPY backend/package.json /temp/prod/backend/
COPY frontend/package.json /temp/prod/frontend/
RUN cd /temp/prod && bun install --frozen-lockfile --production

# copy node_modules from temp directory
# then copy all (non-ignored) project files into the image
FROM base AS prerelease
COPY --from=install /temp/dev/node_modules node_modules
COPY . .

# build
ENV NODE_ENV=production
RUN bun run build

# copy production dependencies and source code into final image
FROM base AS release
COPY --from=install /temp/prod/node_modules node_modules
COPY --from=prerelease /usr/src/app/backend ./backend
COPY --from=prerelease /usr/src/app/frontend ./frontend
COPY --from=prerelease /usr/src/app/package.json .

# ffmpeg
RUN apt-get update -qq && apt-get install ffmpeg -y

# yt-dlp
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o ~/.local/bin/yt-dlp && chmod a+rx ~/.local/bin/yt-dlp

# run the app
# not reccomended to run as root, please run as bun
USER root 
EXPOSE 3000/tcp
ENTRYPOINT [ "bun", "run", "backend/src/index.ts" ]