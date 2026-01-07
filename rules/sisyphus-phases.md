---
alwaysApply: true
---

---
name: sisyphus-phases
description: Phase system for structured task execution
applies_to: all
---

# Sisyphus Phase System

A structured approach to task execution inspired by the Sisyphus automation pattern.
The name reflects the persistent, never-give-up nature of the workflow.

## Four Phases

### Phase 1: EXPLORE (Parallel Discovery)

**Objective**: Understand the problem space before taking action

**Actions**:
- Launch 3+ parallel exploration tasks using Task tool
- Use @explorer for codebase navigation
- Use @librarian for documentation research
- Identify all relevant files, patterns, and constraints

**Output**:
```markdown
## Exploration Summary
- Files identified: [list]
- Key patterns found: [list]
- Constraints discovered: [list]
- Dependencies: [list]
```

**Transition Criteria**:
- Core problem is understood
- Relevant files are identified
- Constraints are documented

### Phase 2: PLAN (Strategic Preparation)

**Objective**: Create a concrete, actionable plan

**Actions**:
- Create comprehensive TODO list using TodoWrite
- Define success criteria
- Identify risks and mitigations
- Sequence tasks by dependency

**Output**:
```markdown
## Implementation Plan
- [ ] Task 1: [description]
- [ ] Task 2: [description]
...

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Risks
- Risk 1 -> Mitigation
```

**Transition Criteria**:
- TODO list is complete
- Success criteria are defined
- Plan is feasible

### Phase 3: EXECUTE (Focused Implementation)

**Objective**: Complete all planned tasks systematically

**Actions**:
- Work through TODO list item by item
- Mark items complete immediately when done
- Delegate to specialists when appropriate:
  - @frontend-engineer for UI work
  - @architect for design decisions
  - @document-writer for documentation
- If stuck 2+ times, consult @architect

**Recovery Protocol**:
```
Failure 1: Retry with adjustment
Failure 2: Try alternative approach
Failure 3: Consult @architect
Failure 5+: Consider scope reduction
```

**Transition Criteria**:
- All TODO items marked complete
- No known failures remaining

### Phase 4: VERIFY (Quality Assurance)

**Objective**: Ensure work meets quality standards

**Actions**:
- Run tests if applicable
- Verify each success criterion
- Check for regressions
- Review code quality

**Output**:
```markdown
## Verification Results
- [ ] Tests pass
- [ ] Success criteria met
- [ ] No regressions
- [ ] Code quality verified

## Summary
[Brief summary of what was accomplished]
```

**Completion**:
When all verification passes, output:
```
<promise>DONE</promise>
```

## Mode-Specific Behavior

| Phase | Manual | Semi-Auto | Ultrawork |
|-------|--------|-----------|-----------|
| EXPLORE | With guidance | Autonomous | Autonomous |
| PLAN | User review | Checkpoint | Autonomous |
| EXECUTE | Step approval | Autonomous | Autonomous |
| VERIFY | User review | Checkpoint | Autonomous |

## Phase Indicators

Use these markers in responses to indicate current phase:

```
[PHASE 1: EXPLORE] Starting parallel discovery...
[PHASE 2: PLAN] Creating implementation plan...
[PHASE 3: EXECUTE] Working on task 3/7...
[PHASE 4: VERIFY] Running verification checks...
```

## Anti-Patterns

1. **Skipping Exploration**
   - Never jump to implementation without understanding
   - Quick tasks still need brief exploration

2. **Incomplete Planning**
   - Vague TODOs lead to scope creep
   - Always define success criteria

3. **Ignoring Failures**
   - Track consecutive failures
   - Escalate to @architect when needed

4. **Premature Completion**
   - Verify before claiming done
   - Output `<promise>DONE</promise>` only when truly complete

## Integration with Ralph Loop

Ralph Loop monitors for `<promise>DONE</promise>` at the Stop event.

- If not detected: Triggers continuation prompt
- If detected: Loop terminates successfully
- If max iterations reached: Loop terminates with warning

The phase system ensures systematic progress toward that completion promise.
