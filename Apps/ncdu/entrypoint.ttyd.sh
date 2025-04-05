#!/bin/sh

# Set HOME to root to ensure the correct configuration path
export HOME=/root

# Check if authentication is enabled
if [ "$TTYD_AUTH_ENABLED" = "true" ]; then
    # Execute command with authentication (using quoted arguments for security)
    exec ttyd -p 7681 -W -c "${TTYD_AUTH_USER}:${TTYD_AUTH_PASS}" ncdu "${NCDU_PATH}"
else
    # Execute the provided command without authentication
    if [ $# -eq 0 ]; then
        # No command provided, use default
        exec ttyd -p 7681 -W ncdu "${NCDU_PATH}"
    else
        # Use provided command
        exec "$@"
    fi
fi
