FROM alpine:3.21.3

# Install required packages for running btop and gotty
RUN apk add --no-cache \
    procps \
    curl \
    iproute2 \
    git \
    go \
    btop \
    libcap

# Clone, build, and install gotty
RUN git clone https://github.com/sorenisanerd/gotty.git /tmp/gotty && \
    cd /tmp/gotty && \
    go build && \
    mv gotty /usr/local/bin/ && \
    cd / && \
    rm -rf /tmp/gotty

# Set the terminal to support UTF-8
ENV LANG=C.UTF-8

# Set default authentication (can be overridden at runtime)
# Note: These values should be overridden at runtime for security
ARG GOTTY_AUTH_USER=bigbear
ARG GOTTY_AUTH_PASS=password
ARG GOTTY_AUTH_ENABLED=false
ENV GOTTY_AUTH_USER=${GOTTY_AUTH_USER}
ENV GOTTY_AUTH_PASS=${GOTTY_AUTH_PASS}
ENV GOTTY_AUTH_ENABLED=${GOTTY_AUTH_ENABLED}

# Create default config directory
RUN mkdir -p /root/.config/btop.default

# Create themes directory
RUN mkdir -p /root/.config/btop/themes

# Copy the default btop.conf to a separate directory
COPY config/btop.conf /root/.config/btop.default/btop.conf

# Expose the port gotty will run on
EXPOSE 7681

# Start gotty and run btop
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
