#!/bin/bash

# Set image name and tag
IMAGE_NAME="bigbeartechworld/big-bear-unbound"
VERSION=$(cat VERSION)
TAG="${VERSION}"

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Enable experimental CLI features
export DOCKER_CLI_EXPERIMENTAL=enabled

# Check if buildx is installed
if ! docker buildx version &> /dev/null; then
    echo "buildx is not installed or not available. Make sure you're using Docker 19.03 or later."
    exit 1
fi

# Update root.hints from InterNIC
echo "Updating root.hints from InterNIC..."
curl -sSL https://www.internic.net/domain/named.root -o root.hints

# Create or use a builder instance
docker buildx create --use --name unbound-builder 2>/dev/null || docker buildx use unbound-builder

# Build the multi-arch image
echo "Building and pushing multi-architecture image: $IMAGE_NAME:$TAG"
docker buildx build \
    --progress plain \
    --platform linux/amd64,linux/arm64,linux/arm/v7 \
    -t "$IMAGE_NAME:$TAG" \
    -t "$IMAGE_NAME:latest" \
    . --push > build.log 2>&1

# Feedback to the user
if [ $? -eq 0 ]; then
    echo "Successfully built and pushed multi-architecture image:"
    echo "  - $IMAGE_NAME:$TAG"
    echo "  - $IMAGE_NAME:latest"
else
    echo "Failed to build the image. Check build.log for details."
    cat build.log
    exit 1
fi
