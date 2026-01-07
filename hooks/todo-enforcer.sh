#!/bin/bash
# TODO Enforcer Hook
# Checks for incomplete TODOs and prompts continuation
# Integrates with Ralph Loop state for coordinated behavior

# State paths
STATE_DIR=".agentic"
RALPH_STATE_FILE="$STATE_DIR/ralph-loop.state.md"
MODE_FILE="$STATE_DIR/mode.txt"

# Determine current mode
CURRENT_MODE="manual"
if [ -f "$MODE_FILE" ]; then
    CURRENT_MODE=$(cat "$MODE_FILE" | tr -d '[:space:]')
fi

# Check if Ralph Loop is active
RALPH_ACTIVE=false
if [ -f "$RALPH_STATE_FILE" ]; then
    if grep -q "active: true" "$RALPH_STATE_FILE"; then
        RALPH_ACTIVE=true
    fi
fi

# Session directory for todos
SESSION_DIR="${CLAUDE_SESSION_DIR:-.agentic}"
TODO_FILE="$SESSION_DIR/todos.json"

# In manual mode with no Ralph Loop, be advisory only
if [ "$CURRENT_MODE" = "manual" ] && [ "$RALPH_ACTIVE" = false ]; then
    if [ -f "$TODO_FILE" ]; then
        # Count pending tasks (jq-free approach)
        PENDING=$(grep -c '"status"[[:space:]]*:[[:space:]]*"pending"\|"status"[[:space:]]*:[[:space:]]*"in_progress"' "$TODO_FILE" 2>/dev/null || echo "0")

        if [ "$PENDING" -gt 0 ]; then
            cat << EOF
[SESSION CHECK - Manual Mode]

Note: $PENDING task(s) still in progress.
Review pending tasks before ending session.
EOF
        fi
    fi
    exit 0
fi

# For semi-auto and ultrawork modes, enforce TODO completion
if [ -f "$TODO_FILE" ]; then
    # Parse JSON without jq - count by status
    PENDING_COUNT=$(grep -c '"status"[[:space:]]*:[[:space:]]*"pending"' "$TODO_FILE" 2>/dev/null || echo "0")
    IN_PROGRESS_COUNT=$(grep -c '"status"[[:space:]]*:[[:space:]]*"in_progress"' "$TODO_FILE" 2>/dev/null || echo "0")
    COMPLETED_COUNT=$(grep -c '"status"[[:space:]]*:[[:space:]]*"completed"' "$TODO_FILE" 2>/dev/null || echo "0")

    # Total is sum of all statuses
    TOTAL_COUNT=$((PENDING_COUNT + IN_PROGRESS_COUNT + COMPLETED_COUNT))
    REMAINING=$((PENDING_COUNT + IN_PROGRESS_COUNT))

    if [ "$REMAINING" -gt 0 ]; then
        # Build task summary
        TASK_SUMMARY=""

        if [ "$IN_PROGRESS_COUNT" -gt 0 ]; then
            TASK_SUMMARY="${TASK_SUMMARY}
IN PROGRESS:"
            # Extract in_progress task contents (simplified parsing)
            IN_PROGRESS_TASKS=$(grep -B5 '"status"[[:space:]]*:[[:space:]]*"in_progress"' "$TODO_FILE" | grep '"content"' | sed 's/.*"content"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/  - \1/' | head -5)
            TASK_SUMMARY="${TASK_SUMMARY}
$IN_PROGRESS_TASKS"
        fi

        if [ "$PENDING_COUNT" -gt 0 ]; then
            TASK_SUMMARY="${TASK_SUMMARY}

PENDING:"
            # Extract pending task contents (simplified parsing)
            PENDING_TASKS=$(grep -B5 '"status"[[:space:]]*:[[:space:]]*"pending"' "$TODO_FILE" | grep '"content"' | sed 's/.*"content"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/  - \1/' | head -5)
            TASK_SUMMARY="${TASK_SUMMARY}
$PENDING_TASKS"
            if [ "$PENDING_COUNT" -gt 5 ]; then
                TASK_SUMMARY="${TASK_SUMMARY}
  ... and $((PENDING_COUNT - 5)) more"
            fi
        fi

        # Ralph Loop status message
        RALPH_STATUS="Ralph Loop: INACTIVE"
        [ "$RALPH_ACTIVE" = true ] && RALPH_STATUS="Ralph Loop: ACTIVE - Will auto-continue"

        cat << EOF
[TODO CONTINUATION REQUIRED]

Progress: $COMPLETED_COUNT/$TOTAL_COUNT completed
Remaining: $REMAINING task(s)
$TASK_SUMMARY

INSTRUCTIONS:
- Complete all in-progress tasks first
- Then work through pending tasks
- Mark each task as completed when done
- If blocked, document the issue and consult @architect

Mode: $CURRENT_MODE
$RALPH_STATUS
EOF
    else
        # All tasks complete
        DONE_MSG=""
        [ "$RALPH_ACTIVE" = true ] && DONE_MSG="Ready to output: <promise>DONE</promise>"

        cat << EOF
[ALL TASKS COMPLETE]

Total completed: $COMPLETED_COUNT tasks

$DONE_MSG
EOF
    fi
else
    # No todo file exists
    if [ "$CURRENT_MODE" != "manual" ]; then
        RALPH_MSG=""
        [ "$RALPH_ACTIVE" = true ] && RALPH_MSG="Ralph Loop active - ensure <promise>DONE</promise> is output when complete"

        cat << EOF
[SESSION CHECK]

No TODO list found. If work is incomplete:
1. Create a TODO list to track remaining tasks
2. Or confirm all requested work is complete

$RALPH_MSG
EOF
    fi
fi

exit 0
