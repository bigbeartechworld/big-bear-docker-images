# Use a small base image
FROM alpine:3.24.1

# Install dependencies
RUN apk --no-cache add ca-certificates wget unzip

# Set Pocketbase version
ARG POCKETBASE_VERSION=0.30.1

# Detect the architecture of the building machine
ARG TARGETARCH

# Set the working directory
WORKDIR /app

# Download and unzip Pocketbase
RUN wget https://github.com/pocketbase/pocketbase/releases/download/v${POCKETBASE_VERSION}/pocketbase_${POCKETBASE_VERSION}_linux_${TARGETARCH}.zip \
    && unzip pocketbase_${POCKETBASE_VERSION}_linux_${TARGETARCH}.zip \
    && rm pocketbase_${POCKETBASE_VERSION}_linux_${TARGETARCH}.zip

# Make the binary executable
RUN chmod +x /app/pocketbase

# OCI Image Labels
ARG VERSION
ARG REVISION
LABEL org.opencontainers.image.title="Big Bear PocketBase" \
      org.opencontainers.image.description="PocketBase open source backend in a single file" \
      org.opencontainers.image.url="https://github.com/bigbeartechworld/big-bear-docker-images" \
      org.opencontainers.image.source="https://github.com/bigbeartechworld/big-bear-docker-images" \
      org.opencontainers.image.vendor="BigBearTechWorld" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}"

# Expose the default Pocketbase port
EXPOSE 8090

# Run Pocketbase
CMD ["/app/pocketbase", "serve", "--http=0.0.0.0:8090"]
