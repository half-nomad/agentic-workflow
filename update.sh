#!/bin/bash
# Agentic Workflow Update Script (WSL/Linux/macOS Bash)

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; GRAY='\033[0;90m'; NC='\033[0m'
info() { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

VERBOSE=false
[[ "$1" == "-v" || "$1" == "--verbose" ]] && VERBOSE=true

CLAUDE_DIR="$HOME/.claude"
SOURCE_FILE="$CLAUDE_DIR/.agentic-workflow-source"

echo ""
echo -e "${MAGENTA}========================================${NC}"
echo -e "${MAGENTA}  Agentic Workflow Updater${NC}"
echo -e "${MAGENTA}========================================${NC}"
echo ""

if [[ ! -f "$SOURCE_FILE" ]]; then
    echo -e "${RED}[-] Installation info not found.${NC}"
    echo -e "${YELLOW}Run install.sh script first.${NC}"
    exit 1
fi

SOURCE_PATH=$(cat "$SOURCE_FILE" | tr -d '\n\r')
info "Source path: $SOURCE_PATH"

if [[ ! -d "$SOURCE_PATH" ]]; then
    echo -e "${RED}[-] Source path does not exist: $SOURCE_PATH${NC}"
    exit 1
fi

success "Source path verified"

SYNC_COUNT=0
declare -a DIRECTORIES=("agents" "rules" "hooks" "commands" "skills")

echo ""
info "Syncing directories..."

for dir in "${DIRECTORIES[@]}"; do
    src_dir="$SOURCE_PATH/$dir"
    dest_dir="$CLAUDE_DIR/$dir"

    if [[ -d "$src_dir" ]]; then
        mkdir -p "$dest_dir"
        file_count=0

        while IFS= read -r -d '' file; do
            relative_path="${file#$src_dir/}"
            dest_file="$dest_dir/$relative_path"
            mkdir -p "$(dirname "$dest_file")"
            cp -f "$file" "$dest_file"
            ((SYNC_COUNT++)); ((file_count++))
            [[ "$VERBOSE" == true ]] && echo -e "  ${GRAY}-> $dir/$relative_path${NC}"
        done < <(find "$src_dir" -type f -print0)

        success "$dir/ ($file_count files)"
    else
        warn "$dir/ directory not found - skipping"
    fi
done

# CLAUDE.global.md -> CLAUDE.md
global_md="$SOURCE_PATH/CLAUDE.global.md"
dest_md="$CLAUDE_DIR/CLAUDE.md"
if [[ -f "$global_md" ]]; then
    cp -f "$global_md" "$dest_md"
    ((SYNC_COUNT++))
    success "CLAUDE.md updated"
fi

echo ""
info "Merging config files..."

if command -v jq &> /dev/null; then
    src_settings="$SOURCE_PATH/settings.json"
    dest_settings="$CLAUDE_DIR/settings.json"
    if [[ -f "$src_settings" ]]; then
        if [[ -f "$dest_settings" ]]; then
            jq -s '.[0] * .[1]' "$dest_settings" "$src_settings" > "$dest_settings.tmp" && mv "$dest_settings.tmp" "$dest_settings"
        else
            cp -f "$src_settings" "$dest_settings"
        fi
        ((SYNC_COUNT++))
        success "settings.json merged"
    fi

    src_mcp="$SOURCE_PATH/.mcp.json"
    dest_mcp="$HOME/.mcp.json"
    if [[ -f "$src_mcp" ]]; then
        if [[ -f "$dest_mcp" ]]; then
            jq -s '.[0] * {mcpServers: ((.[0].mcpServers // {}) * (.[1].mcpServers // {}))}' "$dest_mcp" "$src_mcp" > "$dest_mcp.tmp" && mv "$dest_mcp.tmp" "$dest_mcp"
        else
            cp -f "$src_mcp" "$dest_mcp"
        fi
        ((SYNC_COUNT++))
        success ".mcp.json merged"
    fi
else
    warn "jq not installed. Simple copy for config files."
    [ -f "$SOURCE_PATH/settings.json" ] && cp -f "$SOURCE_PATH/settings.json" "$CLAUDE_DIR/settings.json" && ((SYNC_COUNT++))
    [ -f "$SOURCE_PATH/.mcp.json" ] && cp -f "$SOURCE_PATH/.mcp.json" "$HOME/.mcp.json" && ((SYNC_COUNT++))
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Update Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}Items synced: $SYNC_COUNT${NC}"
echo -e "${GRAY}Target path: $CLAUDE_DIR${NC}"
echo ""
