#!/bin/bash
# Keyword Detector Hook
# Detects ultrawork/ulw keywords and injects Maestro orchestration prompt
# Also creates Ralph Loop state file for automatic continuation

PROMPT="${USER_PROMPT:-}"

# Check for ultrawork activation keywords
if echo "$PROMPT" | grep -qiE "(ultrawork|ulw|finish everything|complete all)"; then

    # Create state directory if needed
    STATE_DIR=".agentic"
    mkdir -p "$STATE_DIR"

    # Set mode file
    echo "ultrawork" > "$STATE_DIR/mode.txt"

    # Create Ralph Loop state file
    STATE_FILE="$STATE_DIR/ralph-loop.state.md"
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Extract the user's request (removing the trigger keyword for cleaner storage)
    CLEAN_REQUEST=$(echo "$PROMPT" | sed -E 's/(ultrawork|ulw|finish everything|complete all)//gi' | xargs)
    if [ -z "$CLEAN_REQUEST" ]; then
        CLEAN_REQUEST="$PROMPT"
    fi

    cat > "$STATE_FILE" << EOF
---
active: true
iteration: 1
max_iterations: 50
completion_promise: "DONE"
started_at: "$TIMESTAMP"
mode: "ultrawork"
---
$CLEAN_REQUEST
EOF

    cat << 'ACTIVATION_MSG'
[ULTRAWORK MODE ACTIVATED - Ralph Loop Enabled]

MAESTRO ORCHESTRATION RULES:
1. ANALYZE task complexity (simple vs complex)
2. SELECT PATTERN: Chaining / Parallelization / Routing / Orchestrator-Workers
3. IDENTIFY agents and tools needed:
   - Built-in: Explore, Plan, general-purpose
   - Specialists: @architect, @frontend-engineer, @librarian, @document-writer
4. EXECUTE with full autonomy (no approval checkpoint in ultrawork)
5. Track progress with TodoWrite
6. If stuck 2+ times -> consult @architect

RALPH LOOP STATUS:
- Active: YES
- Max Iterations: 50
- Completion Signal: <promise>DONE</promise>

COMPLETION:
When ALL work is truly complete, output: <promise>DONE</promise>
This will terminate the Ralph Loop successfully.
ACTIVATION_MSG
fi

exit 0
