FROM ubuntu:22.04

# Install required packages and add the PPA for fastfetch
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:zhangsongcui3371/fastfetch && \
    apt-get update && \
    apt-get install -y \
    procps \
    curl \
    iproute2 \
    git \
    golang-go \
    vim \
    fastfetch \
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

# Start gotty and run ncdu with the specified path
CMD ["gotty", "-p", "7681", "-w", "fastfetch"]
