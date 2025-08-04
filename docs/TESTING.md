# Testing Documentation

Comprehensive testing suite for Docker MCP Context7 with 100% automated coverage.

## Test Suite Overview

### Test Execution
```bash
# Run complete test suite
make test

# Individual test files
./tests/test_build.sh       # Docker build validation
./tests/test_mcp.sh         # MCP functionality tests
./tests/test_integration.sh # Claude Code integration
```

### Test Results
- **Total Tests**: 14 automated tests
- **Pass Rate**: 100% ✅
- **Execution Time**: <30 seconds
- **Coverage**: Build, functionality, integration

## Test Categories

### 1. Build Tests (`test_build.sh`)

**Purpose**: Validate Docker image build process and configuration

| Test | Validation | Success Criteria |
|------|------------|------------------|
| **Build Validation** | Dockerfile syntax and build | Image builds without errors |
| **Size Check** | Image efficiency | <300MB total size |
| **Architecture** | Multi-arch support | ARM64 or AMD64 detected |
| **Security** | Non-root user | Container runs as `app` user |
| **Package** | MCP installation | `context7-mcp` binary available |

**Sample Output**:
```
🧪 Testing Docker Build Process...
✅ Docker build successful  
✅ Image size acceptable: 237MB
✅ Architecture supported: arm64
✅ Running as non-root user: app
✅ Context7 MCP package installed
🎉 All build tests passed!
```

### 2. MCP Functionality Tests (`test_mcp.sh`)

**Purpose**: Validate MCP server functionality and JSON-RPC interface

| Test | Validation | Success Criteria |
|------|------------|------------------|
| **Help Command** | Server startup | `--help` flag works |
| **JSON-RPC** | Protocol compliance | `tools/list` returns valid JSON |
| **Tool Discovery** | Available tools | `resolve-library-id`, `get-library-docs` present |
| **Resource Limits** | Container constraints | 2GB memory limit enforced |
| **Container Naming** | Docker Desktop visibility | Named container appears in `docker ps` |

**Sample Output**:
```
🧪 Testing MCP Functionality...
✅ Server help command works
✅ Tools list returned 2 tools  
✅ Expected tools found: resolve-library-id, get-library-docs
✅ Memory limit properly set: 2GB
✅ Container visible with correct name
🎉 All MCP functionality tests passed!
```

### 3. Integration Tests (`test_integration.sh`)

**Purpose**: Validate Claude Code integration and MCP lifecycle

| Test | Validation | Success Criteria |
|------|------------|------------------|
| **Registration** | MCP registration | Successfully adds to Claude config |
| **List Verification** | Registration persistence | Appears in `claude mcp list` |
| **Connection Health** | MCP connectivity | Shows "Connected" status |
| **Cleanup** | Registration removal | Successfully removes from config |

**Sample Output**:
```
🧪 Testing Claude Code Integration...
✅ MCP registration successful
✅ MCP appears in registration list
✅ MCP connection healthy  
✅ MCP cleanup successful
🎉 All integration tests passed!
```

## Test Implementation Details

### Error Handling
- **Exit on First Failure**: Tests use `set -e` for immediate failure detection
- **Cleanup**: Automatic cleanup of test containers and images
- **Resource Management**: Tests clean up after themselves

### Color-Coded Output
- 🟨 **Yellow**: Test descriptions and progress
- 🟩 **Green**: Successful test results
- 🟥 **Red**: Failed test results (with error details)

### Test Dependencies
- **Docker**: Container runtime for build and execution tests
- **Claude Code**: CLI for MCP registration tests
- **jq**: JSON parsing for MCP response validation
- **bc**: Mathematical operations for size validation

## Manual Testing Procedures

### Container Direct Testing
```bash
# Test container help
docker run --rm context7-mcp:1.0 --help

# Test JSON-RPC manually
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | \
  docker run -i --rm context7-mcp:1.0

# Test container user
docker run --rm --entrypoint /bin/sh context7-mcp:1.0 -c 'whoami'
```

### MCP Registration Testing
```bash
# Check current registrations
claude mcp list

# Test registration health
claude mcp list | grep context7

# Manual registration
claude mcp add test-context7 --scope user -- \
  docker run -i --rm --name test-server --memory 2g --cpus 1 context7-mcp:1.0
```

### Container Lifecycle Monitoring
```bash
# Monitor containers during requests
watch -n 0.5 "docker ps --filter ancestor=context7-mcp:1.0"

# Expected pattern:
# 1. No containers before request
# 2. Container appears during request  
# 3. Container disappears after request
```

## Troubleshooting Failed Tests

### Build Test Failures

**Image Size Too Large**
```bash
# Check image layers
docker history context7-mcp:1.0

# Rebuild with cache disabled
docker build --no-cache -t context7-mcp:1.0 .
```

**Architecture Issues**
```bash
# Check available platforms
docker buildx ls

# Build for specific platform
docker build --platform linux/arm64 -t context7-mcp:1.0 .
```

### MCP Test Failures

**JSON-RPC Not Responding**
```bash
# Test container startup
docker run --rm context7-mcp:1.0 --help

# Check for package installation
docker run --rm --entrypoint /bin/sh context7-mcp:1.0 -c 'which context7-mcp'
```

**Resource Limit Issues**
```bash
# Check Docker system info
docker system info | grep -i memory

# Test limits manually
docker run -d --memory 2g --name test-limits context7-mcp:1.0
docker inspect test-limits --format='{{.HostConfig.Memory}}'
```

### Integration Test Failures

**Claude Code Issues**
```bash
# Check Claude Code version
claude --version

# Verify config file permissions
ls -la ~/.claude.json

# Manual registration test
claude mcp add test --scope user -- echo "test"
claude mcp list
claude mcp remove test
```

## Continuous Testing

### Pre-commit Testing
Run before any commits:
```bash
make test && echo "Ready to commit" || echo "Fix tests first"
```

### Performance Monitoring
```bash
# Time test execution
time make test

# Monitor resource usage during tests
top -p $(pgrep -f "docker.*context7")
```

### Test Maintenance
- Update test image name when bumping versions
- Verify test compatibility with new Claude Code versions
- Monitor test execution time and optimize as needed

---

**Test Suite Status**: ✅ **ALL TESTS PASSING**  
**Coverage**: Build, Functionality, Integration  
**Reliability**: 100% automated with error handling  
**Maintenance**: Self-cleaning with proper resource management