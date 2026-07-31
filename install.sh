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

# Deployment manifest: what we shipped and its hash at deploy time. Uninstall uses
# it to delete only untouched files, and update uses it to retire files the repo
# has since dropped. Without it neither can tell a user edit from a repo change.
MANIFEST="$CLAUDE_HOME/.agentic-workflow-manifest"

file_hash() {
    if command -v shasum >/dev/null 2>&1; then shasum -a256 "$1" 2>/dev/null | cut -d' ' -f1
    elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" 2>/dev/null | cut -d' ' -f1
    fi
}

write_manifest() {
    : > "$MANIFEST"
    local d f rel
    for d in agents rules hooks commands skills; do
        [ -d "$SOURCE_PATH/$d" ] || continue
        while IFS= read -r -d '' f; do
            rel="$d/${f#$SOURCE_PATH/$d/}"
            [ -f "$CLAUDE_HOME/$rel" ] && printf '%s  %s\n' "$(file_hash "$CLAUDE_HOME/$rel")" "$rel" >> "$MANIFEST"
        done < <(find "$SOURCE_PATH/$d" -type f -print0)
    done
}

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

# Timestamped backup root for any pre-existing file we are about to overwrite.
# Installing must never destroy a file the user already had under the same name.
BACKUP_ROOT="$CLAUDE_HOME/backups/install-$(date +%Y%m%d-%H%M%S)"

backup_if_exists() {
    local target="$1"
    [ -e "$target" ] || return 0
    local rel="${target#$CLAUDE_HOME/}"
    mkdir -p "$BACKUP_ROOT/$(dirname "$rel")"
    cp -a "$target" "$BACKUP_ROOT/$rel"
}

# --- CLAUDE.md managed block -------------------------------------------------
# The global CLAUDE.md is shared: this repo owns one section, the user owns the
# rest. Replacing the whole file would delete the user's own instructions, so we
# only rewrite the text between these markers. HTML comments are stripped before
# CLAUDE.md is injected into Claude's context, so the markers cost no tokens.
CLAUDE_MD_BEGIN='<!-- BEGIN agentic-workflow -->'
CLAUDE_MD_END='<!-- END agentic-workflow -->'
CLAUDE_MD_NOTE='<!-- Managed by agentic-workflow. Edits INSIDE this block are overwritten on update. Put your own instructions outside it, or in ~/.claude/rules/personal.md -->'

# Exactly one BEGIN, exactly one END, BEGIN first. Any other topology (duplicate,
# nested, reversed, one-sided) is ambiguous — we must not guess which span is ours.
claude_md_markers_ok() {
    local f="$1" nb ne bl el
    [ -f "$f" ] || return 1
    nb=$(grep -cxF "$CLAUDE_MD_BEGIN" "$f" || true)
    ne=$(grep -cxF "$CLAUDE_MD_END" "$f" || true)
    [ "$nb" = "1" ] && [ "$ne" = "1" ] || return 1
    bl=$(grep -nxF "$CLAUDE_MD_BEGIN" "$f" | cut -d: -f1)
    el=$(grep -nxF "$CLAUDE_MD_END" "$f" | cut -d: -f1)
    [ "$bl" -lt "$el" ]
}

merge_claude_md() {
    local src="$1" dest="$2" tmp
    [ -r "$src" ] || { print_warn "CLAUDE.md source unreadable — skipped."; return 1; }
    tmp="$(mktemp)" || return 1

    # Markers present but malformed -> fail closed rather than delete a guessed span.
    if [ -f "$dest" ] \
       && { grep -qxF "$CLAUDE_MD_BEGIN" "$dest" || grep -qxF "$CLAUDE_MD_END" "$dest"; } \
       && ! claude_md_markers_ok "$dest"; then
        rm -f "$tmp"
        print_warn "CLAUDE.md markers are malformed (duplicated, reversed, or one-sided) — left untouched."
        return 1
    fi

    if claude_md_markers_ok "$dest"; then
        # Both markers present -> replace only what is between them.
        awk -v b="$CLAUDE_MD_BEGIN" -v e="$CLAUDE_MD_END" -v n="$CLAUDE_MD_NOTE" -v f="$src" '
            $0 == b { print b; print n; while ((getline line < f) > 0) print line; close(f); inblock=1; next }
            $0 == e { print e; inblock=0; next }
            inblock { next }
            { print }
        ' "$dest" > "$tmp"
    elif [ -f "$dest" ] && grep -q '^\*Maestro Workflow v' "$dest"; then
        # Migration from a pre-marker install. Those installs overwrote the whole
        # file, so a file carrying our footer but no markers IS our old content.
        # Appending would ship the workflow twice — duplicated, conflicting
        # instructions are worse than a clean replace. The pre-write backup holds
        # anything the user had added by hand.
        print_warn "CLAUDE.md looked like a pre-marker install — replaced with a managed block (see backup)."
        { echo "$CLAUDE_MD_BEGIN"; echo "$CLAUDE_MD_NOTE"; cat "$src"; echo "$CLAUDE_MD_END"; } > "$tmp"
    else
        # No usable markers -> keep the existing file verbatim and append the block.
        { [ -f "$dest" ] && { cat "$dest"; echo ""; }
          echo "$CLAUDE_MD_BEGIN"
          echo "$CLAUDE_MD_NOTE"
          cat "$src"
          echo "$CLAUDE_MD_END"
        } > "$tmp"
    fi

    # Write THROUGH the destination instead of `mv`-ing over it. The docs suggest
    # symlinking CLAUDE.md (e.g. to a dotfiles repo), and `mv` would silently
    # replace that symlink with a regular file — leaving the real target stale.
    # Redirecting also keeps the existing mode/owner/xattrs. The pre-write backup
    # covers the atomicity we give up.
    cat "$tmp" > "$dest"
    rm -f "$tmp"
}

