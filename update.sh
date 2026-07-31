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

# --- CLAUDE.md managed block (mirrors install.sh) ----------------------------
# The global CLAUDE.md is shared: this repo owns one section, the user owns the
# rest. Only the text between the markers is rewritten. HTML comments are
# stripped before CLAUDE.md reaches Claude's context, so markers cost no tokens.
CLAUDE_MD_BEGIN='<!-- BEGIN agentic-workflow -->'
CLAUDE_MD_END='<!-- END agentic-workflow -->'
CLAUDE_MD_NOTE='<!-- Managed by agentic-workflow. Edits INSIDE this block are overwritten on update. Put your own instructions outside it, or in ~/.claude/rules/personal.md -->'

# Exactly one BEGIN, exactly one END, BEGIN first. Any other topology (duplicate,
# nested, reversed, one-sided) is ambiguous — we must not guess which span is ours.
claude_md_markers_ok() {
    local f="$1" nb ne bl el
    [[ -f "$f" ]] || return 1
    nb=$(grep -cxF "$CLAUDE_MD_BEGIN" "$f" || true)
    ne=$(grep -cxF "$CLAUDE_MD_END" "$f" || true)
    [[ "$nb" == "1" && "$ne" == "1" ]] || return 1
    bl=$(grep -nxF "$CLAUDE_MD_BEGIN" "$f" | cut -d: -f1)
    el=$(grep -nxF "$CLAUDE_MD_END" "$f" | cut -d: -f1)
    [[ "$bl" -lt "$el" ]]
}

