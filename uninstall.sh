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

MANIFEST="$CLAUDE_DIR/.agentic-workflow-manifest"
KEPT_MODIFIED=0

file_hash() {
    if command -v shasum >/dev/null 2>&1; then shasum -a256 "$1" 2>/dev/null | cut -d' ' -f1
    elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" 2>/dev/null | cut -d' ' -f1
    fi
}

# Manifest-driven removal: delete only files we deployed AND that still carry the
# hash we deployed. A file the user edited after install is theirs now — deleting
# it by filename alone would destroy their work.
remove_via_manifest() {
    local removed=0 old_hash rel target cur
    while IFS='  ' read -r old_hash rel; do
        [ -n "$rel" ] || continue
        target="$CLAUDE_DIR/$rel"
        [ -f "$target" ] || continue
        cur=$(file_hash "$target")
        if [ -n "$cur" ] && [ "$cur" = "$old_hash" ]; then
            rm -f "$target"; removed=$((removed + 1))
        else
            KEPT_MODIFIED=$((KEPT_MODIFIED + 1))
            warn "kept $rel — modified since install"
        fi
    done < "$MANIFEST"
    [ "$removed" -gt 0 ] && success "$removed files removed (manifest-verified)"
    return 0
}

# Fallback for installs made before manifests existed: match by current repo
# filenames. Cannot distinguish user edits, so warn about that up front.
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
if [ -f "$MANIFEST" ]; then
    remove_via_manifest
    rm -f "$MANIFEST"
else
    warn "No manifest found (installed before manifests existed)."
    warn "Falling back to filename matching — local edits to installed files will be lost."
    remove_installed_files "agents" "agents"
    remove_installed_files "rules" "rules"
    remove_installed_files "hooks" "hooks"
    remove_installed_files "commands" "commands"
    remove_installed_files "skills" "skills"
fi

# CLAUDE.md — remove only our managed block, never the user's own content.
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
CLAUDE_MD_BEGIN='<!-- BEGIN agentic-workflow -->'
CLAUDE_MD_END='<!-- END agentic-workflow -->'

if [ -f "$CLAUDE_MD" ] && grep -qxF "$CLAUDE_MD_BEGIN" "$CLAUDE_MD" && grep -qxF "$CLAUDE_MD_END" "$CLAUDE_MD"; then
    TMP=$(mktemp)
    awk -v b="$CLAUDE_MD_BEGIN" -v e="$CLAUDE_MD_END" '
        $0 == b { inblock=1; next }
        $0 == e { inblock=0; next }
        inblock { next }
        { print }
    ' "$CLAUDE_MD" > "$TMP"
    if [ -s "$TMP" ] && grep -q '[^[:space:]]' "$TMP"; then
        mv "$TMP" "$CLAUDE_MD"
        success "CLAUDE.md: managed block removed (your own content kept)."
    else
        rm -f "$TMP" "$CLAUDE_MD"
        success "CLAUDE.md removed (contained only the managed block)."
    fi
else
    # Pre-marker installs overwrote the whole file and left a timestamped backup.
    BACKUP=$(ls -t "$CLAUDE_DIR/CLAUDE.md.backup."* 2>/dev/null | head -1)
    if [ -n "$BACKUP" ]; then
        cp "$BACKUP" "$CLAUDE_MD" && rm -f "$BACKUP"
        success "CLAUDE.md restored from backup (pre-marker install)."
    elif [ -f "$CLAUDE_MD" ]; then
        warn "CLAUDE.md has no agentic-workflow markers — left untouched."
    fi
fi

[ -f "$SOURCE_FILE" ] && rm -f "$SOURCE_FILE" && success ".agentic-workflow-source file removed."

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Uninstall Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "To reinstall, run install.sh."
echo ""
