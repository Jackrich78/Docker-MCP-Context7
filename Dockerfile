# Multi-architecture Context7 MCP Server
# Supports: linux/arm64, linux/amd64
FROM node:20-alpine

# Metadata
LABEL maintainer="jack@example.com"
LABEL description="Context7 MCP Server for Claude Code"
LABEL version="1.0.0"

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -S app && adduser -S app -G app

# Install Context7 MCP package globally
# Pin to 1.0.x for stability, allow patch updates
RUN npm install -g --omit=dev @upstash/context7-mcp@^1.0.0

# Set ownership and switch to non-root user
RUN chown -R app:app /app
USER app

# Health check for container monitoring
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD context7-mcp --help > /dev/null || exit 1

# MCP server entry point
ENTRYPOINT ["context7-mcp"]
CMD ["--transport", "stdio"]