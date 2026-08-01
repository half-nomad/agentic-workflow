# Maestro Workflow — 절차 · 템플릿 · 근거 (지연 로드)

> **로딩**: `/maestro` 진입 시 **무조건** 읽는다 (compact 후 요약 잔재는 로드 증거가 아니다).
> **정본 분리**: 구속 룰 (가드 · Hard rule · 판정 기준 · 출력 계약) 의 정본은 **`~/.claude/rules/maestro-workflow.md`** (항상 로드). 이 파일은 *그 룰을 어떻게 수행하는가* — 절차 · 템플릿 · 예시 · 사고 근거 — 를 담는다.
> **충돌 시 `rules/maestro-workflow.md` 가 우선.** 이 파일에 룰을 새로 만들지 말 것.

---

## Phase 2: 패턴 선택 절차

```
Is it sequential with dependencies?
├─ Yes → Chaining
└─ No → Are tasks independent?
        ├─ Yes → Parallelization
        └─ No → Is there conditional logic?
                ├─ Yes → Routing
                └─ No → Orchestrator-Workers
```

Agent discovery 결과는 세 위치 모두 plan 의 `Agents & Tools` 에 listing — 글로벌 agent 가 시스템 프롬프트에 자동 노출돼도 명시 listing 을 강제하는 이유는 orchestrator 가 가용 agent 를 한 눈에 보게 하기 위함이다.

## Phase 3: PLAN MODE 절차

Plan Mode 진입 조건: **Phase 1 이 complex 로 판정**(파일 수정 3+ / 새 기능 / 아키텍처 변경) **또는 `goal` modifier**.

`/maestro` 호출 자체는 조건이 아니다 — simple 판정이면 `rules/maestro-workflow.md:32` 대로 EXECUTE 로 직행한다. 단 `goal` 은 complexity 무관하게 PLAN/APPROVE 를 1회 강제한다 (최초 승인을 받을 단계가 사라지지 않도록).

```
1. EnterPlanMode tool
2. orchestrator → Task → built-in Plan agent (clean context — orchestrator 의 누적 세션 컨텍스트 오염 회피)
   prompt: task description + Phase 1 prefilter 결과 (5 Effect 매칭 + Hard rule 매칭)
   Plan agent 가 plan 작성:
     - "Architect 필요 여부" 마킹 (Hard rule 매칭 시 mandatory, 5 Effect 매칭 시 권장)
     - "Codex#1 / Codex#2 활성화" 마킹 (Phase 1 complexity 결과)
     - "Reviewer 선택" 마킹 (R1 first match)
3. orchestrator 가 plan 결과 받음
4. plan 의 "Architect mandatory / 권장" 마킹 →
   orchestrator 가 직접 Architect 호출 (Plan agent 는 Task tool 없음 → orchestrator fallback)
   Architect 출력 → orchestrator 가 plan 문서에 통합
5. plan 헤더에 Architect Decision 명시
6. ExitPlanMode (user approval)
```

**Allowed in Plan Mode**: Task → Plan agent / Explore / @librarian / @architect · Read (최소) · WebSearch, WebFetch, MCP · Plan file Write/Edit · AskUserQuestion.
(Forbidden 은 rules 정본 참조 — 코드 Write/Edit, 수정성 Bash, 구현 작업.)

## Phase 4: Execution Plan 템플릿

```markdown
## Execution Plan

**Pattern**: [Selected pattern]
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
| 5d Review | Reviewer (R1) + Codex#2 (complex auto) **병렬 분업** | Reviewer = 코드 axis / Codex#2 = test axis / orchestrator = 통합 + fix-loop |
| 6 Sanity | 프로젝트 verify-* (있으면) | success criteria (조건부) |

→ Simple task 면 "N/A" 한 줄로 대체 가능.

### Codex#1 findings
[Codex#1 raw output 인용, Phase 4 작업 결과]

### Success Criteria
- [ ] Criterion 1

**Approve to proceed.** (또는 사용자 modifier 로 단계 조정 — Hard rule 외)
```

## Phase 5 절차 상세

### Axis 예시

프로젝트가 결정하는 axis 예시: `unit / type / lint / build / e2e / a11y / perf / content_schema / api_contract / security / gdpr_audit / event_schema / ...`

### 5c — framework 별 auto-detect 커맨드 (프로젝트 axes 미등록 시 fallback)

