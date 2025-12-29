# Use a specific tag for a stable and predictable base image.
FROM python:3.12-slim

# Set non-interactive mode and define timezone to avoid unnecessary prompts during build.
ENV DEBIAN_FRONTEND=noninteractive TZ="America/Chicago"

# Install essential packages in one layer to reduce the image size.
# Combine update, install, and cleanup in a single RUN to minimize layer size.
RUN apt-get update && apt-get install -y --no-install-recommends \
    git sudo cron net-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Expose necessary ports for HTTPS and the application.
EXPOSE 443 8000

# Set the working directory for any subsequent instructions.
WORKDIR /git

# Configure application settings via environment variables.
ENV USE_SERIAL_TCP=true

# Clone the repository with shallow clone to minimize data pulled.
RUN git clone --depth 1 --branch V1.19.06 http://github.com/jgyates/genmon.git && \
    chmod 775 /git/genmon/startgenmon.sh /git/genmon/genmonmaint.sh && \
    rm -rf /git/genmon/.git

# Initialize the application and configure it.
RUN /git/genmon/genmonmaint.sh -i -n

# Clean up apt caches.
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Copy the entrypoint script to the container.
COPY entrypoint.sh /entrypoint.sh

# Make the entrypoint script executable.
RUN chmod +x /entrypoint.sh

# Set the custom entrypoint script as the entrypoint.
ENTRYPOINT ["/entrypoint.sh"]
