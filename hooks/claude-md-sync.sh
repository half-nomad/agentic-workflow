#!/bin/bash
# claude-md-sync.sh
# PostToolUse hook (Edit|Write|MultiEdit): CLAUDE.md 저장 시 AGENTS.md 자동 싱크
#  - 같은 디렉토리에 AGENTS.md 가 이미 존재할 때만 갱신 (프로젝트별 opt-in — 임의 프로젝트에 파일 생성 안 함)
# Non-blocking: always exit 0
# Input: JSON on stdin from Claude Code

INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

# JSON parser: jq preferred, python3 fallback (macOS ships with python3)
json_get() {
    local json="$1" key="$2"
    if command -v jq &>/dev/null; then
        echo "$json" | jq -r "$key // empty" 2>/dev/null
    else
        echo "$json" | python3 -c "
import sys, json, functools, operator
d = json.load(sys.stdin)
keys = '$key'.strip('.').split('.')
try:
    val = functools.reduce(operator.getitem, keys, d)
    print(val if val is not None else '')
except (KeyError, TypeError):
    print('')
" 2>/dev/null
    fi
}

FILE=$(json_get "$INPUT" ".tool_input.file_path")
[ -n "$FILE" ] || exit 0
[ "$(basename "$FILE")" = "CLAUDE.md" ] || exit 0
[ -f "$FILE" ] || exit 0

# The deployed ~/.claude/CLAUDE.md is a symlink into the source repo, so an edit
# through it reports the LINK path — and the sibling lookup below would then aim
# at a nonexistent ~/.claude/AGENTS.md, silently never regenerating the repo's.
# Assign only on success: an empty FILE would make dirname yield "." and clobber
# the current project's AGENTS.md.
RESOLVED=0
if command -v realpath >/dev/null 2>&1; then
    _resolved=$(realpath "$FILE" 2>/dev/null) && [ -n "$_resolved" ] && { FILE="$_resolved"; RESOLVED=1; }
fi

MARKER="<!-- maestro-codex: sync-from-claude -->"
HEADER="<!-- AUTO-SYNCED from CLAUDE.md by Maestro Codex hook; keep the marker above to opt in. -->"

sync_to() {
    local target="$1" note="$2"
    {
        echo "$MARKER"
        echo "$HEADER"
        [ -n "$note" ] && echo "$note"
        echo
        cat "$FILE"
    } > "$target" 2>/dev/null
}

# 1) 같은 디렉토리 AGENTS.md — 이미 존재할 때만 (opt-in)
SIBLING="$(dirname "$FILE")/AGENTS.md"
[ -f "$SIBLING" ] && sync_to "$SIBLING"
