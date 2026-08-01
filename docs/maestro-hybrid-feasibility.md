# Maestro × Dynamic Workflows — 하이브리드 실현 가능성 탐구

> ⚠️ **탐구 문서 — probe 전 가설과 probe 후 결론이 한 파일에 함께 남아 있습니다.** 앞부분의 suspend/restore 권장과 훅 신설 제안은 **§7·§10 의 후속 결정이 supersede 합니다** (`.suspended` 프로토콜은 폐기됐고, `verify-workflow` 훅은 빌드했다가 제거됐습니다 — `CHANGELOG.md` 참조). 앞뒤 결론이 어긋나 보이면 **뒤가 최신**입니다.
> 탐구 과정 자체가 기록이라 정리하지 않고 둡니다.

**Date**: 2026-06-06
**Purpose**: `docs/maestro-vs-dynamic-workflows.md`(Part 1 비교)의 후속. "EXECUTE를 Dynamic Workflow로 위임하는 하이브리드"가 *실질적으로* 가능한지, 어디서 깨지는지, 과최적화는 아닌지를 근거 기반 + 적대적 검증으로 진단.
**Method**: 실제 훅 소스 확인 + architect adversarial review(Codex 부재 환경 fallback).

---

## 0. 한 줄 결론

> **FEASIBLE-WITH-CONSTRAINTS** — 단, 명세된 풀 비전은 과최적화. 프로젝트 자신의 렌즈(`maestro-v4-overoptimization-analysis.md`)를 통과하는 건 **좁은 슬라이스(5a/5b를 workflow로) + rule 레벨 post-workflow 의무(항상-로드)**뿐. 그 이상은 *복잡성과 싸우는 시스템을 복잡성으로 늘리는* 자기모순. (경계 가드 훅은 빌드 후 제거 — §10)
>
> **🔬 Probe 완료 (2026-06-06)**: CRITICAL ship-blocker(workflow-agent write 차단)는 **발생하지 않음** — 실측 결과 workflow 에이전트는 일반 Task 서브에이전트처럼 `agent_id`를 보유해 maestro-guard를 정상 bypass(case B). → suspend/restore 프로토콜은 *필수 아님*(worktree diff 격리 목적의 선택지로 강등). 남은 핵심 리스크는 §1의 5c/5d 경계 silent-skip 하나로 좁혀짐.

---

## 1. 테제 재검토 — "절반만 맞다"

**원래 테제**: silent-skip은 모델 주도 제어 흐름의 *증상*이고, 코드 주도 Dynamic Workflows는 프로젝트가 가드로 근사해온 *root mechanism 교정*이다. → EXECUTE를 workflow로 옮기면 silent-skip이 구조적으로 사라진다.

**적대적 검증 결과**: 테제는 **fan-out 내부에서만 참**. 시스템 전체로는 *category error*.

| 결정 지점 | 제어 흐름 | silent-skip 가능? | 현 상태 대비 |
|---|---|---|---|
| 워크플로 진입 결정 (5a) | 모델 주도 (메인 루프) | 가능 — 모델이 호출 안 할 수 있음 | 신규 surface |
| 스크립트 내부 impl + 5b | **코드 주도** | **불가능 (구조적)** | **진짜 개선** |
| 복귀 후 5c 실행 | 모델 주도 (메인 루프) | **가능** | **악화** ↓ |
| 복귀 후 5d 실행 | 모델 주도 (메인 루프) | **가능** | 현 상태와 동일 |

**"악화" 셀이 핵심**: 현재 `verify-prompt.sh`는 모든 `Agent` 반환 시 "[VERIFY] run tests / review" 넛지를 주입한다(약하지만 *유일한 구조적 가드*). 그런데 `Workflow` 반환은 `tool_name == "Agent"`가 아니므로 — **대량 변경이 착지하는 가장 위험한 순간에 그 훅이 침묵한다**(소스 확인 완료: `verify-prompt.sh:32`). 즉 구조적 가드를 프롬프트 지시("SKILL이 5c를 명시하라")로 교체 → 과최적화 문서가 REGRESSION으로 규정한 바로 그 패턴("root mechanism 변경 없이 가드만 제거 → 재발 거의 확실").

