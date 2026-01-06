---
name: ralph-start
description: Start Ralph Loop - Autonomous work continuation until task completion
allowed-tools:
  - Write
  - Read
  - TodoWrite
---

# Ralph Loop Activation

You are activating Ralph Loop - an autonomous continuation system that ensures tasks run to completion.

## Activation Steps

1. **Create State Directory** (if needed):
```
.agentic/
```

2. **Create Ralph Loop State File** at `.agentic/ralph-loop.state.md`:
```markdown
---
active: true
iteration: 1
max_iterations: 50
completion_promise: "DONE"
started_at: "[CURRENT_ISO_TIMESTAMP]"
mode: "ultrawork"
---
[INSERT THE USER'S ORIGINAL REQUEST HERE]
```

3. **Confirm Activation**:
```
[RALPH LOOP ACTIVATED]

Mode: Ultrawork
Max Iterations: 50
Completion Promise: <promise>DONE</promise>

The loop will continue until:
- You output <promise>DONE</promise> indicating task completion
- Maximum iterations (50) are reached
- User runs /ralph-cancel

Beginning task execution...
```

4. **Begin Task Execution**:
- Create TODO list immediately using TodoWrite
- Start working on the user's request
- Continue until complete, then output `<promise>DONE</promise>`

## Important Notes

- Ralph Loop monitors the Stop event
- If you stop without outputting `<promise>DONE</promise>`, the loop will prompt continuation
- Use `/ralph-cancel` to stop the loop manually
- Consult `@architect` if stuck after 2+ attempts

## State File Location

The state file is located at: `.agentic/ralph-loop.state.md`

This file persists across conversation turns and is read by the Stop hook.
