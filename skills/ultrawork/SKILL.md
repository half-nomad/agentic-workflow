---
name: ultrawork
description: "Full autonomous orchestration mode (ultrawork/ulw/끝까지/완료해). Maximum precision, parallel agents, complete task execution."
allowed-tools: Task, TodoRead, TodoWrite, Read, Bash, Glob, Grep
---

# ULTRAWORK MODE - Full Autonomous Orchestration

[CODE RED] Maximum precision. Complete execution. No partial work.

## Activation
This mode activates when triggered via description keywords: ultrawork, ulw, 끝까지, 완료해

## Orchestration Protocol

### Phase 1: Parallel Exploration
**IMMEDIATELY** launch multiple Task calls:

```
Task(subagent: "explorer", prompt: "Find project structure and entry points")
Task(subagent: "explorer", prompt: "Find files related to [task topic]")
Task(subagent: "librarian", prompt: "Find documentation for [relevant libraries]")
```

**Rules:**
- Launch 3+ parallel searches
- Don't wait sequentially
- Cover different angles

### Phase 2: TODO Planning
**MANDATORY** before any implementation:

```
TodoWrite([
  { content: "Step 1: ...", status: "pending" },
  { content: "Step 2: ...", status: "pending" },
  ...
])
```

**Rules:**
- Break into atomic steps
- Each step must be verifiable
- Include testing/verification steps

### Phase 3: Execution
For each TODO:
1. Mark as `in_progress`
2. Execute the work
3. Verify completion
4. Mark as `completed`
5. Move to next

**Delegation Rules:**
- UI/Visual changes → @frontend-engineer
- Documentation → @document-writer
- Architecture questions → @architect
- External docs needed → @librarian

### Phase 4: Verification
Before completing:
- [ ] All TODOs marked complete
- [ ] Tests pass (if applicable)
- [ ] Build succeeds (if applicable)
- [ ] Original request fulfilled

## Hard Rules

### NEVER
- Stop with incomplete TODOs
- Skip verification steps
- Guess without researching
- Work sequentially when parallel is possible

### ALWAYS
- Use TODO list for tracking
- Verify each step
- Delegate specialized work
- Complete 100% of the request

## Failure Recovery

If stuck 2+ times on same issue:
1. STOP current approach
2. Document what failed
3. Consult @architect for alternatives
4. Try new approach

## Completion Criteria

Session ends ONLY when:
- All TODOs are `completed`
- All tests pass
- Build succeeds
- User request fully addressed
