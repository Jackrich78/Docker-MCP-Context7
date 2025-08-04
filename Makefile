# Docker MCP Context7 - Build & Management
# GitHub: https://github.com/Jackrich78/Docker-MCP-Context7

# Configuration
MCP_NAME := context7
IMAGE_NAME := context7-mcp
IMAGE_TAG := 1.0
CONTAINER_NAME := context7-mcp-server
DOCKER_COMMAND := docker run -i --rm --name $(CONTAINER_NAME) --memory 2g --cpus 1 $(IMAGE_NAME):$(IMAGE_TAG)

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: help setup run clean test status health logs

# Default target
all: setup run

help: ## Show this help message
	@echo "$(BLUE)Docker MCP Context7 - Available Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-12s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Quick Start:$(NC) make setup && make run"
	@echo "$(YELLOW)Then start a NEW Claude Code chat session$(NC)"

setup: ## Build Docker image and prepare environment
	@echo "$(BLUE)🔨 Building Docker image: $(IMAGE_NAME):$(IMAGE_TAG)$(NC)"
	docker build --platform linux/arm64,linux/amd64 -t $(IMAGE_NAME):$(IMAGE_TAG) .
	@echo "$(GREEN)✅ Image built successfully$(NC)"
	@echo "$(YELLOW)📦 Image size:$(NC)"
	@docker images $(IMAGE_NAME):$(IMAGE_TAG) --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

run: ## Register MCP with Claude Code (user scope)
	@echo "$(BLUE)🚀 Registering MCP with Claude Code...$(NC)"
	@claude mcp remove $(MCP_NAME) 2>/dev/null || echo "$(YELLOW)⚠️  MCP not previously registered$(NC)"
	claude mcp add $(MCP_NAME) --scope user -- $(DOCKER_COMMAND)
	@echo "$(GREEN)✅ MCP registered successfully$(NC)"
	@echo "$(YELLOW)🔄 Start a NEW Claude Code chat session to access Context7 tools$(NC)"
	@echo "$(BLUE)💡 Test with: 'Use context7 to find React documentation'$(NC)"

clean: ## Remove containers, images, and MCP registration
	@echo "$(BLUE)🧹 Cleaning up Docker artifacts...$(NC)"
	@docker stop $(CONTAINER_NAME) 2>/dev/null || true
	@docker rm $(CONTAINER_NAME) 2>/dev/null || true
	@docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || echo "$(YELLOW)⚠️  Image not found$(NC)"
	@claude mcp remove $(MCP_NAME) 2>/dev/null || echo "$(YELLOW)⚠️  MCP not registered$(NC)"
	@echo "$(GREEN)✅ Cleanup complete$(NC)"

test: ## Run complete test suite
	@echo "$(BLUE)🧪 Running test suite...$(NC)"
	@./tests/test_build.sh
	@./tests/test_mcp.sh
	@./tests/test_integration.sh
	@echo "$(GREEN)✅ All tests passed$(NC)"

status: ## Show current status of Docker image, containers, and MCP registration
	@echo "$(BLUE)📊 Docker MCP Context7 Status$(NC)"
	@echo ""
	@echo "$(YELLOW)Docker Image:$(NC)"
	@docker images $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || echo "  $(RED)❌ Image not found$(NC)"
	@echo ""
	@echo "$(YELLOW)Running Containers:$(NC)"
	@docker ps --filter ancestor=$(IMAGE_NAME):$(IMAGE_TAG) --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  $(GREEN)✅ No containers running$(NC)"
	@echo ""
	@echo "$(YELLOW)MCP Registration:$(NC)"
	@claude mcp list 2>/dev/null | grep $(MCP_NAME) || echo "  $(RED)❌ MCP not registered$(NC)"

health: ## Check health of MCP server and Docker setup
	@echo "$(BLUE)🏥 Health Check$(NC)"
	@echo "Testing Docker image health..."
	@docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) --help > /dev/null && echo "$(GREEN)✅ Docker image healthy$(NC)" || echo "$(RED)❌ Docker image unhealthy$(NC)"
	@echo "Testing MCP JSON-RPC response..."
	@echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | docker run -i --rm $(IMAGE_NAME):$(IMAGE_TAG) | jq '.result.tools | length' > /dev/null 2>&1 && echo "$(GREEN)✅ MCP server responsive$(NC)" || echo "$(RED)❌ MCP server not responding$(NC)"

logs: ## Show logs from running MCP container
	@echo "$(BLUE)📋 Container Logs$(NC)"
	@docker logs $(CONTAINER_NAME) 2>/dev/null || echo "$(YELLOW)⚠️  No running container found$(NC)"

# Development targets
rebuild: clean setup ## Clean rebuild of Docker image

fresh-start: clean setup run ## Complete fresh installation