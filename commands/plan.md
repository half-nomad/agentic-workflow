---
description: "Create a detailed implementation plan for complex tasks. The plan will be saved for review before execution."
model: opus
---

# /plan - Create Implementation Plan

Create a detailed, reviewable plan before executing complex tasks.

## Workflow
1. **You provide**: Task description
2. **I create**: Detailed plan with steps
3. **You review**: Approve, modify, or reject
4. **Then execute**: Use `/execute` to run the approved plan

## What Gets Created

A plan file at `.claude/plans/[task-name].md` containing:

```markdown
# Plan: [Task Title]

**Status**: PENDING_APPROVAL
**Effort**: [Quick/Short/Medium/Large]

## Summary
[What will be done]

## Prerequisites
- [ ] [Required before starting]

## Steps
### Step 1: [Title]
- Files: [affected files]
- Changes: [specific changes]
- Verify: [how to check]

### Step 2: [Title]
...

## Risks
[Potential issues and mitigations]

## Success Criteria
[How we know it's done]
```

## After Planning

1. **Review** the generated plan file
2. **Modify** if needed (edit the file directly)
3. **Execute** with `/execute` or `/execute [plan-file]`

## Request
$ARGUMENTS

---

I will now analyze your request, gather context, and create a detailed implementation plan.

**Planning Steps:**
1. Explore codebase structure
2. Identify affected files
3. Design implementation approach
4. Create step-by-step plan
5. Save to `.claude/plans/`
