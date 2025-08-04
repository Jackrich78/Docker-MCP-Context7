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

- **Event-driven containers**: Spawn on-demand, appear briefly in Docker Desktop
- **Multi-architecture**: Supports ARM64 (M1/M2 Mac) and AMD64
- **Resource limited**: 2GB RAM, 1 CPU core maximum
- **Security hardened**: Non-root container user
- **Test coverage**: Unit, functional, and integration tests

## 🔍 Container Visibility Explained

**Why containers "flash" and disappear (this is normal!):**

| ❌ What You Might Expect | ✅ What Actually Happens |
|-------------------------|-------------------------|
| Container always visible in Docker Desktop | Container appears only during requests (1-3 seconds) |
| Container stays running like a web server | Container starts → processes request → stops automatically |
| Persistent container using resources | Zero resource usage when idle |

**This Event-Driven Design is Better Because:**
- 🎯 **Zero Waste**: No idle containers consuming 291MB of memory
- 🔄 **Self-Healing**: Fresh container each request eliminates issues
- 🚀 **Fast**: Container starts in under 1 second
- 🧹 **Auto-Cleanup**: No manual container management needed

**What's Normal:**
- Container appears briefly in Docker Desktop during requests
- Container disappears immediately after request completes
- No containers visible when Claude Code is idle

**What Indicates Problems:**
- Container fails to appear during requests
- Error messages in terminal
- Requests taking >10 seconds
- Claude Code shows "MCP connection failed"

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

## 👥 Non-Technical User Guide

### 🚀 First Time Setup

1. **Open Terminal** (Applications → Utilities → Terminal on Mac)
2. **Navigate to project folder:**
   ```bash
   cd /Users/jack/Developer/MCPs
   ```
3. **Build the system:**
   ```bash
   make setup
   ```
   *Wait for "✅ Image built successfully" message*

4. **Register with Claude Code:**
   ```bash
   make run
   ```
   *Wait for "✅ MCP registered successfully" message*

### 📊 Daily Monitoring & Verification

**Check if everything is working:**
```bash
make status
```
**Expected output:**
- ✅ Docker Image: Shows `context7-mcp:1.0`
- ✅ Running Containers: Should be empty (normal!)
- ✅ MCP Registration: Shows "✓ Connected"

**Health check:**
```bash
make health
```
**Expected output:**
- ✅ Docker image healthy
- ✅ MCP server responsive

### 👀 Real-Time Container Monitoring

**To watch containers appear and disappear during requests:**

1. **Open a new terminal window**
2. **Run the monitoring command:**
   ```bash
   watch -n 0.5 'docker ps --filter ancestor=context7-mcp:1.0 --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}"'
   ```
3. **In Claude Code, make a request like:** "Use context7 to find React documentation"
4. **Watch the terminal** - you'll see `context7-mcp-server` appear and disappear!

### 🔧 Testing the System

**Quick test from command line:**
```bash
echo "Testing Context7..." && echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | docker run -i --rm --name context7-mcp-server --memory 2g --cpus 1 context7-mcp:1.0 | head -3
```
**Expected:** Should return JSON with available tools

### 🛑 Shutdown & Cleanup

**To completely stop and remove everything:**
```bash
make clean
```
**This will:**
- Remove the MCP registration from Claude Code
- Delete the Docker image
- Clean up any leftover containers

**To restart later:**
```bash
make setup && make run
```

### 🚨 What to Do If Something Goes Wrong

**If `/mcp` in Claude Code shows "failed":**
- This is usually just a display issue
- Run `claude mcp list` - if it shows "✓ Connected", it's working fine
- The Context7 tools will still work in fresh Claude Code sessions

**If containers never appear in Docker Desktop:**
- Run `make health` to check if the system is working
- Try the command-line test above
- Check Docker Desktop is running and accessible

**If Context7 tools aren't available in Claude Code:**
- **Most common fix:** Start a NEW Claude Code chat session
- Verify registration: `claude mcp list | grep context7`
- If not registered: Run `make run` again

## 🧪 Testing

```bash
# Run all tests
make test

# Individual test suites
./tests/test_build.sh       # Docker build validation
./tests/test_mcp.sh         # MCP functionality tests
./tests/test_integration.sh # Claude Code integration
```

## 🔧 Advanced Troubleshooting

### "I Don't See the Container in Docker Desktop!"

**This is usually normal!** Containers only appear during active requests (1-3 seconds).

**To verify it's working:**
1. **Run the monitoring command** in a separate terminal:
   ```bash
   watch -n 0.5 'docker ps --filter ancestor=context7-mcp:1.0'
   ```
2. **In Claude Code, ask:** "Use context7 to find React documentation"
3. **Watch the monitoring terminal** - you should see the container appear briefly

**If you still don't see it:**
- Run `make health` - should show "✅ MCP server responsive"
- Try the manual test: `echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | docker run -i --rm context7-mcp:1.0`

### Tools Not Available in Chat

**Most Common Issue**: Using old chat session

```bash
# 1. Verify registration
claude mcp list | grep context7

# 2. If shows "✓ Connected": Start NEW Claude Code chat session
# 3. If not registered: Re-run setup
make run
```

**Why this happens:**
- MCP tools load when Claude Code session **starts**
- If you registered MCP during an existing session, tools won't be available
- Fresh sessions automatically load all registered MCPs

### "/mcp Shows Failed Status"

**This is usually a cosmetic issue!**
- The Context7 server prints status messages that Claude interprets as "errors"
- **Real test**: Run `claude mcp list` - if it shows "✓ Connected", it's working
- Context7 tools will still work in fresh Claude Code sessions

### Build Issues

```bash
# Clean rebuild
make clean
make setup
```

### Performance Issues

**If requests take >10 seconds:**
```bash
# 1. Check system resources
make status

# 2. Test direct connection
make health

# 3. Rebuild if needed
make clean && make setup && make run
```

### Complete Reset

**If nothing works, start over:**
```bash
# Remove everything
make clean

# Rebuild from scratch
make setup

# Register again
make run

# Test in NEW Claude Code session
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

## 📋 Quick Reference Card

### Essential Commands
```bash
make setup          # Build Docker image
make run            # Register with Claude Code
make status         # Check system status
make health         # Health check
make clean          # Remove everything
```

### Container Monitoring
```bash
# Watch containers in real-time
watch -n 0.5 'docker ps --filter ancestor=context7-mcp:1.0'

# Manual test
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | docker run -i --rm --name context7-mcp-server --memory 2g --cpus 1 context7-mcp:1.0
```

### Key Concepts
- **Event-Driven**: Containers appear briefly (1-3 seconds) during requests only
- **Fresh Sessions**: Start NEW Claude Code session after registration
- **Zero Idle Resources**: No containers running when Claude Code is idle
- **Auto-Cleanup**: Containers self-destruct after each request

### Normal Behavior ✅
- Container flashes in Docker Desktop during requests
- No containers visible when idle
- "/mcp" might show "failed" (cosmetic issue)
- `claude mcp list` shows "✓ Connected"

### Problem Indicators ❌
- `make health` shows errors
- Requests take >10 seconds
- No container ever appears during requests
- `claude mcp list` shows disconnected

**Key Insight**: Always start a NEW Claude Code chat session after MCP registration to access tools.