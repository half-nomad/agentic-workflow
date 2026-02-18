---
alwaysApply: true
---

# Maestro Workflow Rules

Detailed rules for the Maestro orchestration system.

---

## Core Principle

> Claude becomes an orchestrator when `/maestro` is invoked, planning before executing.

---

## Orchestrator Role (CRITICAL)

In `/maestro` or `/ultrawork` mode, the main agent becomes a **pure orchestrator**.

### Orchestrator ALLOWED Actions
- **Read** files for context (Read, Glob, Grep)
- **Analyze** and plan
- **Delegate** tasks via Task tool
- **Track** progress (TodoWrite/TaskCreate)
- **Synthesize** sub-agent results
- **Report** to user
- **Verify** via read-only commands (`npm test`, `git status`, `ls`)

### Orchestrator FORBIDDEN Actions

**The orchestrator MUST NOT directly use these tools:**
| Tool | Alternative |
|------|-------------|
| `Write` | Delegate to appropriate agent |
| `Edit` | Delegate to appropriate agent |
| `Bash` (file creation/modification) | Delegate to appropriate agent |

**Exception**: Bash for read-only verification (`git status`, `npm test`, `ls`) is allowed.

### Enforcement

When tempted to use a forbidden tool, STOP and ask:
> "Which agent should handle this?"

Then delegate via Task tool.

---

## Quick Reference

### Workflow
```
ANALYZE → PATTERN → [PLAN MODE] → APPROVE → EXECUTE → [VERIFY]
```

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

#### Swarm
```
    ┌→ Agent A ─┐
    │→ Agent B ─┤→ Collect → Synthesize
    └→ Agent C ─┘
```
- N concurrent agents
- Independent parallel processing
- Collect and synthesize results
- Good for: Multi-source research, parallel analysis

#### Evaluator
```
Execute → Verify → [Fix → Re-verify] → Done
```
- Quality verification loop on execution results
- Auto-integrates with `verify-*` skills when registered in project
- On verification failure, delegate fix to agent then re-verify
- Good for: Pre-PR quality assurance, rule compliance, regression prevention

**Evaluator is not a standalone pattern — it operates as the VERIFY phase**, combined with other patterns.
Example: Orchestrator-Workers + Evaluator = implement then verify

---

## Plan Mode Integration

Use Plan Mode for complex tasks (3+ file modifications, new feature implementation).

### Auto-transition Conditions
- File modifications >= 3
- New feature implementation
- Architecture changes
- User invoked `/maestro` or `/ultrawork`

### Workflow

```
1. Call EnterPlanMode tool
2. In Plan Mode:
   - Task → Explore (delegate exploration)
   - Orchestrator plans directly
   - Write plan file
3. ExitPlanMode (user approval)
4. After approval → Switch to Maestro execution mode
   - Implement via Task delegation
   - Verify via Bash (read-only)
```

### Allowed in Plan Mode
- Task → Explore (delegate exploration)
- Read (gather context, minimal)
- Plan file Write/Edit (only exception)
- AskUserQuestion (clarify requirements)

### Forbidden in Plan Mode
- Code file Write/Edit
- Bash (modification commands)
- Implementation work

### Benefits
- Better plan quality by maintaining conversation context
- Clear user approval process
- Exploration still delegated to save context

---

### Phase 3: AGENTS

**Objective**: Identify required agents and tools

**Agent Selection Matrix**:

| Need | Agent | Tools |
|------|-------|-------|
| Codebase search | Built-in `Explore` | Glob, Grep, Read |
| Planning | **Plan Mode** (direct handling) | EnterPlanMode, ExitPlanMode |
| Strategic advice | `@architect` | All analysis tools |
| UI/UX work | `@frontend-engineer` | + MCP browser tools |
| External docs | `@librarian` | WebSearch, WebFetch |
| Documentation | `@document-writer` | Read, Write, Edit |

> **Note**: Planning is no longer delegated to agents. Orchestrator handles it directly in Plan Mode.

**Tool Categories**:
- **Search**: Glob, Grep, Read
- **Modify**: Write, Edit
- **Execute**: Bash
- **Research**: WebSearch, WebFetch, MCP tools
- **Track**: TodoWrite

### Tool Permissions by Role

| Tool | Orchestrator | Sub-Agents |
|------|:------------:|:----------:|
| Read | ✅ | ✅ |
| Glob | ✅ | ✅ |
| Grep | ✅ | ✅ |
| Write | ❌ | ✅ |
| Edit | ❌ | ✅ |
| Bash (read-only) | ✅ | ✅ |
| Bash (modify) | ❌ | ✅ |
| Task | ✅ | ❌ |
| TodoWrite | ✅ | ✅ |
| WebSearch | ✅ | ✅ |
| WebFetch | ✅ | ✅ |

**Orchestrator principle**: Observe, delegate, verify. Never mutate directly.

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
- Mode is ultrawork
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

2. **Delegate via Task Tool (MANDATORY)**
   - See "Delegation Rules" section below
   - MUST use Task tool when agents identified in plan
   - MUST NOT execute agent's work directly

