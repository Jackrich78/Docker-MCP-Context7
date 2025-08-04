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

     ## 🎓 **Universal MCP Principles**

     ### **1. Tool Discovery Pattern**
     Most MCPs follow this pattern:
     1. `tools/list` - Discover available tools
     2. `tools/call` - Execute specific tool
     3. Error handling for invalid requests

     ### **2. Configuration Management**
     ```bash
     # Environment variables pattern
     docker run -e API_KEY=value -e TIMEOUT=30 mcp-image:1.0

     # Secret files pattern (more secure)
     docker run --mount type=bind,source=/path/to/secret,target=/run/secrets/key mcp-image:1.0
     ```

     ### **3. Health Check Implementation**
     ```dockerfile
     HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
       CMD mcp-binary --health || exit 1
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

     **Key Insight:** The session timing discovery was the breakthrough that made this entire integration
      successful. Without understanding that MCP tools load at session initialization, the integration
     appears broken when it's actually working correctly.

     This principle likely applies to ALL MCP integrations with Claude Code, making it the most valuable
     insight for other agents to understand.

     ---

     *These learnings distill the key insights from implementing Context7 MCP with Docker containers for 
     Claude Code. Apply these principles to other MCP integrations for faster, more reliable 
     implementations.*