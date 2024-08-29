#!/bin/sh

# Check if btop.conf exists in the mounted directory
if [ ! -f /root/.config/btop/btop.conf ]; then
    # Copy default config if it doesn't exist
    cp /root/.config/btop.default/btop.conf /root/.config/btop/btop.conf

    # Copy default themes if they don't exist
    cp /usr/share/btop/themes /root/.config/btop/themes
fi

# Execute the provided command (in this case, gotty and btop)
exec "$@"