3. **Handle Failures**
   ```
   Attempt 1: Delegate with clear instructions
   Attempt 2: Delegate with refined instructions
   Attempt 3: Delegate to different agent or dynamic role
   Attempt 4: Consult @architect for strategy
   Attempt 5+: Report blocker to user
   ```

   **NOTE**: "Attempt" means a delegation attempt, NOT direct execution.

4. **Verify Each Step**
   - Confirm output before proceeding
   - Test if applicable
   - Document any issues

---

### Phase 6: VERIFY (Conditional)

**Objective**: Quality verification of execution results (Evaluator pattern implementation)

**This phase is conditional** — not executed for every task.

#### VERIFY Trigger Conditions

| Condition | Run VERIFY | Reason |
|-----------|:----------:|--------|
| 1 agent, 1-2 files | **No** | Overkill — basic checks sufficient |
| 2+ agents, 3+ files | **Yes** | Integration verification prevents regressions |
| Project has `verify-*` skills | **Yes** | Leverage existing rules |
| User explicitly requests | **Yes** | Always run |
| Ultrawork mode + complex task | **Yes** | Quality assurance needed for automation |

#### VERIFY Workflow

```
EXECUTE complete
    ↓
Does the project have verify-* skills?
├─ Yes → Run verify-implementation (sequential skill execution)
│        ├─ PASS → Done
│        └─ FAIL → Delegate fix to agent → Re-verify
└─ No  → Was this a complex task?
         ├─ Yes → Suggest to user:
         │        "You can create verification skills with /manage-skills"
         └─ No  → Basic checks only (git diff, run tests)
```

#### Basic Verification (no verify-* skills)

Orchestrator performs directly (within read-only permissions):

1. `git diff --name-only` — review changed files
2. Run tests (if project has test suite)
3. Build check (if build system exists)
4. Check against Success Criteria

#### verify-* Skill Integration (skills exist)

Leverage existing global skills:

| Skill | Role | When to Run |
|-------|------|-------------|
| `/manage-skills verify` | Detect verify-* skill drift based on changed files | After code changes, for rule maintenance |
| `/verify-implementation` | Sequential execution of registered verify-* skills + integrated report | After EXECUTE, before PR |

**Orchestrator suggests these skills to the user rather than executing directly.**
Exception: In Ultrawork mode, verification logic can run automatically.

#### Domain-Specific Verification

When verification requires domain expertise (security audit, accessibility, etc.):
- Delegate to `@architect` for strategic review
- Or create dynamic role (e.g., security auditor)

---

## Integration with Modes

### Default Mode (no activation command)
- No orchestration — direct Claude interaction

### Maestro Mode (`/maestro`)
- ANALYZE: Autonomous
- PATTERN: Autonomous with explanation
- AGENTS: Autonomous with explanation
- APPROVE: Required (user checkpoint)
- EXECUTE: Autonomous via delegation
- VERIFY: Suggest if conditions met

### Ultrawork Mode (`/ultrawork`)
- ANALYZE: Autonomous
- PATTERN: Autonomous
- AGENTS: Autonomous
- APPROVE: Skipped
- EXECUTE: Autonomous via delegation
- VERIFY: Auto-run if verify-* skills exist
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

## Delegation Rules (MANDATORY)

Delegation is **NOT optional**. When the plan identifies an agent, you MUST delegate via Task tool.

### Agent Priority

```
1️⃣ Project Agents   → Check project's agents/ folder first
2️⃣ Global Agents    → Use pre-defined global agents
3️⃣ Dynamic Roles    → Create on-demand for other domains
```

When project has a specialist agent for the domain, **prefer it over global agents**.

### Skill Handling (CRITICAL)

Skills are classified into two types. **The type determines how Maestro interacts with them.**

#### Task Skills (`context: fork` in frontmatter)

Contain structured workflows (step-by-step execution plans). The skill specifies which agent runs it.

```yaml
# Example: skills/guide-content-seeder/SKILL.md
context: fork
agent: content-writer    # ← Skill decides the agent
```

**Maestro delegation pattern for Task skills:**
1. Read the SKILL.md file (Read tool — allowed for orchestrator)
2. Pass SKILL.md content as part of the Task prompt to the designated agent
3. The agent receives both its expertise (agent.md) AND the workflow (SKILL.md)

```
Task(
  subagent_type: "content-writer",
  prompt: "[SKILL.md content] + [specific arguments/context]"
)
```

**VIOLATION**: Calling a project agent for a structured task WITHOUT including its Task skill workflow. The agent has expertise but lacks the detailed execution steps.

#### Reference Skills (`user-invocable: false` or no `context` field)

Contain rules, conventions, or guidelines. Listed in the agent's `skills:` field and **auto-loaded into agent context at startup**.

```yaml
# Example: agents/content-writer.md
skills: validation-protocol    # ← Agent loads this as reference
```

**No action needed from Maestro** — reference skills are injected automatically when the agent is spawned via Task tool.

#### Decision Guide

