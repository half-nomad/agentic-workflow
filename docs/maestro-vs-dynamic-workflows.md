# Maestro vs Claude Dynamic Workflows — 비교 분석

**Date**: 2026-06-06
**Purpose**: 우리 Maestro 워크플로우와 Claude 공식 Dynamic Workflows 기능을 1차 자료 기반으로 비교하고, 하이브리드 모델 개선 가능성의 토대를 마련.
**Status**: Part 1(비교) 확정. Part 2(하이브리드 실현 가능성)는 `docs/maestro-hybrid-feasibility.md` 참조.

---

## TL;DR

**둘은 경쟁이 아니라 서로 다른 레이어다.** 같은 뿌리(Anthropic "Building Effective Agents" 5패턴)에서 나왔지만:

- **Maestro = 모델 주도(model-driven) 오케스트레이션** — 자연어 룰 + 훅을 모델이 매 턴 해석. 대화·계획·승인·거버넌스 레이어.
- **Dynamic Workflows = 코드 주도(code-driven) 오케스트레이션** — 모델이 JS 스크립트를 한 번 작성 → 결정론적 런타임이 백그라운드 실행. 대규모 fan-out·실행 레이어.

역설적으로 **이름은 반대**다. 우리 "Workflow(Maestro)"는 Anthropic 정의상 **Agent**(모델이 매 턴 스스로 결정)에 가깝고, Claude의 "Dynamic Workflows"는 진짜 **Workflow**(미리 정해진 코드 경로)다.

→ **가장 강력한 활용은 하이브리드**: Maestro가 프론트(ANALYZE·PLAN·APPROVE·거버넌스)를 맡고, 대규모 병렬 EXECUTE는 Dynamic Workflow로 위임.

---

## 1. 최신 공식 정보 (확인된 사실, 2026-06 기준)

| 항목 | 내용 | 출처 |
|---|---|---|
| **Dynamic Workflows** | 2026-05-28 발표, research preview (Claude Code v2.1.154+). 모델이 작업마다 JS 오케스트레이션 스크립트를 동적 생성 → 결정론적 런타임이 수십~수백 서브에이전트를 백그라운드 실행 | code.claude.com/docs/en/workflows |
| **ultracode** | 별도 툴 아님. `xhigh` 추론 + 자동 workflow 계획을 결합한 설정/키워드. 켜면 substantive 작업마다 자동으로 workflow 작성 (구 트리거 `workflow` → `ultracode`) | 동일 |
| **Subagents** | `.claude/agents/*.md`, 독립 컨텍스트, 결과만 요약 반환, **서브에이전트는 다른 서브에이전트를 못 띄움(no nesting)** | docs/en/sub-agents |
| **Agent Teams** | 실험적(기본 off). 여러 세션이 직접 메시지 교환·공유 task list. 토큰 선형 증가 | docs/en/agent-teams |
| **Managed Agents** | 2026-04 베타. REST API로 Anthropic 인프라에서 에이전트 루프 실행 (Claude Code와 별개) | platform.claude.com |
| **Agent SDK** | Claude Code를 Python/TS 라이브러리로. 루프 = "gather context → take action → verify work" | docs/en/agent-sdk |
| **이론적 뿌리** | "Building Effective Agents"(2024-12): Prompt Chaining / Routing / Parallelization / Orchestrator-Workers / Evaluator-Optimizer + "Workflows vs Agents" 구분 | anthropic.com/engineering/building-effective-agents |
| **멀티에이전트 경제학** | multi-agent ≈ 단일 채팅의 **~15x 토큰**, 단일 에이전트 ~4x. "토큰 사용량만으로 성능 분산의 80% 설명" | anthropic.com/engineering/multi-agent-research-system |

> ※ 버전 번호·일부 날짜는 changelog 리서치 기반(경미한 오차 가능). primitive 스펙은 실제 보유한 `Workflow` 툴이 1차 권위 자료.

---

## 2. 같은 뿌리 — 그래서 비교가 의미 있다

`docs/maestro-summary.md`가 명시하듯 Maestro의 "4+1 패턴"은 Anthropic "Building Effective Agents"를 그대로 구현한 것이다. Dynamic Workflows도 같은 5패턴을 코드 primitive로 인코딩한다:

