#!/bin/bash

# Set image name and tag
IMAGE_NAME="bigbeartechworld/big-bear-pocketbase"
TAG="0.25.7"

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

# Create or use a builder instance
docker buildx create --use

# Build the multi-arch image
docker buildx build --progress plain --platform linux/amd64,linux/arm64 -t $IMAGE_NAME:$TAG . --push > build.log

# Feedback to the user
if [ $? -eq 0 ]; then
    echo "Successfully built and pushed multi-architecture image: $IMAGE_NAME:$TAG"
else
    echo "Failed to build the image. Please check the errors above."
    exit 1
fi
