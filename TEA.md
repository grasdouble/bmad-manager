TEA will detect your project type from manifest files:
│
│    - Frontend: package.json with react/vue/angular, playwright.config.*, vite.config.*
│
│    - Backend: pyproject.toml, pom.xml, go.mod, *.csproj, Gemfile, Cargo.toml
│
│    - Full-stack: both frontend and backend indicators present
│
│    Existing installations without test_stack_type default to "auto" (detects frontend).
│
│
│
●  CI Platform Auto-Detection:
│
●  TEA will detect your CI platform from repository files:
│
│    - GitHub Actions: .github/workflows/
│
│    - GitLab CI: .gitlab-ci.yml
│
│    - Jenkins: Jenkinsfile
│
│    - Azure DevOps: azure-pipelines.yml
│
│    - Harness: .harness/
│
│    - CircleCI: .circleci/config.yml
│
│    Existing installations without ci_platform default to "auto".
│
│
│
●  Playwright CLI Setup:
│
│    npm install -g @playwright/cli@latest
│
│    playwright-cli install --skills    # Run from project root
│
│    Node.js 18+ required.
│
│    
│
●  Playwright MCP Setup (two servers):
│
│    1. playwright    — npx @playwright/mcp@latest
│
│    2. playwright-test — npx playwright run-test-mcp-server
│
│    Configure both MCP servers in your IDE settings.
│
│    See: https://github.com/microsoft/playwright-mcp
│
│
│
●  Execution Mode (Auto):
│
│    TEA probes runtime capabilities at orchestration steps.
│
●  Selection order:
│
│    1. agent-team (if supported)
│
│    2. subagent (if supported)
│
│    3. sequential (fallback)
│
│    This keeps behavior portable across Codex, Claude Code, and other runtimes.