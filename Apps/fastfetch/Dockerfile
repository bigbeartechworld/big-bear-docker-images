FROM alpine:latest

# Install required packages
RUN apk update && \
    apk add --no-cache \
    bash \
    procps \
    curl \
    iproute2 \
    git \
    go \
    vim \
    fastfetch \
    && rm -rf /var/cache/apk/*

# Clone, build, and install gotty
RUN git clone --depth 1 --branch v1.7.2 https://github.com/sorenisanerd/gotty.git /tmp/gotty && \
    cd /tmp/gotty && \
    go build && \
    mv gotty /usr/local/bin/ && \
    cd / && \
    rm -rf /tmp/gotty

# Set the terminal to support UTF-8
ENV LANG=C.UTF-8

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
ARG CREATED
LABEL org.opencontainers.image.title="Big Bear FastFetch" \
      org.opencontainers.image.description="FastFetch system information tool accessible via browser using GoTTY web terminal" \
      org.opencontainers.image.url="https://github.com/bigbeartechworld/big-bear-docker-images" \
      org.opencontainers.image.source="https://github.com/bigbeartechworld/big-bear-docker-images" \
      org.opencontainers.image.vendor="BigBearTechWorld" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.created="${CREATED}"

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
