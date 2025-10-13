# Kanbino Action

> AI-powered GitHub Action for automated task implementation using Claude Code

Kanbino Action is a GitHub Action that integrates with [Switch Kanban](https://switchkanban.com.br) to automatically implement tasks using Anthropic's Claude AI through the official [Claude Code Base Action](https://github.com/anthropics/claude-code-base-action).

## Features

- **Plan & Execute Modes**: Plan first, then execute - or both in sequence
- **Automatic PR Creation**: Creates pull requests with implemented changes
- **Status Callbacks**: Real-time updates to Switch Kanban
- **Flexible Tool Access**: Configure additional allowed tools for Claude
- **GitHub Integration**: Seamless integration with your GitHub workflow

## Usage

### Basic Example

```yaml
name: Kanbino Task

on:
  workflow_dispatch:
    inputs:
      task_execution_id:
        description: 'Task Execution ID'
        required: true
      mode:
        description: 'Execution mode (plan or execute)'
        required: true
        default: 'execute'

jobs:
  kanbino:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run Kanbino
        uses: SwitchDreams/kanbino-action@v1
        with:
          mode: ${{ inputs.mode }}
          task_execution_id: ${{ inputs.task_execution_id }}
          task_prompt: "Implement the user authentication feature"
          switch_kanban_api_key: ${{ secrets.SWITCH_KANBAN_API_KEY }}
          claude_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

### With Additional Tools

```yaml
- name: Run Kanbino with Linting
  uses: SwitchDreams/kanbino-action@v1
  with:
    mode: execute
    task_execution_id: ${{ inputs.task_execution_id }}
    task_prompt: "Fix all rubocop issues"
    switch_kanban_api_key: ${{ secrets.SWITCH_KANBAN_API_KEY }}
    claude_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    additional_allowed_tools: "Bash(bundle exec rubocop:*),Bash(bundle exec rspec:*)"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `mode` | Execution mode (`plan` or `execute`) | Yes | - |
| `task_execution_id` | Unique task execution identifier | Yes | - |
| `task_prompt` | Instructions for Claude to execute | Yes | - |
| `switch_kanban_api_key` | API key for Switch Kanban callbacks | Yes | - |
| `callback_url` | URL for status callbacks | No | `https://app.switchkanban.com.br` |
| `claude_api_key` | Anthropic API key | No | - |
| `claude_code_oauth_token` | Claude Code OAuth token | No | - |
| `github_token` | GitHub token for PR creation | No | `${{ github.token }}` |
| `additional_allowed_tools` | Additional tools to allow (comma-separated) | No | `''` |
| `skip_switch_kanban_callbacks` | Skip sending callbacks to Switch Kanban (useful for testing) | No | `'false'` |

### Authentication

You must provide **either** `claude_api_key` **or** `claude_code_oauth_token`:

- **`claude_api_key`**: Direct API key from [Anthropic Console](https://console.anthropic.com/)
- **`claude_code_oauth_token`**: OAuth token from Claude Code CLI

## Outputs

| Output | Description |
|--------|-------------|
| `has_changes` | Whether code changes were made (`true`/`false`) |
| `pull_request_url` | URL of the created pull request (if any) |
| `pull_request_number` | Number of the created pull request (if any) |
| `status` | Final execution status (`success`, `failed`, `no_changes`) |

## Allowed Tools

By default, Claude has access to:
- `Bash(git:*)` - Git commands
- `View` - View files
- `GlobTool` - Search for files
- `GrepTool` - Search in files
- `BatchTool` - Batch operations

### Adding Custom Tools

Use `additional_allowed_tools` to grant access to project-specific commands:

```yaml
additional_allowed_tools: "Bash(npm test:*),Bash(npm run build:*),Bash(bundle exec:*)"
```

**Common examples:**
- Ruby/Rails: `Bash(bundle exec rubocop:*),Bash(bundle exec rspec:*)`
- Node.js: `Bash(npm test:*),Bash(npm run lint:*)`
- Python: `Bash(pytest:*),Bash(black:*)`
- Go: `Bash(go test:*),Bash(go fmt:*)`

## Execution Modes

### Plan Mode
Claude analyzes the task and creates an execution plan without making changes.

```yaml
mode: plan
```

### Execute Mode
Claude implements the task and creates a pull request with changes.

```yaml
mode: execute
```

## Status Callbacks

The action sends callbacks to Switch Kanban at key stages:

1. **Started**: When execution begins
2. **Completed**: When task completes (plan or execute)
3. **Failed**: If an error occurs

Callback format:
```json
{
  "task_execution_id": "123",
  "event": "completed",
  "data": {
    "mode": "execute",
    "output": "...",
    "pull_request_url": "https://github.com/...",
    "session_id": "run-123"
  }
}
```

## Examples

### Multi-step Workflow

```yaml
name: Kanbino Multi-step

on:
  workflow_dispatch:
    inputs:
      task_execution_id:
        required: true

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: SwitchDreams/kanbino-action@v1
        with:
          mode: plan
          task_execution_id: ${{ inputs.task_execution_id }}
          task_prompt: ${{ inputs.task_prompt }}
          switch_kanban_api_key: ${{ secrets.SWITCH_KANBAN_API_KEY }}
          claude_api_key: ${{ secrets.ANTHROPIC_API_KEY }}

  execute:
    needs: plan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: SwitchDreams/kanbino-action@v1
        with:
          mode: execute
          task_execution_id: ${{ inputs.task_execution_id }}
          task_prompt: ${{ inputs.task_prompt }}
          switch_kanban_api_key: ${{ secrets.SWITCH_KANBAN_API_KEY }}
          claude_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

### With Setup Steps

```yaml
jobs:
  kanbino:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.4'
          bundler-cache: true

      - uses: SwitchDreams/kanbino-action@v1
        with:
          mode: execute
          task_execution_id: ${{ inputs.task_execution_id }}
          task_prompt: "Add feature X with tests"
          switch_kanban_api_key: ${{ secrets.SWITCH_KANBAN_API_KEY }}
          claude_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          additional_allowed_tools: "Bash(bundle exec:*),Bash(npm:*)"
```

## Testing

### Local Testing with act

Test the action locally using [act](https://github.com/nektos/act):

```bash
# 1. Install act
brew install act  # macOS

# 2. Create .secrets file with your credentials
cat > .secrets <<EOF
CLAUDE_CODE_OAUTH_TOKEN=your_oauth_token_here
GITHUB_TOKEN=your_github_token_here
SWITCH_KANBAN_API_KEY=test-key
EOF

# 3. Run the test script
./tests/test-with-act.sh
```

The test workflow runs the complete action in plan mode with `skip_switch_kanban_callbacks: true` to avoid sending callbacks during testing.

### Testing via GitHub Actions

Trigger the test workflow manually:

```bash
gh workflow run test-local.yml \
  --field mode=plan \
  --field task_prompt="Describe the project structure"
```

Or use the GitHub UI: **Actions** → **Test Kanbino Action (Local)** → **Run workflow**

### Test Configuration

The test workflow (`.github/workflows/test-local.yml`) accepts:
- `mode`: Execution mode (`plan` or `execute`)
- `task_prompt`: Custom prompt for testing

Requires secrets:
- `CLAUDE_CODE_OAUTH_TOKEN` or `CLAUDE_API_KEY`
- `GITHUB_TOKEN` (automatically provided by GitHub Actions)

## Requirements

- GitHub repository with Actions enabled
- Switch Kanban account with API key
- Anthropic API key or Claude Code OAuth token

## Security

- Store sensitive keys in [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- Never commit API keys to your repository
- Review PRs created by Kanbino before merging

## Troubleshooting

### No changes detected
- Verify the task prompt is clear and actionable
- Check Claude's output in the workflow logs
- Ensure required tools are allowed

### PR creation failed
- Verify `github_token` has write permissions
- Check branch protection rules
- Ensure repository allows PR creation from Actions

### Callback errors
- Verify `switch_kanban_api_key` is correct
- Check `callback_url` is accessible
- Review Switch Kanban API logs

## License

MIT License - see [LICENSE](LICENSE) file for details

## Links

- [Switch Kanban](https://switchkanban.com.br)
- [Claude Code Base Action](https://github.com/anthropics/claude-code-base-action)
- [Anthropic Console](https://console.anthropic.com/)

## Support

For issues and questions:
- GitHub Issues: [SwitchDreams/kanbino-action/issues](https://github.com/SwitchDreams/kanbino-action/issues)
- Switch Kanban Support: support@switchdreams.com.br
