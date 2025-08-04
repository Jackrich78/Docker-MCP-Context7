# Contributing to Context7 MCP Docker Integration

     Thank you for your interest in contributing! This project serves as both a working Context7 MCP
     integration and a reference implementation for other MCP Docker integrations.

     ## 🎯 Project Goals

     1. **Working Context7 Integration** - Provide seamless Context7 documentation access in Claude Code
     2. **MCP Integration Reference** - Demonstrate best practices for MCP + Docker + Claude Code
     3. **Educational Resource** - Help others implement similar MCP integrations

     ## 📋 Ways to Contribute

     ### **Bug Reports & Issues**
     - Use the issue templates when reporting bugs
     - Include reproduction steps and environment details
     - Test with fresh Claude Code chat sessions (most common issue!)

     ### **Documentation Improvements**
     - Fix typos, clarify instructions, improve examples
     - Add troubleshooting for new scenarios
     - Update LEARNINGS.md with new insights

     ### **Code Contributions**
     - Dockerfile optimizations
     - Makefile improvements
     - Testing script enhancements
     - Security improvements

     ### **New MCP Templates**
     - Use this as a template for other MCP integrations
     - Share learnings from other MCP implementations
     - Contribute to LEARNINGS.md with new patterns

     ## 🧪 Testing Requirements

     All contributions must pass:

     1. **Container Testing**
        ```bash
        make setup
        docker run --rm context7-mcp:1.0 --help
        ```

     2. **MCP Registration Testing**
        ```bash
        make run
        claude mcp list | grep context7
        ```

     3. **Chat Session Integration Testing**
        - Start NEW Claude Code chat session
        - Test: `use context7 to get React hooks documentation`
        - Verify: Documentation returned successfully

     4. **Documentation Testing**
        - Follow README.md from scratch
        - Verify all commands work as documented
        - Test troubleshooting steps

     ## 📝 Pull Request Process

     1. **Fork & Branch**
        ```bash
        git checkout -b feature/your-improvement
        ```

     2. **Test Thoroughly**
        - Run all tests mentioned above
        - Test on clean environment if possible
        - Document any breaking changes

     3. **Update Documentation**
        - Update README.md if user-facing changes
        - Update LEARNINGS.md if new insights
        - Update version numbers if applicable

     4. **Submit PR**
        - Use descriptive title and description
        - Reference any related issues
        - Include testing evidence

     ## 🔒 Security Guidelines

     - Never commit secrets or API keys
     - Use Docker security best practices
     - Report security vulnerabilities privately first
     - Test resource limits work correctly

     ## 📚 Development Environment

     ### **Prerequisites**
     - Docker Desktop 4.30+
     - Claude Code 1.0.65+
     - macOS, Linux, or WSL2

     ### **Setup**
     ```bash
     git clone <your-fork>
     cd context7-mcp-docker
     make setup
     make run
     # Test in fresh Claude Code chat session
     ```

     ### **Debugging**
     ```bash
     # Interactive container debugging
     make debug

     # Test MCP protocol directly
     ./test-mcp-direct.sh

     # Monitor container lifecycle
     watch -n 0.5 "docker ps --filter ancestor=context7-mcp:1.0"
     ```

     ## 🎓 Learning Resources

     - **LEARNINGS.md** - Comprehensive MCP integration insights
     - **PLAN.md** - Step-by-step implementation guide
     - **SOP.md** - Operational procedures
     - **TESTING.md** - Testing methodologies

     ## 🤝 Code Style

     - Follow existing patterns in Makefile and scripts
     - Use clear, descriptive variable names
     - Include helpful echo statements in Makefile targets
     - Comment Docker and shell scripts appropriately
     - Keep documentation up-to-date with code changes

     ## 💡 Ideas for Contributions

     ### **High Impact**
     - Performance optimizations
     - Multi-platform testing (Linux, Windows)
     - Alternative MCP implementations using this pattern
     - Integration with CI/CD pipelines

     ### **Documentation**
     - Video walkthrough of setup process
     - Troubleshooting flowcharts
     - Comparison with other MCP integration approaches
     - Translation to other languages

     ### **Developer Experience**
     - VS Code devcontainer configuration
     - GitHub Codespaces support
     - Automated testing workflows
     - Pre-commit hooks

     ## 🚀 Recognition

     Contributors will be:
     - Listed in repository contributors
     - Mentioned in release notes for significant contributions
     - Credited in LEARNINGS.md for new insights
     - Invited to review related PRs

     ## ❓ Questions?

     - Open an issue for general questions
     - Check existing issues for similar questions
     - Review LEARNINGS.md for common solutions
     - Test with fresh Claude Code chat session first!

     ## 📄 License

     By contributing, you agree that your contributions will be licensed under the MIT License.