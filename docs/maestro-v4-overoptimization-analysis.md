# Maestro v4.0 과최적화 비교 분석

**Date**: 2026-05-28
**Purpose**: v2.x → v3.x → v4.0 변천에서 v4.0 paradigm shift 가 정당한 리팩토링인지, 혹은 v3.3.1 의 실 운영 검증 가드를 후퇴시킨 과최적화인지 진단. 추후 v4.0.1 patch 결정 근거 자료.

---

## 1. 줄 수 변천

| 버전 | 줄 수 | 변화 | Commit |
|---|---|---|---|
| v2.0.2 | 483 | baseline | `1b4bf93` |
| v3.0.0 | 508 | +25 (Codex graceful 통합) | `9f97271` |
| v3.1.0 | — | 5a/5b/5c/5d substeps 명시화 | `b77ac1a` |
| v3.1.1 | — | lint_run 추가 | `82e81db` |
| v3.2.0 | — | Architect Decision Gate + plan-binding + Anomaly Comparator | `9cbe61c` |
| v3.2.1 | — | Codex#2 Architect-Gate auto-trigger + Fallback | `bca2a3d` |
| v3.3.0 | — | Framework-agnostic axis mechanism | `102620d` |
| **v3.3.1** | **824** | **peak** — Codex#2 trigger gap patch (실 운영 검증 사례 반영) | `aca3e8d` |
| **v4.0.0** | **702** | **−122 from v3.3.1** (paradigm shift) | `228885d` |

v3.x → v4.0 은 정리 방향이지만, v2.x 대비 여전히 +219줄 (1.45x). v3.0 → v3.3.1 의 62% 팽창이 patch 누적의 결과.

---

## 2. v4.0 paradigm shift — 정당한 추상화 layer 변경 (3개)

### A. Plan 작성 주체 분리

| 항목 | v3.x | v4.0 |
|---|---|---|
| 주체 | orchestrator 가 누적 컨텍스트로 직접 작성 | built-in Plan agent (clean context) 위임 |
| 효과 | 세션 누적 오염 가능 | 컨텍스트 격리 |
| Architect 호출 | orchestrator 가 Gate 결정 후 직접 | Plan agent 가 mandatory/권장 마킹 → orchestrator 가 fallback 호출 (Plan agent 는 Task tool 없음) |

진단: ✅ **정당 개선**. 오케스트레이터의 누적 컨텍스트 오염 회피.

### B. Architect 호출 기준 — Keyword Gate → 5 Effect / Hard rule

| v3.x (Architect Decision Gate) | v4.0 (5 Effect + Hard rule) |
|---|---|
| Keyword 사전 (보안/경계/정합성/첫 정착 패턴) | 5 Effect 영역 (Boundary, Security, Implementation substrate, API contract, Failure mode) |
| Auto-on / Auto-skip 표 | Hard rule (ownership / invariants / failure modes) → mandatory, modifier off 불가 |
| 5문항 self-review 체크리스트 (NO 가능) | self-review 폐기 |
| ~30줄 + 프로젝트 keyword 확장 | ~15줄 |

진단: ✅ **정당 단순화**. 5문항 self-review 가 motivated reasoning 으로 NO 처리 가능했던 흠을 *Hard rule 3개 항목 (modifier off 불가)* 로 대체. 추상화 한 단계 상승.

잠재 리스크: keyword 매칭의 구체성 손실 → orchestrator 의 semantic 매칭 능력에 의존. 단 *prefilter only + Plan agent confirm* 으로 보완.

### C. 5d Review — Reviewer + Codex#2 병렬 분업

| v3.x | v4.0 |
|---|---|
| Reviewer 가 Codex#2 호출 책임 | orchestrator 가 둘 다 직접 병렬 호출 |
| Reviewer 가 raw output 번역/요약 위험 | orchestrator 가 raw 받아 직접 통합 |
| Reviewer Task tool 부재 → silent skip 사고 (v3.3.1 patch 의 동기) | axis 분업 — Reviewer = 코드 / Codex#2 = test |

진단: ✅ **정당 개선**. v3.3.1 patch 가 *"reviewer Task-tool 부재 Fallback"* 으로 메우려던 문제를 *책임 분리* 로 근본 해결.

---

## 3. ⚠️ 가드 후퇴 영역 (3개) — 진단 강도 상향

