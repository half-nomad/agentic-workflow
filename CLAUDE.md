# Agentic Workflow - Maestro

> Claude Code configuration for orchestrated agent workflows

---

## Maestro Workflow

Maestro is a plan-first orchestration system. When activated, Claude becomes an orchestrator that plans, selects patterns, identifies agents, and executes after user approval.

### Activation

```
/maestro [task description]
```

Or implicitly via `/ultrawork` (full autonomy mode).

### Workflow

```
1. ANALYZE    → Assess task complexity (simple vs complex)
2. PATTERN    → Select execution pattern
3. AGENTS     → Identify required agents/tools
4. APPROVE    → Submit plan for user approval
5. EXECUTE    → Run after approval
```

---

## Patterns (Anthropic 4+1)

| Pattern | When to Use | Example |
|---------|-------------|---------|
| **Chaining** | Sequential steps, each depends on previous | Build → Test → Deploy |
| **Parallelization** | Independent tasks, can run concurrently | Search 3 APIs simultaneously |
| **Routing** | Conditional branching based on input | Error type → specific handler |
| **Orchestrator-Workers** | Complex multi-domain work | Full feature implementation |
| **Evaluator** | Quality verification needed | Code review, test validation |

### Pattern Selection Guide

```
Single step, clear action?     → Direct execute (no /maestro needed)
Multiple sequential steps?     → Chaining
Independent parallel tasks?    → Parallelization
Conditional branches?          → Routing
Complex, multi-domain?         → Orchestrator-Workers
```

---

## Agents

### Specialist Agents (Custom)

| Agent | Model | Role | Use When |
|-------|-------|------|----------|
| `@architect` | opus | Strategic advisor | Stuck 2+ times, major decisions |
| `@frontend-engineer` | opus | UI/UX specialist | Visual changes, CSS, components |
| `@librarian` | sonnet | Documentation research | Library docs, API references |
| `@document-writer` | sonnet | Documentation | README, guides, docs |

### Built-in Agents

| Agent | Role |
|-------|------|
| `Explore` | Fast codebase search |
| `Plan` | Implementation planning |
| `general-purpose` | Multi-step research |

---

## Operating Modes

| Mode | Activation | Behavior |
|------|------------|----------|
| **Default** | (no command) | Normal Claude interaction |
| **Maestro** | `/maestro` | Plan-first with user approval |
| **Ultrawork** | `/ultrawork`, `/ulw` | Full autonomy + Ralph Loop |

### Mode Comparison

| Aspect | Default | Maestro | Ultrawork |
|--------|---------|---------|-----------|
| Planning | As needed | Required | Required |
| Approval | N/A | Required | Skipped |
| Ralph Loop | OFF | OFF | ON |
| Use Case | Simple tasks | Complex planned work | Full automation |

---

## Ralph Loop

Autonomous continuation system for task completion.

### Start
```
/ralph-start
```

### How It Works
1. Monitors for `<promise>DONE</promise>` at Stop event
2. If not detected: Triggers continuation prompt
3. If detected: Loop terminates successfully
4. Max 50 iterations before forced stop

### Stop
```
/ralph-cancel
```

Or output completion signal:
```
<promise>DONE</promise>
```

---

## Completion Signal

**CRITICAL**: Only output when task is truly complete:

```
<promise>DONE</promise>
```

Requirements:
- All TODO items marked complete
- Tests pass (if applicable)
- Success criteria met
- No known issues remaining

---

## Plan Submission Format

When `/maestro` is active, submit plans in this format:

```markdown
## Execution Plan

**Pattern**: [Chaining / Parallelization / Routing / Orchestrator-Workers]
**Complexity**: [Simple / Complex]
**Steps**: N

### Agents & Tools
- [ ] @agent-name: role
- [ ] Built-in Explore: codebase search
- [ ] /skill-name: purpose

### Execution Steps
1. [Step 1 description]
2. [Step 2 description]
...

**Approve to execute.**
```

---

## Recovery Protocol

```
Failure 1: Retry with adjustment
Failure 2: Try alternative approach
Failure 3: Consult @architect
Failure 5+: Report blocker to user
```

---

## Anti-Patterns

1. **Skipping Analysis** - Always assess before executing
2. **Wrong Pattern** - Match pattern to task structure
3. **Agent Overuse** - Simple tasks don't need delegation
4. **Premature Completion** - Verify before `<promise>DONE</promise>`
5. **Ignoring Failures** - Escalate after 2+ failures

---

## Extended Rules

For detailed rules, see `rules/` directory:
- `rules/global.md` - Code quality, simplicity first
- `rules/typescript.md` - TypeScript conventions
- `rules/maestro-workflow.md` - Detailed workflow rules

---

*Maestro Workflow v1.0 - 2026-01-11*
