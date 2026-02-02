#!/bin/bash
#
# Agentic Workflow Installation Script (WSL/Linux/macOS Bash)
# Installs agentic-workflow configuration files to ~/.claude/ directory for Claude Code.
#
# Usage: ./install.sh
#

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m'

# Output functions
print_step() { echo -e "${CYAN}[*] $1${NC}"; }
print_success() { echo -e "${GREEN}[+] $1${NC}"; }
print_warn() { echo -e "${YELLOW}[!] $1${NC}"; }
print_error() { echo -e "${RED}[-] $1${NC}"; }
print_dim() { echo -e "${GRAY}    $1${NC}"; }

# Path conversion function: Convert PowerShell commands to bash (for Linux/macOS)
# Note: This function must be called after CLAUDE_HOME is set
convert_hooks_path() {
    local content="$1"
    local hooks_path="$CLAUDE_HOME/hooks"
    # Escape special sed characters in path (& / \ etc.)
    local escaped_path
    escaped_path=$(printf '%s\n' "$hooks_path" | sed 's/[&/\]/\\&/g')

    # Convert PowerShell commands to bash
    # powershell -NoProfile -ExecutionPolicy Bypass -File "hooks/xxx.ps1" -> bash "$HOME/.claude/hooks/xxx.sh"
    echo "$content" | sed -E \
        -e "s|powershell -NoProfile -ExecutionPolicy Bypass -File \"hooks/([^\"]+)\\.ps1\"|bash \"${escaped_path}/\\1.sh\"|g" \
        -e "s|\"hooks/|\"${escaped_path}/|g"
}

# Find script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_PATH="$SCRIPT_DIR"

# Detect WSL environment working with Windows filesystem
if [[ "$SCRIPT_DIR" =~ ^/mnt/c/Users/([^/]+) ]]; then
    WIN_USER="${BASH_REMATCH[1]}"
    CLAUDE_HOME="/mnt/c/Users/$WIN_USER/.claude"
    WSL_WINDOWS_MODE=true
else
    CLAUDE_HOME="$HOME/.claude"
    WSL_WINDOWS_MODE=false
fi

echo ""
echo -e "${MAGENTA}========================================${NC}"
echo -e "${MAGENTA}  Agentic Workflow Installer (Bash)${NC}"
echo -e "${MAGENTA}========================================${NC}"
echo ""

# WSL Windows mode detection output
if [ "$WSL_WINDOWS_MODE" = true ]; then
    print_warn "WSL Windows filesystem detected"
    print_warn "Installing to Windows home: $CLAUDE_HOME"
    echo ""
else
    print_step "Installation location: $CLAUDE_HOME"
    echo ""
fi

# 1. Save project source path
print_step "Saving project source path..."
mkdir -p "$CLAUDE_HOME"
SOURCE_FILE_PATH="$CLAUDE_HOME/.agentic-workflow-source"
echo -n "$SOURCE_PATH" > "$SOURCE_FILE_PATH"
print_success "Source path saved: $SOURCE_FILE_PATH"

# 2. Create directories
print_step "Creating directories..."
DIRECTORIES=("$CLAUDE_HOME" "$CLAUDE_HOME/agents" "$CLAUDE_HOME/rules" "$CLAUDE_HOME/hooks" "$CLAUDE_HOME/skills")
for dir in "${DIRECTORIES[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_success "Created: $dir"
    else
        print_dim "Already exists: $dir"
    fi
done