→ **silent-skip 원장(ledger)**: 5a/5b는 FIXED(정당), 5c/5d는 RELOCATED + 경계 넛지 소실로 WORSE. **경계에 구조적 가드를 재배치하지 않으면 순효과는 음수.**

---

## 2. 브리지 메커니즘 — Maestro가 Workflow를 *합법적으로* 호출하는 경로

| 질문 | 답 | 근거 |
|---|---|---|
| Maestro가 Workflow 툴을 부를 수 있나? | 가능 | Workflow opt-in 규칙에 "skill/command instructions가 호출을 지시하면" 포함 → Maestro SKILL이 정당한 opt-in 경로 |
| maestro-guard가 막나? | **안 막음** | `maestro-guard.sh:34`는 `^(Write\|Edit\|MultiEdit)$`만 매칭. `Workflow`는 통과 (소스 확인) |
| 어디서 호출? | **메인 루프에서만** | Task 서브에이전트가 Workflow 호출 = 서브에이전트가 서브에이전트 생성 = no-nesting 위반. 오케스트레이터가 직접 호출해야 함 |
| 언제? | **승인 후 Phase 5만** | Plan Mode는 실행 금지. workflow는 실제 작업(에이전트가 파일 씀) |
| 비용 규율은? | **후보 제안 + 승인** | Workflow 툴 자체가 "scale을 추론 말고 사용자가 요청해야"라고 명시. Phase 4 승인 = 양쪽(Maestro 게이트 + Workflow opt-in)을 동시에 만족 |

→ 브리지 자체는 **깔끔하다**: Maestro의 가장 약한 지점(대규모 병렬 EXECUTE)과 Workflows의 가장 강한 지점이 정확히 맞물리고, Maestro의 승인 게이트가 Workflow의 비용/opt-in 규율 문제를 해결한다.

---

## 3. 검증된 사실 vs 미검증 가정 (값싼 테스트)

| 항목 | 상태 | 테스트 | 차단? |
|---|---|---|---|
| maestro-guard가 Workflow 툴을 통과시킴 | ✅ 확인 (소스) | — | — |
| verify-prompt이 Workflow 반환엔 안 뜸 | ✅ 확인 (소스) | — | — |
| **workflow 에이전트의 Write가 maestro-guard에 막히나** | ✅ **확인 — 안 막힘 (case B, 2026-06-06)** | 1-agent probe 완료 (아래) | 해소 |
| 완료 알림이 Maestro phase 컨텍스트로 재진입 가능한가 | ❓ 미검증 | 사소한 2-agent workflow 후 복귀 턴에 plan/phase 컨텍스트 있는지 관찰 | YES |
| `isolation:'worktree'` diff가 메인 루프 `git diff`에 보이나 | ❓ 미검증 | worktree workflow 후 메인 루프 git diff | YES |

### Ship-blocker probe (Q2 — 가장 중요)

**문제**: workflow 백그라운드 에이전트가 `impl + 5b`(=Write/Edit/Bash)를 할 때 `.agentic/maestro-mode.state`는 *여전히 존재*(삭제는 `— 작업 완료 —` 시점, `SKILL.md:21`). 만약 PreToolUse 훅이 발동하는데 stdin에 `agent_id`가 없으면 → `maestro-guard.sh:58-59` exit 2 → **모든 workflow write 차단 → 백그라운드에서 half-applied diff로 실패** (대화 스레드도 없어 복구 난해).

