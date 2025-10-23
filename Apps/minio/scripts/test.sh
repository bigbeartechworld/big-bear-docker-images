#!/bin/bash

# Test script for MinIO Docker image
# This script builds and tests the MinIO Docker image

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}  MinIO Docker Image Test Suite${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Function to print test results
print_test() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        exit 1
    fi
}

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Cleaning up...${NC}"
    docker-compose -f docker-compose.dev.yml down -v 2>/dev/null || true
    docker rm -f minio-test 2>/dev/null || true
    docker volume rm minio-test-data 2>/dev/null || true
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Test 1: Build the image
echo -e "${YELLOW}Test 1: Building Docker image...${NC}"
docker build -t bigbeartechworld/big-bear-minio:test . > /dev/null 2>&1
print_test $? "Docker image built successfully"

# Test 2: Check if MinIO binary exists and is executable
echo -e "${YELLOW}Test 2: Checking MinIO binary...${NC}"
docker run --rm bigbeartechworld/big-bear-minio:test minio --version > /dev/null 2>&1
print_test $? "MinIO binary is executable"

# Test 3: Verify MinIO version output
echo -e "${YELLOW}Test 3: Verifying MinIO version...${NC}"
VERSION_OUTPUT=$(docker run --rm bigbeartechworld/big-bear-minio:test minio --version 2>&1)
echo "$VERSION_OUTPUT" | grep -q "MinIO"
print_test $? "MinIO version output is correct"
echo -e "  ${BLUE}Version:${NC} $(echo "$VERSION_OUTPUT" | head -n 1)"

# Test 4: Start container and check if it runs
echo -e "${YELLOW}Test 4: Starting MinIO container...${NC}"
docker run -d \
    --name minio-test \
    -p 9090:9000 \
    -p 9091:9001 \
    -e MINIO_ROOT_USER=testadmin \
    -e MINIO_ROOT_PASSWORD=testpassword \
    -v minio-test-data:/data \
    bigbeartechworld/big-bear-minio:test \
    server /data --console-address ":9001" > /dev/null 2>&1
print_test $? "Container started successfully"

# Wait for MinIO to be ready
echo -e "${YELLOW}Waiting for MinIO to be ready...${NC}"
sleep 10

# Test 5: Check if container is running
echo -e "${YELLOW}Test 5: Checking container status...${NC}"
docker ps | grep minio-test > /dev/null 2>&1
print_test $? "Container is running"

# Test 6: Check health endpoint
echo -e "${YELLOW}Test 6: Testing health endpoint...${NC}"
curl -sf http://localhost:9090/minio/health/live > /dev/null 2>&1
print_test $? "Health endpoint responds"

# Test 7: Check if API is responding
echo -e "${YELLOW}Test 7: Testing API endpoint...${NC}"
curl -sf http://localhost:9090/minio/health/ready > /dev/null 2>&1
print_test $? "API endpoint is ready"

# Test 8: Check console accessibility
echo -e "${YELLOW}Test 8: Testing console accessibility...${NC}"
curl -sf http://localhost:9091/ > /dev/null 2>&1
print_test $? "Console is accessible"

# Test 9: Verify logs contain no errors
echo -e "${YELLOW}Test 9: Checking container logs...${NC}"
LOGS=$(docker logs minio-test 2>&1)
echo "$LOGS" | grep -q "MinIO Object Storage Server"
print_test $? "MinIO started successfully"

# Test 10: Check data directory permissions
echo -e "${YELLOW}Test 10: Checking data directory...${NC}"
docker exec minio-test ls -la /data > /dev/null 2>&1
print_test $? "Data directory is accessible"

# Test 11: Verify user is not root (security check)
echo -e "${YELLOW}Test 11: Security check (non-root user)...${NC}"
# Check the user running the MinIO process (PID 1)
MINIO_PROCESS_USER=$(docker exec minio-test sh -c 'ps aux | grep "minio server" | grep -v grep' 2>/dev/null | awk '{print $1}')
if [ "$MINIO_PROCESS_USER" != "root" ] && [ -n "$MINIO_PROCESS_USER" ]; then
    print_test 0 "MinIO process running as non-root user ($MINIO_PROCESS_USER)"
else
    print_test 1 "MinIO process running as root (security risk)"
fi

# Test 12: Check resource usage
echo -e "${YELLOW}Test 12: Checking resource usage...${NC}"
STATS=$(docker stats minio-test --no-stream --format "{{.MemUsage}}")
print_test $? "Resource stats available"
echo -e "  ${BLUE}Memory Usage:${NC} $STATS"

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}All tests passed successfully!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Quick Access URLs (during test):${NC}"
echo -e "  Console: ${BLUE}http://localhost:9091${NC}"
echo -e "  API:     ${BLUE}http://localhost:9090${NC}"
echo -e "  User:    ${BLUE}testadmin${NC}"
echo -e "  Pass:    ${BLUE}testpassword${NC}"
echo ""
