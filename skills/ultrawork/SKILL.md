---
name: ultrawork
description: "Full autonomous mode with Ralph Loop"
---

# Ultrawork - Full Autonomous Mode

[ULTRAWORK MODE ACTIVATED]

$ARGUMENTS

---

## Session Resume

MEMORY.md is auto-loaded into the system prompt. Check the `## Next Session` section for previous context. If user says "continue", resume from that context. Otherwise start fresh with the new task.

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

When outputting `<promise>DONE</promise>`, update the `## Next Session` section in MEMORY.md:

```markdown
## Next Session
- **Task**: <what was worked on>
- **Status**: completed|in_progress|blocked
- **Summary**: <what was accomplished>
- **Pending**: <remaining items, if any>
```

If status is `completed` with no pending items, clear the `## Next Session` section.

## Orchestrator Rules

Even in ultrawork mode, orchestrator delegation rules apply:
- **DO**: Read, analyze, delegate via Task tool, update MEMORY.md
- **DON'T**: Direct file modifications (delegate instead)

Continue until `<promise>DONE</promise>`.