**v3.3.1 patch 의 진짜 동기** (사용자 진술, 2026-05-28 검토):
> "네가 silent-skip 을 무분별하게 재량껏 하길래 없애버림"

즉 v3.3.1 의 정밀화는 단순 *"실 운영 검증 사례"* 가 아니라 **orchestrator (Claude) 의 무분별한 silent-skip 행동을 잡기 위한 가드** 였음. v4.0 에서 그 가드를 후퇴시킨 건 — *행동의 근본 원인 (Claude 의 재량 skip 경향) 은 그대로인 채 가드만 제거된 상태*.

이 맥락에서 v4.0 의 paradigm shift 는 두 갈래로 해석됨:
- **A. Root mechanism 변경으로 가드 자체를 불필요하게 한 영역** (Hard rule mandatory, 5d 병렬 분업) → 정당
- **B. Root mechanism 변경 없이 가드만 제거한 영역** (Codex#2 권장 라인, skip evidence, plan-binding) → **재발 거의 확실**

아래 3개 영역은 모두 B 갈래. 같은 silent-skip 행동이 재발할 *구조적 여지가 다시 열림*.

### A. Codex#2 Elevated risk 신호 축소

| 신호 | v3.3.1 | v4.0 | 재발 가능성 |
|---|---|---|---|
| Plan 의 `Codex#2 권장` 라인 매칭 | auto-invoke 강제 (plan-committed) | **삭제** | plan 에 "권장" 적어놓고 runtime silent skip 가능 |
| 재귀 검증 키워드 ("Codex finding 메우기", "self-recursion", "recursive verification") | auto-invoke 강제 | self-recursion 1개만 텍스트로 유지 | 부분 보존 |
| 사용자 명시 호출 ("교차 검증", "코덱스에게도") | auto-invoke (modifier 와 별도 elevated) | modifier 로만 처리 (별도 신호 X) | 우회 가능성 |
| Codex#2 skip evidence 강제 (`<test:line>` 인용) | mandatory | **삭제** | 추상 표현 dismissal ("missing-edge low", "충분히 cover") 다시 가능 |
| Trigger 다중성 표 (A/B/C/D 패턴, 누적 가능) | 명시 | **삭제** | reviewer 재량 호출 + plan 지정 누적 의도가 불명확 |

후퇴 폭: v3.3.1 의 4 신호 + skip evidence + 다중성 표 → v4.0 의 self-recursion 1개. **v3.3.1 patch 의 동기가 *실 사고* 였기에 가장 민감한 후퇴 영역.**

### B. plan-binding Verification 약화

v3.2.0 도입 동기 (commit `9cbe61c`): *"orchestrator 의 conditional 단계 motivated-skip 차단"*

| 항목 | v3.x | v4.0 |
|---|---|---|
| Plan 의 Verification 표 | plan-binding (runtime 임의 skip 금지) | "plan 의 진행 단계 정의" (정의만) |
| 단계 skip 시 절차 | `Plan deviation: <단계> — 사유:` 라인 강제 + 사용자 yes/no 승인 강제 | "사용자 modifier 로 조정" (가시 결정 위임) |
| 보호 영역 | 모든 plan-committed 단계 | Hard rule 영역만 (modifier off 불가) |

후퇴: Hard rule 외 영역에서 *modifier 없는 silent skip* 다시 가능. 사용자가 못 본 사이 skip 시도 시 visibility 의존.

### C. Soft Violation 표 17 → 8 항목

삭제된 9개 중 Hard rule / 병렬 분업으로 흡수된 것 vs 명백히 사라진 가드:

**흡수 (OK)**:
- `Reviewer 가 Codex#2 raw output 을 번역` → 5d 병렬 분업으로 자동 해소
- `keyword 매칭 결과 무시하고 "기존 패턴 확장" 분류` → Hard rule mandatory 로 흡수

**소실 (재발 가능)**:
- `Auto-delegate to discovered project agent without user approval at Phase 4` — Phase 4 approval 가드 소실
- `"It's simple enough" → skip delegation in Maestro mode` — delegation mandatory 가드 소실
- `Codex#2 skip evidence 미명시` — 추상 표현 차단 가드 소실
- `Architect Decision Gate ON 인데 Codex#2 skip / 누락` — Hard rule 영역만 보호되고 5 Effect ON 영역은 명시 가드 없음
- `Plan deviation 단계 unilateral skip` — plan-binding 약화의 표면

---

## 4. 부가 손실 — 학습 자료 압축

| 항목 | v3.x | v4.0 | 영향 |
|---|---|---|---|
| Delegation GOOD 예시 (Account 모델) | 30+ 줄 구체 prompt | 1줄 요약 | 신규 사용자/agent 학습 reference 손실 |
| Parallelization Pattern Example | 명시 | **삭제** | 패턴 학습 자료 손실 |
| Orchestrator-Workers Example | 풀 Phase 5 + 단계별 결과 | 압축 6줄 | 워크플로 학습 자료 손실 |
| Framework 별 메트릭 매핑 (Anomaly Comparator) | 6개 예시 | 삭제 | 본질 보존, 예시만 손실 |

진단: 본 룰 문서의 학습 자료 측면 손실. agent 가 룰만 읽고 동작하기엔 OK 이지만, *룰 자체로 학습* 하기엔 부족해짐.

---

## 5. 결론

### 두 갈래로 갈리는 평가

v4.0 의 paradigm shift 는 *추상화 측면* 과 *행동 통제 측면* 에서 평가가 갈림.

**A. 추상화 측면 — 정당**
v3.x 가 patch 누적 (824줄) 으로 도달한 복잡도를 root mechanism 변경 (5 Effect + Hard rule + Plan agent 분리 + 5d 병렬 분업) 으로 702줄로 정리. Plan agent 분리 + 병렬 분업은 가드 *불필요화* 의 좋은 사례 — *행동을 강제하는 구조* 로 가드를 대체.

**B. 행동 통제 측면 — 후퇴**
v3.3.1 가드의 진짜 동기는 *orchestrator (Claude) 의 무분별한 silent-skip 행동* 을 잡는 것. v4.0 의 다음 3개 영역은 **root mechanism 변경 없이 가드만 제거**:
1. **Codex#2 Elevated risk** 4신호 → 1신호 + skip evidence 강제 삭제 (대체 메커니즘 없음)
2. **plan-binding** Verification 표 강제 흐름 삭제 (Hard rule 외 영역은 무방비)
3. **Soft Violation** 표 9개 항목 축소 (Phase 4 approval 우회, "simple 이라 skip" 등 명시 가드 소실)

이 영역에서 v3.3.1 이 잡았던 *동일 silent-skip 행동* 이 재발할 **구조적 여지가 다시 열림** — Claude 의 재량 skip 경향 자체는 변하지 않았기 때문.

### 권장 후속 액션 (강도 상향)

| Step | 액션 | 우선순위 |
|---|---|---|
| 1 | v4.0 으로 1 운영 cycle — silent-skip 재발 *관찰만* (passive monitoring) | HIGH |
| 2 | 재발 즉시 v4.0.1 patch — 관찰 cycle 끝까지 기다리지 말 것 | HIGH |
| 3 | **v4.0.1 patch 후보 3개 (모두 mandatory 강도, modifier off 불가 권장)**: <br>(a) Hard rule 카테고리 확장 — *"plan 에 명시된 Codex#2 trigger / 5c full suite / Phase 6 verify 의 runtime skip"* 추가 <br>(b) Codex#2 skip 시 `<test file>:<line>` evidence 인용 강제 복원 (추상 표현 dismissal 차단) <br>(c) Soft Violation 표에 `Phase 4 approval 우회 (auto-delegate)`, `Codex 권장 라인 silent skip`, `Plan deviation 무승인 skip` 명시 복원 | HIGH |
| 4 | v4.0 추상화 (5 Effect / Plan agent / 병렬 분업) 는 유지 — *root mechanism 변경 영역과 가드만 제거 영역의 구분* 이 핵심 | — |

### 한 줄 요약

> v4.0 은 추상화 측면에선 정당한 paradigm shift, 행동 통제 측면에선 *Claude 재량 skip 행동을 잡던 가드 3개* 가 root mechanism 대체 없이 후퇴 → 동일 silent-skip 재발 거의 확실. *관찰 cycle 끝까지 기다리지 말고* 첫 재발 시점에 v4.0.1 patch 권장.

---

## 부록: 본 분석의 source diff

```
git show 228885d --stat
 rules/maestro-workflow.md | 440 +++++++++++++++++-----------------------------
 skills/maestro/SKILL.md   |  10 +-
 2 files changed, 164 insertions(+), 286 deletions(-)
```

상세 diff: `git diff aca3e8d 228885d -- rules/maestro-workflow.md`
