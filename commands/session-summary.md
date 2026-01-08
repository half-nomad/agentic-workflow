---
description: "Summarize Claude Code features used in current session"
---

# /session-summary - Session Feature Summary

Analyze and summarize Claude Code features used in the current conversation session.

## Task

Review the entire conversation history and identify:
1. **Used features** - Tools, agents, modes that were actually invoked
2. **Unused features** - Available but not used in this session

## Features to Track

### Core Tools
- Task (subagent types: Explore, Plan, Bash, general-purpose, code-reviewer, etc.)
- TodoWrite
- AskUserQuestion
- EnterPlanMode / ExitPlanMode
- Skill (slash commands)
- WebSearch / WebFetch
- MCP tools (context7, grep-app, ide, etc.)

### Custom Agents
- code-reviewer
- notion-gateway
- Other project-specific agents

### Skills
- e2e-setup, e2e-test
- smart-dev-session-manager
- Other project-specific skills

## Output Format

Generate a summary in this exact format:

```markdown
## 이번 세션에서 사용된 Claude Code 기능들

### 사용됨
| 기능 | 용도 |
|-----|------|
| [Feature Name] | [How it was used] |
| ... | ... |

### 사용 안 됨
| 기능 | 비고 |
|-----|------|
| [Feature Name] | [Why not used or N/A] |
| ... | ... |
```

## Instructions

1. Scan the conversation for all tool invocations
2. Group by feature category
3. For used features: describe the specific purpose
4. For unused features: note if it was unnecessary or just not applicable
5. Present in clean markdown table format

$ARGUMENTS

---
Analyze the current session and generate the feature usage summary.
