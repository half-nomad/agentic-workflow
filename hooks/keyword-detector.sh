#!/bin/bash
# Keyword Detector Hook
# Detects ultrawork/ulw keywords and injects orchestration prompt
# Also creates Ralph Loop state file for automatic continuation

PROMPT="${USER_PROMPT:-}"

# Check for ultrawork activation keywords
if echo "$PROMPT" | grep -qiE "(ultrawork|ulw|끝까지|완료해|finish everything|complete all)"; then

    # Create state directory if needed
    STATE_DIR=".agentic"
    mkdir -p "$STATE_DIR"

    # Set mode file
    echo "ultrawork" > "$STATE_DIR/mode.txt"

    # Create Ralph Loop state file
    STATE_FILE="$STATE_DIR/ralph-loop.state.md"
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Extract the user's request (removing the trigger keyword for cleaner storage)
    CLEAN_REQUEST=$(echo "$PROMPT" | sed -E 's/(ultrawork|ulw|끝까지|완료해|finish everything|complete all)//gi' | xargs)
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

ORCHESTRATION RULES:
1. Create comprehensive TODO list IMMEDIATELY using TodoWrite
2. Use Task tool for parallel exploration with @explorer/@librarian agents
3. Delegate specialized work to appropriate agents:
   - UI/UX changes -> @frontend-engineer
   - Architecture questions -> @architect
   - Documentation -> @document-writer
   - Planning -> @planner
4. NEVER stop until ALL TODOs are marked as completed
5. VERIFY each step with evidence before marking complete
6. If stuck 2+ times -> consult @architect for alternative approaches

RALPH LOOP STATUS:
- Active: YES
- Max Iterations: 50
- Completion Signal: <promise>DONE</promise>

EXECUTION FLOW (Sisyphus Phases):
Phase 1: EXPLORE - Parallel discovery with @explorer, @librarian
Phase 2: PLAN - Create detailed TODO list with success criteria
Phase 3: EXECUTE - Work through tasks, delegate to specialists
Phase 4: VERIFY - Validate results, run tests

COMPLETION:
When ALL work is truly complete, output: <promise>DONE</promise>
This will terminate the Ralph Loop successfully.
ACTIVATION_MSG
fi

exit 0
