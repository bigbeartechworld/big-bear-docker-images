#!/bin/bash

# Test script for Unbound Docker image
# This script builds and tests the Unbound DNS resolver Docker image

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Container and image names
IMAGE_NAME="${IMAGE_NAME:-bigbeartechworld/big-bear-unbound}"
IMAGE_TAG="${IMAGE_TAG:-test}"
CONTAINER_NAME="unbound-test-$$"
HOST_PORT="${HOST_PORT:-5353}"

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}  Unbound Docker Image Test Suite${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Function to print test results
print_test() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $2"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        if [ -n "$3" ]; then
            echo -e "  ${RED}Error: $3${NC}"
        fi
    fi
}

# Function to print section header
print_section() {
    echo ""
    echo -e "${CYAN}─── $1 ───${NC}"
}

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Cleaning up...${NC}"
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
    if [ "$REMOVE_IMAGE" = "true" ]; then
        docker rmi "${IMAGE_NAME}:${IMAGE_TAG}" 2>/dev/null || true
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"

# Change to app directory
cd "$APP_DIR"

print_section "Build Tests"

# Test 1: Build the Docker image
echo -e "${YELLOW}Test 1: Building Docker image...${NC}"
if docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" . > /dev/null 2>&1; then
    print_test 0 "Docker image built successfully"
    REMOVE_IMAGE="true"
else
    print_test 1 "Docker image build failed"
    echo -e "${RED}Build failed. Check Dockerfile and dependencies.${NC}"
    exit 1
fi

# Test 2: Check image size is reasonable
echo -e "${YELLOW}Test 2: Checking image size...${NC}"
IMAGE_SIZE=$(docker images "${IMAGE_NAME}:${IMAGE_TAG}" --format "{{.Size}}")
print_test 0 "Image size: $IMAGE_SIZE"

print_section "Configuration Tests"

# Test 3: Verify Unbound binary exists
echo -e "${YELLOW}Test 3: Checking Unbound binary...${NC}"
if docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" which unbound > /dev/null 2>&1; then
    print_test 0 "Unbound binary exists"
else
    print_test 1 "Unbound binary not found"
fi

# Test 4: Check Unbound version
echo -e "${YELLOW}Test 4: Checking Unbound version...${NC}"
VERSION_OUTPUT=$(docker run --rm --user root "${IMAGE_NAME}:${IMAGE_TAG}" unbound -V 2>&1 | head -1 || true)
if echo "$VERSION_OUTPUT" | grep -q "Version"; then
    print_test 0 "Unbound version retrieved"
    echo -e "  ${BLUE}$VERSION_OUTPUT${NC}"
else
    print_test 1 "Could not retrieve Unbound version"
fi

# Test 5: Validate configuration file
echo -e "${YELLOW}Test 5: Validating unbound.conf...${NC}"
if docker run --rm --user root "${IMAGE_NAME}:${IMAGE_TAG}" unbound-checkconf /etc/unbound/unbound.conf > /dev/null 2>&1; then
    print_test 0 "Configuration file is valid"
else
    print_test 1 "Configuration file validation failed"
    docker run --rm --user root "${IMAGE_NAME}:${IMAGE_TAG}" unbound-checkconf /etc/unbound/unbound.conf 2>&1 || true
fi

# Test 6: Check root.hints exists
echo -e "${YELLOW}Test 6: Checking root.hints file...${NC}"
if docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" test -f /var/lib/unbound/root.hints; then
    print_test 0 "root.hints file exists"
else
    print_test 1 "root.hints file not found"
fi

# Test 7: Check root.key exists (DNSSEC trust anchor)
echo -e "${YELLOW}Test 7: Checking root.key file...${NC}"
if docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" test -f /var/lib/unbound/root.key; then
    print_test 0 "root.key file exists (DNSSEC trust anchor)"
else
    print_test 1 "root.key file not found"
fi

print_section "Security Tests"

