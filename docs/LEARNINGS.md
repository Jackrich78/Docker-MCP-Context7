# 🚀 Universal Guide: Docker MCPs for Claude Code

*A comprehensive guide for implementing any Model Context Protocol (MCP) server in Docker containers for Claude Code integration.*

## 📖 Overview

This guide distills learnings from implementing multiple MCP servers in Docker containers, providing reusable patterns and best practices for **any MCP type**. Whether you're building database connectors, API wrappers, file system tools, or documentation servers, these principles apply universally.

### 🎯 **Scope of This Guide**
- **Universal Patterns**: Works with any MCP server type
- **Production Ready**: Security, performance, and reliability focused
- **Claude Code Optimized**: Specific patterns for Claude Code integration
- **Cross-Platform**: ARM64 and AMD64 compatible
- **Automation First**: Makefile-driven workflows

---

## 🔧 **MCP Types & Docker Strategies**

### **1. Documentation MCPs** (Context7, Devdocs, etc.)
```dockerfile
FROM node:20-alpine
RUN npm install -g @mcp/documentation-server@^1.0.0
# Optimized for: Fast lookups, minimal memory usage
# Resource limits: 2GB RAM, 1 CPU
# Network: Outbound HTTPS to documentation sources
```

### **2. Database MCPs** (PostgreSQL, MongoDB, etc.)
```dockerfile
FROM node:20-alpine
RUN npm install -g @mcp/database-connector@^1.0.0
COPY --from=postgres:15-alpine /usr/local/bin/psql /usr/local/bin/
# Optimized for: Connection pooling, query performance
# Resource limits: 4GB RAM, 2 CPUs (query processing)
# Network: Database connections, secure credential handling
```

### **3. API MCPs** (REST, GraphQL connectors)
```dockerfile
FROM node:20-alpine
RUN npm install -g @mcp/api-connector@^1.0.0
# Optimized for: HTTP client efficiency, rate limiting
# Resource limits: 2GB RAM, 1 CPU
# Network: Outbound API calls, credential management
```

### **4. File System MCPs** (Local file operations)
```dockerfile
FROM node:20-alpine
RUN npm install -g @mcp/filesystem-tools@^1.0.0
# Optimized for: File I/O, permission handling
# Resource limits: 1GB RAM, 1 CPU
# Volumes: Bind mounts for file access (security considerations)
```

### **5. AI/ML MCPs** (Model inference, data processing)
```dockerfile
FROM python:3.11-slim
RUN pip install mcp-ml-server==1.0.0
# Optimized for: Model loading, inference performance
# Resource limits: 8GB RAM, 4 CPUs (model dependent)
# Network: Model downloads, API calls
```

---

## 🌐 **Transport Protocol Patterns**

### **STDIO Transport** (Recommended)
```bash
# ✅ STDIO works perfectly with Docker
docker run -i --rm mcp-image:1.0

# ❌ TTY allocation not needed (and can cause issues)
docker run -it --rm mcp-image:1.0
```

**Key Points:**
- Use `-i` (interactive) but NOT `-t` (TTY) for MCP STDIO
- Docker handles stdin/stdout communication perfectly
- No special network configuration needed
- Works across all platforms (ARM64, AMD64)
- **Best for**: Most MCP use cases, simplest setup

### **HTTP Transport**
```bash
# HTTP MCPs need port exposure
docker run -d -p 3000:3000 --name mcp-http-server mcp-image:1.0 --transport http
```

**Registration Pattern:**
```bash
claude mcp add http-mcp --scope user -- curl -X POST http://localhost:3000/mcp
```

**Best for**: MCPs needing web interfaces, debugging, persistent connections

### **Server-Sent Events (SSE)**
```bash
# SSE transport for streaming responses
docker run -d -p 3001:3001 --name mcp-sse-server mcp-image:1.0 --transport sse
```

**Best for**: Real-time data streams, live updates, monitoring MCPs

---

## 🔐 **Security Patterns by MCP Type**

### **Documentation MCPs** (Low Security Risk)
```dockerfile
# Standard security hardening sufficient
FROM node:20-alpine
RUN addgroup -S app && adduser -S app -G app
USER app
# Network: Outbound HTTPS only
```

### **Database MCPs** (High Security Risk)
```dockerfile
FROM node:20-alpine
RUN addgroup -S app && adduser -S app -G app
# Never include credentials in image
COPY --chown=app:app . /app
USER app
# Use Docker secrets for credentials
```

**Secure Registration:**
```bash
claude mcp add db-mcp --scope user -- docker run -i --rm \
  --mount type=bind,source=/path/to/credentials,target=/run/secrets/db \
  --memory 4g --cpus 2 db-mcp:1.0
```

### **File System MCPs** (Critical Security Risk)
```dockerfile
FROM node:20-alpine
RUN addgroup -S app && adduser -S app -G app
USER app
# Restrict file access with read-only mounts
```