```
Maestro needs to delegate a structured task?
├─ Project has a Task skill for it?
│   ├─ Yes → Read SKILL.md, pass in Task prompt to designated agent
│   └─ No  → Delegate to agent with clear instructions (dynamic role if needed)
└─ Agent needs domain rules/conventions?
    └─ Already handled via Reference skills in agent's skills: field
```

### Global Agents (Always Available)

| Agent | Domain | Model | Tools | Trigger |
|-------|--------|-------|-------|---------|
| 🔵 `@architect` | Strategy | opus | all | Stuck 2+ times, major decisions |
| 🟢 `@frontend-engineer` | UI/UX | opus | all | Visual changes, styling, animations |
| 🟡 `@librarian` | Research | sonnet | limited | Library docs, API references |
| 🟣 `@document-writer` | Docs | sonnet | all | README, guides, docs |

### When to Use Dynamic Roles

Use dynamic role assignment for domains without specialist agents:
- Backend development
- DevOps / Infrastructure
- Security review
- Database design
- Other specialized domains

### Dynamic Role Template

When no specialist agent exists, create a dynamic role:

```
Task tool call:
- subagent_type: general-purpose
- prompt: |
    ## Role
    You are a [DOMAIN] expert specializing in [SPECIFIC AREA].

    ## Context
    [Relevant background - keep brief]

    ## Task
    [Specific deliverable expected]

    ## Output Format
    [Expected structure of response]
```

**Example - Backend API work:**
```
- subagent_type: general-purpose
- prompt: |
    ## Role
    You are a backend engineer expert in REST API design.

    ## Context
    We're adding user authentication to an Express.js app.

    ## Task
    Create auth endpoints: POST /login, POST /register, GET /me

    ## Output Format
    - Route implementations
    - Middleware code
    - Brief usage notes
```

### Complexity-Based Delegation

| Condition | Action |
|-----------|--------|
| Files >= 5 | Split into sub-tasks, delegate |
| Independent tasks >= 3 | Parallel delegation |
| Single domain, < 3 files | Delegate to single agent (streamlined) |

**NOTE**: Even simple tasks require delegation in Maestro/Ultrawork mode.

### Result Integration

After receiving sub-agent results:
1. **Read and understand** the changes made (use Read tool)
2. **Verify** results meet requirements (use Bash for tests if needed)
3. **Update** TODO items to reflect completion
4. **Summarize** outcomes for user or next step
5. **Proceed** to next delegation or report completion

**IMPORTANT**: If results need modification, delegate the fix - do NOT edit directly.

### Delegation Anti-Patterns (VIOLATION)

These are **workflow violations**:

| Anti-Pattern | Correct Behavior |
|--------------|------------------|
| Plan identifies @agent → Execute directly | Plan identifies @agent → Task tool |
| "It's simple" → Skip delegation | Follow delegation rules regardless |
| Accumulate context → Do everything | Delegate to manage context |
| Ignore dynamic role option | Create role when no specialist exists |
| Call agent without Task skill for structured work | Read SKILL.md → include in Task prompt |
| Put Task skills in agent's `skills:` field | Task skills use `context: fork` + `agent:` in SKILL.md |

### Self-Check Before Any Tool Use

Before using Write, Edit, or Bash (non-read-only):

1. Am I in Maestro/Ultrawork mode?
2. If YES → I **MUST** delegate this action
3. Have I identified which agent handles this domain?
4. Have I crafted clear instructions for the sub-agent?

If any check fails, **STOP and correct course**.

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
Agent: @frontend-engineer (single domain)

Execution:
1. Orchestrator: Read current form (gather context)
2. Task tool → @frontend-engineer:
   "Add validation schema, integrate into form, add error display"
3. Orchestrator: Run tests to verify (`npm test`)
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

### Orchestrator-Workers Pattern (with Proper Delegation)
```
User: "/maestro Implement user authentication"

Plan:
Pattern: Orchestrator-Workers
- @architect: Design auth architecture
- Worker 1: Backend auth endpoints (dynamic role)
- Worker 2: Frontend auth UI (@frontend-engineer)
- Worker 3: Documentation (@document-writer)

Execution (CORRECT):
1. Task tool → @architect
   "Design auth architecture for Express + React app"

2. Task tool → general-purpose (dynamic: backend engineer)
   "Implement auth endpoints based on architect's design"

3. Task tool → @frontend-engineer (parallel with #2)
   "Build login/register UI components"

4. Task tool → @document-writer (parallel with #2, #3)
   "Create auth documentation"

5. Main agent: Integrate and test

Execution (WRONG - VIOLATION):
❌ Plan says @architect → Main agent designs directly
❌ Plan says @frontend-engineer → Main agent writes CSS
❌ Skipping Task tool "because it's faster"
```

---

## State Persistence (boulder.json)

Session-to-session plan state persistence mechanism.

### File Location
`.agentic/boulder.json`

### Behavior
- **Session start**: Load boulder.json, inject previous plan context
- **Session end**: Save current state to boulder.json

### User Commands
- "continue": Resume previous plan
- "new": Clear boulder.json, fresh start

---

*Maestro Workflow Rules v1.8*