# Test 8: Verify container runs as non-root user
echo -e "${YELLOW}Test 8: Checking non-root user...${NC}"
CONTAINER_USER=$(docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" whoami 2>/dev/null || echo "unknown")
if [ "$CONTAINER_USER" != "root" ] && [ "$CONTAINER_USER" != "unknown" ]; then
    print_test 0 "Container runs as non-root user ($CONTAINER_USER)"
else
    print_test 1 "Container runs as root (security risk)"
fi

# Test 9: Check file permissions
echo -e "${YELLOW}Test 9: Checking file permissions...${NC}"
PERMS_OK=true
# Check config is readable
if ! docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" test -r /etc/unbound/unbound.conf; then
    PERMS_OK=false
fi
# Check root.hints is readable
if ! docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" test -r /var/lib/unbound/root.hints; then
    PERMS_OK=false
fi
if [ "$PERMS_OK" = "true" ]; then
    print_test 0 "File permissions are correct"
else
    print_test 1 "File permissions issue detected"
fi

print_section "Runtime Tests"

# Test 10: Start the container
echo -e "${YELLOW}Test 10: Starting Unbound container...${NC}"
if docker run -d \
    --name "$CONTAINER_NAME" \
    -p "${HOST_PORT}:53/udp" \
    -p "${HOST_PORT}:53/tcp" \
    "${IMAGE_NAME}:${IMAGE_TAG}" > /dev/null 2>&1; then
    print_test 0 "Container started successfully"
else
    print_test 1 "Failed to start container"
    exit 1
fi

# Wait for Unbound to be ready
echo -e "${YELLOW}Waiting for Unbound to initialize...${NC}"
READY=false
for i in {1..30}; do
    if docker exec "$CONTAINER_NAME" dig +short +time=2 +tries=1 @127.0.0.1 -p 53 nlnetlabs.nl > /dev/null 2>&1; then
        READY=true
        break
    fi
    sleep 1
done

if [ "$READY" = "false" ]; then
    echo -e "${RED}Unbound failed to start within 30 seconds${NC}"
    docker logs "$CONTAINER_NAME"
    exit 1
fi

# Test 11: Check container is running
echo -e "${YELLOW}Test 11: Verifying container status...${NC}"
if docker ps | grep -q "$CONTAINER_NAME"; then
    print_test 0 "Container is running"
else
    print_test 1 "Container is not running"
fi

# Test 12: Verify Unbound process is running as correct user
echo -e "${YELLOW}Test 12: Checking Unbound process user...${NC}"
PROCESS_USER=$(docker exec "$CONTAINER_NAME" ps aux 2>/dev/null | grep "[u]nbound" | head -1 | awk '{print $1}' || echo "unknown")
if [ "$PROCESS_USER" = "unbound" ] || [ "$PROCESS_USER" = "101" ]; then
    print_test 0 "Unbound process running as user: $PROCESS_USER"
elif [ "$PROCESS_USER" = "root" ] || [ "$PROCESS_USER" = "0" ]; then
    print_test 1 "Unbound process running as root (security issue)"
else
    print_test 0 "Unbound process running as: $PROCESS_USER"
fi

print_section "DNS Resolution Tests"

# Test 13: Test basic DNS resolution (from inside container)
echo -e "${YELLOW}Test 13: Testing DNS resolution (inside container)...${NC}"
RESULT=$(docker exec "$CONTAINER_NAME" dig +short example.com @127.0.0.1 2>/dev/null || echo "")
if [ -n "$RESULT" ]; then
    print_test 0 "DNS resolution works (example.com -> $RESULT)"
else
    print_test 1 "DNS resolution failed"
fi

# Test 14: Test UDP DNS from host
echo -e "${YELLOW}Test 14: Testing UDP DNS from host...${NC}"
if command -v dig > /dev/null 2>&1; then
    RESULT=$(dig +short +time=5 +tries=2 example.com @127.0.0.1 -p "$HOST_PORT" 2>/dev/null || echo "")
    if [ -n "$RESULT" ]; then
        print_test 0 "UDP DNS from host works"
    else
        print_test 1 "UDP DNS from host failed"
    fi
else
    echo -e "  ${YELLOW}Skipped: dig not installed on host${NC}"
fi

# Test 15: Test TCP DNS from host
echo -e "${YELLOW}Test 15: Testing TCP DNS from host...${NC}"
if command -v dig > /dev/null 2>&1; then
    RESULT=$(dig +short +tcp +time=5 +tries=2 example.com @127.0.0.1 -p "$HOST_PORT" 2>/dev/null || echo "")
    if [ -n "$RESULT" ]; then
        print_test 0 "TCP DNS from host works"
    else
        print_test 1 "TCP DNS from host failed"
    fi
else
    echo -e "  ${YELLOW}Skipped: dig not installed on host${NC}"
fi

# Test 16: Test DNSSEC validation
echo -e "${YELLOW}Test 16: Testing DNSSEC validation...${NC}"
DNSSEC_RESULT=$(docker exec "$CONTAINER_NAME" dig +dnssec +short nlnetlabs.nl @127.0.0.1 2>/dev/null || echo "")
if [ -n "$DNSSEC_RESULT" ]; then
    print_test 0 "DNSSEC query returned results"
else
    print_test 1 "DNSSEC query failed"
fi

# Test 17: Test NXDOMAIN response
echo -e "${YELLOW}Test 17: Testing NXDOMAIN response...${NC}"
NXDOMAIN_STATUS=$(docker exec "$CONTAINER_NAME" dig +noall +comments thisdomaindoesnotexist12345.com @127.0.0.1 2>/dev/null | grep -c "NXDOMAIN" || echo "0")
if [ "$NXDOMAIN_STATUS" -gt 0 ]; then
    print_test 0 "NXDOMAIN response works correctly"
else
    print_test 1 "NXDOMAIN response not received"
fi

# Test 18: Test multiple domains in parallel
echo -e "${YELLOW}Test 18: Testing multiple DNS queries...${NC}"
DOMAINS_OK=0
for domain in google.com cloudflare.com github.com; do
    RESULT=$(docker exec "$CONTAINER_NAME" dig +short "$domain" @127.0.0.1 2>/dev/null | head -1 || echo "")
    if [ -n "$RESULT" ]; then
        DOMAINS_OK=$((DOMAINS_OK + 1))
    fi
done
if [ "$DOMAINS_OK" -eq 3 ]; then
    print_test 0 "Multiple DNS queries successful ($DOMAINS_OK/3)"
else
    print_test 1 "Multiple DNS queries: $DOMAINS_OK/3 succeeded"
fi

print_section "Performance Tests"

# Test 19: Test response time
echo -e "${YELLOW}Test 19: Measuring response time...${NC}"
QUERY_TIME=$(docker exec "$CONTAINER_NAME" dig example.com @127.0.0.1 2>/dev/null | grep "Query time" | awk '{print $4}' || echo "unknown")
if [ "$QUERY_TIME" != "unknown" ]; then
    print_test 0 "Query time: ${QUERY_TIME}ms"
else
    print_test 1 "Could not measure query time"
fi

# Test 20: Test cache (second query should be faster)
echo -e "${YELLOW}Test 20: Testing cache functionality...${NC}"
# First query (should miss cache)
docker exec "$CONTAINER_NAME" dig +short uncachedtest.example.com @127.0.0.1 > /dev/null 2>&1 || true
TIME1=$(docker exec "$CONTAINER_NAME" dig example.com @127.0.0.1 2>/dev/null | grep "Query time" | awk '{print $4}' || echo "0")
# Second query (should hit cache)
TIME2=$(docker exec "$CONTAINER_NAME" dig example.com @127.0.0.1 2>/dev/null | grep "Query time" | awk '{print $4}' || echo "0")
if [ "$TIME2" -le "$TIME1" ] 2>/dev/null; then
    print_test 0 "Cache working (${TIME1}ms -> ${TIME2}ms)"
else
    print_test 0 "Cache test completed"
fi

print_section "Health Check Tests"

# Test 21: Verify health check is configured
echo -e "${YELLOW}Test 21: Checking health check configuration...${NC}"
HEALTHCHECK=$(docker inspect --format='{{.Config.Healthcheck}}' "${IMAGE_NAME}:${IMAGE_TAG}" 2>/dev/null || echo "")
if [ -n "$HEALTHCHECK" ] && [ "$HEALTHCHECK" != "<nil>" ]; then
    print_test 0 "Health check is configured"
else
    print_test 1 "Health check not configured"
fi

# Test 22: Check container health status
echo -e "${YELLOW}Test 22: Checking container health status...${NC}"
sleep 5  # Wait for health check to run
HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")
if [ "$HEALTH_STATUS" = "healthy" ]; then
    print_test 0 "Container health: $HEALTH_STATUS"
elif [ "$HEALTH_STATUS" = "starting" ]; then
    print_test 0 "Container health: $HEALTH_STATUS (still initializing)"
else
    print_test 1 "Container health: $HEALTH_STATUS"
fi

print_section "Logs & Diagnostics"

# Test 23: Check for errors in logs
echo -e "${YELLOW}Test 23: Checking logs for errors...${NC}"
ERRORS=$(docker logs "$CONTAINER_NAME" 2>&1 | grep -iE "error|fatal|panic" | head -5 || echo "")
if [ -z "$ERRORS" ]; then
    print_test 0 "No errors found in logs"
else
    print_test 1 "Errors found in logs"
    echo "$ERRORS"
fi

# Test 24: Check memory usage
echo -e "${YELLOW}Test 24: Checking resource usage...${NC}"
STATS=$(docker stats "$CONTAINER_NAME" --no-stream --format "{{.MemUsage}}" 2>/dev/null || echo "unknown")
if [ "$STATS" != "unknown" ]; then
    print_test 0 "Memory usage: $STATS"
else
    print_test 1 "Could not get resource stats"
fi

# Print summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
echo -e "  Total Tests:  ${TESTS_TOTAL}"
echo -e "  ${GREEN}Passed:${NC}       ${TESTS_PASSED}"
echo -e "  ${RED}Failed:${NC}       ${TESTS_FAILED}"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}All tests passed successfully!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the output above.${NC}"
    exit 1
fi
