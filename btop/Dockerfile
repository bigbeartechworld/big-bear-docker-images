FROM debian:latest

# Install required packages for building gotty and running btop
RUN apt-get update && apt-get install -y \
    btop \
    procps \
    curl \
    iproute2 \
    git \
    golang-go \
    && apt-get clean

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

# Start gotty and run btop
CMD ["gotty", "-p", "7681", "-w", "btop"]
