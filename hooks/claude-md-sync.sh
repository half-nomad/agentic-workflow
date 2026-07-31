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

# The deployed ~/.claude/CLAUDE.md is a symlink into the source repo, so an edit
# through it reports the LINK path — and the sibling lookup below would then aim
# at a nonexistent ~/.claude/AGENTS.md, silently never regenerating the repo's.
# Assign only on success: an empty FILE would make dirname yield "." and clobber
# the current project's AGENTS.md.
RESOLVED=0
if command -v realpath >/dev/null 2>&1; then
    _resolved=$(realpath "$FILE" 2>/dev/null) && [ -n "$_resolved" ] && { FILE="$_resolved"; RESOLVED=1; }
fi

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
# `>` writes THROUGH a symlink, so this branch decides by what the destination
# IS, never by what it merely is not:
#   not a symlink  -> ours to write (the Windows copy install, which is why this
#                     branch exists at all; there branch 1 no-ops)
#   symlink -> $SIBLING -> branch 1 already wrote that exact file. Writing again
#                     would fight it: this branch emits 4 header lines where
#                     branch 1 emits 3, churning a git-tracked file forever.
#   any other symlink, broken included -> NOT ours. Never write through a link
#                     whose destination we did not create.
CODEX_AGENTS="$HOME/.codex/AGENTS.md"
if [ -f "$HOME/.claude/CLAUDE.md" ] && [ "$FILE" -ef "$HOME/.claude/CLAUDE.md" ] && [ -d "$HOME/.codex" ]; then
    if [ -L "$HOME/.claude/CLAUDE.md" ] && [ "$RESOLVED" -ne 1 ]; then
        # Edited through the deployed link with no realpath available: $SIBLING
        # is a guess (~/.claude/AGENTS.md, which does not exist), the -ef test
        # below is meaningless, and the sync would write through the Codex link
        # into the repo's tracked AGENTS.md. Skip rather than guess.
        echo "claude-md-sync: cannot resolve ~/.claude/CLAUDE.md (no realpath); skipped ~/.codex/AGENTS.md sync" >&2
    elif [ ! -L "$CODEX_AGENTS" ]; then
        sync_to "$CODEX_AGENTS" "<!-- source: ~/.claude/CLAUDE.md · 상대 경로(rules/, skills/)는 ~/.claude/ 기준 -->"
    elif [ "$CODEX_AGENTS" -ef "$SIBLING" ]; then
        : # branch 1 already wrote it
    else
        echo "claude-md-sync: ~/.codex/AGENTS.md is a symlink to something this repo did not create; skipped (writing would overwrite its target)" >&2
    fi
fi

exit 0
