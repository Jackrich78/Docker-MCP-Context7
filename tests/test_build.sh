#!/bin/bash
# Build Process Tests

set -e
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}🧪 Testing Docker Build Process...${NC}"

# Test 1: Dockerfile syntax and build
echo -e "\n${YELLOW}Test 1: Docker build validation${NC}"
if docker build -t context7-mcp-test:latest . > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker build successful${NC}"
else
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
fi

# Test 2: Image size check (should be <300MB)
echo -e "\n${YELLOW}Test 2: Image size validation${NC}"
SIZE=$(docker images context7-mcp-test:latest --format "{{.Size}}" | sed 's/MB//')
if (( $(echo "$SIZE < 300" | bc -l) )); then
    echo -e "${GREEN}✅ Image size acceptable: ${SIZE}MB${NC}"
else
    echo -e "${RED}❌ Image too large: ${SIZE}MB${NC}"
    exit 1
fi

# Test 3: Multi-architecture support
echo -e "\n${YELLOW}Test 3: Architecture support${NC}"
ARCH=$(docker inspect context7-mcp-test:latest --format='{{.Architecture}}')
if [[ "$ARCH" == "arm64" ]] || [[ "$ARCH" == "amd64" ]]; then
    echo -e "${GREEN}✅ Architecture supported: ${ARCH}${NC}"
else
    echo -e "${RED}❌ Unsupported architecture: ${ARCH}${NC}"
    exit 1
fi

# Test 4: User security check
echo -e "\n${YELLOW}Test 4: Non-root user validation${NC}"
USER=$(docker run --rm --entrypoint /bin/sh context7-mcp-test:latest -c 'whoami' 2>/dev/null)
if [[ "$USER" == "app" ]]; then
    echo -e "${GREEN}✅ Running as non-root user: ${USER}${NC}"
else
    echo -e "${RED}❌ Running as root or wrong user: ${USER}${NC}"
    exit 1
fi

# Test 5: Package installation
echo -e "\n${YELLOW}Test 5: Context7 MCP package validation${NC}"
if docker run --rm context7-mcp-test:latest --help | grep -q "context7-mcp"; then
    echo -e "${GREEN}✅ Context7 MCP package installed${NC}"
else
    echo -e "${RED}❌ Context7 MCP package not found${NC}"
    exit 1
fi

# Cleanup test image
docker rmi context7-mcp-test:latest > /dev/null 2>&1

echo -e "\n${GREEN}🎉 All build tests passed!${NC}"