# 3. File copy function
copy_directory_contents() {
    local source_dir="$1"
    local dest_dir="$2"
    local count=0
    if [ -d "$source_dir" ]; then
        for file in "$source_dir"/*; do
            if [ -f "$file" ]; then
                cp -f "$file" "$dest_dir/"
                print_dim "Copied: $(basename "$file")"
                ((count++))
            fi
        done
    fi
    echo $count
}

# Copy files
print_step "Copying files..."

echo "  Copying agents/..."
count=$(copy_directory_contents "$SOURCE_PATH/agents" "$CLAUDE_HOME/agents")
print_success "agents: $count files copied"

echo "  Copying rules/..."
count=$(copy_directory_contents "$SOURCE_PATH/rules" "$CLAUDE_HOME/rules")
print_success "rules: $count files copied"

echo "  Copying hooks/..."
count=$(copy_directory_contents "$SOURCE_PATH/hooks" "$CLAUDE_HOME/hooks")
print_success "hooks: $count files copied"

echo "  Copying skills/..."
if [ -d "$SOURCE_PATH/skills" ]; then
    cp -rf "$SOURCE_PATH/skills/"* "$CLAUDE_HOME/skills/" 2>/dev/null || true
    print_success "skills: copy complete"
fi

# CLAUDE.md
echo "  Setting up CLAUDE.md..."
CLAUDE_MD_SOURCE="$SOURCE_PATH/CLAUDE.md"
CLAUDE_MD_DEST="$CLAUDE_HOME/CLAUDE.md"

if [ -f "$CLAUDE_MD_SOURCE" ]; then
    if [ -f "$CLAUDE_MD_DEST" ]; then
        BACKUP_PATH="$CLAUDE_MD_DEST.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$CLAUDE_MD_DEST" "$BACKUP_PATH"
        print_warn "Existing CLAUDE.md backed up: $BACKUP_PATH"
    fi
    cp "$CLAUDE_MD_SOURCE" "$CLAUDE_MD_DEST"
    print_success "CLAUDE.md copied (Maestro workflow)"
else
    print_dim "CLAUDE.md not found (skipping)"
fi

# 4. Merge configuration files
print_step "Merging configuration files..."

SETTINGS_SOURCE="$SOURCE_PATH/settings.json"
SETTINGS_DEST="$CLAUDE_HOME/settings.json"
MCP_SOURCE="$SOURCE_PATH/.mcp.json"
# MCP installed to user home (Windows home if WSL Windows mode)
if [ "$WSL_WINDOWS_MODE" = true ]; then
    MCP_DEST="/mnt/c/Users/$WIN_USER/.mcp.json"
else
    MCP_DEST="$HOME/.mcp.json"
fi

if command -v jq &> /dev/null; then
    # Merge settings.json (including per-event array merge for hooks)
    if [ -f "$SETTINGS_SOURCE" ]; then
        # Apply platform-specific path conversion
        SETTINGS_CONVERTED=$(convert_hooks_path "$(cat "$SETTINGS_SOURCE")")

        if [ -f "$SETTINGS_DEST" ]; then
            # Merge hooks arrays per event + permissions.allow merge
            echo "$SETTINGS_CONVERTED" | jq -s '
              .[0] as $old | .[1] as $new |
              $old * $new |
              .hooks = (
                ($old.hooks // {}) | to_entries | map({key, value: .value}) |
                . + (($new.hooks // {}) | to_entries | map({key, value: .value})) |
                group_by(.key) | map({key: .[0].key, value: (map(.value) | add)}) |
                from_entries
              ) |
              .permissions.allow = (($old.permissions.allow // []) + ($new.permissions.allow // []) | unique)
            ' "$SETTINGS_DEST" - > "$SETTINGS_DEST.tmp" && mv "$SETTINGS_DEST.tmp" "$SETTINGS_DEST"
            print_success "settings.json merged (per-event array merge for hooks)"
        else
            echo "$SETTINGS_CONVERTED" > "$SETTINGS_DEST"
            print_success "settings.json copied (new file, path conversion applied)"
        fi
    fi

    # Merge .mcp.json
    if [ -f "$MCP_SOURCE" ]; then
        if [ -f "$MCP_DEST" ]; then
            jq -s '.[0] * .[1] | .mcpServers = (.[0].mcpServers // {}) * (.[1].mcpServers // {})' \
                "$MCP_DEST" "$MCP_SOURCE" > "$MCP_DEST.tmp" && mv "$MCP_DEST.tmp" "$MCP_DEST"
            print_success ".mcp.json merged: $MCP_DEST"
        else
            cp "$MCP_SOURCE" "$MCP_DEST"
            print_success ".mcp.json copied (new file): $MCP_DEST"
        fi
    fi
else
    print_warn "============================================"
    print_warn "jq is not installed!"
    print_warn "Config files will be simply copied, existing settings may be lost."
    print_warn "Recommended: sudo apt install jq (Ubuntu/Debian)"
    print_warn "             brew install jq (macOS)"
    print_warn "============================================"

    # settings.json handling (backup then copy)
    if [ -f "$SETTINGS_SOURCE" ]; then
        # Apply platform-specific path conversion
        SETTINGS_CONVERTED=$(convert_hooks_path "$(cat "$SETTINGS_SOURCE")")

        if [ -f "$SETTINGS_DEST" ]; then
            BACKUP_PATH="$SETTINGS_DEST.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$SETTINGS_DEST" "$BACKUP_PATH"
            print_warn "Existing settings.json backed up: $BACKUP_PATH"
            print_warn "Existing settings will be overwritten (merge not possible without jq)"
        fi
        echo "$SETTINGS_CONVERTED" > "$SETTINGS_DEST"
        print_success "settings.json copied (path conversion applied)"
    fi

    # .mcp.json handling (backup then copy)
    if [ -f "$MCP_SOURCE" ]; then
        if [ -f "$MCP_DEST" ]; then
            BACKUP_PATH="$MCP_DEST.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$MCP_DEST" "$BACKUP_PATH"
            print_warn "Existing .mcp.json backed up: $BACKUP_PATH"
            print_warn "Existing settings will be overwritten (merge not possible without jq)"
        fi
        cp "$MCP_SOURCE" "$MCP_DEST"
        print_success ".mcp.json copied"
    fi
fi

# 5. MCP installation guide
echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  MCP Tools Installation Guide${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "grep_app_mcp installation required. Run the following command:"
echo ""
echo -e "${CYAN}  uvx --from git+https://github.com/ai-tools-all/grep_app_mcp grep-app-mcp${NC}"
echo ""
echo -e "${GRAY}If uv is not installed:${NC}"
echo -e "${GRAY}  pip install uv${NC}"
echo ""

# 6. Completion message
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Installation location: $CLAUDE_HOME"
echo ""
echo "Installed components:"
echo "  - agents/     : AI agent prompts"
echo "  - rules/      : Coding rules"
echo "  - hooks/      : Claude Code hook scripts"
echo "  - skills/     : Slash commands & skills"
echo "  - settings.json : Claude Code settings"
echo "  - ~/.mcp.json   : MCP server settings"
echo ""
echo -e "${YELLOW}Restart Claude Code to apply changes.${NC}"
echo ""
