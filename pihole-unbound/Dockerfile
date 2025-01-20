# Use pihole base image
FROM pihole/pihole:2024.07.0

# Set environment variables for Unbound installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package list, install Unbound and clean up in one layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends unbound && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create the Unbound service directory
RUN mkdir -p /etc/services.d/unbound

# Create the Unbound service run script
COPY unbound/unbound_run_script /etc/services.d/unbound/run
RUN chmod +x /etc/services.d/unbound/run

# Copy the root hints file
# https://www.internic.net/domain/named.root
COPY unbound/root.hints /var/lib/unbound/root.hints

# Set permissions for Unbound
RUN chown -R unbound:unbound /var/lib/unbound

# Copy Unbound configuration files
COPY unbound/unbound.conf /etc/unbound/unbound.conf

# Copy Pi-hole configuration files
COPY pihole/setupVars.conf /etc/pihole/setupVars.conf

# Set correct permissions for Pi-hole files
RUN chown -R www-data:www-data /etc/pihole && \
    chmod -R 755 /etc/pihole

# Add a volume for Unbound configuration
VOLUME ["/etc/unbound"]

# Expose Unbound DNS port
EXPOSE 5353/tcp 5353/udp

# Entrypoint
ENTRYPOINT ./s6-init

# Healthcheck for Pi-hole and Unbound
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD dig +short @127.0.0.1 -p 53 pi.hole || exit 1; \
  dig +short @127.0.0.1 -p 5353 example.com || exit 1
