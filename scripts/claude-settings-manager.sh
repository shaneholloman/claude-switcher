#!/bin/bash

# Settings.json State Management Utilities
# Functions to save/restore apiKeyHelper state without being destructive to existing configs

CLAUDE_SETTINGS_FILE="$HOME/.claude/settings.json"
API_KEY_HELPER_SCRIPT="$HOME/.claude-switcher/claude-api-key-helper.sh"
STATE_FILE="$HOME/.claude-switcher/apiKeyHelper-state-$$.tmp"

# Save current apiKeyHelper state before making changes
save_api_key_helper_state() {
    local current_helper=""
    
    # Check if apiKeyHelper exists and get its value
    if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
        if command -v jq &> /dev/null; then
            current_helper=$(jq -r '.apiKeyHelper // empty' "$CLAUDE_SETTINGS_FILE" 2>/dev/null)
        elif command -v python3 &> /dev/null; then
            current_helper=$(python3 << 'EOF'
import json
try:
    with open("$CLAUDE_SETTINGS_FILE", 'r') as f:
        settings = json.load(f)
        print(settings.get('apiKeyHelper', ''))
except:
    pass
EOF
)
        fi
    fi
    
    # Save state to temp file
    if [ -n "$current_helper" ]; then
        echo "EXISTED=true" > "$STATE_FILE"
        echo "VALUE=$current_helper" >> "$STATE_FILE"
    else
        echo "EXISTED=false" > "$STATE_FILE"
    fi
}

# Restore apiKeyHelper to its original state
restore_api_key_helper_state() {
    if [ ! -f "$STATE_FILE" ]; then
        # No state saved, can't restore
        return 0
    fi
    
    # Load saved state
    source "$STATE_FILE"
    
    # Restore based on original state
    if [ "$EXISTED" = "true" ]; then
        # It existed before, restore the original value
        if [ -n "$VALUE" ]; then
            # Only restore if it's different from what we set
            if [ "$VALUE" != "$API_KEY_HELPER_SCRIPT" ]; then
                print_status "Restoring original apiKeyHelper configuration..."
                
                # Backup  current before restoring
                if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
                    cp "$CLAUDE_SETTINGS_FILE" "$CLAUDE_SETTINGS_FILE.backup-$(date +%Y%m%d-%H%M%S)"
                fi
                
                # Restore original value
                if command -v jq &> /dev/null; then
                    jq --arg helper "$VALUE" '. + {apiKeyHelper: $helper}' \
                        "$CLAUDE_SETTINGS_FILE" > "$CLAUDE_SETTINGS_FILE.tmp" && \
                        mv "$CLAUDE_SETTINGS_FILE.tmp" "$CLAUDE_SETTINGS_FILE"
                elif command -v python3 &> /dev/null; then
                    python3 << EOF
import json
settings_file = "$CLAUDE_SETTINGS_FILE"
helper_value = "$VALUE"
with open(settings_file, 'r') as f:
    settings = json.load(f)
settings['apiKeyHelper'] = helper_value
with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)
EOF
                fi
            fi
        fi
    else
        # It didn't exist before, remove it
        if grep -q "apiKeyHelper" "$CLAUDE_SETTINGS_FILE" 2>/dev/null; then
            print_status "Removing apiKeyHelper (wasn't present before)..."
            
            # Backup before removing
            cp "$CLAUDE_SETTINGS_FILE" "$CLAUDE_SETTINGS_FILE.backup-$(date +%Y%m%d-%H%M%S)"
            
            # Remove apiKeyHelper
            if command -v jq &> /dev/null; then
                jq 'del(.apiKeyHelper)' "$CLAUDE_SETTINGS_FILE" > "$CLAUDE_SETTINGS_FILE.tmp" && \
                    mv "$CLAUDE_SETTINGS_FILE.tmp" "$CLAUDE_SETTINGS_FILE"
            elif command -v python3 &> /dev/null; then
                python3 << 'EOF'
import json
settings_file = "$CLAUDE_SETTINGS_FILE"
with open(settings_file, 'r') as f:
    settings = json.load(f)
if 'apiKeyHelper' in settings:
    del settings['apiKeyHelper']
with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)
EOF
            fi
        fi
    fi
    
    # Clean up state file
    rm -f "$STATE_FILE"
}

# Add apiKeyHelper to settings.json (only if not already pointing to our script)
add_api_key_helper() {
    local helper_path="${1:-$API_KEY_HELPER_SCRIPT}"
    
    # Check if already configured with our script
    if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
        if grep -q "$API_KEY_HELPER_SCRIPT" "$CLAUDE_SETTINGS_FILE" 2>/dev/null; then
            # Already pointing to our script
            return 0
        fi
    fi
    
    # Backup existing settings if present
    if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
        cp "$CLAUDE_SETTINGS_FILE" "$CLAUDE_SETTINGS_FILE.backup-$(date +%Y%m%d-%H%M%S)"
    fi
    
    # Try jq first
    if command -v jq &> /dev/null; then
        if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
            jq --arg helper "$helper_path" '. + {apiKeyHelper: $helper}' \
                "$CLAUDE_SETTINGS_FILE" > "$CLAUDE_SETTINGS_FILE.tmp" && \
                mv "$CLAUDE_SETTINGS_FILE.tmp" "$CLAUDE_SETTINGS_FILE"
        else
            jq -n --arg helper "$helper_path" '{apiKeyHelper: $helper}' \
                > "$CLAUDE_SETTINGS_FILE"
        fi
        return 0
    fi
    
    # Try Python as fallback
    if command -v python3 &> /dev/null; then
        python3 << EOF
import json
import os
settings_file = "$CLAUDE_SETTINGS_FILE"
helper_path = "$helper_path"
if os.path.exists(settings_file):
    with open(settings_file, 'r') as f:
        settings = json.load(f)
else:
    settings = {}
settings['apiKeyHelper'] = helper_path
with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)
EOF
        return 0
    fi
    
    # Manual fallback
    if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
        print_error "Cannot safely merge settings.json without jq or python3"
        return 1
    else
        cat > "$CLAUDE_SETTINGS_FILE" << EOF
{
  "apiKeyHelper": "$helper_path"
}
EOF
        return 0
    fi
}

# Check if apiKeyHelper is configured
is_api_key_helper_configured() {
    if [ -f "$CLAUDE_SETTINGS_FILE" ] && grep -q "apiKeyHelper" "$CLAUDE_SETTINGS_FILE" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}