- **Ruby/Rails**: `bin/test` / `bin/rails test` (unit), `rubocop` (lint), `brakeman` (security), `srb tc` (type)
- **Node / TypeScript**: `npm test` / `pnpm test` (unit), `tsc --noEmit` (type), `eslint` (lint), `pnpm playwright test` (e2e)
- **Next.js**: 위 Node + `pnpm next build` (build verify), `pnpm lhci autorun` (perf/lighthouse, 선택)
- **Astro**: `pnpm astro build` (build), `pnpm astro check` (content_schema + type), broken-link-check
- **Python / FastAPI**: `pytest` (unit), `mypy` (type), `ruff` (lint), `bandit` (security), `schemathesis run <openapi>` (api_contract)
- **Rust**: `cargo test` (unit), `cargo clippy` (lint)
- **Go**: `go test ./...` (unit), `go vet` (lint)

CLAUDE.md · `.claude/maestro-axes.md` · README · `package.json` scripts 에 프로젝트 관례가 있으면 그쪽 우선.

### 5d — 병렬 호출 형태

```
병렬 호출 (orchestrator 가 직접):

  ┌─ Reviewer (R1 first match — project *-reviewer.md / @code-reviewer / @architect fallback)
  │    axis: 코드 품질 (구조 / 일관성 / 위험 패턴 / 가독성)
  │    input: diff + 5b worker self-test 출력
  │
  ├─ Codex#2 (complex task auto, Codex 가용 시 — mode T/A)
  │    axis: mode T = test verification / mode A = implementation attack
  │    input: mode T = test 코드 + 5b 결과 / mode A = 구현 diff + 공격 표면 목록
  │    output: run log `Codex#2 findings` 섹션에 raw 인용
  │
  └─ frontend-engineer (UI-bearing 청크만)
       axis: 시각 디자인 (실제 렌더 vs 디자인 레퍼런스)
       input: 변경 페이지 + 프로젝트 디자인 레퍼런스 (DESIGN_SYSTEM / 와이어프레임 / 기존 페이지)

orchestrator: 출력들 받아 fix-loop input 통합
```

**왜 병렬 분업인가**: Reviewer 와 Codex#2 가 다른 axis 라 책임 분리가 명확하고, Reviewer 가 Codex#2 를 invoke·번역할 책임이 없어져 (Task tool 부재 fallback 불필요) 구조가 단순해진다. orchestrator 가 raw output 을 직접 받으므로 visibility 도 자동 보장.

**시각 axis 수행 방법**: 변경 페이지를 실제 렌더 (dev 서버 + 필요 시 dev auth bypass) → 모바일(375px) + 데스크톱 뷰포트 스크린샷 (Playwright / Chrome) → 프로젝트 디자인 레퍼런스와 대조. **채점표는 `rubrics/visual-axis.md`** — 위임 프롬프트에 그 내용을 임베딩하고 V1~V8 판정 + 출력 계약대로 받는다. 디자인 레퍼런스·뷰포트 기준은 **프로젝트가 공급** — 글로벌은 메커니즘과 루브릭만 정의.

**mode A 도입 근거 (실운영 사례)**: 표준 5d 3축이 전부 PASS 한 뒤 공격형 QA 가 내부 리뷰가 놓친 실결함 2건을 회수했다 — MAJOR: 정규화된 상한값을 상태 복원 함수가 되돌리지 않아 Back/Forward 후 필터 조건이 조용히 소실 (내부 리뷰어는 같은 지점을 보고도 도달성을 오판) / MINOR: 클라이언트 저장소의 UI 선호가 단방향이라 캐시 스냅샷이 최신 선호를 덮어씀. 동시에 공격 표면 7개 중 5개는 "no finding" 으로 반환됐고 1건은 설계 근거로 기각됐다 — 가드레일 4항이 "반대를 위한 반대" 변질을 막았다는 실증.

## Phase 6 절차

```
Phase 5d fix-loop passed
    ↓
