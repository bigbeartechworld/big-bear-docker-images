FROM golang:alpine as builder

# Install necessary packages
RUN apk add --no-cache \
    git \
    vim

# Clone and build gotty
RUN git clone https://github.com/sorenisanerd/gotty.git /gotty && \
    cd /gotty && \
    go build

FROM alpine:latest

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
ENV LANG C.UTF-8

# Define the NCDU_PATH environment variable with a default value
ENV NCDU_PATH /

# Expose the port gotty will run on
EXPOSE 7681

# Start gotty and run ncdu with the specified path
CMD gotty -p 7681 -w ncdu $NCDU_PATH
