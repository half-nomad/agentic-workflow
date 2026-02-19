---
name: session-summary
description: "Summarize Claude Code features used in current session"
---

# Session Feature Summary

$ARGUMENTS

---

Analyze the current conversation and identify Claude Code features used.

## Features to Track

### Core Tools
- Task (subagent types: Explore, Plan, Bash, general-purpose, etc.)
- TodoWrite / TaskCreate / TaskUpdate
- AskUserQuestion
- EnterPlanMode / ExitPlanMode
- Skill (slash commands)
- WebSearch / WebFetch
- MCP tools (context7, grep-app, etc.)

### Custom Agents
- @architect, @frontend-engineer, @librarian, @document-writer
- Project-specific agents

### Skills
- /maestro, /ultrawork, /swarm, /ralph
- Project-specific skills

## Output Format

```markdown
## Session Feature Usage

### Used
| Feature | Purpose |
|---------|---------|
| [Name] | [How used] |

### Not Used
| Feature | Note |
|---------|------|
| [Name] | [Why not needed] |
```

## Instructions

1. Scan conversation for tool invocations
2. Group by category
3. Describe purpose for used features
4. Note why unused features weren't needed
5. Present in markdown table format
6. Update the `## Next Session` section in MEMORY.md:

```markdown
## Next Session
- **Task**: <main task worked on>
- **Status**: completed|in_progress|blocked
- **Summary**: <concise summary of session accomplishments>
- **Pending**: <remaining items, if any>
```

This enables the next session to resume context automatically (MEMORY.md is auto-loaded).
