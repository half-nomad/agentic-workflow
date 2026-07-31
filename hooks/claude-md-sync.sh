#!/bin/bash
# claude-md-sync.sh
# PostToolUse hook (Edit|Write|MultiEdit): CLAUDE.md 저장 시 AGENTS.md 자동 싱크
#  - 같은 디렉토리에 AGENTS.md 가 이미 존재할 때만 갱신 (프로젝트별 opt-in — 임의 프로젝트에 파일 생성 안 함)
#  - 전역 ~/.claude/CLAUDE.md 저장 시 ~/.codex/AGENTS.md (Codex 전역 지침) 로도 싱크
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

HEADER="<!-- AUTO-SYNCED from CLAUDE.md — edit CLAUDE.md, not this file. (hooks/claude-md-sync) -->"
RULES_NOTE="<!-- Also read ~/.claude/rules/*.md (secure-coding, global, ...) and apply those rules identically when working here. -->"

sync_to() {
    local target="$1" note="$2"
    {
        echo "$HEADER"
        echo "$RULES_NOTE"
        [ -n "$note" ] && echo "$note"
        echo
        cat "$FILE"
    } > "$target" 2>/dev/null
}

# 1) 같은 디렉토리 AGENTS.md — 이미 존재할 때만 (opt-in)
SIBLING="$(dirname "$FILE")/AGENTS.md"
[ -f "$SIBLING" ] && sync_to "$SIBLING"

# 2) 전역 CLAUDE.md → Codex 전역 지침
if [ -f "$HOME/.claude/CLAUDE.md" ] && [ "$FILE" -ef "$HOME/.claude/CLAUDE.md" ] && [ -d "$HOME/.codex" ]; then
    sync_to "$HOME/.codex/AGENTS.md" "<!-- source: ~/.claude/CLAUDE.md · 상대 경로(rules/, skills/)는 ~/.claude/ 기준 -->"
fi

exit 0
