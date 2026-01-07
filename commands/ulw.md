---
description: "Switch to Ultrawork mode - Full automation with Ralph Loop"
allowed-tools: Write, Read, TodoWrite
---

# Ultrawork Mode Activation

Switching to Ultrawork mode - Full automation with Ralph Loop enabled.

## Mode Characteristics

| Feature | Status |
|---------|--------|
| Ralph Loop | ENABLED |
| Auto-continuation | FULL |
| TODO enforcement | Strict |
| User confirmation | Only when blocked |

## Activation Steps

1. **Create State Directory** (if needed):
   ```
   mkdir .agentic
   ```

2. **Set Mode Indicator**:
   Update `.agentic/mode.txt` with:
   ```
   ultrawork
   ```

3. **Activate Ralph Loop**:
   Create/Update `.agentic/ralph-loop.state.md`:
   ```markdown
   ---
   active: true
   iteration: 1
   max_iterations: 50
   completion_promise: "DONE"
   started_at: "[CURRENT_ISO_TIMESTAMP]"
   mode: "ultrawork"
   ---
   [USER'S CURRENT REQUEST OR CONTEXT]
   ```

4. **Confirm Activation**:
   ```
   [ULTRAWORK MODE ACTIVATED]

   - Ralph Loop: ENABLED (50 iterations max)
   - Auto-continuation: FULL
   - Completion signal: <promise>DONE</promise>

   I will work autonomously until the task is complete.
   Use /ralph-cancel to stop or /manual to switch modes.

   Beginning execution...
   ```

## Behavior in Ultrawork Mode

### Fully Autonomous
- Complete task execution without pauses
- Automatic error recovery with alternative approaches
- Parallel exploration using Task tool
- Agent delegation for specialized work

### Delegation Strategy
| Task Type | Delegate To |
|-----------|-------------|
| Codebase search | @explorer |
| Documentation lookup | @librarian |
| Architecture decisions | @architect |
| UI/UX implementation | @frontend-engineer |
| Documentation writing | @document-writer |
| Planning complex tasks | @planner |

### Recovery Protocol
1. First failure: Retry with adjusted approach
2. Second failure: Try alternative method
3. Third failure: Consult @architect for new strategy
4. Fifth failure: Consider /ralph-cancel

## Completion

When ALL tasks are complete, output:
```
<promise>DONE</promise>
```

This signals Ralph Loop to terminate successfully.

## Keywords that Trigger Ultrawork

- `ultrawork`, `ulw`
- `끝까지`, `완료해`
- `finish everything`, `complete all`

## When to Use

- Large implementation tasks
- Multi-file refactoring
- Feature development
- When you trust full automation
