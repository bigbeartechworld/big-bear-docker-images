#!/bin/bash

# Build script for Pluton Docker image
# This script builds the Pluton Docker image for multiple architectures

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="bigbeartechworld/big-bear-pluton"
VERSION=$(cat VERSION)

echo -e "${GREEN}Building Pluton Docker Image${NC}"
echo -e "${YELLOW}Version: ${VERSION}${NC}"

# Check if we are in the right directory
if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}Error: Dockerfile not found. Please run this script from the Apps/pluton directory.${NC}"
    exit 1
fi

# Build the image
echo -e "${YELLOW}Building image...${NC}"
docker build -t "${IMAGE_NAME}:${VERSION}" -t "${IMAGE_NAME}:latest" .

echo -e "${GREEN}Build complete!${NC}"
echo -e "Tags:"
echo -e "  - ${IMAGE_NAME}:${VERSION}"
echo -e "  - ${IMAGE_NAME}:latest"