Project has verify-* skills?
├─ Yes → Delegate to dynamic verifier (sonnet):
│        Read the project's verify-* aggregator SKILL.md (e.g. verify-implementation)
│        → pass content in Task prompt
│        Verifier confirms success criteria are met
│        ├─ PASS → Done
│        └─ FAIL → Report to user
└─ No  → Basic sanity: git diff review + success criteria checklist
```

**채점표**: `rubrics/success-criteria.md` (S1~S6 + 출력 계약). verify-* 스킬이 있든 없든 이 루브릭으로 sign-off 한다.

**Verifier delegation 템플릿**:

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

## Delegation 템플릿

**왜 선행 임베딩이 토큰을 아끼는가**:
- 서브에이전트 자가 탐색: Glob/Grep/Read 5~15회 × (시스템 프롬프트 + 툴 스키마 오버헤드) = **10K+ 토큰 낭비**
- 선행 임베딩: 프롬프트에 2~5K, **탐색 0회**, 첫 시도에 정확한 출력
- 컨텍스트 부족으로 인한 wrong-pattern → 재작업 = **비용 2배**

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

**Orchestrator 책임**: ANALYZE 에서 context 수집 (TRD, 기존 코드, design docs) → EXECUTE 에서 위임 프롬프트에 임베딩. 서브에이전트가 자기 탐색하게 두지 말 것.

### Skill 분류 + 위임 판단

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

### Dynamic Roles 템플릿

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

## Codex — 부가 절차

**Fallback 담당** (미설치 / 호출 실패 — 구속 룰은 `rules/maestro-workflow.md` §Codex):

| 원래 단계 | 담당 | 방식 |
|---|---|---|
| Codex#1 (Phase 4) | @architect | plan-stage adversarial 자체 수행 |
| Codex#2 (Phase 5d) | @architect | **mode T 등가 대체만**. 프로젝트 reviewer 가 별도면 5d 안에 @architect 추가 호출 |

일시 outage → 1회 재시도 후 fallback. 사용자에게 `Codex 호출 실패 → @architect fallback` 명시.

**Escalation (auto trigger 와 별개)**:
- 같은 단계에서 위임 5회+ stuck → **Codex 에 직접 진단 조회** (읽기전용 companion 호출) 후 통합 → 그래도 막히면 blocker 보고. 사용자 개입이 필요한 건 *구현 이관* 뿐 (`/codex:rescue` 제안) — 의견 조회에 사용자를 거치지 않는다
- fix-loop max 3 초과 → @architect escalation (architect 는 자체 룰에 따라 Codex 를 self-invoke 할 수 있음)

**User-explicit invocation**: `@codex` 언급, "코덱스에게" / "코덱스 의견" / "교차 검증" / "second opinion" → 어느 phase 에서든 강제 호출.
**Exclusion**: "코덱스 없이" / "main만" → 세션 내 Codex 배제.
**Architect discretion**: `@architect` 는 고위험·모호 리뷰에서 Codex 를 **companion 직접 호출**로 self-invoke 할 수 있다 (`agents/architect.md`). 서브에이전트 중첩 금지 — 실패가 orchestrator 에 안 보여 재디스패치 Hard rule 이 발동하지 못한다.

**mode A 재디스패치 근거 (실운영 사례)**: Codex 컴패니언 런타임 재시작으로 Codex#1/#2 잡이 좀비화됐고, @architect fallback 은 test-adequacy 만 대체해 교차벤더 적대 축이 비어 있었다. 런타임 복구 후 재디스패치가 내부 리뷰가 놓친 실결함 2건을 회수했다 — 그래서 fallback 종결 전에 1회 재디스패치가 Hard rule 이 됐다. 좀비 판정·정리는 `/codex:status` · `/codex:cancel` (세션 기반 판정) 참조.

## Fable — 배경

Fable(`claude-fable-5`) = Anthropic 최상위 범용 모델. Opus 2× 비용 + safety classifier refusal (사이버보안 콘텐츠 오탐) 리스크가 있어 **설계 지점에만** 상시 상향한다 — 저볼륨이라 절대 비용이 미미하고 오판 비용이 가장 큰 지점이기 때문.

Codex(교차벤더 검증)와 직교. **적용 룰 정본 → `agents/architect.md` §Model.**

## 전체 흐름 예시

```
User: "/maestro Implement user authentication"

Phase 1 ANALYZE — complex, 5 Effect 매칭 (Security/guard, Boundary/data — Hard rule "ownership" 매칭 → Architect mandatory)
Phase 2 PATTERN — Orchestrator-Workers, project @code-reviewer 발견
Phase 3 PLAN MODE
  - Plan agent (clean context) plan 작성, Architect mandatory 마킹
  - orchestrator → @architect 호출 → 설계 통합
Phase 4 APPROVE
  - Codex#1 (complex auto) → plan adversarial → 2 edge cases finding → plan 통합
  - 사용자 승인 (Hard rule 영역이라 Architect off 불가)
Phase 5 EXECUTE
  5a. workers 병렬 (@frontend-engineer, dynamic backend role, @document-writer)
  5b. 각 worker self-test (tests / lint / build 보고)
  5c. orchestrator 풀 슈트 + Anomaly Comparator → 회귀 1건 → fix → PASS
  5d. Reviewer (@code-reviewer) 코드 axis + Codex#2 (complex auto) test axis 병렬
      → orchestrator 가 통합 → security 이슈 1 → fix → re-review PASS
Phase 6 VERIFY — verify-implementation skill → PASS
```

---

*Maestro WORKFLOW v4.3.0 (지연 로드) — 구속 룰 정본은 `rules/maestro-workflow.md`. 이 파일은 절차·템플릿·예시·근거 전용.*
