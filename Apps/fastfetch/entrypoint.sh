#!/bin/sh

# Set HOME to root to ensure the correct configuration path
export HOME=/root

# Check if authentication is enabled
if [ "$GOTTY_AUTH_ENABLED" = "true" ]; then
    # Execute command with authentication (using quoted arguments for security)
    exec gotty -p 7681 -w -c "${GOTTY_AUTH_USER}:${GOTTY_AUTH_PASS}" fastfetch
else
    # Execute the provided command without authentication
    if [ $# -eq 0 ]; then
        # No command provided, use default
        exec gotty -p 7681 -w fastfetch
    else
        # Use provided command
        exec "$@"
    fi
fi
