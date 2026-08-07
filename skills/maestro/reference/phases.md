# 참조 — Phase 절차 상세

> **이건 지시가 아니라 방법의 한 가지다.** `WORKFLOW.md` 의 강제 규약을 만족한다면 다른 방법을 써도 된다 — 다르게 했으면 무엇을 왜 다르게 했는지 한 줄 기록한다 (`WORKFLOW.md` §기록).
> **언제 읽나**: 판정이 애매할 때, 이 워크플로가 처음일 때, 특정 단계의 원래 설계를 확인할 때.

---

## Phase 1 — Architect prefilter: 5 Effect 영역

Hard rule 3개(ownership / invariants / failure modes)는 `WORKFLOW.md` 에서 강제된다. 아래는 그보다 넓은 **권장** 영역 — 매칭되면 Architect 를 부르는 쪽이 대체로 낫다는 경험칙이고, 사용자 modifier 로 끌 수 있다.

| # | Effect 영역 | 매칭 신호 |
|---|---|---|
| 1 | **Boundary / state / data redesign** | cross-namespace, multi-tenant, schema 변경, migration, 백필, race, 정합성, state ownership 변경 |
| 2 | **Security / guard / permission** | auth, scope, 권한, OAuth, CSRF, CSP, XSS, SSRF, sanitize, password hashing, 인증, 가드, 회귀 방어선 |
| 3 | **Implementation substrate choice** | 새 framework / library 도입, tech 선택, 첫 helper / module / service / utility 도입, convention 정착 |
| 4 | **API contract / interface change** | API contract, OpenAPI 변경, public method signature, schema 변경 (interface 측), client/server 경계 |
| 5 | **Failure mode / recovery / observability** | failure mode, recovery, idempotency, retry, observability 추가, logging 표준 |

매칭 keyword 가 있어도 *코드 파일 변경이 없으면* (md / TODO / CHANGELOG only) 무효화. 프로젝트 도메인 용어는 프로젝트 CLAUDE.md 또는 `.claude/maestro-keywords.md` 에서 합집합 scan.

plan 헤더 표기: `Architect: mandatory (Hard rule: <...>)` / `on (Effect: <...>)` / `skip (사유: <한 줄>)`.

## Phase 2 — 에이전트 · 스킬 스캔

세 위치를 모두 scan (session-once cache, CWD 변경 시 재scan):
`~/.claude/agents/*.md` (global) · `.claude/agents/*.md` (project) · `agents/*.md` (정본 repo 내).

1. 세 위치 모두 plan 에 listing — 글로벌이 시스템 프롬프트에 자동 노출돼도 명시 listing. orchestrator 가 가용 agent 를 한 눈에 보게 하기 위함
2. **Domain match preempts global** — project `@code-reviewer` > `@architect` (post-impl review), `@<x>-engineer` > generic worker
3. **Do not auto-delegate** — 사용자 승인 후
4. Skill candidates 도 `[skill candidate] /skill-name` 로 plan 에 제안

> 실행 형태(순차/병렬)에는 이름을 붙이지 않는다. 의존이 있으면 순차, 없으면 병렬 — 위임 계획을 짜면 자연히 결정된다.

## Phase 3 — PLAN MODE 절차

```
1. EnterPlanMode tool
2. orchestrator → Task → built-in Plan agent (clean context — 누적 세션 컨텍스트 오염 회피)
   prompt: task description + Phase 1 prefilter 결과 (5 Effect 매칭 + Hard rule 매칭)
   Plan agent 가 plan 작성:
     - "Architect 필요 여부" 마킹 (Hard rule 매칭 시 mandatory, 5 Effect 매칭 시 권장)
     - "Codex 활성화" 마킹
     - "Reviewer 선택" 마킹 (R1 first match)
3. orchestrator 가 plan 결과 받음
4. plan 의 Architect 마킹 → orchestrator 가 직접 Architect 호출
   (Plan agent 는 Task tool 이 없어 스스로 부르지 못한다 → orchestrator fallback)
   Architect 출력 → plan 문서에 통합
5. plan 헤더에 Architect Decision 명시
6. ExitPlanMode (user approval)
```

**Allowed in Plan Mode**: Task → Plan agent / Explore / @librarian / @architect · Read (최소) · WebSearch, WebFetch, MCP · Plan file Write/Edit · AskUserQuestion.
**Forbidden**: 코드 파일 Write/Edit, 수정성 Bash, 구현 작업.

