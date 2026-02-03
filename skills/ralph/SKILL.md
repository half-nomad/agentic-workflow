---
name: ralph
description: "Ralph Loop control - autonomous continuation until task completion. Use '/ralph start' or '/ralph cancel'"
invocation: user
allowed-tools: Write, Read, TodoWrite
---

# Ralph Loop Control

$ARGUMENTS

---

## Usage

- `/ralph start` - Activate Ralph Loop
- `/ralph cancel` - Deactivate Ralph Loop

---

## Start Ralph Loop

### Activation Steps

1. **Create State Directory** (if needed): `.agentic/`

2. **Create State File** at `.agentic/ralph-loop.state.md`:
```markdown
---
active: true
iteration: 1
max_iterations: 50
completion_promise: "DONE"
started_at: "[CURRENT_ISO_TIMESTAMP]"
mode: "ultrawork"
---
[USER'S ORIGINAL REQUEST]
```

3. **Confirm Activation**:
```
[RALPH LOOP ACTIVATED]

Mode: Ultrawork
Max Iterations: 50
Completion Promise: <promise>DONE</promise>

The loop will continue until:
- You output <promise>DONE</promise>
- Maximum iterations (50) reached
- User runs /ralph cancel

Beginning task execution...
```

4. **Begin Execution**: Create TODO list with TodoWrite, start working

---

## Cancel Ralph Loop

### Cancellation Steps

1. **Update State File** - Set `active: false`:
```markdown
---
active: false
cancelled_at: "[CURRENT_ISO_TIMESTAMP]"
---
```

2. **Confirm Cancellation**:
```
[RALPH LOOP CANCELLED]

Autonomous continuation stopped.
Progress preserved. You can:
- Continue manually
- Restart with /ralph start
- Review TODO list

Switching to Manual mode.
```

---

## Notes

- State file: `.agentic/ralph-loop.state.md`
- Stop hook monitors this file
- Without `<promise>DONE</promise>`, loop prompts continuation
- Consult `@architect` if stuck after 2+ attempts
