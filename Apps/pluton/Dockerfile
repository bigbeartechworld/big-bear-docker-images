# Stage 0: Clone
FROM alpine:latest as source
RUN apk add --no-cache git
WORKDIR /src
ARG PLUTON_VERSION=1a2986b2d59ecd49e82a19df4afa8066b70a20af
RUN git clone https://github.com/plutonhq/pluton.git . && \
    git checkout ${PLUTON_VERSION}

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
RUN apk add --no-cache curl ca-certificates fuse3 bash su-exec

# Create data directory and set permissions
RUN mkdir -p /data /data/logs /data/db /data/config && \
    chown -R node:node /data /app

# Download specific versions of restic and rclone binaries
ARG TARGETARCH
ARG RESTIC_VERSION=0.18.1
ARG RCLONE_VERSION=1.71.2

# Checksums
ARG RESTIC_SHA256_AMD64=680838f19d67151adba227e1570cdd8af12c19cf1735783ed1ba928bc41f363d
ARG RESTIC_SHA256_ARM64=87f53fddde38764095e9c058a3b31834052c37e5826d2acf34e18923c006bd45
ARG RCLONE_SHA256_AMD64=ab9fa5877cee91c64fdfd61a27028a458cf618b39259e5c371dc2ec34a12e415
ARG RCLONE_SHA256_ARM64=e2e2efc7ed143026352d60216ef0d46d3fa4fe9d647eff1bd929e6fea498e6f1

RUN echo "Building for architecture: ${TARGETARCH}" && \
    echo "Installing restic v${RESTIC_VERSION} and rclone v${RCLONE_VERSION}" && \
    # Download restic
    if [ "${TARGETARCH}" = "amd64" ]; then \
        wget -q "https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_amd64.bz2" -O /tmp/restic.bz2; \
        echo "${RESTIC_SHA256_AMD64}  /tmp/restic.bz2" | sha256sum -c -; \
    elif [ "${TARGETARCH}" = "arm64" ]; then \
        wget -q "https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_arm64.bz2" -O /tmp/restic.bz2; \
        echo "${RESTIC_SHA256_ARM64}  /tmp/restic.bz2" | sha256sum -c -; \
    fi && \
    bunzip2 /tmp/restic.bz2 && \
    mv /tmp/restic /usr/local/bin/restic && \
    chmod +x /usr/local/bin/restic && \
    # Download rclone
    if [ "${TARGETARCH}" = "amd64" ]; then \
        wget -q "https://downloads.rclone.org/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-linux-amd64.zip" -O /tmp/rclone.zip; \
        echo "${RCLONE_SHA256_AMD64}  /tmp/rclone.zip" | sha256sum -c -; \
    elif [ "${TARGETARCH}" = "arm64" ]; then \
        wget -q "https://downloads.rclone.org/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-linux-arm64.zip" -O /tmp/rclone.zip; \
        echo "${RCLONE_SHA256_ARM64}  /tmp/rclone.zip" | sha256sum -c -; \
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
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ARG APP_VERSION
ENV NODE_ENV=production \
    IS_DOCKER=true \
    SERVER_PORT=5173 \
    APP_VERSION=${APP_VERSION}

EXPOSE 5173

ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", "--loader", "./loader.mjs", "dist/index.js"]