**Secure Registration:**
```bash
claude mcp add fs-mcp --scope project -- docker run -i --rm \
  --mount type=bind,source=/project/data,target=/data,readonly \
  --memory 1g --cpus 1 fs-mcp:1.0
```

### **API MCPs** (Medium Security Risk)
```dockerfile
FROM node:20-alpine
RUN addgroup -S app && adduser -S app -G app
USER app
# Use secrets for API keys, implement rate limiting
```

---

## 🌍 **Environment & Configuration Management**

### **Environment Variables Pattern**
```dockerfile
# Standard environment configuration
ENV MCP_TIMEOUT=30
ENV MCP_RETRIES=3
ENV MCP_LOG_LEVEL=info
```

**Registration with Environment:**
```bash
claude mcp add api-mcp --scope user -- docker run -i --rm \
  -e API_KEY="$API_KEY" \
  -e TIMEOUT=60 \
  --memory 2g --cpus 1 api-mcp:1.0
```

### **Configuration Files Pattern**
```dockerfile
# Configuration via mounted files
COPY --chown=app:app config.json /app/config.json
```

**Registration with Config:**
```bash
claude mcp add configured-mcp --scope user -- docker run -i --rm \
  --mount type=bind,source=/path/to/config.json,target=/app/config.json \
  --memory 2g --cpus 1 configured-mcp:1.0
```

### **Docker Secrets Pattern** (Most Secure)
```bash
# Create secret file
echo "api_key_here" | docker secret create mcp-api-key -

# Use in registration
claude mcp add secure-mcp --scope user -- docker run -i --rm \
  --mount type=bind,source=/run/secrets/mcp-api-key,target=/run/secrets/api-key \
  --memory 2g --cpus 1 secure-mcp:1.0
```

---

## 🏗️ **Advanced Dockerfile Patterns**

### **Multi-Stage Build Pattern**
```dockerfile
# Build stage
FROM node:20 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Runtime stage
FROM node:20-alpine AS runtime
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=builder --chown=app:app /app/node_modules ./node_modules
COPY --chown=app:app . .
USER app
ENTRYPOINT ["node", "mcp-server.js"]
```

### **Language-Specific Patterns**

**Python MCPs:**
```dockerfile
FROM python:3.11-slim
RUN groupadd -r app && useradd -r -g app app
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY --chown=app:app . .
USER app
ENTRYPOINT ["python", "mcp_server.py"]
```

**Go MCPs:**
```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o mcp-server

FROM alpine:latest
RUN addgroup -S app && adduser -S app -G app
COPY --from=builder --chown=app:app /app/mcp-server /app/
USER app
ENTRYPOINT ["/app/mcp-server"]
```

**Rust MCPs:**
```dockerfile
FROM rust:1.70 AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs && cargo build --release
COPY src ./src
RUN cargo build --release

FROM debian:bookworm-slim
RUN groupadd -r app && useradd -r -g app app
COPY --from=builder --chown=app:app /app/target/release/mcp-server /app/
USER app
ENTRYPOINT ["/app/mcp-server"]
```

---

## 🔄 **Event-Driven vs Persistent Container Patterns**

### **Event-Driven** (Recommended for Most MCPs)
```bash
# Container starts on request, stops after response
claude mcp add event-mcp --scope user -- docker run -i --rm \
  --name event-mcp-server --memory 2g --cpus 1 event-mcp:1.0
```

**Benefits:**
- Zero idle resource usage
- Fresh state each request
- Self-healing
- Scales to zero

**Best for:** Documentation, API calls, stateless operations

### **Persistent Container** (Special Cases Only)
```bash
# Container stays running
docker run -d --name persistent-mcp-server \
  --memory 4g --cpus 2 persistent-mcp:1.0

claude mcp add persistent-mcp --scope user -- docker exec -i persistent-mcp-server mcp-client
```

**Benefits:**
- Maintains connections/cache
- Faster subsequent requests
- Stateful operations

**Best for:** Database connections, model loading, cached operations

---

