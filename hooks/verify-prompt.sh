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

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
TOOL_NAME=$(json_get "$INPUT" ".tool_name")

if [ "$TOOL_NAME" = "Agent" ]; then
    STATE_FILE="$PROJECT_DIR/.agentic/maestro-mode.state"
    if [ -f "$STATE_FILE" ]; then
        # Run git diff stat
        DIFF_STAT=$(git -C "$PROJECT_DIR" diff --stat 2>/dev/null)
        if [ -n "$DIFF_STAT" ]; then
            echo "[VERIFY] Agent completed. Changed files:"
            echo "$DIFF_STAT"
            echo ""
        fi

        # Check for test runner
        HAS_TESTS=false
        [ -f "$PROJECT_DIR/package.json" ] && HAS_TESTS=true
        [ -f "$PROJECT_DIR/pytest.ini" ] && HAS_TESTS=true
        [ -f "$PROJECT_DIR/pyproject.toml" ] && HAS_TESTS=true
        [ -f "$PROJECT_DIR/Gemfile" ] && HAS_TESTS=true

        if [ "$HAS_TESTS" = true ]; then
            echo "[VERIFY] Test suite detected. Run tests before marking complete."
        fi

        echo "[VERIFY] Review changes against success criteria before proceeding."
    fi
fi

exit 0
