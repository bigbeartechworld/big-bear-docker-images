#!/bin/sh
set -e

# If command starts with an option, prepend minio.
if [ "${1}" != "minio" ]; then
    if [ -n "${1}" ]; then
        set -- minio "$@"
    fi
fi

# Function to switch user if environment variables are set
docker_switch_user() {
    if [ -n "${MINIO_USERNAME}" ] && [ -n "${MINIO_GROUPNAME}" ]; then
        if [ -n "${MINIO_UID}" ] && [ -n "${MINIO_GID}" ]; then
            # Add user with specific UID/GID if they don't exist
            if ! getent passwd "${MINIO_UID}" >/dev/null 2>&1; then
                echo "${MINIO_USERNAME}:x:${MINIO_UID}:${MINIO_GID}:${MINIO_USERNAME}:/:/sbin/nologin" >> /etc/passwd
            fi
            if ! getent group "${MINIO_GID}" >/dev/null 2>&1; then
                echo "${MINIO_GROUPNAME}:x:${MINIO_GID}" >> /etc/group
            fi
            # Change ownership of data directory
            chown -R "${MINIO_UID}:${MINIO_GID}" /data
            # Execute as the specified user
            exec su-exec "${MINIO_UID}:${MINIO_GID}" "$@"
        else
            # Add user with default UID/GID if they don't exist
            if ! getent passwd 1000 >/dev/null 2>&1; then
                echo "${MINIO_USERNAME}:x:1000:1000:${MINIO_USERNAME}:/:/sbin/nologin" >> /etc/passwd
            fi
            if ! getent group 1000 >/dev/null 2>&1; then
                echo "${MINIO_GROUPNAME}:x:1000" >> /etc/group
            fi
            # Change ownership of data directory
            chown -R 1000:1000 /data
            # Execute as the specified user
            exec su-exec 1000:1000 "$@"
        fi
    else
        # Run as default minio user
        chown -R minio:minio /data
        exec su-exec minio:minio "$@"
    fi
}

# Switch to appropriate user and execute command
docker_switch_user "$@"
