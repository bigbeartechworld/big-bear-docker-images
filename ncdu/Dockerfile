FROM debian:latest

# Install required packages
RUN apt-get update && apt-get install -y \
    ncdu \
    procps \
    curl \
    iproute2 \
    git \
    golang-go \
    vim \
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

# Define the NCDU_PATH environment variable with a default value
ENV NCDU_PATH /

# Expose the port gotty will run on
EXPOSE 7681

# Start gotty and run ncdu with the specified path
CMD ["gotty", "-p", "7681", "-w", "ncdu", "$NCDU_PATH"]