가능한 거동:
- **(A)** workflow 에이전트가 PreToolUse 훅을 아예 우회 → 안전
- **(B)** 훅 발동하되 `agent_id` 포함 → `maestro-guard.sh:38-39` bypass → 안전
- **(C)** 훅 발동 + `agent_id` 없음 → **전부 차단 → 실패** (비관적 기본 가정)

**값싼 probe** (실제 fan-out 금지): 단일 에이전트가 비화이트리스트 경로에 Write 1회 하는 throwaway workflow를 `.agentic/maestro-mode.state` 존재 상태에서 실행. `maestro-guard.sh` 최상단에 임시로 trace(`printf '%s\n' "$INPUT" >> …`) 추가 → (a) 훅 발동? (b) `agent_id` 존재? (c) `tool_name`? 확인. 비용 = 최소 1 에이전트 런. **이 probe가 프로젝트 전체를 게이트한다 — 하이브리드 SKILL 한 줄 쓰기 전에 먼저 실행.**

### Probe 결과 (2026-06-06 실측) — case (B), SAFE

실제 실행(Run `wf_0e13c76b-ee0`): `.agentic/maestro-mode.state` arming + 글로벌 훅 trace 계측 상태에서 1-agent workflow가 비화이트리스트 프로젝트 경로(`.wf-probe-output.tmp`)에 **Write 툴**로 쓰기 시도.

| 관측 | 값 |
|---|---|
| 훅 발동 여부 | **발동** (trace entry 1개) |
| `tool_name` | `Write` |
| `agent_id` | **존재** (`a55d3...`) → `maestro-guard.sh:38-39`에서 bypass |
| 추가 식별자 | `agent_type` 등 — 일반 Task 서브에이전트와 동일한 stdin 구조 |
| write 결과 | **성공** (MAESTRO GUARD 차단 없음) |
| 판정 | **case (B)** — workflow 에이전트 = Task 서브에이전트와 동일하게 guard 정상 통과 |

→ **CRITICAL ship-blocker 해소.** suspend/restore는 correctness용으론 불필요(worktree diff 격리를 원할 때만 선택). 계측·상태·임시물은 probe 후 전량 원복(글로벌 훅 = repo 버전 IDENTICAL 검증, 상태 disarmed).

**가장 견고한 우회 (probe 결과 무관하게 권장)**: workflow 동안 상태 파일 *비활성화*. 5a에서 오케스트레이터가 (1) `.agentic/maestro-mode.state` → `.state.suspended` 리네임, (2) `isolation:'worktree'`로 Workflow 호출(aggregate diff 격리), (3) 완료 알림 시 5c/5d 전에 상태 파일 복원. 이러면 "가드가 올바로 발동하나?"가 *무의미*해짐(가드 자체가 비무장). 복원 시점은 5c/5d를 *강제*하는 자연스러운 자리이기도 함(§1 경계 가드 필요와 결합).

리스크: 오케스트레이터가 workflow 중 크래시 → 상태 파일이 suspended로 남아 다음 메인 루프 편집이 무방비. → re-arm 훅 필요(아래 MVP).

---

## 4. 비동기 핸드오프 — 4개 파손 지점

1. **상태 파일 라이프사이클** (§3): workflow보다 오래 살아야 하는데(오케스트레이터가 5c/5d/완료 해야) workflow write는 막으면 안 됨 → suspend/restore 필수. 사용자가 알림 전 세션 이탈 시 `.suspended` 고아 → 복구 절차 문서화 필요.
2. **Phase 추적**: 백그라운드는 task id 반환 후 즉시 메인 루프 복귀 → 알림이 *여러 턴 뒤*(무관한 작업 도중) 도착 가능. phase 상태는 현재 모델 내러티브에만 존재 → **`.agentic/maestro-phase.json` 같은 파일 영속화 필요**(실 신규 기계장치). MVP에선 probe 통과 전까지 *유보 권장*.
3. **`/goal` 자율 루프 충돌 (가장 날카로움)**: `/goal` = iterate-until-criterion 동기 루프. Workflow = fire-and-forget, mid-run 입력 불가. 폴링·조향 불가 → 의미 불일치. **MVP에서 `/goal` + Workflow 조합 명시적 금지**.
4. **`— 작업 완료 —` 신호**: 알림 도착 + 5c/5d 완료까지 지연돼야 함. fix-loop가 fan-out 일부 재실행 필요 시 → 2차 workflow 대신 **plain Task로 fix** (fix는 N≥5 독립 항목이 드뭄).