# 3. File copy function
copy_directory_contents() {
    local source_dir="$1"
    local dest_dir="$2"
    local count=0
    if [ -d "$source_dir" ]; then
        for file in "$source_dir"/*; do
            if [ -f "$file" ]; then
                backup_if_exists "$dest_dir/$(basename "$file")"
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
    while IFS= read -r -d '' src; do
        rel="${src#$SOURCE_PATH/skills/}"
        backup_if_exists "$CLAUDE_HOME/skills/$rel"
    done < <(find "$SOURCE_PATH/skills" -type f -print0)
    cp -rf "$SOURCE_PATH/skills/"* "$CLAUDE_HOME/skills/" 2>/dev/null || true
    print_success "skills: copy complete"
fi

# CLAUDE.md
echo "  Setting up CLAUDE.md..."
CLAUDE_MD_SOURCE="$SOURCE_PATH/CLAUDE.md"
CLAUDE_MD_DEST="$CLAUDE_HOME/CLAUDE.md"

if [ -f "$CLAUDE_MD_SOURCE" ]; then
    # Marker-delimited section, NOT whole-file overwrite. Anything you wrote
    # outside the markers survives install/update; only the block between them
    # is replaced. HTML comments are stripped before CLAUDE.md reaches Claude's
    # context, so the markers cost zero tokens.
    if [ -f "$CLAUDE_MD_DEST" ]; then
        backup_if_exists "$CLAUDE_MD_DEST"
    fi
    merge_claude_md "$CLAUDE_MD_SOURCE" "$CLAUDE_MD_DEST"
    print_success "CLAUDE.md section synced (content outside markers preserved)"
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
                ($old.hooks // {}) as $oh | ($new.hooks // {}) as $nh |
                ((($oh | keys) + ($nh | keys)) | unique) as $events |
                [ $events[] as $e |
                  ([ ($nh[$e] // [])[] | .matcher as $m | (.hooks // [])[] | {m: $m, id: (.command // tojson)} ]) as $nid |
                  {key: $e,
                   value: ((($oh[$e] // [])
                            | map(.matcher as $m
                                  | .hooks = ((.hooks // [])
                                              | map(select({m: $m, id: (.command // tojson)} as $k
                                                           | ($nid | any(. == $k)) | not))))
                            | map(select((.hooks // []) | length > 0)))
                           + ($nh[$e] // []))}
                ] | from_entries
              ) |
              .permissions.allow = ((($old.permissions.allow // []) + ($new.permissions.allow // []) | unique) - ["Bash(npm:*)", "Bash(npx:*)", "Bash(pnpm:*)", "Bash(yarn:*)"]) |
              .permissions.ask = (($old.permissions.ask // []) + ($new.permissions.ask // []) | unique)
            ' "$SETTINGS_DEST" - > "$SETTINGS_DEST.tmp" && mv "$SETTINGS_DEST.tmp" "$SETTINGS_DEST"
            print_success "settings.json merged (per-event array merge for hooks)"
        else
            echo "$SETTINGS_CONVERTED" > "$SETTINGS_DEST"
            print_success "settings.json copied (new file, path conversion applied)"
        fi
    fi

    # Merge .mcp.json (skip if source not found)
    if [ -f "$MCP_SOURCE" ]; then
        if [ -f "$MCP_DEST" ]; then
            jq -s '.[0] as $old | .[1] as $new | ($old * $new) | .mcpServers = (($old.mcpServers // {}) * ($new.mcpServers // {}))' \
                "$MCP_DEST" "$MCP_SOURCE" > "$MCP_DEST.tmp" && mv "$MCP_DEST.tmp" "$MCP_DEST"
            print_success ".mcp.json merged: $MCP_DEST"
        else
            cp "$MCP_SOURCE" "$MCP_DEST"
            print_success ".mcp.json copied (new file): $MCP_DEST"
        fi
    else
        print_dim ".mcp.json not found in source — skipping MCP configuration"
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

    # .mcp.json handling (backup then copy, skip if source not found)
    if [ -f "$MCP_SOURCE" ]; then
        if [ -f "$MCP_DEST" ]; then
            BACKUP_PATH="$MCP_DEST.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$MCP_DEST" "$BACKUP_PATH"
            print_warn "Existing .mcp.json backed up: $BACKUP_PATH"
            print_warn "Existing settings will be overwritten (merge not possible without jq)"
        fi
        cp "$MCP_SOURCE" "$MCP_DEST"
        print_success ".mcp.json copied"
    else
        print_dim ".mcp.json not found in source — skipping MCP configuration"
    fi
fi

# 5. MCP installation guide (only if .mcp.json was installed)
if [ -f "$MCP_SOURCE" ]; then
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
fi

# Record what was deployed, so uninstall can tell our files from the user's edits.
write_manifest

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
