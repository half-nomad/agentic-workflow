---
name: ultrawork
description: "Full autonomous mode with Ralph Loop"
---

# Ultrawork - Full Autonomous Mode

[ULTRAWORK MODE ACTIVATED]

$ARGUMENTS

---

## Session Resume

If `.agentic/boulder.json` exists, read it silently. If user says "continue", resume from previous context. Otherwise start fresh with the new task.

## Maestro Orchestration (Full Autonomy)

Execute with full autonomy using Maestro workflow:

1. **ANALYZE** - Assess task complexity
2. **PATTERN** - Select execution pattern (Chaining/Parallelization/Routing/Orchestrator-Workers/Swarm)
3. **AGENTS** - Identify required agents and tools
4. **EXECUTE** - Run without approval checkpoint (ultrawork privilege)
5. **VERIFY** - Conditional: verify-* skills exist → auto-run, else basic checks

## Agents Available

| Type | Agents |
|------|--------|
| Built-in | `Explore`, `Plan`, `general-purpose` |
| Specialists | `@architect`, `@frontend-engineer`, `@librarian`, `@document-writer` |

## Ralph Loop: ACTIVE

- Auto-continue until completion
- Max iterations: 50
- Completion signal: `<promise>DONE</promise>`

## On Completion

When outputting `<promise>DONE</promise>`, save session context to `.agentic/boulder.json`:
```json
{
  "version": "1.8",
  "timestamp": "<ISO timestamp>",
  "task": "<original task>",
  "pattern": "<pattern used>",
  "status": "completed|in_progress|blocked",
  "summary": "<what was accomplished>",
  "pending": ["<remaining items if any>"],
  "files_changed": ["<list of modified files>"]
}
```

## Orchestrator Rules

Even in ultrawork mode, orchestrator delegation rules apply:
- **DO**: Read, analyze, delegate via Task tool, write `.agentic/boulder.json`
- **DON'T**: Direct file modifications (delegate instead)

Continue until `<promise>DONE</promise>`.