merge_claude_md() {
    local src="$1" dest="$2" tmp
    [[ -r "$src" ]] || { warn "CLAUDE.md source unreadable — skipped."; return 1; }
    tmp="$(mktemp)" || return 1

    # Markers present but malformed -> fail closed rather than delete a guessed span.
    if [[ -f "$dest" ]] \
       && { grep -qxF "$CLAUDE_MD_BEGIN" "$dest" || grep -qxF "$CLAUDE_MD_END" "$dest"; } \
       && ! claude_md_markers_ok "$dest"; then
        rm -f "$tmp"
        warn "CLAUDE.md markers are malformed (duplicated, reversed, or one-sided)."
        warn "Left untouched. Fix the BEGIN/END pair by hand, then re-run."
        return 1
    fi

    if claude_md_markers_ok "$dest"; then
        awk -v b="$CLAUDE_MD_BEGIN" -v e="$CLAUDE_MD_END" -v n="$CLAUDE_MD_NOTE" -v f="$src" '
            $0 == b { print b; print n; while ((getline line < f) > 0) print line; close(f); inblock=1; next }
            $0 == e { print e; inblock=0; next }
            inblock { next }
            { print }
        ' "$dest" > "$tmp"
    elif [[ -f "$dest" ]] && grep -q '^\*Maestro Workflow v' "$dest"; then
        # Migration from a pre-marker install. Those installs overwrote the whole
        # file, so a file carrying our footer but no markers IS our old content.
        # Appending here would ship the workflow twice — duplicated, conflicting
        # instructions are worse than a clean replace. The pre-write backup holds
        # anything the user had added by hand.
        warn "CLAUDE.md looked like a pre-marker install — replaced with a managed block."
        warn "Any hand-written additions are in the backup listed at the end of this run."
        { echo "$CLAUDE_MD_BEGIN"; echo "$CLAUDE_MD_NOTE"; cat "$src"; echo "$CLAUDE_MD_END"; } > "$tmp"
    else
        { [[ -f "$dest" ]] && { cat "$dest"; echo ""; }
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

# --- deployment manifest -----------------------------------------------------
# Records every file this repo deployed, with its hash at deploy time. Without it
# we cannot tell "the user edited this file" from "the repo changed it", so
# uninstall would delete user edits and update could never retire a file the repo
# dropped. Written after a successful sync; the previous copy drives pruning.
MANIFEST="$CLAUDE_DIR/.agentic-workflow-manifest"
declare -a DEPLOYED=()
declare -a RETIRED=()   # files we deleted this run — their hook registrations must go too

file_hash() {
    if command -v shasum >/dev/null 2>&1; then shasum -a256 "$1" 2>/dev/null | cut -d' ' -f1
    elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" 2>/dev/null | cut -d' ' -f1
    fi
}

# Files present in the old manifest but no longer shipped: retire them, but only
# if they still carry the hash we deployed (i.e. the user never touched them).
prune_removed() {
    [[ -f "$MANIFEST" ]] || return 0
    local rel old_hash cur target pruned=0 kept=0
    while IFS='  ' read -r old_hash rel; do
        [[ -n "$rel" ]] || continue
        printf '%s\n' "${DEPLOYED[@]}" | grep -qxF "$rel" && continue   # still shipped
        target="$CLAUDE_DIR/$rel"
        [[ -e "$target" ]] || continue
        cur=$(file_hash "$target")
        if [[ -n "$cur" && "$cur" == "$old_hash" ]]; then
            backup_if_differs "$target" ""
            rm -f "$target"
            RETIRED+=("$rel")
            pruned=$((pruned + 1))
        else
            kept=$((kept + 1))
            warn "kept $rel — no longer shipped, but modified since install."
        fi
    done < "$MANIFEST"
    (( pruned > 0 )) && success "retired $pruned file(s) the repo no longer ships"
    (( kept > 0 )) && warn "$kept modified file(s) left in place — delete by hand if unwanted"
    return 0
}

# A retired hook file leaves its settings.json registration behind. The hook then
# fails silently on every matching tool call, which is indistinguishable from
# "no hook" — so the registration has to go with the file.
unregister_retired_hooks() {
    (( ${#RETIRED[@]} > 0 )) || return 0
    command -v jq >/dev/null 2>&1 || return 0
    local dest="$CLAUDE_DIR/settings.json"
    [[ -f "$dest" ]] || return 0

    local names=() r tmp
    for r in "${RETIRED[@]}"; do
        [[ "$r" == hooks/* ]] && names+=("$(basename "$r")")
    done
    (( ${#names[@]} > 0 )) || return 0

    tmp=$(mktemp) || return 0
    if jq --argjson names "$(printf '%s\n' "${names[@]}" | jq -R . | jq -s .)" '
          .hooks = ((.hooks // {}) | with_entries(
            .value |= (map(.hooks = ((.hooks // [])
                          | map(select((.command // "") as $c
                                       | ($names | any(. as $n | $c | contains($n))) | not))))
                       | map(select((.hooks // []) | length > 0)))
          ))' "$dest" > "$tmp"; then
        cat "$tmp" > "$dest"
        success "unregistered hooks for ${#names[@]} retired file(s)"
    fi
    rm -f "$tmp"
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
            DEPLOYED+=("$dir/$relative_path")
            ((SYNC_COUNT++)); ((file_count++))
            [[ "$VERBOSE" == true ]] && echo -e "  ${GRAY}-> $dir/$relative_path${NC}"
        done < <(find "$src_dir" -type f -print0)

        success "$dir/ ($file_count files)"
    else
        warn "$dir/ directory not found - skipping"
    fi
done

# CLAUDE.md — managed block only (the user owns everything outside the markers).
# Replaces the old CLAUDE.global.md branch, which could never work as intended:
# a personal-content file cannot live in a public repo.
src_md="$SOURCE_PATH/CLAUDE.md"
dest_md="$CLAUDE_DIR/CLAUDE.md"
if [[ -f "$src_md" ]]; then
    backup_if_differs "$dest_md" "$src_md"
    merge_claude_md "$src_md" "$dest_md"
    SYNC_COUNT=$((SYNC_COUNT + 1))
    success "CLAUDE.md section synced (content outside markers preserved)"
fi

echo ""
info "Merging config files..."

if command -v jq &> /dev/null; then
    src_settings="$SOURCE_PATH/settings.json"
    dest_settings="$CLAUDE_DIR/settings.json"
    if [[ -f "$src_settings" ]]; then
        if [[ -f "$dest_settings" ]]; then
            # Per-event array merge for hooks (jq `*` REPLACES arrays — a naive
            # merge silently drops user-only hooks). Mirrors install.sh.
            #
            # Identity is the (matcher, command) PAIR, and filtering happens at the
            # handler level — not the entry level.
            #   - Keying on matcher alone unregistered every user hook that shared a
            #     matcher with a repo hook (one PreToolUse[Bash] hook would drop all
            #     the user's PreToolUse[Bash] guards).
            #   - Keying on command alone was also wrong: it dropped the same command
            #     registered under a different matcher, and dropped a whole entry —
            #     losing its other handlers — when just one handler was re-shipped.
            # Handlers without `command` (http / mcp_tool / prompt / agent) fall back
            # to their full JSON as identity, and a missing `hooks` array is treated
            # as empty instead of crashing jq.
            jq -s '
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

# Retire files the repo dropped, then record what this run deployed.
echo ""
prune_removed
unregister_retired_hooks
: > "$MANIFEST"
for rel in "${DEPLOYED[@]}"; do
    printf '%s  %s\n' "$(file_hash "$CLAUDE_DIR/$rel")" "$rel" >> "$MANIFEST"
done

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
