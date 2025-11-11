# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Kanbino Action is a GitHub composite action that wraps the [Claude Code Base Action](https://github.com/anthropics/claude-code-base-action) to provide automated task implementation integrated with Switch Kanban. It orchestrates Claude AI execution with callback mechanisms for external status tracking.

## Architecture

### Composite Action Structure

This is a **GitHub composite action** (not a JavaScript/Docker action), defined entirely in `action.yml`. The action orchestrates several steps sequentially:

1. **Callback Initialization** - Sends "started" webhook to Switch Kanban
2. **Environment Setup** - Adds Claude CLI to PATH (required for `act` compatibility)
3. **Tool Preparation** - Merges default and additional allowed tools
4. **Claude Execution** - Delegates to `anthropics/claude-code-base-action@beta`
5. **Output Processing** - Extracts Claude's response from execution file
6. **Change Detection** - Uses `git diff` to detect code modifications
7. **Conditional Branching** - Different flows for `plan` vs `execute` modes
8. **PR Creation** - Creates pull request if changes detected (execute mode only)
9. **Status Callbacks** - Sends completion/failure webhooks to Switch Kanban

### Key Design Patterns

**Composite Action Pattern**: All logic lives in `action.yml` using shell scripts. No separate action code files exist.

**Callback-Driven Architecture**: Three callback events to external API:
- `started` - On workflow start
- `completed` - On successful completion (plan or execute)
- `failed` - On any failure

**Mode-Based Execution**:
- `plan` mode: Claude analyzes and plans without making changes
- `execute` mode: Claude implements changes and creates PR

**Tool Allowlisting**: Security model where only explicitly allowed tools are available to Claude. Defaults to read-only operations (`View`, `GlobTool`, `GrepTool`) plus git commands.

## Authentication

The action accepts **either** (not both):
- `anthropic_api_key` - Direct Anthropic API key
- `claude_code_oauth_token` - OAuth token from Claude Code CLI

These are mutually exclusive and passed directly to the underlying `claude-code-base-action`.

## Output Processing

Claude's execution results are stored in a JSON file (path in `steps.claude.outputs.execution_file`). The action extracts the last assistant message:

```bash
jq -c '[.[] | select(.role == "assistant")] | last | .content'
```

This output is included in callback payloads to Switch Kanban.

## Branch Naming Convention

All PRs are created on branches named: `kanbino/task-{task_execution_id}`

## Development Commands

This repository contains no build, test, or lint commands. It's a pure GitHub Actions composite action.

### Testing Locally

Use [act](https://github.com/nektos/act) to test the action locally:

```bash
act workflow_dispatch --input mode=plan --input task_execution_id=123 --input task_prompt="Test prompt"
```

Note: The "Setup Claude CLI PATH" step exists specifically for `act` compatibility.

## Common Modifications

### Adding Default Tools

Edit the `DEFAULT_TOOLS` variable in the "Prepare allowed tools" step (action.yml:86):

```yaml
DEFAULT_TOOLS="Bash(git:*),View,GlobTool,GrepTool,BatchTool,NewTool"
```

### Modifying Callback Payload Structure

Callbacks are constructed using `jq` and written to temporary JSON files. See steps:
- `plan_data` (line 142)
- `exec_data` (line 170)
- `pr_data_new` (line 227)
- `failed_data` (line 261)

### Changing PR Format

Edit the "Create Pull Request" step (line 202) to modify:
- Branch naming pattern
- PR title format
- Commit message structure
- PR body template

## Dependencies

### Required Actions
- `fjogeleit/http-request-action@v1` - HTTP callbacks
- `anthropics/claude-code-base-action@beta` - Core Claude execution
- `peter-evans/create-pull-request@v6` - PR creation

### Required Tools in Runner
- `git` - Change detection and version control
- `jq` - JSON processing for callbacks and outputs
- `bash` - All script execution

## Security Considerations

- The `switch_kanban_api_key` is sent as Bearer token in all callbacks
- The `github_token` must have PR creation permissions (write access to repository)
- Claude's tool access is explicitly restricted via `allowed_tools` parameter
- No credentials are logged or included in PR descriptions

## Callback API Contract

All callbacks to `{callback_url}/api/v1/kanbino/callbacks`:

**Headers:**
- `Authorization: Bearer {switch_kanban_api_key}`
- `Content-Type: application/json`

**Started Event:**
```json
{
  "task_execution_id": "string",
  "event": "started",
  "data": {
    "mode": "plan|execute",
    "run_id": "github_run_id"
  }
}
```

**Completed Event:**
```json
{
  "task_execution_id": "string",
  "event": "completed",
  "data": {
    "mode": "plan|execute",
    "output": "claude_response",
    "session_id": "github_run_id",
    "pull_request_url": "string (execute mode only)",
    "pull_request_number": number (execute mode only),
    "branch_name": "string (execute mode only)",
    "no_changes": boolean (execute mode only)
  }
}
```

**Failed Event:**
```json
{
  "task_execution_id": "string",
  "event": "failed",
  "data": {
    "error": "error_message",
    "workflow_url": "github_workflow_url"
  }
}
```