| Anthropic 패턴 | Maestro 구현 | Dynamic Workflows 구현 |
|---|---|---|
| Prompt Chaining | Chaining 패턴 (Phase 2) | `pipeline(items, stage1, stage2…)` |
| Routing | Routing 패턴 | JS `if/switch` 분기 |
| Parallelization | Parallelization/Swarm 패턴 | `parallel([...])` (배리어) |
| Orchestrator-Workers | 핵심 패턴 (Phase 5) | `agent()` fan-out + 합성 |
| Evaluator-Optimizer | VERIFY + 5d fix-loop(max 3) | loop-until-dry, judge panel |

→ 두 시스템은 동일한 설계 철학의 두 구현체. Maestro = *프롬프트/룰* 구현(userland), Dynamic Workflows = *런타임* 구현(kernel).

---

## 3. 핵심 비교 포인트

| 축 | Maestro (우리) | Dynamic Workflows (공식) |
|---|---|---|
| **제어 흐름** | 모델 주도 — 매 턴 모델이 다음 단계 판단 | 코드 주도 — JS 런타임이 결정론적 실행 |
| **계획이 사는 곳** | 모델 컨텍스트 창 (재추론·사용자 노출·승인) | 스크립트 변수 (컨텍스트 밖) → 토큰 절약 |
| **실행 위치** | 메인 대화 루프 (in-session) | 백그라운드 작업 (세션은 계속 응답 가능) |
| **확장 규모** | 소수 Task 위임 (컨텍스트·주의력 한계) | 수백 에이전트 (동시 16, 누적 1000) |
| **결정론/재현성** | 비결정적 — drift·silent skip 발생 가능 | 결정론적 — 같은 스크립트+args = 같은 경로, 캐시 재개 |
| **인간 개입** | Plan-first + 명시 승인 게이트(Phase 4), 대화 중 조정 | fire-and-forget, 실행 중 입력 불가(권한 프롬프트만 일시정지) |
| **구조화 출력** | 자연어 보고 (5b output contract) | JSON Schema 강제 검증 (`schema` 옵션) |
| **재개/저널** | MEMORY.md `Next Session` (거친·산문형) | 에이전트별 캐시 저널, `resumeFromRunId` (세밀·자동) |
| **검증 철학** | 5b/5c/5d + Anomaly Comparator + Codex#1/#2 | adversarial verify·judge panel·completeness critic (코드 primitive) |
| **교차 벤더 검증** | Codex(GPT-5.x) 통합 — 이종 모델 adversarial | Claude 전용 (tier만 선택: opus/sonnet/haiku) |
| **거버넌스/보안** | secure-coding 룰 + npm 공급망 가드 + maestro-guard 훅 | 구조적 가드(에이전트 캡, 스크립트 내 shell 금지)만, 도메인 정책 없음 |
| **진입 비용** | 자연어 `/maestro` — JS 불필요, 소·중 작업에 적합 | JS 스크립트 작성 필요, opt-in(`ultracode`) — 대규모에 적합 |
| **격리** | Task 서브에이전트 컨텍스트 격리 | 동일 + `isolation:'worktree'` (병렬 파일 변경 충돌 방지) |

### 가장 중요한 4가지 심층 분석

**① 계획의 위치 = 토큰 경제학 (가장 결정적 차이)**
Maestro는 오케스트레이션 상태가 매 턴 컨텍스트 창을 점유한다. 작업이 커질수록 토큰이 선형~초선형으로 늘고 결국 컨텍스트 한계에 부딪힌다. Dynamic Workflows는 중간 결과를 스크립트 변수에 두고 모델엔 최종 답만 전달 → 500 에이전트 실행이 가능한 이유. Maestro가 구조적으로 못 하는 스케일을 Workflows는 한다.

**② 결정론 — "silent skip" 문제의 근본 해결**
`docs/maestro-v4-overoptimization-analysis.md`에 기록된 핵심 고통: 모델이 검증 단계를 멋대로 건너뛰는 것("Claude의 무분별한 silent-skip"). v3.x 가드(Anomaly Comparator, soft-violation guard, maestro-guard 훅)는 전부 *모델의 재량 skip을 잡으려는 프롬프트 방어선*이다. Dynamic Workflows는 루프가 **코드**라서 silent skip이 **구조적으로 불가능**하다. 즉 우리가 룰로 싸워온 문제를 런타임이 설계로 제거한다. → Part 2의 핵심 논거.

