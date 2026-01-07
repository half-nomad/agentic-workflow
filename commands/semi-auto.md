---
description: "Switch to Semi-Auto mode - Balanced automation with checkpoints"
allowed-tools: Write, Read
---

# Semi-Auto Mode Activation

Switching to Semi-Auto mode - Balanced automation with strategic checkpoints.

## Mode Characteristics

| Feature | Status |
|---------|--------|
| Ralph Loop | DISABLED |
| Auto-continuation | Within phases only |
| TODO enforcement | Active |
| User confirmation | At phase transitions |

## Activation Steps

1. **Cancel Ralph Loop** (if active):
   - Update `.agentic/ralph-loop.state.md` to set `active: false`

2. **Set Mode Indicator**:
   Update `.agentic/mode.txt` with:
   ```
   semi-auto
   ```

3. **Confirm Activation**:
   ```
   [SEMI-AUTO MODE ACTIVATED]

   - Ralph Loop: DISABLED
   - Phase automation: ENABLED
   - Checkpoint confirmations: ENABLED

   I will work autonomously within each phase but pause for confirmation
   at major decision points and phase transitions.

   Use /ulw for full automation or /manual for full control.
   ```

## Behavior in Semi-Auto Mode

### Autonomous Actions (No confirmation needed)
- Exploration and research
- Reading files and understanding code
- Creating TODO lists
- Small, reversible changes
- Running tests

### Checkpoint Pauses (Confirmation required)
- Before starting implementation phase
- After completing major features
- Before file deletions
- When encountering unexpected issues
- At phase transitions (Explore -> Plan -> Execute -> Verify)

## Phase Structure

```
[PHASE 1: EXPLORE] - Autonomous
    |
    v
[CHECKPOINT: Present findings, confirm plan]
    |
    v
[PHASE 2: PLAN] - Autonomous
    |
    v
[CHECKPOINT: Present plan, get approval]
    |
    v
[PHASE 3: EXECUTE] - Autonomous within scope
    |
    v
[CHECKPOINT: Show results, confirm next steps]
    |
    v
[PHASE 4: VERIFY] - Autonomous
    |
    v
[COMPLETE: Final summary]
```

## When to Use

- Standard development tasks
- When you want visibility without micromanagement
- Collaborative pair programming
- Complex tasks requiring periodic review