## Phase 5 — 실행 substep

### 5a. Implementation

Worker delegation via Task tool, context-embedded prompt (`reference/delegation.md`).

**Workflow 위임 게이트** (research-preview, opt-in) — **독립 항목의 병렬 실행**이고 다음을 모두 만족할 때만 `[workflow candidate]` 제안 (never auto-fire): 항목 ≥ 5 AND 항목 간 독립 · 완전 사전명세 · 자기완결 검증 · `/goal` OFF. 승인 시 orchestrator 가 **메인 루프에서 직접** Workflow 호출 (Task 경유 금지 — no-nesting).

**Post-workflow (중요)**: workflow 완료는 hookable 하지 않다. 완료 notification 수신 시 orchestrator 가 풀 스위트 + 리뷰를 메인 루프에서 실행한 뒤 완료 선언. 항목 < 5 이거나 의존/판단이 섞이면 plain Task 위임이 엄격히 우월 — workflow 금지.

### 5b. Worker Self-Test — 출력 계약

```
tests:     <axis 결과 — e.g., "42/42 PASS" / "0 errors" / "build successful">
lint:      <axis 결과 — OR "N/A">
build:     <axis 결과 — OR "N/A">
[추가 axis 등록 시]:  <project-defined axes 결과>
known_gaps: <edge cases / 미커버 시나리오>
```

적용 불가 axis 는 `N/A — <reason>`.

### 5c. Full Suite Run

**Anomaly Comparator** — 기계적 비교, axis-agnostic:

| 비교 항목 | 정상 | ANOMALY |
|---|---|---|
| count delta (각 axis) | `baseline + 워커 신규 수` 와 일치 | 일치 안 함 |
| failure + error count | 0 (required axis) | 0 초과 |
| 보조 메트릭 (axis 제공 시) | baseline 동일 또는 개선 (rename/refactor 제외) | 회귀 |

ANOMALY → default = investigate (stash-baseline 직접 측정 / 신규 file verbose 실행). accept 하려면:

```
anomaly: <delta 구체 수치> — <root cause 한 줄>
response: accept — 사유: <구체 근거>
```

baseline **출처도 명시** (commit message 메타는 stale 가능 → 의심되면 stash 직접 측정).

**생략 조건**: (a) simple task, single-file edit (b) 테스트 스위트 부재 — (b) 는 `WORKFLOW.md` §검증 0 상태를 함께 적용.

### 5d. Post-Implementation Review — 병렬 분업

| 검증자 | axis | 선택 |
|---|---|---|
| Reviewer | 코드 품질 (구조 / 일관성 / 위험 패턴 / 가독성) | R1 first match — project `*-reviewer.md` → `@code-reviewer` → `@architect` fallback |
| Codex#2 | mode T = test verification / mode A = implementation attack | trigger → `WORKFLOW.md` §교차검증 |
| frontend-engineer | 시각 디자인 (실제 렌더 vs 디자인 레퍼런스) | UI-bearing 청크만 |

```
  ┌─ Reviewer          input: diff + worker self-test 출력
  ├─ Codex#2           input: mode T = test 코드 + 결과 / mode A = 구현 diff + 공격 표면 목록
  └─ frontend-engineer input: 변경 페이지 + 디자인 레퍼런스

orchestrator: raw output 을 직접 받아 fix-loop input 으로 통합
```

**왜 병렬 분업인가**: Reviewer 가 Codex 를 invoke·번역할 책임이 없어져 구조가 단순해지고, orchestrator 가 raw output 을 직접 받으므로 visibility 가 자동 보장된다. (v3.x 사고 배경 → `reference/rationale.md`)

**mode A 선택 기준** (하나라도 해당): 공유 파셜/공용 컴포넌트 변경 · 클라이언트 상태 로직 (JS 상태 머신) · 요청 간 상태 이동 (URL·localStorage·캐시·스냅샷) · Hard rule 인접 영역 · **이 런에서 절차와 다르게 판단한 것이 있을 때**. 그 외 루틴 청크는 mode T.

> 계획 단계 교차검증은 complex 면 **기본 on** 이다 (끄는 경우 3가지 → `WORKFLOW.md` §교차검증). 구현 쪽만 위 기준으로 표적 선택한다.

**공격형 가드레일 4항 (mode A 프롬프트 규약)** — "반대를 위한 반대" 변질 방지:

