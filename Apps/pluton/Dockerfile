# Stage 0: Clone
FROM alpine:latest as source
RUN apk add --no-cache git
WORKDIR /src
RUN git clone https://github.com/plutonhq/pluton.git .

ARG APP_VERSION=0.0.1
ARG RESTIC_VERSION=0.18.1
ARG RCLONE_VERSION=1.71.2

# Stage 1: Dependencies
FROM node:24-alpine AS deps
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /workspace
COPY --from=source /src/package.json /src/pnpm-workspace.yaml /src/pnpm-lock.yaml /src/turbo.json ./
COPY --from=source /src/frontend/package.json ./frontend/package.json
COPY --from=source /src/backend/package.json ./backend/package.json
RUN pnpm install --frozen-lockfile

# Stage 2: Frontend Builder
FROM node:24-alpine AS frontend-builder
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /workspace
COPY --from=deps /workspace/node_modules ./node_modules
COPY --from=deps /workspace/pnpm-lock.yaml ./
COPY --from=source /src ./
RUN pnpm install --frozen-lockfile
RUN pnpm --filter @plutonhq/core-frontend build

# Stage 3: Backend Builder
FROM node:24-alpine AS backend-builder
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /workspace
COPY --from=deps /workspace/node_modules ./node_modules
COPY --from=deps /workspace/pnpm-lock.yaml ./
COPY --from=source /src ./
COPY --from=frontend-builder /workspace/frontend/dist ./frontend/dist
RUN pnpm install --frozen-lockfile
RUN pnpm --filter @plutonhq/core-backend build
RUN pnpm --filter @plutonhq/core-backend deploy --prod --legacy /deploy

# Stage 4: Runner
FROM node:24-alpine AS runner
WORKDIR /app
RUN apk add --no-cache curl ca-certificates fuse3 bash

# Create data directory
RUN mkdir -p /data /data/logs /data/db /data/config

# Download specific versions of restic and rclone binaries
ARG TARGETARCH
ARG RESTIC_VERSION=0.18.1
ARG RCLONE_VERSION=1.71.2

RUN echo "Building for architecture: ${TARGETARCH}" && \
    echo "Installing restic v${RESTIC_VERSION} and rclone v${RCLONE_VERSION}" && \
    # Download restic
    if [ "${TARGETARCH}" = "amd64" ]; then \
        wget -q "https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_amd64.bz2" -O /tmp/restic.bz2; \
    elif [ "${TARGETARCH}" = "arm64" ]; then \
        wget -q "https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_arm64.bz2" -O /tmp/restic.bz2; \
    fi && \
    bunzip2 /tmp/restic.bz2 && \
    mv /tmp/restic /usr/local/bin/restic && \
    chmod +x /usr/local/bin/restic && \
    # Download rclone
    if [ "${TARGETARCH}" = "amd64" ]; then \
        wget -q "https://downloads.rclone.org/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-linux-amd64.zip" -O /tmp/rclone.zip; \
    elif [ "${TARGETARCH}" = "arm64" ]; then \
        wget -q "https://downloads.rclone.org/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-linux-arm64.zip" -O /tmp/rclone.zip; \
    fi && \
    apk add --no-cache unzip && \
    unzip -q /tmp/rclone.zip -d /tmp && \
    mv /tmp/rclone-*/rclone /usr/local/bin/rclone && \
    chmod +x /usr/local/bin/rclone && \
    rm -rf /tmp/rclone* && \
    apk del unzip && \
    # Verify installations
    unset RESTIC_VERSION RCLONE_VERSION && \
    restic version && \
    rclone version

# Create Pluton wrapper scripts for rclone and restic
RUN echo '#!/bin/sh' > /usr/local/bin/prclone && \
    echo '# Pluton Wrapper for rclone' >> /usr/local/bin/prclone && \
    echo 'exec /usr/local/bin/rclone --config /data/config/rclone.conf "$@"' >> /usr/local/bin/prclone && \
    chmod +x /usr/local/bin/prclone && \
    echo '#!/bin/sh' > /usr/local/bin/prestic && \
    echo '# Pluton Wrapper for restic' >> /usr/local/bin/prestic && \
    echo 'export RCLONE_CONFIG=/data/config/rclone.conf' >> /usr/local/bin/prestic && \
    echo 'exec /usr/local/bin/restic -o rclone.program=/usr/local/bin/rclone "$@"' >> /usr/local/bin/prestic && \
    chmod +x /usr/local/bin/prestic

COPY --from=backend-builder /deploy ./
COPY --from=source /src/backend/drizzle ./drizzle
COPY --from=backend-builder /workspace/backend/loader.mjs ./loader.mjs
COPY --from=frontend-builder /workspace/frontend/dist ./public

ARG APP_VERSION
ENV NODE_ENV=production \
    IS_DOCKER=true \
    SERVER_PORT=5173 \
    APP_VERSION=${APP_VERSION}

EXPOSE 5173

CMD ["node", "--loader", "./loader.mjs", "dist/index.js"]
