FROM alpine:3.21.3

# Install required packages for building gotty and running btop
RUN apk add --no-cache \
    procps \
    curl \
    iproute2 \
    git \
    go \
    tar \
    make \
    g++ \
    gcc \
    cmake \
    ninja \
    linux-headers

# Clone, build, and install gotty
RUN git clone https://github.com/sorenisanerd/gotty.git /tmp/gotty && \
    cd /tmp/gotty && \
    go build && \
    mv gotty /usr/local/bin/ && \
    cd / && \
    rm -rf /tmp/gotty

# Set btop version
ARG BTOP_VERSION=1.4.2

# Clone and build btop with GPU support
RUN git clone https://github.com/aristocratos/btop.git /tmp/btop && \
    cd /tmp/btop && \
    git checkout v${BTOP_VERSION} && \
    make GPU_SUPPORT=true && \
    make install && \
    cd / && \
    rm -rf /tmp/btop

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

# Set capabilities to enable GPU monitoring for Intel GPUs
RUN apk add --no-cache libcap && \
    setcap cap_sys_admin=ep /usr/local/bin/btop

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
