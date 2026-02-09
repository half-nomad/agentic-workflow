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
ANALYZE → PATTERN → [PLAN MODE] → APPROVE → EXECUTE
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
- N개 에이전트 동시 실행
- 독립적 작업 병렬 처리
- 결과 수집 및 통합
- Good for: 다중 소스 리서치, 병렬 분석

---

## Plan Mode Integration

복잡한 작업(3개 이상 파일 수정, 새 기능 구현) 시 Plan Mode 활용.

### 자동 전환 조건
- 파일 수정 >= 3개
- 새로운 기능 구현
- 아키텍처 변경
- 사용자가 `/maestro` 또는 `/ultrawork`로 요청

### 워크플로우

```
1. EnterPlanMode 도구 호출
2. Plan Mode에서:
   - Task → Explore (탐색은 위임)
   - Orchestrator가 직접 계획 수립
   - 계획 파일 작성
3. ExitPlanMode (사용자 승인)
4. 승인 후 → Maestro 실행 모드로 전환
   - Task 위임으로 구현
   - Bash(read-only)로 검증
```

### Plan Mode에서 허용되는 작업
- Task → Explore (탐색 위임)
- Read (컨텍스트 파악, 최소한)
- 계획 파일 Write/Edit (유일한 예외)
- AskUserQuestion (요구사항 확인)

### Plan Mode에서 금지되는 작업
- 코드 파일 Write/Edit
- Bash (수정 명령)
- 구현 작업

### 장점
- 대화 맥락 유지로 계획 품질 향상
- 사용자 승인 프로세스 명확화
- 탐색은 여전히 위임하여 컨텍스트 절약

---

### Phase 3: AGENTS

**Objective**: Identify required agents and tools

**Agent Selection Matrix**:

| Need | Agent | Tools |
|------|-------|-------|
| Codebase search | Built-in `Explore` | Glob, Grep, Read |
| Planning | **Plan Mode** (직접 핸들링) | EnterPlanMode, ExitPlanMode |
| Strategic advice | `@architect` | All analysis tools |
| UI/UX work | `@frontend-engineer` | + MCP browser tools |
| External docs | `@librarian` | WebSearch, WebFetch |
| Documentation | `@document-writer` | Read, Write, Edit |

> **Note**: Planning은 더 이상 에이전트에 위임하지 않음. Orchestrator가 Plan Mode에서 직접 수행.

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

## Delegation Rules (MANDATORY)

Delegation is **NOT optional**. When the plan identifies an agent, you MUST delegate via Task tool.

### Agent Priority

```
1️⃣ Project Agents   → Check project's agents/ folder first
2️⃣ Global Agents    → Use pre-defined global agents
3️⃣ Dynamic Roles    → Create on-demand for other domains
```

When project has a specialist agent for the domain, **prefer it over global agents**.

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

세션 간 계획 상태 유지 메커니즘.

### 파일 위치
`.agentic/boulder.json`

### 동작
- **세션 시작**: boulder.json 로드, 이전 계획 컨텍스트 주입
- **세션 종료**: 현재 상태 boulder.json에 저장

### 사용자 명령
- "계속" / "continue": 이전 계획 재개
- "새로 시작" / "new": boulder.json 초기화

---

*Maestro Workflow Rules v1.4*
