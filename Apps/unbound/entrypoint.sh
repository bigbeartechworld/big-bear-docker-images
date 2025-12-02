#!/bin/sh
set -e

# ==============================================================================
# Unbound Docker Entrypoint Script
# ==============================================================================
# This script handles proper initialization of Unbound in a Docker container:
# 1. Updates DNSSEC root trust anchor
# 2. Validates configuration
# 3. Starts Unbound (which will drop privileges to 'unbound' user after binding)
# ==============================================================================

# If the first argument is a command (not a flag), execute it directly
# This allows running commands like: docker run image unbound -V
# or: docker run image which unbound
if [ "${1#-}" = "$1" ] && [ -n "$1" ]; then
    exec "$@"
fi

# Update root trust anchor for DNSSEC validation
# unbound-anchor returns 1 if the anchor was updated, which is not an error
echo "Updating DNSSEC root trust anchor..."
unbound-anchor -a /var/lib/unbound/root.key || true

# Ensure proper ownership of the root.key file
chown unbound:unbound /var/lib/unbound/root.key 2>/dev/null || true

# Validate configuration before starting
echo "Validating Unbound configuration..."
if ! unbound-checkconf /etc/unbound/unbound.conf; then
    echo "ERROR: Invalid Unbound configuration"
    exit 1
fi

echo "Starting Unbound DNS resolver..."
# Execute Unbound - it will bind to port 53 as root, then drop to 'unbound' user
exec unbound -d -c /etc/unbound/unbound.conf