1. finding 마다 **file:line 근거 + 재현(도달) 경로** — 없으면 채택 불가
2. 공격 표면별 **"no finding" 명시가 허용·기대되는 출력**임을 프롬프트에 선언
3. **수용 전 검증 게이트**: 공격자 출력은 fix-loop *input* 일 뿐 — 재현(또는 e2e/시각 축 재검)으로 확인한 finding 만 fix 위임
4. **심각도 정직**: NIT/스타일 부풀리기 금지 — 심각도 상향 시 이유를 로그에

**시각 axis**: `app/views/**` · Stimulus 컨트롤러 · CSS/디자인 토큰 변경 시에만 (백엔드/모델/test-only 비대상). 변경 페이지를 실제 렌더 → 모바일(375px) + 데스크톱 스크린샷 → 디자인 레퍼런스와 대조. **채점표는 `rubrics/visual-axis.md`** — 위임 프롬프트에 임베딩하고 V1~V8 출력 계약대로 받는다.
**"토큰을 올바르게 썼는가"(코드 축) ≠ "제대로 보이는가"(시각 축)** — code-reviewer PASS 가 시각 PASS 를 의미하지 않는다.

**Fix-loop**: issue → 구현 agent 에 fix 위임 → 재검증. **Max 3** → 초과 시 @architect escalation → 사용자 blocker 보고.

**Reviewer miss 기록**: Reviewer PASS 이후 다른 축(풀 스위트·시각·사용자)이 결함을 발견했거나 Codex 단독 발견 finding 이 있으면 `5d reviewer miss: <놓친 것>` 한 줄.

## Phase 6 — VERIFY (조건부)

테스트는 5b/5c 에서 이미 끝났다. Phase 6 는 **success criteria sign-off** 전용. 채점표 = `rubrics/success-criteria.md` (S1~S6 + 출력 계약).

| Condition | Run VERIFY |
|-----------|:----------:|
| Project has `verify-*` skills | Yes |
| 2+ agents, 3+ files | Yes |
| User explicitly requests | Yes |
| `approval skip` modifier + complex task | Yes |
| Otherwise | No |

verify-* 스킬이 있으면 그 SKILL.md 내용을 Task 프롬프트에 임베딩해 `general-purpose`(sonnet)에 위임 — 템플릿 → `reference/delegation.md`. 없으면 `git diff` 리뷰 + success criteria 체크리스트.

## Codex — 교차검증 상세

### mode 와 fallback

- **mode T (test-adequacy)**: spec 적정성 / missing edges / boundary 매트릭스
- **mode A (implementation-attack)**: 구현 diff 직접 공격 — orchestrator 가 공격 표면 목록을 명시해 프롬프트에 임베딩

**Fallback**: 미설치·호출 실패 시 @architect 가 대체 — 단 **mode T 등가 대체일 뿐**이고 교차벤더 적대 축(mode A)은 **미충족**으로 남는다.

| 원래 단계 | 담당 | 방식 |
|---|---|---|
| Codex#1 (plan 적대) | @architect | plan-stage adversarial 자체 수행 |
| Codex#2 (구현 검증) | @architect | mode T 등가 대체만. 프로젝트 reviewer 가 별도면 @architect 추가 호출 |

**mode A 대상 청크에서 Codex 실패(좀비화 포함) 시** fallback 즉시 종결 금지: 런타임 복구 확인 후 **1회 재디스패치**, 그래도 실패면 `codex mode A 미수행 (재디스패치 실패) — fallback 종결` 명시. 일시 outage → 1회 재시도 후 fallback. (근거 → `reference/rationale.md`)

### Escalation

- 같은 단계에서 위임 5회+ stuck → **Codex 에 직접 진단 조회** (읽기전용) 후 통합 → 그래도 막히면 blocker 보고. 사용자 개입이 필요한 건 *구현 이관* 뿐 (`/codex:rescue` 제안)
- fix-loop max 3 초과 → @architect escalation (architect 는 Codex 를 self-invoke 할 수 있음 — companion 직접 호출, 서브에이전트 중첩 금지)

### 사용자 배제 ≠ 호출 실패

재디스패치 규정은 *Codex 에 도달하려다 실패한* 경우의 복구이지, 사용자가 안 쓰기로 한 경우를 실패로 재분류하지 않는다. 배제 시엔 @architect 가 mode T 를 대체하고 mode A 는 미충족으로 남는다 (로그에 명시).
