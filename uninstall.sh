#!/bin/bash
# agentic-workflow Uninstall Script (WSL/Linux/macOS Bash)

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; NC='\033[0m'
info() { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

CLAUDE_DIR="$HOME/.claude"
SOURCE_FILE="$CLAUDE_DIR/.agentic-workflow-source"
FORCE=false
[[ "$1" == "-f" || "$1" == "--force" ]] && FORCE=true

echo ""
echo -e "${MAGENTA}========================================${NC}"
echo -e "${MAGENTA}  agentic-workflow Uninstaller${NC}"
echo -e "${MAGENTA}========================================${NC}"
echo ""

info "Checking installation status..."

if [ ! -f "$SOURCE_FILE" ]; then
    warn "agentic-workflow is not installed."
    exit 0
fi

SOURCE_PATH=$(cat "$SOURCE_FILE" | tr -d '\r\n')
info "Installed source path: $SOURCE_PATH"

if [ "$FORCE" = false ]; then
    read -p "Remove agentic-workflow? (y/N) " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { info "Removal cancelled."; exit 0; }
fi

# File removal function
remove_installed_files() {
    local folder_name="$1" source_subdir="$2"
    local target_dir="$CLAUDE_DIR/$folder_name" source_dir="$SOURCE_PATH/$source_subdir"

    [ ! -d "$target_dir" ] || [ ! -d "$source_dir" ] && return

    local removed_count=0
    while IFS= read -r -d '' file; do
        local relative_path="${file#$source_dir/}"
        local target_file="$target_dir/$relative_path"
        [ -f "$target_file" ] && rm -f "$target_file" && ((removed_count++))
    done < <(find "$source_dir" -type f -print0)

    [ "$removed_count" -gt 0 ] && success "$removed_count files removed from $folder_name"
}

info "Removing installed files..."
remove_installed_files "agents" "agents"
remove_installed_files "rules" "rules"
remove_installed_files "hooks" "hooks"
remove_installed_files "commands" "commands"
remove_installed_files "skills" "skills"

# CLAUDE.md handling
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
BACKUP=$(ls -t "$CLAUDE_DIR/CLAUDE.md.backup."* 2>/dev/null | head -1)
if [ -n "$BACKUP" ]; then
    cp "$BACKUP" "$CLAUDE_MD" && rm -f "$BACKUP"
    success "CLAUDE.md restored from backup."
elif [ -f "$CLAUDE_MD" ]; then
    rm -f "$CLAUDE_MD"
    success "CLAUDE.md removed."
fi

[ -f "$SOURCE_FILE" ] && rm -f "$SOURCE_FILE" && success ".agentic-workflow-source file removed."

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Uninstall Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "To reinstall, run install.sh."
echo ""
