#!/bin/sh

# Check if btop.conf exists in the mounted directory
if [ ! -f /root/.config/btop/btop.conf ]; then
    # Copy default config if it doesn't exist
    cp /root/.config/btop.default/btop.conf /root/.config/btop/btop.conf
fi

# Execute the provided command (in this case, gotty and btop)
exec "$@"
