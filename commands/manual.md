---
name: manual
description: Switch to Manual mode - No automation, full user control
allowed-tools:
  - Write
  - Read
---

# Manual Mode Activation

Switching to Manual mode - Full user control, no automation.

## Mode Characteristics

| Feature | Status |
|---------|--------|
| Ralph Loop | DISABLED |
| Auto-continuation | DISABLED |
| TODO enforcement | Advisory only |
| User confirmation | Required for each step |

## Activation Steps

1. **Cancel Ralph Loop** (if active):
   - Update `.agentic/ralph-loop.state.md` to set `active: false`
   - Or create the file with `active: false` if it doesn't exist

2. **Set Mode Indicator**:
   Update `.agentic/mode.txt` with:
   ```
   manual
   ```

3. **Confirm Activation**:
   ```
   [MANUAL MODE ACTIVATED]

   - Ralph Loop: DISABLED
   - Auto-continuation: DISABLED
   - Awaiting explicit user instructions

   I will wait for your direction on each step.
   Use /ulw or /semi-auto to change modes.
   ```

## Behavior in Manual Mode

- Wait for explicit user approval before major actions
- Provide recommendations but don't auto-execute
- Ask clarifying questions when uncertain
- No automatic task continuation
- Present options for user to choose

## When to Use

- Sensitive operations requiring careful review
- Learning/exploration sessions
- When you want step-by-step control
- Debugging complex issues
