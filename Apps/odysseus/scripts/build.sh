#!/bin/bash
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

IMAGE_NAME="bigbeartechworld/big-bear-odysseus"
UPSTREAM_REPO="https://github.com/pewdiepie-archdaemon/odysseus.git"
PUSH=0
REF="main"
for arg in "$@"; do
    if [ "$arg" == "--push" ]; then
        PUSH=1
    else
        REF="$arg"
    fi
done
VERSION=$(cat "$(dirname "$0")/../config/VERSION")
PLATFORMS="linux/amd64,linux/arm64"

echo -e "${GREEN}Building Odysseus Docker Image${NC}"
echo -e "${YELLOW}Version: ${VERSION}  Ref: ${REF}${NC}"

if ! docker buildx version &> /dev/null; then
    echo -e "${RED}Error: docker buildx is not available${NC}"; exit 1
fi
docker buildx inspect multiarch &> /dev/null || docker buildx create --name multiarch --use
docker buildx use multiarch

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
echo -e "${YELLOW}Cloning ${UPSTREAM_REPO}@${REF}...${NC}"
git clone --depth 1 --branch "$REF" "$UPSTREAM_REPO" "$WORKDIR" \
  || git clone "$UPSTREAM_REPO" "$WORKDIR"
git -C "$WORKDIR" checkout "$REF"
SHA=$(git -C "$WORKDIR" rev-parse --short HEAD)
echo -e "${YELLOW}Upstream SHA: ${SHA}${NC}"

if [ "$PUSH" == "1" ]; then
    docker buildx build --platform "${PLATFORMS}" \
        -t "${IMAGE_NAME}:${VERSION}" \
        -t "${IMAGE_NAME}:${VERSION}-${SHA}" \
        -t "${IMAGE_NAME}:latest" \
        --label "org.opencontainers.image.revision=$(git -C "$WORKDIR" rev-parse HEAD)" \
        --push "$WORKDIR"
    echo -e "${GREEN}Pushed ${IMAGE_NAME}:${VERSION}-${SHA}${NC}"
else
    docker buildx build --platform "linux/amd64" \
        -t "${IMAGE_NAME}:${VERSION}" \
        -t "${IMAGE_NAME}:latest" \
        --load "$WORKDIR"
    echo -e "${GREEN}Built ${IMAGE_NAME}:${VERSION} (local amd64)${NC}"
fi
