FROM alpine:latest

# Install required packages for building gotty and running btop
RUN apk add --no-cache \
    btop \
    procps \
    curl \
    iproute2 \
    git \
    go

# Clone, build, and install gotty
RUN git clone https://github.com/sorenisanerd/gotty.git /tmp/gotty && \
    cd /tmp/gotty && \
    go build && \
    mv gotty /usr/local/bin/ && \
    cd / && \
    rm -rf /tmp/gotty

# Set the terminal to support UTF-8
ENV LANG C.UTF-8

# Create default config directory
RUN mkdir -p /root/.config/btop.default

# Copy the default btop.conf to a separate directory
COPY btop.conf /root/.config/btop.default/btop.conf

# Expose the port gotty will run on
EXPOSE 7681

# Start gotty and run btop
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["gotty", "-p", "7681", "-w", "btop"]
