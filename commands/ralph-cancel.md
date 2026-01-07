---
description: "Cancel Ralph Loop - Stop autonomous continuation"
---

# Ralph Loop Cancellation

You are cancelling the Ralph Loop autonomous continuation system.

## Cancellation Steps

1. **Check State File** at `.agentic/ralph-loop.state.md`

2. **Update State File** - Set `active: false`:
```markdown
---
active: false
iteration: [CURRENT_ITERATION]
max_iterations: 50
completion_promise: "DONE"
started_at: "[ORIGINAL_START_TIME]"
cancelled_at: "[CURRENT_ISO_TIMESTAMP]"
mode: "ultrawork"
---
[ORIGINAL REQUEST]
```

3. **Confirm Cancellation**:
```
[RALPH LOOP CANCELLED]

The autonomous continuation loop has been stopped.
Completed iterations: [X]

Current progress has been preserved. You can:
- Continue manually
- Restart with /ralph-start
- Review TODO list for remaining tasks

Switching to Manual mode.
```

## Notes

- Cancellation preserves all work done so far
- TODO list remains intact for review
- State file is kept for reference (marked inactive)
- No further continuation prompts will be issued
