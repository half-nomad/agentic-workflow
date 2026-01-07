---
description: "Execute an approved plan step by step. Use after reviewing a plan created with /plan."
---

# /execute - Execute Approved Plan

Execute a previously created and approved plan.

## Usage
```
/execute                    # Execute the most recent plan
/execute [plan-file.md]     # Execute a specific plan
```

## Execution Protocol

### Before Starting
1. Read the plan file
2. Verify prerequisites are met
3. Confirm plan status is PENDING_APPROVAL or APPROVED

### During Execution
For each step:
1. Mark step as **IN_PROGRESS**
2. Execute the changes
3. Run verification
4. Mark as **COMPLETED** or **FAILED**
5. Update plan file with results

### On Failure
- Stop execution
- Document what went wrong
- Suggest fixes or rollback

## Plan File Updates

```markdown
### Step 1: [Title]
**Status**: COMPLETED ✓
**Files**: [files modified]
**Changes**: [what was done]
**Verification**: PASSED
**Notes**: [any observations]
```

## Request
$ARGUMENTS

---

I will now:
1. Load the plan file (latest or specified)
2. Check prerequisites
3. Execute each step with verification
4. Update progress in the plan file

**Beginning execution...**
