#!/bin/sh

# Check if btop.conf exists in the mounted directory
if [ ! -f /root/.config/btop/btop.conf ]; then
    # Copy default config if it doesn't exist
    mkdir -p /root/.config/btop
    cp /root/.config/btop.default/btop.conf /root/.config/btop/btop.conf
    # Copy default themes if they don't exist
    cp -rn /usr/share/btop/themes/* /root/.config/btop/themes 2>/dev/null || true
fi

# Set HOME to root to ensure the correct configuration path
export HOME=/root

# Check if authentication is enabled
if [ "$TTYD_AUTH_ENABLED" = "true" ]; then
    # Execute command with authentication (using quoted arguments for security)
    exec ttyd -p 7681 -W -c "${TTYD_AUTH_USER}:${TTYD_AUTH_PASS}" btop
else
    # Execute the provided command without authentication
    if [ $# -eq 0 ]; then
        # No command provided, use default
        exec ttyd -p 7681 -W btop
    else
        # Use provided command
        exec "$@"
    fi
fi
