#!/bin/sh

# Fix permissions for /data
chown -R node:node /data

# Execute the command as node user
exec su-exec node "$@"
