FROM alpine:latest

# Install required packages
RUN apk update && \
    apk add --no-cache \
    bash \
    procps \
    curl \
    iproute2 \
    git \
    go \
    vim \
    fastfetch \
    && rm -rf /var/cache/apk/*

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

# Start gotty and run fastfetch
CMD ["gotty", "-p", "7681", "-w", "fastfetch"]
