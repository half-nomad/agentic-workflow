# Agentic Workflow - Maestro

> Plan-first orchestration for complex tasks

---

## Quick Reference

### Activation

| Skill | Mode | Behavior |
|-------|------|----------|
| `/maestro [task]` | Maestro | Plan with approval |
| `/ultrawork`, `/ulw` | Ultrawork | Full autonomy + Ralph Loop |
| `/swarm [task]` | Swarm | 병렬 에이전트 실행 |
| `/ralph start\|cancel` | Ralph | Autonomous loop control |
| (none) | Default | Normal interaction |

### Workflow

```
ANALYZE → PATTERN → AGENTS → APPROVE → EXECUTE
```

### Patterns

| Pattern | When to Use |
|---------|-------------|
| **Chaining** | Sequential dependencies |
| **Parallelization** | Independent concurrent tasks |
| **Routing** | Conditional branching |
| **Orchestrator-Workers** | Multi-domain complexity |
| **Swarm** | N개 에이전트 병렬 실행 |
| **Evaluator** | Quality verification |

### Agents

| Agent | Model | Role |
|-------|-------|------|
| `@architect` | opus | Strategic decisions, architecture |
| `@frontend-engineer` | opus | UI/UX, components, styling |
| `@librarian` | sonnet | Documentation research |
| `@document-writer` | sonnet | README, guides, docs |

Built-in: `Explore` (search), `Plan` (planning), `general-purpose` (research)

---

## Completion

Only output when task is truly complete:

```
<promise>DONE</promise>
```

Requirements: All TODOs done, tests pass, success criteria met.

---

## Detailed Rules

See `rules/` directory:
- `rules/maestro-workflow.md` - Workflow phases, patterns, examples
- `rules/global.md` - Code quality, simplicity first
- `rules/typescript.md` - TypeScript conventions

---

## State Persistence

Sessions resume via `.agentic/boulder.json`:
- "계속" / "continue": Resume previous plan
- "새로 시작" / "new": Clear state, fresh start

---

*Maestro Workflow v1.6*
