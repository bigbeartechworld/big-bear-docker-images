# Use pihole base image
FROM pihole/pihole:2025.04.0

# Install Unbound using apk (Alpine package manager)
RUN apk update && apk add --no-cache unbound \
  && rm -rf /var/cache/apk/*

# Copy the root hints file
# https://www.internic.net/domain/named.root
COPY unbound/root.hints /var/lib/unbound/root.hints

# Set permissions for Unbound
# Note: Alpine uses 'unbound' user/group by default for the unbound package
RUN chown -R unbound:unbound /var/lib/unbound

# Copy Unbound configuration files
COPY unbound/unbound.conf /etc/unbound/unbound.conf

# Copy Pi-hole configuration files
COPY pihole/setupVars.conf /etc/pihole/setupVars.conf

# Copy the startup script to a standard location and make it executable
COPY unbound/start-unbound.sh /start-unbound.sh
RUN chmod +x /start-unbound.sh

# Entrypoint - using the absolute path with brackets
ENTRYPOINT ["/start-unbound.sh"]

# Healthcheck for Pi-hole and Unbound
HEALTHCHECK --interval=1m --timeout=10s \
  CMD dig +short @127.0.0.1 -p 53 pi.hole || exit 1; \
  dig +short @127.0.0.1 -p 5353 example.com || exit 1
