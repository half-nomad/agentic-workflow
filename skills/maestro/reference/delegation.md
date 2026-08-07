# 참조 — 위임 템플릿 · plan 템플릿

> **언제 읽나**: 위임 프롬프트를 처음 짤 때, plan 문서 형식이 필요할 때. 매 런 읽을 필요는 없다.
> 구속력 있는 규약(위임 의무 · Context Embedding 필수 · 5b 출력 계약)은 `WORKFLOW.md` §Delegation Rules 에 있다.

---

## Context Embedding — 무엇을 실어야 하나

서브에이전트는 프로젝트 컨텍스트가 **0**이다. 아래를 위임 프롬프트에 직접 임베딩한다.

| Context Type | When Required |
|-------------|---------------|
| **Schema/Spec** | Models, migrations, APIs |
| **Existing Code** | 기존 패턴을 따라야 할 때 (mirror 대상) |
| **Design Rules** | UI/frontend work |
| **Constraints** | 이미 내려진 아키텍처 결정 |
| **Routes / i18n Keys** | Controller/view work, 번역 포함 뷰 |
| **File Paths** | 모든 작업 — 생성/수정 정확한 경로 |
| **Self-test expectation** | 모든 구현 작업 — 5b 출력 계약 요구 |

## 위임 프롬프트 템플릿

```
Task tool call:
- prompt: |
    ## Task
    [What to build/change — specific deliverable]

    ## Reference: Schema
    [Paste relevant TRD schema — exact columns, types, constraints]

    ## Reference: Existing Pattern
    [Paste existing code the agent should mirror]

    ## Reference: Design System (if UI work)
    [CSS variables, component classes, styling rules]

    ## Constraints
    - [Hard rule 1 — e.g., "UUID PK"]
    - [Hard rule 2 — e.g., "has_secure_password(allow_nil)"]

    ## File Paths
    - Create: [exact paths for new files]
    - Modify: [exact paths + what to change]

    ## Self-test (mandatory before reporting complete)
    New testable behavior → write the failing test FIRST (RED), then implement to GREEN.
    Run your spec AND static analysis (lint/typecheck), then report:
      tests_run:      <test commands>
      test_results:   <pass/fail counts>
      lint_run:       <lint commands OR "N/A — no lint config">
      lint_results:   <clean / violations OR "N/A">
      not_run_reason: <if any not run>
      known_gaps:     <edge cases not covered>
```

**Bad vs Good**

- **BAD** — `Task → agent: "Account 모델 + 마이그레이션 생성"` (schema, PK 타입, 기존 패턴 모름 → 잘못된 출력 또는 10+ 탐색 호출)
- **GOOD** — TRD schema + 기존 패턴 (mirror 할 코드) + Constraints + File Paths + Self-test 요구사항을 모두 프롬프트에 임베딩. 서브에이전트가 zero exploration 으로 정확한 출력.

## Dynamic Roles 템플릿

전문 agent 가 없을 때 `general-purpose` 로 동적 역할 생성:

```
Task tool call:
- subagent_type: general-purpose
- prompt: |
    ## Role
    You are a [DOMAIN] expert specializing in [SPECIFIC AREA].

    ## Context
    [Relevant background]

    ## Task
    [Specific deliverable expected]

    ## Output Format
    [Expected structure of response]
```

용도: backend, DevOps, security review, database design 등 전문 agent 부재 도메인.

## Phase 6 Verifier delegation 템플릿

```
Task(subagent_type: general-purpose, model: sonnet):
  "## Role
   You are a code verification specialist.

   ## Task
   Execute the verification workflow below. Confirm success criteria
   are met. Report PASS or FAIL with specifics.

   ## Verification Workflow
   [paste the project's verify-* SKILL.md content]"
```

## Execution Plan 템플릿

```markdown
## Execution Plan

**Modifiers**: [auto-skip | parallel-preferred | goal:"<criterion>" | codex-on | codex-off]
**Complexity**: Simple / Complex

### Architect Decision
- `mandatory` (Hard rule: <ownership/invariants/failure modes>) — modifier off 불가
- `on` (Effect: <영역>) — modifier 로 off 가능
- `skip` (사유: <한 줄>)

### Agents & Tools
- [ ] Agent/tool: purpose

### Execution Steps
1. Step description

### Verification

| Step | 누가 | 무엇 |
|---|---|---|
| 5a Impl | worker(s) | 코드 변경 |
| 5b Self-test | each worker | tests / lint / build 결과 + known_gaps |
| 5c Full suite | orchestrator | 풀 슈트 실행 + Anomaly Comparator |
| 5d Review | Reviewer (R1) + Codex#2 (trigger 시) + frontend-engineer (UI 청크) **병렬 분업** | orchestrator 가 통합 + fix-loop |
| 6 Sanity | 프로젝트 verify-* (있으면) | success criteria (조건부) |

→ Simple task 면 "N/A" 한 줄로 대체 가능.
→ **검증 축이 하나도 없으면** 그 사실을 여기 명시한다 (§검증 0 상태).

### Codex#1 findings
[Codex#1 raw output 인용, Phase 4 작업 결과]

### Success Criteria
- [ ] Criterion 1

**Approve to proceed.** (또는 사용자 modifier 로 단계 조정 — Hard rule 외)
```

## Skill 분류

| Type | Identifier | Behavior |
|------|-----------|----------|
| **Task Skill** | `context: fork` in frontmatter | 구조화된 workflow 포함. SKILL.md 를 읽어 Task 프롬프트에 실어 위임 |
| **Reference Skill** | `user-invocable: false` 또는 `context` 없음 | 에이전트 컨텍스트에 자동 로드. Maestro 조치 불요 |

```
Maestro needs to delegate a structured task?
├─ Project has a Task skill for it?
│   ├─ Yes → Read SKILL.md, pass in Task prompt to designated agent
│   └─ No  → Delegate to agent with clear instructions
└─ Agent needs domain rules/conventions?
    └─ Already handled via Reference skills in agent's skills: field
```
