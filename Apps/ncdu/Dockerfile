FROM golang:alpine as builder

# Install necessary packages
RUN apk add --no-cache \
    git \
    vim

# Clone and build gotty
RUN git clone https://github.com/sorenisanerd/gotty.git /gotty && \
    cd /gotty && \
    go build

FROM alpine:3.21.3

# Install ncdu, procps, curl, iproute2, and clean up
RUN apk add --no-cache \
    ncdu \
    procps \
    curl \
    iproute2 \
    vim \
    && rm -rf /var/cache/apk/*

# Copy the built gotty binary from the builder stage
COPY --from=builder /gotty/gotty /usr/local/bin/gotty

# Set the terminal to support UTF-8
ENV LANG=C.UTF-8

# Define the NCDU_PATH environment variable with a default value
ENV NCDU_PATH=/

# Set default authentication (can be overridden at runtime)
# Note: These values should be overridden at runtime for security
ARG GOTTY_AUTH_USER=bigbear
ARG GOTTY_AUTH_PASS=password
ARG GOTTY_AUTH_ENABLED=false
ENV GOTTY_AUTH_USER=${GOTTY_AUTH_USER}
ENV GOTTY_AUTH_PASS=${GOTTY_AUTH_PASS}
ENV GOTTY_AUTH_ENABLED=${GOTTY_AUTH_ENABLED}

# Expose the port gotty will run on
EXPOSE 7681

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
