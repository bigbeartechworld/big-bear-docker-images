#!/bin/bash

# Build script for MinIO Docker image
# This script builds the MinIO Docker image for multiple architectures

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="bigbeartechworld/big-bear-minio"
VERSION=$(cat VERSION)
PLATFORMS="linux/amd64,linux/arm64"

echo -e "${GREEN}Building MinIO Docker Image${NC}"
echo -e "${YELLOW}Version: ${VERSION}${NC}"
echo -e "${YELLOW}Platforms: ${PLATFORMS}${NC}"
echo ""

# Check if buildx is available
if ! docker buildx version &> /dev/null; then
    echo -e "${RED}Error: docker buildx is not available${NC}"
    echo "Please install Docker Buildx to build multi-architecture images"
    exit 1
fi

# Create buildx builder if it doesn't exist
if ! docker buildx inspect multiarch &> /dev/null; then
    echo -e "${YELLOW}Creating buildx builder 'multiarch'...${NC}"
    docker buildx create --name multiarch --use
fi

# Use the multiarch builder
docker buildx use multiarch

# Build and push (or load for local testing)
echo -e "${GREEN}Building image...${NC}"

if [ "$1" == "--push" ]; then
    echo -e "${YELLOW}Building and pushing to registry...${NC}"
    docker buildx build \
        --platform "${PLATFORMS}" \
        -t "${IMAGE_NAME}:${VERSION}" \
        -t "${IMAGE_NAME}:latest" \
        --push \
        .
    echo -e "${GREEN}Successfully built and pushed ${IMAGE_NAME}:${VERSION}${NC}"
else
    echo -e "${YELLOW}Building for local use (amd64 only)...${NC}"
    docker buildx build \
        --platform "linux/amd64" \
        -t "${IMAGE_NAME}:${VERSION}" \
        -t "${IMAGE_NAME}:latest" \
        --load \
        .
    echo -e "${GREEN}Successfully built ${IMAGE_NAME}:${VERSION}${NC}"
    echo -e "${YELLOW}To push to registry, run: $0 --push${NC}"
fi

echo ""
echo -e "${GREEN}Build complete!${NC}"
echo ""
echo "To test locally:"
echo "  docker-compose up -d"
echo ""
echo "To test the image:"
echo "  docker run --rm ${IMAGE_NAME}:${VERSION} minio --version"
