# Build stage
FROM golang:1.24-alpine AS builder

# Install git and build dependencies
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /build

# Clone and build MinIO from source
RUN go install github.com/minio/minio@latest

# Runtime stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache ca-certificates curl su-exec

# Create minio user and group
RUN addgroup -g 1000 minio && \
    adduser -D -u 1000 -G minio minio

# Copy the built binary from builder stage
COPY --from=builder /go/bin/minio /usr/bin/minio

# Copy entrypoint script
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

# Create data directory and set permissions
RUN mkdir -p /data && \
    chown -R minio:minio /data

# Expose MinIO ports
# 9000 - API port
# 9001 - Console port
EXPOSE 9000 9001

# Set volume
VOLUME ["/data"]

# Set entrypoint
ENTRYPOINT ["/usr/bin/entrypoint.sh"]

# Default command
CMD ["minio", "server", "/data", "--console-address", ":9001"]
