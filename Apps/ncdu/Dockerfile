FROM golang:alpine as builder

# Install necessary packages
RUN apk add --no-cache \
    git \
    vim

# Clone and build gotty
RUN git clone --depth 1 --branch v1.7.2 https://github.com/sorenisanerd/gotty.git /gotty
WORKDIR /gotty
RUN go build

FROM alpine:3.23.4

# Install ncdu, procps, curl, iproute2, and clean up
RUN apk add --no-cache \
    ncdu \
    procps \
    curl \
    iproute2 \
    vim \
    && rm -rf /var/cache/apk/*

# Copy the built gotty binary from the builder stage
COPY --from=builder /gotty/gotty /usr/local/bin/gotty

# Set the terminal to support UTF-8
ENV LANG=C.UTF-8

# Define the NCDU_PATH environment variable with a default value
ENV NCDU_PATH=/

# Set default authentication (can be overridden at runtime)
# Note: These values should be overridden at runtime for security
ARG GOTTY_AUTH_USER=bigbear
ARG GOTTY_AUTH_PASS=password
ARG GOTTY_AUTH_ENABLED=false
ENV GOTTY_AUTH_USER=${GOTTY_AUTH_USER}
ENV GOTTY_AUTH_PASS=${GOTTY_AUTH_PASS}
ENV GOTTY_AUTH_ENABLED=${GOTTY_AUTH_ENABLED}

# Expose the port gotty will run on
EXPOSE 7681

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# OCI Image Labels
ARG VERSION
ARG REVISION
LABEL org.opencontainers.image.title="Big Bear NCDU" \
      org.opencontainers.image.description="NCDU disk usage analyzer accessible via browser using GoTTY web terminal" \
      org.opencontainers.image.url="https://github.com/bigbeartechworld/big-bear-docker-images" \
      org.opencontainers.image.source="https://github.com/bigbeartechworld/big-bear-docker-images" \
      org.opencontainers.image.vendor="BigBearTechWorld" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}"

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
