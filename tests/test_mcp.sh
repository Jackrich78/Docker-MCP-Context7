#!/bin/bash
# MCP Functionality Tests

set -e
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}🧪 Testing MCP Functionality...${NC}"

IMAGE_NAME="context7-mcp:1.0"

# Test 1: Server startup and help
echo -e "\n${YELLOW}Test 1: Server help command${NC}"
if docker run --rm $IMAGE_NAME --help | grep -q "transport"; then
    echo -e "${GREEN}✅ Server help command works${NC}"
else
    echo -e "${RED}❌ Server help command failed${NC}"
    exit 1
fi

# Test 2: JSON-RPC tools/list
echo -e "\n${YELLOW}Test 2: JSON-RPC tools/list${NC}"
RESPONSE=$(echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | docker run -i --rm $IMAGE_NAME --transport stdio 2>/dev/null | head -1)
if echo "$RESPONSE" | jq -e '.result.tools | length > 0' > /dev/null 2>&1; then
    TOOL_COUNT=$(echo "$RESPONSE" | jq '.result.tools | length')
    echo -e "${GREEN}✅ Tools list returned ${TOOL_COUNT} tools${NC}"
else
    echo -e "${RED}❌ Tools list request failed${NC}"
    exit 1
fi

# Test 3: Tool names validation
echo -e "\n${YELLOW}Test 3: Expected tools validation${NC}"
TOOLS=$(echo "$RESPONSE" | jq -r '.result.tools[].name')
if echo "$TOOLS" | grep -q "resolve-library-id" && echo "$TOOLS" | grep -q "get-library-docs"; then
    echo -e "${GREEN}✅ Expected tools found: resolve-library-id, get-library-docs${NC}"
else
    echo -e "${RED}❌ Expected tools not found${NC}"
    echo "Found tools: $TOOLS"
    exit 1
fi

# Test 4: Resource limits compliance
echo -e "\n${YELLOW}Test 4: Resource limits test${NC}"
CONTAINER_ID=$(docker run -d --memory 2g --cpus 1 --name test-limits --entrypoint /bin/sh $IMAGE_NAME -c 'sleep 5')
sleep 2
MEMORY_LIMIT=$(docker inspect test-limits --format='{{.HostConfig.Memory}}')
CPU_LIMIT=$(docker inspect test-limits --format='{{.HostConfig.CpuQuota}}')
docker stop test-limits > /dev/null 2>&1
docker rm test-limits > /dev/null 2>&1

if [[ "$MEMORY_LIMIT" == "2147483648" ]]; then
    echo -e "${GREEN}✅ Memory limit properly set: 2GB${NC}"
else
    echo -e "${RED}❌ Memory limit not set correctly: $MEMORY_LIMIT${NC}"
    exit 1
fi

# Test 5: Container naming and visibility
echo -e "\n${YELLOW}Test 5: Container naming test${NC}"
CONTAINER_ID=$(docker run -d --name context7-mcp-server-test --entrypoint /bin/sh $IMAGE_NAME -c 'sleep 3')
sleep 1
if docker ps --format '{{.Names}}' | grep -q "context7-mcp-server-test"; then
    echo -e "${GREEN}✅ Container visible with correct name${NC}"
else
    echo -e "${RED}❌ Container not visible or wrong name${NC}"
    exit 1
fi
docker stop context7-mcp-server-test > /dev/null 2>&1
docker rm context7-mcp-server-test > /dev/null 2>&1

echo -e "\n${GREEN}🎉 All MCP functionality tests passed!${NC}"