# Use pihole base image
FROM pihole/pihole:2025.02.1

# Set environment variables for Unbound installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package list, install Unbound
RUN apt-get update && apt-get install -y --no-install-recommends unbound

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

# Entrypoint
ENTRYPOINT ./s6-init

# Healthcheck for Pi-hole and Unbound
HEALTHCHECK --interval=1m --timeout=10s \
  CMD dig +short @127.0.0.1 -p 53 pi.hole || exit 1; \
  dig +short @127.0.0.1 -p 5353 example.com || exit 1
