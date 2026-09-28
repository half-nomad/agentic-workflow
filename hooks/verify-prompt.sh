#!/bin/bash
# verify-prompt.sh
# PostToolUse hook: After Agent tool returns, inject verification reminder
# Input: JSON on stdin from Claude Code
# Output: stdout text injected as context to Claude

INPUT=$(cat)
if [ -z "$INPUT" ]; then exit 0; fi

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

# 세션별 상태 파일 — 근거는 maestro-guard.sh 의 같은 블록. 세 훅이 같은 판정을 쓴다.
maestro_active() {
    local dir="${CLAUDE_PROJECT_DIR:-.}/.agentic/maestro" sid="${CLAUDE_CODE_SESSION_ID:-}"
    [ -z "$sid" ] && sid=$(json_get "$INPUT" ".session_id")
    [[ "$sid" =~ ^[A-Za-z0-9_-]+$ ]] || sid=""
    [ -f "$dir/unknown.state" ] && return 0
    if [ -n "$sid" ]; then
        [ -f "$dir/$sid.state" ]
    else
        compgen -G "$dir/*.state" >/dev/null
    fi
}

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
TOOL_NAME=$(json_get "$INPUT" ".tool_name")

if [ "$TOOL_NAME" = "Agent" ]; then
    if maestro_active; then
        # Emit INFORMATION, not exhortation. What the orchestrator cannot get for
        # free is "what did that agent actually change" — a tool call it would
        # otherwise have to spend. Reminders to run tests and check success
        # criteria are already binding in skills/maestro/WORKFLOW.md (§5b output
        # contract, §Result Integration); repeating them after every single Agent
        # return is noise that trains the reader to skim past this block.
        DIFF_STAT=$(git -C "$PROJECT_DIR" diff --stat 2>/dev/null)
        if [ -n "$DIFF_STAT" ]; then
            echo "[VERIFY] Agent completed. Uncommitted changes in the worktree:"
            echo "$DIFF_STAT"
            echo ""
        fi
    fi
fi

exit 0
