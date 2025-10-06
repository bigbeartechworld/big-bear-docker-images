# Use an official Debian-based image as a base
FROM debian:bookworm-slim

# Install Unbound and clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends unbound && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Generate the root key using unbound-anchor
COPY root.key /var/lib/unbound/root.key

RUN chown unbound:unbound /var/lib/unbound/root.key
RUN chmod 644 /var/lib/unbound/root.key

# Copy the root hints file
# https://www.internic.net/domain/named.root
COPY root.hints /var/lib/unbound/root.hints

# Copy the Unbound configuration file into the container
COPY ./unbound.conf /etc/unbound/unbound.conf

# Expose the DNS port (UDP)
EXPOSE 53/udp

# Start Unbound with the configuration file when the container runs
CMD ["unbound", "-vvv", "-c", "/etc/unbound/unbound.conf"]

# Healthcheck for Unbound
# HEALTHCHECK --interval=1m --timeout=10s \
#   CMD dig +short @127.0.0.1 -p 53 example.com || exit 1
