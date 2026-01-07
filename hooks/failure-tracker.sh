#!/bin/bash
# Failure Tracker Hook
# Detects repeated failures and triggers recovery strategies
# Integrates with Ralph Loop for automated recovery

TOOL_NAME="${TOOL_NAME:-}"
TOOL_OUTPUT="${TOOL_OUTPUT:-}"
TOOL_INPUT="${TOOL_INPUT:-}"

# State directory
STATE_DIR=".agentic"
FAILURE_FILE="$STATE_DIR/failure-log.json"

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Initialize failure log if not exists
if [ ! -f "$FAILURE_FILE" ]; then
    cat > "$FAILURE_FILE" << 'EOF'
{
  "failures": [],
  "consecutive_failures": 0,
  "last_failure_time": null,
  "recovery_attempts": 0
}
EOF
fi

# Read current failure state (using grep/sed for jq-free operation)
get_json_value() {
    local key="$1"
    local file="$2"
    grep -o "\"$key\"[[:space:]]*:[[:space:]]*[0-9]*" "$file" 2>/dev/null | grep -o '[0-9]*$' || echo "0"
}

CONSECUTIVE_FAILURES=$(get_json_value "consecutive_failures" "$FAILURE_FILE")
RECOVERY_ATTEMPTS=$(get_json_value "recovery_attempts" "$FAILURE_FILE")

# Detect failure patterns
IS_FAILURE=false
FAILURE_TYPE=""
FAILURE_DETAILS=""

# Check for common failure patterns
if echo "$TOOL_OUTPUT" | grep -qiE "(error|failed)"; then
    IS_FAILURE=true
    FAILURE_TYPE="error"
    FAILURE_DETAILS=$(echo "$TOOL_OUTPUT" | grep -iE "(error|exception|failed)" | head -3 | tr '\n' '; ')
elif echo "$TOOL_OUTPUT" | grep -qiE "(not found|NotFound|cannot find|doesn't exist|does not exist)"; then
    IS_FAILURE=true
    FAILURE_TYPE="not_found"
    FAILURE_DETAILS="Resource not found"
elif echo "$TOOL_OUTPUT" | grep -qiE "(permission denied|access denied|unauthorized)"; then
    IS_FAILURE=true
    FAILURE_TYPE="permission"
    FAILURE_DETAILS="Permission or access issue"
elif echo "$TOOL_OUTPUT" | grep -qiE "(timeout|timed out|connection refused)"; then
    IS_FAILURE=true
    FAILURE_TYPE="timeout"
    FAILURE_DETAILS="Connection or timeout issue"
fi

# Check for Edit tool specific failures
if [ "$TOOL_NAME" = "Edit" ] && echo "$TOOL_OUTPUT" | grep -qiE "(old_string not found|no match|string not unique)"; then
    IS_FAILURE=true
    FAILURE_TYPE="edit_mismatch"
    FAILURE_DETAILS="Edit target string not found or not unique"
fi

# Check for Bash exit code failures
if [ "$TOOL_NAME" = "Bash" ] && echo "$TOOL_OUTPUT" | grep -qE "exit code [1-9]"; then
    IS_FAILURE=true
    FAILURE_TYPE="command_failure"
    FAILURE_DETAILS="Command exited with non-zero status"
fi

if [ "$IS_FAILURE" = true ]; then
    # Increment consecutive failures
    CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Truncate input summary
    INPUT_SUMMARY="${TOOL_INPUT:0:200}"
    [ ${#TOOL_INPUT} -gt 200 ] && INPUT_SUMMARY="${INPUT_SUMMARY}..."

    # Update failure log (simple JSON update without jq)
    cat > "$FAILURE_FILE" << EOF
{
  "failures": [
    {
      "timestamp": "$TIMESTAMP",
      "tool": "$TOOL_NAME",
      "type": "$FAILURE_TYPE",
      "details": "$FAILURE_DETAILS"
    }
  ],
  "consecutive_failures": $CONSECUTIVE_FAILURES,
  "last_failure_time": "$TIMESTAMP",
  "recovery_attempts": $RECOVERY_ATTEMPTS
}
EOF

    # Determine recovery strategy based on consecutive failures
    if [ "$CONSECUTIVE_FAILURES" -ge 3 ]; then
        RECOVERY_ATTEMPTS=$((RECOVERY_ATTEMPTS + 1))

        cat << EOF

[FAILURE PATTERN DETECTED - Recovery Strategy Required]

Consecutive Failures: $CONSECUTIVE_FAILURES
Failure Type: $FAILURE_TYPE
Recovery Attempt: $RECOVERY_ATTEMPTS

RECOMMENDED ACTIONS:
EOF

        case "$FAILURE_TYPE" in
            "edit_mismatch")
                cat << 'EOF'
1. Re-read the target file to get current content
2. Verify the exact string to match (check whitespace, indentation)
3. Use a longer, more unique old_string
4. Consider using Write tool if edit keeps failing
EOF
                ;;
            "not_found")
                cat << 'EOF'
1. Use Glob to find the correct file path
2. Verify the project structure
3. Check for typos in file/directory names
4. Consider if the resource needs to be created first
EOF
                ;;
            "command_failure")
                cat << 'EOF'
1. Check command syntax and arguments
2. Verify required tools are installed
3. Check working directory context
4. Try alternative commands
EOF
                ;;
            "permission")
                cat << 'EOF'
1. Check file/directory permissions
2. Verify you have write access
3. Consider if elevated permissions are needed
EOF
                ;;
            *)
                cat << 'EOF'
1. Review the error message carefully
2. Try a different approach
3. Consult @architect for alternative strategies
4. Break down the task into smaller steps
EOF
                ;;
        esac

        if [ "$CONSECUTIVE_FAILURES" -ge 5 ]; then
            cat << 'EOF'

[CRITICAL] 5+ consecutive failures detected.
Consider: /ralph-cancel to stop automation and review manually.
Or: Consult @architect for a completely different approach.
EOF
        fi

        # Update recovery attempts in file
        sed -i.bak "s/\"recovery_attempts\": [0-9]*/\"recovery_attempts\": $RECOVERY_ATTEMPTS/" "$FAILURE_FILE" 2>/dev/null || \
        sed -i '' "s/\"recovery_attempts\": [0-9]*/\"recovery_attempts\": $RECOVERY_ATTEMPTS/" "$FAILURE_FILE" 2>/dev/null
        rm -f "${FAILURE_FILE}.bak" 2>/dev/null
    fi
else
    # Success - reset consecutive failure count
    if [ "$CONSECUTIVE_FAILURES" -gt 0 ]; then
        sed -i.bak "s/\"consecutive_failures\": [0-9]*/\"consecutive_failures\": 0/" "$FAILURE_FILE" 2>/dev/null || \
        sed -i '' "s/\"consecutive_failures\": [0-9]*/\"consecutive_failures\": 0/" "$FAILURE_FILE" 2>/dev/null
        rm -f "${FAILURE_FILE}.bak" 2>/dev/null
    fi
fi

exit 0
