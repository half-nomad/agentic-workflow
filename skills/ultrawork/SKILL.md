---
name: ultrawork
description: "Full autonomous mode with Ralph Loop. Aliases: /ulw"
---

# Ultrawork - Full Autonomous Mode

[ULTRAWORK MODE ACTIVATED]

$ARGUMENTS

---

## Maestro Orchestration (Full Autonomy)

Execute with full autonomy using Maestro workflow:

1. **ANALYZE** - Assess task complexity
2. **PATTERN** - Select execution pattern (Chaining/Parallelization/Routing/Orchestrator-Workers/Swarm)
3. **AGENTS** - Identify required agents and tools
4. **EXECUTE** - Run without approval checkpoint (ultrawork privilege)
5. **VERIFY** - Ensure success criteria met

## Agents Available

| Type | Agents |
|------|--------|
| Built-in | `Explore`, `Plan`, `general-purpose` |
| Specialists | `@architect`, `@frontend-engineer`, `@librarian`, `@document-writer` |

## Ralph Loop: ACTIVE

- Auto-continue until completion
- Max iterations: 50
- Completion signal: `<promise>DONE</promise>`

## Orchestrator Rules

Even in ultrawork mode, orchestrator delegation rules apply:
- **DO**: Read, analyze, delegate via Task tool
- **DON'T**: Direct file modifications (delegate instead)

Continue until `<promise>DONE</promise>`.
