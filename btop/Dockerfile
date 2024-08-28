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

# Expose the port gotty will run on
EXPOSE 7681

# Define a volume to persist btop settings
VOLUME ["/root/.config/btop"]

# Start gotty and run btop
CMD ["gotty", "-p", "7681", "-w", "btop"]
