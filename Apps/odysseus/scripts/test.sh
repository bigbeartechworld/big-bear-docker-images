#!/bin/bash
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
IMAGE="bigbeartechworld/big-bear-odysseus:test"
UPSTREAM_REPO="https://github.com/pewdiepie-archdaemon/odysseus.git"
REF="${1:-main}"

print_test() { if [ "$1" -eq 0 ]; then echo -e "${GREEN}✓${NC} $2"; else echo -e "${RED}✗${NC} $2"; exit 1; fi; }

WORKDIR=$(mktemp -d)
cleanup() {
    docker rm -f odysseus-test 2>/dev/null || true
    rm -rf "$WORKDIR"
}
trap cleanup EXIT

echo -e "${BLUE}Odysseus Docker Image Test${NC}"

echo -e "${YELLOW}Cloning upstream@${REF}...${NC}"
git clone --depth 1 --branch "$REF" "$UPSTREAM_REPO" "$WORKDIR" 2>/dev/null \
  || { git clone "$UPSTREAM_REPO" "$WORKDIR"; git -C "$WORKDIR" checkout "$REF"; }

LOG="$WORKDIR/docker.log"

echo -e "${YELLOW}Test 1: Build image...${NC}"
docker build -t "$IMAGE" "$WORKDIR" > "$LOG" 2>&1 && BUILD_RC=0 || BUILD_RC=$?
[ "$BUILD_RC" -ne 0 ] && cat "$LOG"
print_test "$BUILD_RC" "Image builds"

echo -e "${YELLOW}Test 2: Start container...${NC}"
docker run -d --name odysseus-test \
    -p 7000:7000 \
    -e ODYSSEUS_ADMIN_PASSWORD=testpass123 \
    "$IMAGE" > "$LOG" 2>&1 && RUN_RC=0 || RUN_RC=$?
[ "$RUN_RC" -ne 0 ] && cat "$LOG"
print_test "$RUN_RC" "Container started"

echo -e "${YELLOW}Waiting for /api/health...${NC}"
READY=1
for i in $(seq 1 30); do
    if curl -sf http://localhost:7000/api/health > /dev/null 2>&1; then READY=0; break; fi
    sleep 2
done
print_test $READY "Health endpoint /api/health returns 200"

echo -e "${YELLOW}Test 3: Non-root process...${NC}"
PROC_USER=$(docker exec odysseus-test sh -c 'ps -o user= -p 1' 2>/dev/null | tr -d ' ')
if [ "$PROC_USER" != "root" ] && [ -n "$PROC_USER" ]; then
    print_test 0 "PID 1 runs as non-root ($PROC_USER)"
else
    print_test 1 "PID 1 runs as root (security risk)"
fi

echo -e "${GREEN}All tests passed${NC}"
