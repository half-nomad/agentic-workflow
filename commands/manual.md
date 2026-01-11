---
description: "Switch to Manual mode - No automation, full user control"
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
   Use /maestro for orchestrated planning.
   ```

## Maestro in Manual Mode

When using `/maestro` in manual mode:
- Plan presented for approval
- Each execution step requires confirmation
- Full visibility and control

## When to Use

- Sensitive operations requiring careful review
- Learning/exploration sessions
- When you want step-by-step control
- Debugging complex issues
