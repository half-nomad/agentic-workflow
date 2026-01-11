---
alwaysApply: true
---

# Maestro Workflow Rules

Detailed rules for the Maestro orchestration system.

---

## Core Principle

> Claude becomes an orchestrator when `/maestro` is invoked, planning before executing.

---

## Workflow Phases

### Phase 1: ANALYZE

**Objective**: Determine task complexity and scope

**Questions to answer**:
- Is this a single-step or multi-step task?
- How many files/domains are involved?
- Are there dependencies between steps?
- Is user approval needed?

**Complexity Classification**:

| Indicator | Simple | Complex |
|-----------|--------|---------|
| Steps | 1-2 | 3+ |
| Files | 1-2 | 3+ |
| Domains | Single | Multiple |
| Dependencies | None/Linear | Branching |

**Output**: Complexity determination (Simple → skip to execute, Complex → continue to PATTERN)

---

### Phase 2: PATTERN

**Objective**: Select the appropriate execution pattern

**Decision Tree**:

```
Is it sequential with dependencies?
├─ Yes → Chaining
└─ No → Are tasks independent?
        ├─ Yes → Parallelization
        └─ No → Is there conditional logic?
                ├─ Yes → Routing
                └─ No → Orchestrator-Workers
```

**Pattern Details**:

#### Chaining
```
Task A → Task B → Task C
```
- Each step depends on previous
- Linear execution
- Good for: Build pipelines, data transformations

#### Parallelization
```
    ┌→ Task A ─┐
Input → Task B → Merge → Output
    └→ Task C ─┘
```
- Independent concurrent execution
- Results merged at end
- Good for: Multi-source search, parallel API calls

#### Routing
```
        ┌→ Handler A (if condition A)
Input ──┼→ Handler B (if condition B)
        └→ Handler C (default)
```
- Conditional branching
- Single path executed
- Good for: Error handling, input classification

#### Orchestrator-Workers
```
Orchestrator
    ├→ Worker A (domain 1)
    ├→ Worker B (domain 2)
    └→ Worker C (domain 3)
         ↓
    Synthesize results
```
- Complex multi-domain coordination
- Dynamic task distribution
- Good for: Full features, large refactors

---

### Phase 3: AGENTS

**Objective**: Identify required agents and tools

**Agent Selection Matrix**:

| Need | Agent | Tools |
|------|-------|-------|
| Codebase search | Built-in `Explore` | Glob, Grep, Read |
| Planning | Built-in `Plan` | Read, Grep, TodoWrite |
| Strategic advice | `@architect` | All analysis tools |
| UI/UX work | `@frontend-engineer` | + MCP browser tools |
| External docs | `@librarian` | WebSearch, WebFetch |
| Documentation | `@document-writer` | Read, Write, Edit |

**Tool Categories**:
- **Search**: Glob, Grep, Read
- **Modify**: Write, Edit
- **Execute**: Bash
- **Research**: WebSearch, WebFetch, MCP tools
- **Track**: TodoWrite

---

### Phase 4: APPROVE

**Objective**: Get user approval before execution

**Plan Format**:

```markdown
## Execution Plan

**Pattern**: [Selected pattern]
**Complexity**: Simple / Complex
**Estimated Steps**: N

### Agents & Tools
- [ ] Agent/tool 1: purpose
- [ ] Agent/tool 2: purpose

### Execution Steps
1. Step description
   - Sub-action if needed
2. Step description
...

### Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2

**Approve to proceed.**
```

**Skip Conditions** (Ultrawork mode):
- Mode is ultrawork/ulw
- Ralph Loop is active
- User explicitly requested full autonomy

---

### Phase 5: EXECUTE

**Objective**: Complete the planned work

**Execution Rules**:

1. **Track Progress**
   - Use TodoWrite for all multi-step work
   - Mark items complete immediately when done
   - Never batch completions

2. **Delegate Appropriately**
   - Use Task tool for parallel agent work
   - Use specialist agents for domain expertise
   - Use built-in agents for standard operations

3. **Handle Failures**
   ```
   Attempt 1: Direct approach
   Attempt 2: Adjusted approach
   Attempt 3: Alternative method
   Attempt 4: Consult @architect
   Attempt 5+: Report blocker
   ```

4. **Verify Each Step**
   - Confirm output before proceeding
   - Test if applicable
   - Document any issues

---

## Integration with Modes

### Manual Mode
- ANALYZE: Present findings, ask for guidance
- PATTERN: Suggest, let user choose
- AGENTS: List options, user confirms
- APPROVE: Always required
- EXECUTE: User approves each action

### Semi-Auto Mode
- ANALYZE: Autonomous
- PATTERN: Autonomous with explanation
- AGENTS: Autonomous with explanation
- APPROVE: Required (checkpoint)
- EXECUTE: Autonomous

### Ultrawork Mode
- ANALYZE: Autonomous
- PATTERN: Autonomous
- AGENTS: Autonomous
- APPROVE: Skipped
- EXECUTE: Autonomous
- Ralph Loop: Active

---

## Quality Gates

Before marking complete:

- [ ] All TODO items completed
- [ ] No failing tests
- [ ] Code compiles/runs
- [ ] Success criteria met
- [ ] No regressions introduced

Only then output:
```
<promise>DONE</promise>
```

---

## Examples

### Simple Task (No Maestro needed)
```
User: "Fix the typo in README"
Claude: [Direct edit, no orchestration needed]
```

### Chaining Pattern
```
User: "/maestro Add input validation to the login form"

Plan:
Pattern: Chaining
1. Read current form implementation
2. Add validation schema
3. Integrate validation into form
4. Add error display
5. Test validation
```

### Parallelization Pattern
```
User: "/maestro Research best practices for error handling in React, Vue, and Angular"

Plan:
Pattern: Parallelization
- Task A: @librarian research React error boundaries
- Task B: @librarian research Vue error handling
- Task C: @librarian research Angular error handling
- Merge: Synthesize findings into comparison doc
```

### Orchestrator-Workers Pattern
```
User: "/maestro Implement user authentication"

Plan:
Pattern: Orchestrator-Workers
- @architect: Design auth architecture
- Worker 1: Backend auth endpoints
- Worker 2: Frontend auth UI (@frontend-engineer)
- Worker 3: Documentation (@document-writer)
- Integration: Connect all parts, test flow
```

---

*Maestro Workflow Rules v1.0*
