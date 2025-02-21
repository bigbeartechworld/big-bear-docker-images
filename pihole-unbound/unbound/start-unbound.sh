#!/bin/sh
set -e

# Generate the root.key file for DNSSEC
sh -c "unbound-anchor -a /var/lib/unbound/root.key"
chown unbound:unbound /var/lib/unbound/root.key

# Start Unbound in the background
echo "Starting Unbound..."
unbound -d &

# Wait briefly to ensure Unbound starts
sleep 2

# Verify Unbound is running
if pgrep unbound > /dev/null; then
  echo "Unbound started successfully"
else
  echo "Failed to start Unbound"
  exit 1
fi

# Start Pi-hole using the original entrypoint
echo "Starting Pi-hole..."
exec start.sh "$@"