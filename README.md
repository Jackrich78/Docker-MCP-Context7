# Docker MCP Context7

A containerized [Context7](https://github.com/upstash/context7) Model Context Protocol (MCP) server for Claude Code, providing live library documentation access.

## 🚀 Quick Start

```bash
# 1. Build and setup
make setup

# 2. Register with Claude Code
make run

# 3. Start NEW Claude Code chat session
# Then ask: "Use context7 to find React hooks documentation"
```

## 📋 Prerequisites

- Docker Desktop ≥ 4.30
- Claude Code v1.0.65+
- Git (for development)

## 🎯 Features

- **Event-driven containers**: Spawn on-demand, visible in Docker Desktop
- **Multi-architecture**: Supports ARM64 (M1/M2 Mac) and AMD64
- **Resource limited**: 2GB RAM, 1 CPU core maximum
- **Security hardened**: Non-root container user
- **Test coverage**: Unit, functional, and integration tests

## 📚 Usage

### Available Commands

```bash
make help         # Show all available commands
make setup        # Build Docker image
make run          # Register MCP with Claude Code (user scope)
make status       # Show current status
make test         # Run complete test suite
make health       # Health check
make clean        # Remove everything
make logs         # Show container logs
```

### Using in Claude Code

After running `make setup && make run`:

1. **Start a NEW Claude Code chat session** (required for MCP loading)
2. Ask questions like:
   - "Use context7 to find React hooks documentation"
   - "Get Next.js routing documentation via context7"
   - "Find Tailwind CSS utility documentation"

### Expected Behavior

- **Container Lifecycle**: Containers appear in Docker Desktop only during requests
- **Response Time**: Documentation requests complete in <10 seconds
- **Tools Available**: `resolve-library-id` and `get-library-docs`

## 🧪 Testing

```bash
# Run all tests
make test

# Individual test suites
./tests/test_build.sh       # Docker build validation
./tests/test_mcp.sh         # MCP functionality tests
./tests/test_integration.sh # Claude Code integration
```

## 🔧 Troubleshooting

### Tools Not Available in Chat

**Most Common Issue**: Using old chat session

```bash
# 1. Verify registration
claude mcp list | grep context7

# 2. If registered: Start NEW chat session
# 3. If not registered: Re-run setup
make run
```

### Container Not Visible

```bash
# Check Docker Desktop while making a request
# Container should appear during documentation requests
make status
```

### Build Issues

```bash
# Clean rebuild
make clean
make setup
```

## 🏗️ Development

### Project Structure

```
├── Dockerfile              # Multi-arch container
├── Makefile                # Build automation
├── tests/                  # Test suite
│   ├── test_build.sh      # Build validation
│   ├── test_mcp.sh        # MCP functionality
│   └── test_integration.sh # Claude integration
└── docs/                   # Documentation
```

### Manual Testing

```bash
# Test container directly
docker run --rm context7-mcp:1.0 --help

# Test JSON-RPC
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | \
  docker run -i --rm context7-mcp:1.0
```

## 📚 Documentation

- [PRD.md](PRD.md) - Product requirements
- [LEARNINGS.md](docs/LEARNINGS.md) - Implementation learnings
- [TESTING.md](docs/TESTING.md) - Testing procedures

---

**Key Insight**: Always start a NEW Claude Code chat session after MCP registration to access tools.