---

## 5. 과최적화 점검 — "짓지 말라"는 반론 (최대 강도)

Maestro의 *문서화된 핵심 가치*는 복잡성과 모델의 재량 skip과 싸우는 것. 하이브리드는 새 제어 패러다임 + 새 opt-in surface + 비동기 핸드오프 + suspend/restore 프로토콜 + phase 영속화 + 미검증 훅 상호작용을 — *이미 저자 스스로 과최적화로 진단한* 시스템에 추가한다. **복잡성을 복잡성으로 싸우는 꼴.**

**Plain Task 위임이 엄격히 더 나은 경우**:
- 항목 <5 또는 항목 간 의존 존재 → fan-out 기계장치는 순수 오버헤드 + 비동기 세금(§4)만 지불
- mid-course 인간 조향 필요 → Workflow는 mid-run 입력 금지. *실제 `/maestro` 작업 대부분*(auth 구현, 문서 수정 등 3-file·판단 무거운·단일 도메인)이 정확히 Workflow에 *부적합한* 모양
- 교차벤더 검증이 핵심 → workflow 에이전트는 Claude 전용(§6)

**N≥5 임계는 충분조건이 아님**. 진짜 술어는 결합형: (a) ≥5 AND (b) 진짜 독립(공유 파일/순서 없음) AND (c) 완전 사전명세(항목별 판단 없음 — mid-run 입력 불가하므로) AND (d) 자기완결 검증(5b가 에이전트 내부서 실행 가능). 실무적으로 이건 **spec-from-codegen fan-out**(예: "OpenAPI 스펙에서 12개 CRUD 엔드포인트 + 각자 테스트 생성")을 가리키는 *좁은* 슬라이스. 중앙값 작업에선 절대 트리거 안 됨. **거의 안 켜지는 임계 = 투기적 기능의 강한 신호.**

**순효과 EV**: 토큰 경제학(컨텍스트 밖 상태 → 수백 에이전트)은 유일한 확실한 승리. 그러나 솔로 유저 repo-scale 작업에서 수백 에이전트가 *필요한* 경우는 드물고, 필요할 때의 실패 복구 스토리(half-applied 백그라운드 diff)가 대화 내 Task 실패보다 훨씬 무섭다. **사용자가 ≥5-독립-명세 항목 모양을 반복적으로 진짜 맞닥뜨리지 않는 한 EV는 음수.** 분기당 1회면 두 번째 제어 패러다임 유지비 > 이득.

---

## 6. 교차벤더 검증 — Codex는 workflow 밖에 머물러야