## 🐳 **Docker Best Practices for MCPs**

     ### **1. Multi-Architecture Support**
     ```dockerfile
     FROM node:20-alpine  # Automatically supports ARM64 and AMD64
     # Avoid: FROM --platform=linux/amd64 node:20-alpine
     ```

     ### **2. Security Hardening**
     ```dockerfile
     # ✅ Non-root user pattern
     RUN addgroup -S app && adduser -S app -G app \
      && chown -R app:app /app
     USER app

     # ✅ Minimal base images
     FROM node:20-alpine  # Not full node:20

     # ✅ Specific package versions
     RUN npm install -g @package/name@^1.0.0
     ```

     ### **3. Resource Limits**
     ```bash
     # ✅ Always set resource limits
     docker run --memory 2g --cpus 1 mcp-image:1.0

     # Prevents runaway containers
     # Makes resource usage predictable
     # Better for production deployments
     ```

     ### **4. Container Naming Strategy**
     ```bash
     # ✅ Descriptive, consistent naming
     --name context7-mcp-server
     --name sequential-mcp-server

     # Helps with Docker Desktop visibility
     # Easier troubleshooting and monitoring
     # Clear container purpose identification
     ```

     ---

     ## 🔧 **Registration & Management Patterns**

     ### **1. Cleanup Before Registration**
     ```bash
     # ✅ Always remove before adding
     claude mcp remove context7 2>/dev/null || true
     claude mcp add context7 --scope user -- docker run ...
     ```

     **Why This Matters:**
     - Prevents "already exists" errors
     - Ensures clean registration state
     - Handles re-registration gracefully
     - Works in automation scripts

     ### **2. Makefile Automation Patterns**
     ```make
     # ✅ User-friendly automation
     run:
         @echo "🚀 Registering MCP..."
         @claude mcp remove $(MCP_NAME) 2>/dev/null || echo "Not previously registered"
         claude mcp add $(MCP_NAME) --scope user -- $(DOCKER_COMMAND)
         @echo "✅ Registration complete"
         @echo "🔄 Start NEW Claude Code chat session to access tools"

     # Always include the "start new session" reminder
     ```

     ### **3. Status & Validation Commands**
     ```make
     status:
         @echo "📊 MCP Status"
         @docker image ls $(IMAGE_NAME) || echo "Image not found"
         @claude mcp list | grep $(MCP_NAME) || echo "Not registered"
     ```

     ---

     ## 🧪 **Testing Strategies**

     ### **1. Multi-Level Testing Approach**

     **Level 1: Docker Container Testing**
     ```bash
     # Test container can start and respond
     docker run --rm mcp-image:1.0 --help
     echo '{"method":"tools/list"}' | docker run -i --rm mcp-image:1.0
     ```

     **Level 2: MCP Registration Testing**
     ```bash
     # Test registration and connection
     claude mcp list | grep mcp-name
     ```

     **Level 3: Chat Session Integration Testing**
     ```bash
     # Manual test in fresh Claude Code chat session
     # "use [mcp] to [task]"
     ```

     ### **2. Container Lifecycle Monitoring**
     ```bash
     # Monitor container lifecycle during testing
     watch -n 0.5 "docker ps --filter ancestor=mcp-image:1.0"
     ```

     **Expected Pattern:**
     1. No containers before request
     2. Container appears during request
     3. Container disappears after request

     ### **3. Performance Benchmarking**
     ```bash
     # Time container startup
     time docker run --rm mcp-image:1.0 --help

     # Time full request cycle (manual in chat)
     # Target: <10 seconds for documentation requests
     ```

     ---

     ## 🚨 **Common Pitfalls & Solutions**

     ### **1. "Tools Not Available" Issues**

     **Most Common Cause:** User didn't start fresh chat session
     ```
     Solution Pattern:
     1. Check MCP registration: claude mcp list
     2. If registered: "Start NEW Claude Code chat session"
     3. If not registered: Re-run registration
     4. If still issues: Rebuild and re-register
     ```

     ### **2. Container Resource Issues**
     ```bash
     # ❌ WRONG: No resource limits
     docker run mcp-image:1.0

     # ✅ RIGHT: Always set limits
     docker run --memory 2g --cpus 1 mcp-image:1.0
     ```

     ### **3. Permission & Ownership Issues**
     ```dockerfile
     # ✅ Ensure proper ownership in Dockerfile
     RUN chown -R app:app /app
     USER app
     ```

     ### **4. Network Connectivity Issues**
     ```bash
     # Test network access from container
     docker run --rm mcp-image:1.0 ping github.com
     docker run --rm mcp-image:1.0 curl -I https://api.github.com
     ```

     ---

     ## 📋 **User Experience Principles**

     ### **1. Minimize Setup Friction**
     ```bash
     # ✅ Ideal UX: 2 commands to working MCP
     make setup && make run
     # Then: Start new chat session
     ```

     ### **2. Clear Status Communication**
     ```bash
     # ✅ Provide clear feedback
     @echo "✅ Setup complete. Image: $(IMAGE_NAME)"
     @echo "🔄 Start NEW Claude Code chat session to access tools"
     ```

     ### **3. Self-Documenting Commands**
     ```make
     # ✅ Help target with clear descriptions
     help:
         @echo "  run         - Register MCP (user scope - all chat sessions)"
         @echo "  run-project - Register MCP (project scope - current dir only)"
     ```

     ### **4. Graceful Error Handling**
     ```bash
     # ✅ Handle missing prerequisites gracefully
     docker --version >/dev/null 2>&1 || { echo "Docker not installed"; exit 1; }
     claude --version >/dev/null 2>&1 || { echo "Claude Code not installed"; exit 1; }
     ```

     ---

     ## 📚 **Documentation Patterns**

     ### **1. Essential Documentation Files**
     ```
     README.md       - Quick start, usage examples
     TESTING.md      - Step-by-step testing procedures
     SOP.md          - Operational procedures, maintenance
     Makefile        - Automation with help targets
     ```

     ### **2. Key Information to Document**
     - Fresh chat session requirement (most important!)
     - User vs project scope implications
     - Expected container lifecycle behavior
     - Performance expectations
     - Common troubleshooting steps

     ### **3. Documentation Consistency**
     Ensure all docs emphasize:
     - New chat session requirement
     - User scope as default
     - Event-driven container behavior
     - Step-by-step reproduction guides

     ---

     ## 🔄 **Development Workflow**

     ### **1. Iterative Development Pattern**
     ```bash
     # 1. Build and test container
     make setup
     docker run --rm mcp-image:1.0 --help

     # 2. Test MCP registration
     make run
     claude mcp list

     # 3. Test in fresh chat session
     # 4. Debug issues, rebuild, repeat
     ```

     ### **2. Debugging Techniques**
     ```bash
     # Interactive container debugging
     docker run -it --rm --entrypoint /bin/sh mcp-image:1.0

     # Direct JSON-RPC testing
     echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | docker run -i --rm mcp-image:1.0

     # Container logs monitoring
     docker logs $(docker ps -q --filter ancestor=mcp-image:1.0)
     ```

     ### **3. Version Management**
     ```dockerfile
     # ✅ Use flexible version constraints
     RUN npm install -g @package/name@^1.0.0

     # Allows minor updates while preventing breaking changes
     ```

     ---

     ## ⚡ **Performance Optimization**

     ### **1. Container Startup Optimization**
     ```dockerfile
     # ✅ Minimize layers and size
     FROM node:20-alpine
     RUN npm install -g --omit=dev package@^1.0.0
     # Single RUN command, no dev dependencies
     ```

     ### **2. Resource Allocation Guidelines**
     ```
     Memory: 2GB (conservative, handles most use cases)
     CPU: 1 core (sufficient for documentation retrieval)
     Network: Outbound HTTPS only (security + performance)
     ```

     ### **3. Caching Strategies**
     ```dockerfile
     # ✅ Cache package installation
     COPY package*.json ./
     RUN npm install
     COPY . .
     # Dependencies cached separately from code changes
     ```

     ---

     ## 📊 **Monitoring & Observability**

     ### **Container Lifecycle Monitoring**
     ```bash
     # Universal container monitoring script
     #!/bin/bash
     echo "Monitoring MCP: $1"
     watch -n 0.5 "docker ps --filter ancestor=$1 --format 'table {{.Names}}\t{{.Status}}\t{{.RunningFor}}\t{{.Size}}'"
     ```

     ### **Resource Usage Monitoring**
     ```bash
     # Monitor all MCP containers
     docker stats --filter name=*-mcp-server --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

     # MCP-specific resource tracking
     docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
       alpine/docker-compose stats --filter ancestor=*-mcp:*
     ```

     ### **Logging Patterns**
     ```dockerfile
     # Structured logging for MCPs
     ENV MCP_LOG_FORMAT=json
     ENV MCP_LOG_LEVEL=info
     
     # Log to stdout (Docker best practice)
     COPY --chown=app:app logging.config /app/
     ```

     **Log Aggregation:**
     ```bash
     # Centralized logging for multiple MCPs
     docker run -d --name mcp-logs \
       -v /var/log/mcp:/logs \
       fluent/fluent-bit:latest
     ```

     ### **Health Check Patterns by MCP Type**

     **Documentation MCPs:**
     ```dockerfile
     HEALTHCHECK --interval=30s --timeout=5s \
       CMD echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | mcp-server | jq '.result.tools | length > 0'
     ```

     **Database MCPs:**
     ```dockerfile
     HEALTHCHECK --interval=60s --timeout=10s \
       CMD mcp-server --health-check || exit 1
     ```

     **API MCPs:**
     ```dockerfile
     HEALTHCHECK --interval=45s --timeout=8s \
       CMD curl -f http://localhost:3000/health || exit 1
     ```

     ---

     ## 🚀 **Production Deployment Strategies**

     ### **Single-Host Deployment**
     ```yaml
     # docker-compose.yml for multiple MCPs
     version: '3.8'
     services:
       context7-mcp:
         image: context7-mcp:1.0
         deploy:
           resources:
             limits:
               memory: 2G
               cpus: '1'
       database-mcp:
         image: database-mcp:1.0
         deploy:
           resources:
             limits:
               memory: 4G
               cpus: '2'
         secrets:
           - db_credentials
     secrets:
       db_credentials:
         file: ./secrets/db_creds.txt
     ```

     ### **Container Orchestration Patterns**

     **Docker Swarm:**
     ```bash
     # Deploy MCP stack
     docker stack deploy -c docker-compose.yml mcp-stack

     # Scale specific MCPs
     docker service scale mcp-stack_context7-mcp=3
     ```

     **Kubernetes (Advanced):**
     ```yaml
     apiVersion: apps/v1
     kind: Deployment
     metadata:
       name: context7-mcp
     spec:
       replicas: 2
       selector:
         matchLabels:
           app: context7-mcp
       template:
         metadata:
           labels:
             app: context7-mcp
         spec:
           containers:
           - name: context7-mcp
             image: context7-mcp:1.0
             resources:
               limits:
                 memory: "2Gi"
                 cpu: "1"
     ```

     ### **Load Balancing MCPs**
     ```bash
     # HAProxy for HTTP MCPs
     claude mcp add balanced-mcp --scope user -- \
       curl -X POST http://load-balancer:8080/mcp
     ```

     ---

     ## 🔗 **Cross-MCP Communication Patterns**

     ### **MCP Chaining**
     ```bash
     # Database MCP feeds documentation MCP
     claude mcp add db-docs-chain --scope user -- docker run -i --rm \
       --link db-mcp-server:database \
       --memory 3g --cpus 2 chained-mcp:1.0
     ```

     ### **Shared Data Volumes**
     ```bash
     # Multiple MCPs sharing data
     docker volume create mcp-shared-data

     claude mcp add data-producer --scope user -- docker run -i --rm \
       -v mcp-shared-data:/data \
       --memory 2g --cpus 1 producer-mcp:1.0

     claude mcp add data-consumer --scope user -- docker run -i --rm \
       -v mcp-shared-data:/data:ro \
       --memory 1g --cpus 1 consumer-mcp:1.0
     ```

     ### **Event-Driven MCP Workflows**
     ```bash
     # Trigger MCP based on other MCP outputs
     claude mcp add workflow-trigger --scope user -- docker run -i --rm \
       --mount type=bind,source=/tmp/mcp-events,target=/events \
       --memory 1g --cpus 1 trigger-mcp:1.0
     ```

     ---

     ## ⚡ **Resource Optimization Strategies**

     ### **Memory Optimization by MCP Type**
     ```bash
     # Documentation MCPs: Optimize for lookup speed
     --memory 2g --memory-swap 2g  # No swap usage

     # Database MCPs: Allow for connection pooling
     --memory 4g --memory-swap 6g  # Some swap for large queries

     # ML MCPs: High memory, possible GPU access
     --memory 8g --gpus all  # GPU acceleration if available
     ```

     ### **CPU Optimization Patterns**
     ```bash
     # I/O bound MCPs (most documentation/API MCPs)
     --cpus 1

     # CPU bound MCPs (data processing, ML inference)
     --cpus 4 --cpu-quota 400000  # Allow burst usage

     # Balanced MCPs (database queries, complex processing)
     --cpus 2 --cpuset-cpus 0,1  # Pin to specific cores
     ```

     ### **Disk I/O Optimization**
     ```bash
     # Read-heavy MCPs
     --device-read-bps /dev/sda:100mb

     # Write-heavy MCPs
     --device-write-bps /dev/sda:50mb

     # Temporary file optimization
     --tmpfs /tmp:rw,size=1g,mode=1777
     ```

     ---

     ## 🔍 **Advanced Debugging Patterns**

     ### **Interactive Debugging**
     ```bash
     # Debug MCP in interactive mode
     docker run -it --rm --entrypoint /bin/sh mcp-image:1.0

     # Debug with MCP tools available
     docker run -it --rm --entrypoint bash \
       -v $(pwd):/debug mcp-image:1.0

     # Debug with network access
     docker run -it --rm --net=host mcp-image:1.0 /bin/sh
     ```

     ### **JSON-RPC Protocol Debugging**
     ```bash
     # Test MCP protocol manually
     echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | \
       docker run -i --rm mcp-image:1.0 | jq '.'

     # Test specific tool calls
     echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"tool-name","arguments":{}}}' | \
       docker run -i --rm mcp-image:1.0 | jq '.'

     # Protocol validation
     echo '{"jsonrpc":"2.0","id":3,"method":"invalid"}' | \
       docker run -i --rm mcp-image:1.0 | jq '.error'
     ```

     ### **Performance Profiling**
     ```bash
     # Profile container resource usage during requests
     docker run -d --name mcp-profile mcp-image:1.0
     docker stats mcp-profile --format "{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

     # Profile startup time
     time docker run --rm mcp-image:1.0 --help

     # Profile request latency
     time (echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | docker run -i --rm mcp-image:1.0)
     ```

     ---

     ## 🎓 **Universal MCP Principles**

     ### **1. Tool Discovery Pattern**
     Most MCPs follow this pattern:
     1. `tools/list` - Discover available tools
     2. `tools/call` - Execute specific tool
     3. Error handling for invalid requests

     **Standard Implementation:**
     ```json
     {
       "jsonrpc": "2.0",
       "id": 1,
       "method": "tools/list"
     }
     ```

     **Expected Response:**
     ```json
     {
       "jsonrpc": "2.0",
       "id": 1,
       "result": {
         "tools": [
           {
             "name": "tool-name",
             "description": "Tool description",
             "inputSchema": { "type": "object", "properties": {...} }
           }
         ]
       }
     }
     ```

     ### **2. Configuration Management Hierarchy**
     ```bash
     # Priority order (highest to lowest):
     # 1. Command line arguments
     docker run mcp-image:1.0 --config /custom/config.json

     # 2. Environment variables
     docker run -e MCP_CONFIG=/app/config.json mcp-image:1.0

     # 3. Configuration file
     COPY config.json /app/config.json

     # 4. Built-in defaults
     ENV MCP_TIMEOUT=30
     ```

     ### **3. Error Handling Patterns**
     ```dockerfile
     # Graceful error handling in MCP servers
     ENV MCP_ERROR_MODE=graceful  # vs strict
     ENV MCP_RETRY_COUNT=3
     ENV MCP_TIMEOUT=30
     ```

     **Error Response Format:**
     ```json
     {
       "jsonrpc": "2.0",
       "id": 1,
       "error": {
         "code": -32000,
         "message": "Tool execution failed",
         "data": {
           "tool": "tool-name",
           "details": "Specific error information"
         }
       }
     }
     ```

     ---

     ## 🚀 **Scaling to Multiple MCPs**

     ### **1. Naming Conventions**
     ```
     Images: mcp-name:version (e.g., context7-mcp:1.0)
     Containers: mcp-name-server (e.g., context7-mcp-server)
     Registration: mcp-name (e.g., context7)
     ```

     ### **2. Resource Management**
     ```bash
     # ✅ Consistent resource limits across MCPs
     --memory 2g --cpus 1

     # Monitor total resource usage
     docker stats --filter ancestor=*-mcp:*
     ```

     ### **3. Automation Templates**
     Create reusable Makefile templates:
     ```make
     # Template variables
     MCP_NAME := your-mcp
     IMAGE_NAME := $(MCP_NAME):1.0
     # ... reusable targets
     ```

     ---

     ## 🎯 **Success Metrics**

     **For Any MCP Integration:**
     - [ ] Setup time: ≤ 15 minutes from zero to working
     - [ ] User commands: ≤ 2 commands to working state
     - [ ] Response time: ≤ 10 seconds for typical requests
     - [ ] Fresh session tools: Available in 100% of new sessions
     - [ ] Documentation: Clear reproduction steps
     - [ ] Troubleshooting: Decision tree for common issues

     ---

     ## 💡 **Final Recommendations**

     ### **For Claude Code Agents:**
     1. **Always test session timing** - This will be your #1 issue
     2. **Start with user scope** - Better UX for most MCPs
     3. **Use event-driven containers** - More reliable than persistent
     4. **Document the fresh session requirement prominently**
     5. **Create comprehensive troubleshooting guides**

     ### **For MCP Developers:**
     1. **Follow Docker security best practices**
     2. **Support multi-architecture builds**
     3. **Implement proper resource limits**
     4. **Design for STDIO protocol compatibility**
     5. **Provide clear tool discovery and usage patterns**

     ### **For Users:**
     1. **Remember: New session after registration**
     2. **Use `claude mcp list` for health checks**
     3. **Check Docker resource usage periodically**
     4. **Report issues with specific reproduction steps**

     ---

     ## 🚨 **Troubleshooting Decision Tree**

     ### **"MCP Tools Not Available in Claude Code"**
     ```
     1. Check MCP registration
        └── `claude mcp list | grep mcp-name`
            ├── Not listed? → Run registration: `claude mcp add ...`
            └── Listed? → Continue to step 2

     2. Check connection status
        └── Shows "✓ Connected"?
            ├── Yes → Go to step 3
            └── No → Check Docker image: `docker run --rm mcp-image:1.0 --help`

     3. Check session timing
        └── Fresh Claude Code session started after registration?
            ├── No → Start NEW Claude Code session
            └── Yes → Check tool discovery: Test JSON-RPC manually

     4. Verify tool discovery
        └── `echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | docker run -i --rm mcp-image:1.0`
            ├── Error → Debug container/MCP server
            └── Success → Check Claude Code version compatibility
     ```

     ### **"Container Not Visible in Docker Desktop"**
     ```
     1. Understand container lifecycle
        └── Event-driven containers only appear during requests
            ├── Expected: Brief appearance (1-3 seconds)
            └── Problem: Never appears → Continue to step 2

     2. Test container manually
        └── `docker run --rm mcp-image:1.0 --help`
            ├── Works → MCP server issue
            └── Fails → Docker image issue

     3. Monitor during request
        └── `watch -n 0.5 'docker ps --filter ancestor=mcp-image:1.0'`
            ├── Container appears → Normal behavior
            └── Never appears → Registration issue
     ```

     ### **"Performance Issues"**
     ```
     1. Check resource limits
        └── `docker run --memory 2g --cpus 1 mcp-image:1.0`
            ├── Too restrictive → Increase limits
            └── Appropriate → Continue to step 2

     2. Profile container startup
        └── `time docker run --rm mcp-image:1.0 --help`
            ├── >5 seconds → Optimize Dockerfile
            └── <5 seconds → Check request latency

     3. Profile request latency
        └── Test JSON-RPC request timing
            ├── >10 seconds → Optimize MCP server
            └── <10 seconds → Check Claude Code integration
     ```

     ---

     ## 📋 **Implementation Templates**

     ### **Makefile Template for Any MCP**
     ```make
     # Universal MCP Makefile Template
     MCP_NAME := your-mcp-name
     IMAGE_NAME := $(MCP_NAME)
     IMAGE_TAG := 1.0
     CONTAINER_NAME := $(MCP_NAME)-server
     DOCKER_COMMAND := docker run -i --rm --name $(CONTAINER_NAME) --memory 2g --cpus 1 $(IMAGE_NAME):$(IMAGE_TAG)

     # Colors
     RED := \033[0;31m
     GREEN := \033[0;32m
     YELLOW := \033[0;33m
     BLUE := \033[0;34m
     NC := \033[0m

     .PHONY: help setup run clean test status health logs

     setup: ## Build Docker image
         @echo "$(BLUE)🔨 Building $(IMAGE_NAME):$(IMAGE_TAG)$(NC)"
         docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .
         @echo "$(GREEN)✅ Build complete$(NC)"

     run: ## Register MCP with Claude Code
         @echo "$(BLUE)🚀 Registering $(MCP_NAME)$(NC)"
         @claude mcp remove $(MCP_NAME) 2>/dev/null || true
         claude mcp add $(MCP_NAME) --scope user -- $(DOCKER_COMMAND)
         @echo "$(GREEN)✅ Registration complete$(NC)"
         @echo "$(YELLOW)🔄 Start NEW Claude Code session$(NC)"

     clean: ## Remove everything
         @echo "$(BLUE)🧹 Cleaning up$(NC)"
         @docker stop $(CONTAINER_NAME) 2>/dev/null || true
         @docker rm $(CONTAINER_NAME) 2>/dev/null || true
         @docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true
         @claude mcp remove $(MCP_NAME) 2>/dev/null || true
         @echo "$(GREEN)✅ Cleanup complete$(NC)"

     status: ## Show status
         @echo "$(BLUE)📊 $(MCP_NAME) Status$(NC)"
         @docker images $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || echo "Image not found"
         @claude mcp list | grep $(MCP_NAME) || echo "Not registered"

     health: ## Health check
         @echo "$(BLUE)🏥 Health Check$(NC)"
         @docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) --help > /dev/null && echo "$(GREEN)✅ Healthy$(NC)" || echo "$(RED)❌ Unhealthy$(NC)"

     test: ## Run tests
         @echo "$(BLUE)🧪 Testing$(NC)"
         @echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | docker run -i --rm $(IMAGE_NAME):$(IMAGE_TAG) | jq '.result.tools | length > 0'

     help: ## Show help
         @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-12s$(NC) %s\n", $$1, $$2}'
     ```

     ### **Dockerfile Template by Language**

     **Node.js MCPs:**
     ```dockerfile
     FROM node:20-alpine
     WORKDIR /app
     RUN addgroup -S app && adduser -S app -G app
     RUN npm install -g --omit=dev your-mcp-package@^1.0.0
     RUN chown -R app:app /app
     USER app
     HEALTHCHECK --interval=30s --timeout=5s CMD your-mcp --help > /dev/null || exit 1
     ENTRYPOINT ["your-mcp"]
     CMD ["--transport", "stdio"]
     ```

     **Python MCPs:**
     ```dockerfile
     FROM python:3.11-slim
     WORKDIR /app
     RUN groupadd -r app && useradd -r -g app app
     COPY requirements.txt .
     RUN pip install --no-cache-dir -r requirements.txt
     COPY --chown=app:app . .
     USER app
     HEALTHCHECK --interval=30s --timeout=5s CMD python -c "import your_mcp; print('ok')" || exit 1
     ENTRYPOINT ["python", "your_mcp.py"]
     ```

     ### **Test Script Template**
     ```bash
     #!/bin/bash
     # Universal MCP Test Script
     set -e

     MCP_NAME="your-mcp"
     IMAGE_NAME="$MCP_NAME:1.0"

     echo "🧪 Testing $MCP_NAME"

     # Test 1: Build validation
     echo "Test 1: Build validation"
     docker build -t $IMAGE_NAME . > /dev/null && echo "✅ Build successful" || exit 1

     # Test 2: Container health
     echo "Test 2: Container health"
     docker run --rm $IMAGE_NAME --help > /dev/null && echo "✅ Container healthy" || exit 1

     # Test 3: MCP protocol
     echo "Test 3: MCP protocol"
     RESPONSE=$(echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | docker run -i --rm $IMAGE_NAME)
     echo "$RESPONSE" | jq '.result.tools | length > 0' > /dev/null && echo "✅ Protocol working" || exit 1

     # Test 4: Registration
     echo "Test 4: Registration test"
     claude mcp remove $MCP_NAME 2>/dev/null || true
     claude mcp add $MCP_NAME --scope user -- docker run -i --rm --name ${MCP_NAME}-server --memory 2g --cpus 1 $IMAGE_NAME
     claude mcp list | grep $MCP_NAME > /dev/null && echo "✅ Registration successful" || exit 1

     # Cleanup
     claude mcp remove $MCP_NAME 2>/dev/null || true

     echo "🎉 All tests passed!"
     ```

     ---

     ## 💡 **Key Takeaways for Claude Assistants**

     ### **🚨 Critical Success Factors**
     1. **Session Timing is Everything**: MCP tools load at Claude Code session initialization
     2. **Event-Driven is Superior**: Event-driven containers are more reliable than persistent ones
     3. **Resource Limits are Mandatory**: Always set `--memory` and `--cpus` limits
     4. **Security First**: Always use non-root users in containers
     5. **Test Early and Often**: Build comprehensive test suites from day one

     ### **⚡ Quick Wins**
     - Use `make setup && make run` pattern for 2-command setup
     - Include monitoring commands for container visibility
     - Provide clear "fresh session" instructions
     - Use colored terminal output for better UX
     - Document expected vs actual behavior extensively

     ### **🔄 Universal Workflow**
     ```
     1. Reverse-engineer or build Dockerfile
     2. Create comprehensive Makefile with all targets
     3. Build test suite (build → MCP → integration)
     4. Register with Claude Code
     5. Test in fresh Claude Code session
     6. Document troubleshooting procedures
     7. Provide monitoring and debugging tools
     ```

     ### **📈 Success Metrics for Any MCP**
     - [ ] Setup time: ≤ 15 minutes from zero to working
     - [ ] User commands: ≤ 2 commands to working state  
     - [ ] Response time: ≤ 10 seconds for typical requests
     - [ ] Fresh session tools: Available in 100% of new sessions
     - [ ] Container visibility: Appears briefly during requests
     - [ ] Documentation: Complete troubleshooting guide
     - [ ] Tests: 100% automated test coverage

     ---

     ## 🌟 **Final Recommendations**

     ### **For Claude Code Agents Implementing MCPs:**
     1. **Start with templates** - Use the patterns in this guide
     2. **Test session timing first** - This is the #1 source of confusion
     3. **Focus on event-driven containers** - More reliable than persistent
     4. **Comprehensive documentation** - Users need clear expectations
     5. **Build monitoring tools** - Container visibility is crucial for confidence

     ### **For Users of Docker MCPs:**
     1. **Remember: Fresh sessions required** after MCP registration
     2. **Event-driven containers are normal** - brief visibility is expected
     3. **Use monitoring commands** to understand container lifecycle
     4. **Resource limits protect your system** - don't disable them
     5. **Report issues with reproduction steps** - include exact commands

     ### **Universal Debugging Approach:**
     ```
     1. Registration: `claude mcp list | grep mcp-name`
     2. Container: `docker run --rm mcp-image:1.0 --help`
     3. Protocol: `echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | docker run -i --rm mcp-image:1.0`
     4. Session: Start fresh Claude Code session
     5. Integration: Test MCP tools in new session
     ```

     ---

     **🔑 Master Insight:** The session timing discovery was the breakthrough that made Docker MCP 
     integrations reliable. MCP tools load at Claude Code session initialization, not during 
     registration. This principle applies to ALL MCP integrations and is the most valuable insight 
     for successful implementations.

     **🎯 Goal:** Use these patterns to implement any MCP type in Docker containers with Claude Code 
     integration, achieving production-ready reliability and user experience in minimal time.

     ---

     *This universal guide distills learnings from implementing multiple MCP types in Docker containers. 
     Apply these patterns for faster, more reliable MCP implementations across any technology stack.*