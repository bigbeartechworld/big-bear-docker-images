#!/bin/sh
set -e

# ==============================================================================
# Unbound Docker Entrypoint Script
# ==============================================================================
# This script handles proper initialization of Unbound in a Docker container:
# 1. Ensures root.hints file exists (downloads if missing)
# 2. Updates DNSSEC root trust anchor
# 3. Validates configuration
# 4. Starts Unbound (which will drop privileges to 'unbound' user after binding)
# ==============================================================================

# If the first argument is a command (not a flag), execute it directly
# This allows running commands like: docker run image unbound -V
# or: docker run image which unbound
if [ "${1#-}" = "$1" ] && [ -n "$1" ]; then
    exec "$@"
fi

# Ensure root.hints file exists (may be missing if /var/lib/unbound is mounted)
ROOT_HINTS="/var/lib/unbound/root.hints"
if [ ! -f "$ROOT_HINTS" ]; then
    echo "Root hints file not found, downloading from InterNIC..."
    if curl -sSL https://www.internic.net/domain/named.root -o "$ROOT_HINTS"; then
        chown unbound:unbound "$ROOT_HINTS" 2>/dev/null || true
        chmod 644 "$ROOT_HINTS"
        echo "Root hints downloaded successfully"
    else
        echo "ERROR: Failed to download root hints from InterNIC"
        exit 1
    fi
fi

# Update root trust anchor for DNSSEC validation
# unbound-anchor exit codes:
#   0 = no update was necessary, anchor up to date
#   1 = updated the anchor, fetch was successful
#   other = failure (network, permissions, etc.)
echo "Updating DNSSEC root trust anchor..."
ANCHOR_OUTPUT=$(unbound-anchor -a /var/lib/unbound/root.key 2>&1) || ANCHOR_EXIT=$?
ANCHOR_EXIT=${ANCHOR_EXIT:-0}

case $ANCHOR_EXIT in
    0)
        echo "Root trust anchor is up to date"
        ;;
    1)
        echo "Root trust anchor was updated successfully"
        ;;
    *)
        echo "ERROR: unbound-anchor failed with exit code $ANCHOR_EXIT"
        if [ -n "$ANCHOR_OUTPUT" ]; then
            echo "Output: $ANCHOR_OUTPUT"
        fi
        exit 1
        ;;
esac

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
