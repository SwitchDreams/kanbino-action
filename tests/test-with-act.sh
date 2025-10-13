#!/bin/bash
# Script to test the Kanbino action locally using act
# Requires: act (https://github.com/nektos/act)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🎭 Kanbino Action - Local Testing with act${NC}\n"

# Check if act is installed
if ! command -v act &> /dev/null; then
    echo -e "${RED}❌ 'act' is not installed${NC}"
    echo ""
    echo "Install it with:"
    echo "  brew install act  (macOS)"
    echo "  or visit: https://github.com/nektos/act"
    exit 1
fi

echo -e "${GREEN}✅ act is installed${NC}\n"

# Default values
MODE="${1:-plan}"
TASK_PROMPT="${2:-List all files and describe the project structure}"

echo -e "${YELLOW}Configuration:${NC}"
echo "  Mode: $MODE"
echo "  Prompt: $TASK_PROMPT"
echo ""

# Check if .secrets file exists, if not create a template
if [ ! -f .secrets ]; then
    echo -e "${YELLOW}⚠️  No .secrets file found. Creating template...${NC}"
    cat > .secrets <<'EOF'
# Secrets for local testing with act
# Copy this file and fill in your actual values
# NEVER commit this file to git!

CLAUDE_CODE_OAUTH_TOKEN=your_oauth_token_here
GITHUB_TOKEN=your_github_token_here
SWITCH_KANBAN_API_KEY=test-key
EOF
    echo -e "${GREEN}✅ Created .secrets template${NC}"
    echo -e "${YELLOW}⚠️  Please edit .secrets and add your credentials${NC}\n"
fi

# Run the test workflow with act
echo -e "${BLUE}🚀 Running test workflow with act...${NC}\n"

act workflow_dispatch \
    --workflows .github/workflows/test-local.yml \
    --input mode="$MODE" \
    --input task_prompt="$TASK_PROMPT" \
    --secret-file .secrets

echo ""
echo -e "${GREEN}✅ Test completed!${NC}"