Workflow 에이전트는 Claude 전용(tier만 선택, 교차벤더 X). 스크립트 내부서 Codex 호출 불가 → 5d(Reviewer + Codex#2)는 필연적으로 메인 루프에서 aggregate diff에 대해 실행. **이게 §1의 silent-skip surface를 재도입한다** — 5d-in-main-loop는 모델 주도라 skip 가능. 완화책은 §1/§3과 동일: *workflow 후 상태 파일 복원*이 5c+5d를 강제하는 트리거가 되게 하고, `tool_name == "Workflow"`에 대한 PostToolUse 리마인더(verify-prompt 아날로그)를 re-arm. (참고: v4.0은 *이미* 이 5d-skip surface를 가짐 — 과최적화 문서 "소실—재발 가능" 목록. 하이브리드가 *생성*하진 않지만 *조용히 상속*해도 안 됨.)

---

## 7. 권장 — Minimal Viable Version

**안쪽 슬라이스만 짓고 나머지는 문서로 남긴다.**

**IN scope (MVP, 추정 1–4h)**:
1. ❌ **PostToolUse 훅 — 빌드 후 제거** (§10 후속 결정): launch 시점에만 발동(완료 hookable 불가)이라 항상-로드 rule 대비 증분 가치 ~0 + "가드처럼 보이나 아닌" false-confidence 비용. → 제거. 대신 **rule §5a의 Post-workflow Hard 의무**가 유일·명시 강제선 (always-loaded라 mistimed 훅보다 강함).
2. ~~**상태 파일 suspend/restore 프로토콜**~~ → **probe로 불필요 판명** (workflow write가 `agent_id`로 정상 bypass, §3). worktree diff 격리를 원하면 `isolation:'worktree'`만 선택적으로 사용 — 별도 프로토콜 불요.
3. **이 문서** — probe 결과 + 4개 비동기 파손 + 보수적 트리거 술어 기록.
4. **트리거 술어 (의도적으로 보수)**: pattern ∈ {Parallelization, Orchestrator-Workers} AND items ≥5 AND 독립 AND 완전 사전명세 AND `/goal` OFF 일 때만 Phase 4 *후보*(승인 게이트, never auto). 기본 OFF.

**OUT of scope (non-goal로 명시)**:
- `/goal` 하의 Workflow (의미 불일치, §4.3)
- fix-loop 내부 Workflow (fix는 plain Task)
- 승인 없는 auto-fire (양쪽 opt-in 규율 위반)
- 스크립트 내 Codex (불가능, §6)
- phase 영속화 기계장치(`maestro-phase.json`) — probe가 write 경로 작동을 증명하기 전까지 유보

**Pre-ship gate**: ✅ **통과** — §3 probe가 case (B) 반환(2026-06-06). 실제 fan-out 진행 가능.

---

## 8. 실패 모드 (심각도 순)

1. ~~**(CRITICAL)** workflow-agent write가 maestro-guard에 차단 (§3 case C)~~ → **probe로 배제됨** (case B 실측, §3, 2026-06-06). 더 이상 리스크 아님.
2. **(HIGH)** workflow 후 5c/5d silent-skip (§1) → 기존 넛지가 최고 위험 순간에 침묵. *신규 훅으로만 완화.*
3. **(HIGH)** 비동기 복귀 시 phase/state 비동기화 (§4.2) → 알림이 phase 컨텍스트 없이 도착. *영속화 또는 세션 규율 필요.*
4. **(MEDIUM)** `/goal` × fire-and-forget 불일치 (§4.3). *조합 금지로 완화.*
5. **(MEDIUM)** 크래시/이탈 시 `.suspended` 고아 (§3) → 다음 편집 무방비. *re-arm 훅으로 완화.*
6. **(LOW)** 과최적화 / 임계 거의 안 켜짐 (§5). *MVP 최소화 + OUT 명시로 완화.*

---

## 9. 최종 의견

아키텍처적 *통찰*은 진짜 좋다 — 코드 주도 실행은 프로젝트가 가드로 근사해온 진짜 root-mechanism 교정이고, 안쪽 5a/5b 슬라이스는 그걸 적용할 정당한 자리다. 그러나 *시스템*으로서의 풀 명세는 *얇고 좁은 이득*을 *넓은 신규 공격면*(비동기 핸드오프·상태 라이프사이클·미검증 훅)에 펼친다 — 사용자가 드물게 맞닥뜨리는 작업 모양을 위해.

> **15줄 훅 + suspend/restore 프로토콜 + 이 문서를 짓고, §3 probe로 게이트하고, 나머지는 OUT 리스트에 두면 — 위험의 ~10%로 가치의 ~80%를 잡는다. 그 MVP를 넘어서는 건, 프로젝트 자신의 가치 기준으로, 그것이 싸우려는 과최적화다.**

**다음 결정적 행동**: ✅ probe 완료(2026-06-06, case B). ✅ MVP 정착 — rule §5a(trigger 술어 + Post-workflow Hard 의무) + 지식 문서. 경계 훅은 빌드 후 제거(§10). 남은 선택: 실전 maestro 작업에서 1 cycle 운영 후 rule-only 강제의 실효성 관찰 → 부족하면 Stop+marker hard 가드 검토.

---

## 10. Build log (2026-06-06) — MVP 구현 완료 (옵션 B)

**구현된 것**:
- `hooks/verify-workflow.sh` + `.ps1` — PostToolUse(matcher `Workflow`), maestro-mode-gated, verify-prompt 대칭.
- repo `settings.json` + `.claude/settings.json` + 글로벌 `~/.claude/settings.json` 에 PostToolUse `Workflow` 매처 배선 (additive — 기존 설정 보존).
- 글로벌 `~/.claude/hooks/` 스크립트 배포 + `~/.claude/rules/maestro-workflow.md` 미러.
- `rules/maestro-workflow.md` §5a 에 Workflow 위임 trigger 술어(≥5 독립 사전명세 self-verifiable, `/goal` off, never auto) + **post-workflow Hard 의무** 추가.
- 단위 테스트 통과: Workflow+maestro→리마인더 / Agent→무반응 / Workflow+maestro-off→무반응. JSON 유효 + 사용자 글로벌 설정(opus/xhigh/plugins) 보존.

**구현 중 확정된 기술 사실** (claude-code-guide docs + 보유 Workflow 툴 스펙 교차):
- `PostToolUse(Workflow)` 는 **launch 시점** 발동 (툴이 즉시 task id 반환). *완료 시점 아님.*
- 백그라운드 workflow **완료를 잡는 hookable 이벤트 없음** — task-notification 이 훅 파이프라인을 우회.

**정직한 한계**: 따라서 `verify-workflow` 는 *완료 시점 hard 가드가 아니라* launch 시점에 의무를 심는 **soft 리마인더**. 완료 경계 silent-skip 을 *구조적으로* 막진 못함(그 지점이 hookable 하지 않음). 실제 강제력 = (a) rules 의 Post-workflow Hard 의무 + (b) launch 리마인더 의 조합 — 둘 다 모델 준수 의존. 완전한 hard 가드는 Stop 훅 + marker 파일(workflow 스크립트가 완료 시 marker write)이 필요하나, repo 에 Stop 훅 부재 + per-workflow 스크립트 수정 필요 → 현 시점 over-engineering 으로 판단, **defer (OUT of scope)**. 1 운영 cycle 관찰 후 재평가.

### 후속 결정 (2026-06-06, 같은 날) — verify-workflow 훅 제거

빌드 직후 손익 재평가: 훅은 **launch 시점에만 발동**(완료는 hookable 불가)이라, 항상-로드되는 rule §5a "Post-workflow Hard 의무"가 *같은 의무를 더 잘* 운반함 → 훅의 증분 가치 ~0. 게다가 "가드처럼 보이나 완료를 강제 못 하는" 장치는 프로젝트가 가장 경계하는 **false-confidence**(가짜 안심) 비용을 만듦.

→ **훅(`verify-workflow.{sh,ps1}`) + 3개 settings 배선 + 글로벌 배포 전량 제거.** 강제는 rule §5a 한 곳으로 단일화(always-loaded). 지식 문서·probe·trigger 술어는 보존.

남는 MVP = **rule §5a (trigger 술어 + Post-workflow Hard 의무) + 본 문서(지식)**. 완료 시점 hard 가드(Stop+marker)는 workflow 선택 자체가 드문 좁은 경로라 불비례 → 계속 defer. 실전 1 cycle 후 rule-only 강제로 충분한지 관찰.
