#!/bin/bash
# Ralph Loop - Stop Event Handler
# Monitors for completion promise and triggers continuation
# Based on oh-my-opencode's Sisyphus automation pattern

ASSISTANT_RESPONSE="${ASSISTANT_RESPONSE:-}"
STOP_REASON="${STOP_REASON:-}"

# State file path
STATE_DIR=".agentic"
STATE_FILE="$STATE_DIR/ralph-loop.state.md"

# Exit if state file doesn't exist (Ralph Loop not active)
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# Read state file content
STATE_CONTENT=$(cat "$STATE_FILE")

# Check if file has valid YAML frontmatter
if ! echo "$STATE_CONTENT" | grep -q "^---"; then
    echo "[RALPH ERROR] Invalid state file format"
    exit 1
fi

# Parse YAML frontmatter values
get_yaml_value() {
    local key="$1"
    echo "$STATE_CONTENT" | grep -E "^$key:" | head -1 | sed -E "s/^$key:[[:space:]]*[\"']?([^\"']*)[\"']?$/\1/"
}

get_yaml_number() {
    local key="$1"
    echo "$STATE_CONTENT" | grep -E "^$key:" | head -1 | grep -oE '[0-9]+' || echo "$2"
}

ACTIVE=$(get_yaml_value "active")
ITERATION=$(get_yaml_number "iteration" "1")
MAX_ITERATIONS=$(get_yaml_number "max_iterations" "50")
COMPLETION_PROMISE=$(get_yaml_value "completion_promise")
MODE=$(get_yaml_value "mode")

# Set defaults
[ -z "$COMPLETION_PROMISE" ] && COMPLETION_PROMISE="DONE"
[ -z "$MODE" ] && MODE="ultrawork"

# Exit if not active
if [ "$ACTIVE" != "true" ]; then
    exit 0
fi

# Check for completion promise in assistant response
PROMISE_PATTERN="<promise>${COMPLETION_PROMISE}</promise>"
HAS_PROMISE=false

if echo "$ASSISTANT_RESPONSE" | grep -qF "$PROMISE_PATTERN"; then
    HAS_PROMISE=true
fi

# Also check for Korean completion keywords
KOREAN_COMPLETE=false
if echo "$ASSISTANT_RESPONSE" | grep -qE "(작업[[:space:]]*완료|모든[[:space:]]*작업.*완료|DONE|완료했습니다)"; then
    KOREAN_COMPLETE=true
fi

if [ "$HAS_PROMISE" = true ] || [ "$KOREAN_COMPLETE" = true ]; then
    # Task completed - deactivate Ralph Loop
    sed -i.bak 's/active: true/active: false/' "$STATE_FILE" 2>/dev/null || \
    sed -i '' 's/active: true/active: false/' "$STATE_FILE" 2>/dev/null
    rm -f "${STATE_FILE}.bak" 2>/dev/null

    cat << EOF

[RALPH LOOP COMPLETE]
Iteration: $ITERATION
Promise detected: $PROMISE_PATTERN
Ralph Loop has been deactivated.

EOF
    exit 0
fi

# Check iteration limit
if [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
    # Max iterations reached - deactivate
    sed -i.bak 's/active: true/active: false/' "$STATE_FILE" 2>/dev/null || \
    sed -i '' 's/active: true/active: false/' "$STATE_FILE" 2>/dev/null
    rm -f "${STATE_FILE}.bak" 2>/dev/null

    cat << EOF

[RALPH LOOP LIMIT REACHED]
Maximum iterations ($MAX_ITERATIONS) exceeded.
Ralph Loop has been forcefully terminated.
Please review progress and restart if needed with /ralph-start

EOF
    exit 0
fi

# Increment iteration and update state file
NEW_ITERATION=$((ITERATION + 1))
sed -i.bak "s/iteration: $ITERATION/iteration: $NEW_ITERATION/" "$STATE_FILE" 2>/dev/null || \
sed -i '' "s/iteration: $ITERATION/iteration: $NEW_ITERATION/" "$STATE_FILE" 2>/dev/null
rm -f "${STATE_FILE}.bak" 2>/dev/null

# Extract original request (everything after the YAML frontmatter)
ORIGINAL_REQUEST=$(echo "$STATE_CONTENT" | sed -n '/^---$/,/^---$/!p' | tail -n +1)
[ -z "$ORIGINAL_REQUEST" ] && ORIGINAL_REQUEST="Continue previous task"

# Output continuation prompt
cat << EOF

[RALPH LOOP CONTINUATION - Iteration $NEW_ITERATION/$MAX_ITERATIONS]

The task is not yet complete. Continue working until you can output:
<promise>$COMPLETION_PROMISE</promise>

ORIGINAL REQUEST:
$ORIGINAL_REQUEST

INSTRUCTIONS:
1. Review what has been accomplished so far
2. Check remaining TODO items
3. Continue executing pending tasks
4. ONLY output <promise>$COMPLETION_PROMISE</promise> when ALL work is truly complete
5. If stuck, try alternative approaches or consult @architect

DO NOT STOP until the promise can be fulfilled.

EOF

exit 0
