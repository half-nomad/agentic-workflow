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

# Timestamped backup root. Syncing must never destroy a file the user already had
# under the same name (their own agent/rule/hook/skill, or local edits).
BACKUP_ROOT="$CLAUDE_DIR/backups/update-$(date +%Y%m%d-%H%M%S)"
BACKED_UP=0

backup_if_differs() {
    local target="$1" source="$2"
    [[ -e "$target" ]] || return 0
    cmp -s "$target" "$source" && return 0   # identical — nothing to lose
    local rel="${target#$CLAUDE_DIR/}"
    mkdir -p "$BACKUP_ROOT/$(dirname "$rel")"
    cp -a "$target" "$BACKUP_ROOT/$rel"
    BACKED_UP=$((BACKED_UP + 1))   # not ((x++)): under `set -e` that returns 1 when x is 0
}

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
            backup_if_differs "$dest_file" "$file"
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
            # Per-event array merge for hooks (jq `*` REPLACES arrays — a naive
            # merge silently drops global-only hooks). Mirrors install.sh.
            jq -s '
              .[0] as $old | .[1] as $new |
              $old * $new |
              .hooks = (
                ($old.hooks // {}) as $oh | ($new.hooks // {}) as $nh |
                ((($oh | keys) + ($nh | keys)) | unique) as $events |
                [ $events[] as $e |
                  ((($nh[$e] // []) | map(.matcher)) as $nm |
                   {key: $e,
                    value: ((($oh[$e] // []) | map(select(.matcher as $m | ($nm | index($m)) == null))) + ($nh[$e] // []))})
                ] | from_entries
              ) |
              .permissions.allow = ((($old.permissions.allow // []) + ($new.permissions.allow // []) | unique) - ["Bash(npm:*)", "Bash(npx:*)", "Bash(pnpm:*)", "Bash(yarn:*)"]) |
              .permissions.ask = (($old.permissions.ask // []) + ($new.permissions.ask // []) | unique)
            ' "$dest_settings" "$src_settings" > "$dest_settings.tmp" && mv "$dest_settings.tmp" "$dest_settings"
        else
            cp -f "$src_settings" "$dest_settings"
        fi
        ((SYNC_COUNT++))
        success "settings.json merged (per-event array merge for hooks)"
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
    else
        warn ".mcp.json not found in source — skipping"
    fi
else
    warn "jq not installed — config files are OVERWRITTEN, not merged."
    warn "Existing settings are backed up first; install jq to merge instead."
    if [ -f "$SOURCE_PATH/settings.json" ]; then
        backup_if_differs "$CLAUDE_DIR/settings.json" "$SOURCE_PATH/settings.json"
        cp -f "$SOURCE_PATH/settings.json" "$CLAUDE_DIR/settings.json"; ((SYNC_COUNT++))
    fi
    if [ -f "$SOURCE_PATH/.mcp.json" ]; then
        [ -e "$HOME/.mcp.json" ] && { mkdir -p "$BACKUP_ROOT"; cp -a "$HOME/.mcp.json" "$BACKUP_ROOT/.mcp.json"; BACKED_UP=$((BACKED_UP + 1)); }
        cp -f "$SOURCE_PATH/.mcp.json" "$HOME/.mcp.json"; ((SYNC_COUNT++))
    else
        warn ".mcp.json not found — skipping"
    fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Update Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}Items synced: $SYNC_COUNT${NC}"
if (( BACKED_UP > 0 )); then
    echo -e "${YELLOW}Overwritten files backed up ($BACKED_UP): $BACKUP_ROOT${NC}"
fi
echo -e "${GRAY}Target path: $CLAUDE_DIR${NC}"
echo ""