**③ 인간 개입 — 정반대 철학**
Maestro의 정체성은 Plan-first + 승인(대화형·협업형). Dynamic Workflows는 자율 배치(실행 중 사람 못 끼어듦). 우열이 아니라 용도 차이: 되돌리기 어려운 결정·설계가 걸린 작업엔 Maestro의 게이트가 안전판, 명확히 정의된 대량 반복 작업엔 Workflows의 무인 실행이 효율.

**④ 검증 패턴의 독립적 수렴 = Maestro 설계 검증**
둘이 독립적으로 같은 검증 패턴에 도달했다. Maestro의 Codex#1/#2 adversarial + Reviewer 병렬 분업 ↔ Workflows의 adversarial verify(N skeptics)·perspective-diverse verify·judge panel·loop-until-dry. 공식 런타임이 우리와 같은 결론을 코드로 박았다는 건 Maestro 검증 설계가 옳았다는 강한 방증. 차이는 인코딩 방식뿐(자연어 룰 vs 재사용 코드 primitive).

---

## 4. 각자만의 강점

**Maestro가 가진 것 (Workflows엔 없음)**
- Plan-first + 명시적 인간 승인 게이트, 대화 중 실시간 조정
- Codex(이종 벤더) adversarial 교차 검증
- 도메인 보안·거버넌스 정책(secure-coding, npm 공급망 가드)
- 무코드 진입 — 소·중 작업에 가볍다
- 프로젝트 agent/skill 자동 발견 + 사용자 승인 기반 후보 제안

**Dynamic Workflows가 가진 것 (Maestro엔 구조적으로 없음)**
- 수백 에이전트 스케일 + 토큰 효율(컨텍스트 밖 상태)
- 결정론·재현성·세밀 재개(저널 캐시)
- 백그라운드 비동기(세션 응답 유지)
- 스키마 강제 구조화 출력
- `pipeline`(배리어 없는 스테이지)·`worktree` 격리·`budget` primitive

---

## 5. 중복/재플랫폼 후보 (Dynamic Workflows 등장으로 재검토)

Maestro는 네이티브 primitive가 없던 시절(v1.0, 2026-01)의 프롬프트 엔지니어링 해법이다. 일부는 런타임으로 옮기면 더 견고하다:

| Maestro 메커니즘 | 존재 이유 | Workflows에서의 상태 |
|---|---|---|
| maestro-guard 훅 (오케스트레이터 직접 편집 차단) | 위임 강제 | 스크립트는 애초에 fs/shell 불가 → 워크플로 내부에선 불필요 |
| Anomaly Comparator + soft-violation 가드 | silent skip 차단 | 결정론 루프 → 워크플로 내부에선 구조적으로 해소 |
| Parallelization/Swarm 패턴 | 병렬 실행 | `parallel()/pipeline()` + 자동 동시성 캡 → 네이티브 대체 |
| 5d Reviewer + Codex#2 병렬 분업 | 다축 검증 | pipeline 스테이지 + parallel verify thunk로 인코딩 가능 |

**단, 옮기면 안 되는 것**: 승인 게이트·Codex 교차검증·보안 정책·대화형 조정 — Maestro의 정체성이고 Workflows엔 없다.

---

## 6. 결론

Maestro는 "**무엇을·왜·안전하게**"(판단·거버넌스), Dynamic Workflows는 "**어떻게 대량으로·결정론적으로**"(실행). 두 시스템은 서로의 약점을 메운다 — Maestro의 약점(스케일·토큰·silent-skip)이 Workflows의 강점이고, Workflows의 약점(승인·거버넌스·교차벤더)이 Maestro의 강점.

→ 실제 하이브리드 개선 가능성·실현 경로·제약·리스크는 `docs/maestro-hybrid-feasibility.md` 참조.

---

## 출처
- code.claude.com/docs/en/workflows · /sub-agents · /agent-teams · /agent-sdk
- claude.com/blog — Introducing dynamic workflows in Claude Code (2026-05-28)
- anthropic.com/engineering/building-effective-agents (2024-12) · /multi-agent-research-system · /demystifying-evals-for-ai-agents · /effective-context-engineering-for-ai-agents
- platform.claude.com/docs/en/managed-agents
- 보유 `Workflow` 툴 스펙(primitive 1차 자료), 로컬 `rules/maestro-workflow.md` · `skills/maestro/SKILL.md` · `docs/maestro-summary.md`
