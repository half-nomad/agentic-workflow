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
| Auto-continuation | Within tasks only |
| TODO enforcement | Active |
| User confirmation | At plan approval |

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
   - Task automation: ENABLED
   - Checkpoint confirmations: ENABLED

   I will work autonomously within approved plans but pause for
   confirmation at major decision points.

   Use /ulw for full automation or /manual for full control.
   ```

## Maestro in Semi-Auto Mode

When using `/maestro` in semi-auto mode:
- ANALYZE: Autonomous
- PATTERN: Autonomous with explanation
- AGENTS: Autonomous with explanation
- APPROVE: **Required** (checkpoint)
- EXECUTE: Autonomous after approval

## Autonomous Actions (No confirmation)
- Exploration and research
- Reading files and understanding code
- Creating TODO lists
- Small, reversible changes
- Running tests

## Checkpoint Pauses (Confirmation required)
- Before starting execution (plan approval)
- After completing major features
- Before file deletions
- When encountering unexpected issues

## When to Use

- Standard development tasks
- When you want visibility without micromanagement
- Collaborative pair programming
- Complex tasks requiring periodic review
