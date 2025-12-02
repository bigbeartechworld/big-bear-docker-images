# ==============================================================================
# Stage 1: Build Unbound from source
# ==============================================================================
FROM debian:bookworm-slim AS builder

# Set shell options for better error handling in pipes
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Unbound version to build
ARG UNBOUND_VERSION=1.24.2

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        libssl-dev \
        libexpat1-dev \
        libnghttp2-dev \
        libevent-dev \
        bison \
        flex \
        && rm -rf /var/lib/apt/lists/*

# Download and extract Unbound source with SHA256 verification
WORKDIR /tmp
RUN curl -sSL "https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz" -o unbound.tar.gz && \
    curl -sSL "https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz.sha256" -o unbound.tar.gz.sha256 && \
    echo "$(cat unbound.tar.gz.sha256)  unbound.tar.gz" | sha256sum -c - && \
    tar xzf unbound.tar.gz && \
    mv unbound-${UNBOUND_VERSION} unbound

# Build Unbound with optimizations and security features
WORKDIR /tmp/unbound
RUN ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-pidfile=/run/unbound.pid \
        --with-rootkey-file=/var/lib/unbound/root.key \
        --with-libevent \
        --with-pthreads \
        --with-ssl \
        --with-libnghttp2 \
        --enable-tfo-client \
        --enable-tfo-server \
        --disable-rpath \
        --disable-static \
    && make -j"$(nproc)" \
    && make install DESTDIR=/tmp/install

# ==============================================================================
# Stage 2: Runtime image
# ==============================================================================
FROM debian:bookworm-slim

# Labels for the image
LABEL maintainer="BigBearTechWorld"
LABEL org.opencontainers.image.source="https://github.com/bigbeartechworld/big-bear-docker-images"
LABEL org.opencontainers.image.description="Unbound DNS recursive resolver for privacy-focused DNS resolution"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.version="1.24.2"

# Install runtime dependencies and dnsutils for healthcheck
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        libssl3 \
        libexpat1 \
        libnghttp2-14 \
        libevent-2.1-7 \
        dnsutils \
    && rm -rf /var/lib/apt/lists/*

# Create unbound user and group
RUN groupadd -r -g 101 unbound && \
    useradd -r -u 101 -g unbound -d /var/lib/unbound -s /usr/sbin/nologin unbound

# Copy Unbound binaries from builder stage
COPY --from=builder /tmp/install/usr/sbin/unbound /usr/sbin/unbound
COPY --from=builder /tmp/install/usr/sbin/unbound-anchor /usr/sbin/unbound-anchor
COPY --from=builder /tmp/install/usr/sbin/unbound-checkconf /usr/sbin/unbound-checkconf
COPY --from=builder /tmp/install/usr/sbin/unbound-control /usr/sbin/unbound-control
COPY --from=builder /tmp/install/usr/sbin/unbound-host /usr/sbin/unbound-host
COPY --from=builder /tmp/install/usr/lib/ /usr/lib/

# Create directory structure and set permissions
RUN mkdir -p /var/lib/unbound /etc/unbound /run && \
    chown -R unbound:unbound /var/lib/unbound && \
    chown unbound:unbound /run

# Copy the root hints file (updated from https://www.internic.net/domain/named.root)
COPY root.hints /var/lib/unbound/root.hints
RUN chown unbound:unbound /var/lib/unbound/root.hints && \
    chmod 644 /var/lib/unbound/root.hints

# Generate/update the root trust anchor for DNSSEC validation
# unbound-anchor will create or update the root.key file
# Note: unbound-anchor returns 1 if the anchor was updated, so we check for actual failure
RUN unbound-anchor -a /var/lib/unbound/root.key; \
    ANCHOR_STATUS=$?; \
    if [ $ANCHOR_STATUS -ne 0 ] && [ $ANCHOR_STATUS -ne 1 ]; then \
        echo "Error: unbound-anchor failed with status $ANCHOR_STATUS"; \
        exit 1; \
    fi && \
    test -f /var/lib/unbound/root.key || (echo "Error: root.key was not created" && exit 1) && \
    chown unbound:unbound /var/lib/unbound/root.key && \
    chmod 644 /var/lib/unbound/root.key

# Copy the Unbound configuration file into the container
COPY ./unbound.conf /etc/unbound/unbound.conf
RUN chown root:unbound /etc/unbound/unbound.conf && \
    chmod 644 /etc/unbound/unbound.conf

# Copy and set permissions for the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose DNS ports (UDP and TCP)
EXPOSE 53/udp 53/tcp

# Start as root - Unbound will drop privileges after binding to port 53
# This is the standard approach for DNS servers that need to bind to privileged ports
ENTRYPOINT ["/entrypoint.sh"]

# Healthcheck for Unbound - verify DNS resolution is working
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD dig +short +time=2 +tries=1 @127.0.0.1 -p 53 nlnetlabs.nl > /dev/null || exit 1
