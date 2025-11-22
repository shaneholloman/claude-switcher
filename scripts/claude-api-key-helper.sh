#!/bin/bash
# API Key Helper for Claude Switcher
# Returns ANTHROPIC_API_KEY only when in Anthropic mode
#
# This script is called by Claude Code via the apiKeyHelper setting in ~/.claude/settings.json
# It enables seamless switching between Claude Pro/Max subscription and Anthropic API key
# without requiring logout flows.
#
# Behavior:
# - In "anthropic" mode: outputs ANTHROPIC_API_KEY → Claude uses API key auth
# - In "pro" mode (or any other): outputs nothing → Claude uses web auth
# - AWS, Vertex, Azure don't use this - they have their own environment variables

MODE_FILE="$HOME/.claude-switcher/current-mode.sh"
SECRETS_FILE="$HOME/.claude-switcher/secrets.sh"

# Load secrets if available
if [ -f "$SECRETS_FILE" ]; then
    source "$SECRETS_FILE"
fi

# Load current mode (sets CLAUDE_SWITCHER_MODE)
if [ -f "$MODE_FILE" ]; then
    source "$MODE_FILE"
fi

# Return API key ONLY for Anthropic mode
# For all other modes (pro, aws, vertex, azure), return nothing
if [ "${CLAUDE_SWITCHER_MODE}" = "anthropic" ]; then
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        echo "$ANTHROPIC_API_KEY"
    fi
fi

# Exit successfully either way
exit 0
