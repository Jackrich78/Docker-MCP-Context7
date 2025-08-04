#!/bin/bash
# Integration Tests

set -e
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}🧪 Testing Claude Code Integration...${NC}"

MCP_NAME="context7-test"
IMAGE_NAME="context7-mcp:1.0"

# Test 1: MCP registration
echo -e "\n${YELLOW}Test 1: MCP registration${NC}"
claude mcp remove $MCP_NAME 2>/dev/null || true
if claude mcp add $MCP_NAME --scope user -- docker run -i --rm --name ${MCP_NAME}-server --memory 2g --cpus 1 $IMAGE_NAME; then
    echo -e "${GREEN}✅ MCP registration successful${NC}"
else
    echo -e "${RED}❌ MCP registration failed${NC}"
    exit 1
fi

# Test 2: MCP list verification
echo -e "\n${YELLOW}Test 2: MCP list verification${NC}"
if claude mcp list | grep -q $MCP_NAME; then
    echo -e "${GREEN}✅ MCP appears in registration list${NC}"
else
    echo -e "${RED}❌ MCP not found in registration list${NC}"
    exit 1
fi

# Test 3: MCP connection test
echo -e "\n${YELLOW}Test 3: MCP connection health${NC}"
if claude mcp list | grep $MCP_NAME | grep -q "Connected"; then
    echo -e "${GREEN}✅ MCP connection healthy${NC}"
else
    echo -e "${RED}❌ MCP connection unhealthy${NC}"
    claude mcp list | grep $MCP_NAME
    exit 1
fi

# Test 4: Cleanup test
echo -e "\n${YELLOW}Test 4: MCP cleanup${NC}"
if claude mcp remove $MCP_NAME; then
    echo -e "${GREEN}✅ MCP cleanup successful${NC}"
else
    echo -e "${RED}❌ MCP cleanup failed${NC}"
    exit 1
fi

echo -e "\n${GREEN}🎉 All integration tests passed!${NC}"