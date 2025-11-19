#!/bin/bash

# AWS Bedrock Models
# Default to Sonnet 4.5
export CLAUDE_MODEL_SONNET_AWS="us.anthropic.claude-sonnet-4-5-20250929-v1:0"
export CLAUDE_MODEL_OPUS_AWS="us.anthropic.claude-opus-4-1-20250805-v1:0"

# Google Vertex Models
# Note: Vertex model IDs often don't have the full version suffix in the same way, 
# but Claude Code might expect specific formats. 
# These are best-guess defaults based on current naming conventions.
export CLAUDE_MODEL_SONNET_VERTEX="claude-sonnet-4-5@20250929" 
export CLAUDE_MODEL_OPUS_VERTEX="claude-opus-4-1@20250805" 

# Anthropic API Models
export CLAUDE_MODEL_SONNET_ANTHROPIC="claude-sonnet-4-5-20250929"
export CLAUDE_MODEL_OPUS_ANTHROPIC="claude-opus-4-1-20250805"
