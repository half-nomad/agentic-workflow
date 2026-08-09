# 참조 — 알려진 실패 모드 (과거에 실제로 났던 것)

> **언제 읽나**: 검증 단계를 건너뛰고 싶어질 때, 리뷰 결과를 기각하려 할 때, 완료를 선언하기 직전에 뭔가 걸릴 때.
> **이건 지시가 아니라 병력(病歷)이다.** 과거 특정 시점의 모델이 실제로 저질렀던 것들이고, 지금도 유효한지는 측정 중이다 (§발동 기록).
>
> **왜 매 런 로드하지 않나**: 이 표들은 v3.x 시절 *"재량껏 silent-skip 하길래 없애버림"* 이라는 관찰에서 나왔다. 그 관찰의 대상 모델은 지금 모델이 아니다. 매 런 주입하면 표가 일을 하는지 알 수 없으므로, **주입을 멈추고 재발 여부를 관찰한다.** 재발하면 되돌린다.

---

## Soft Violation — 훅이 못 잡는 판단 오류

| Soft Violation | Correct Action |
|----------------|----------------|
| Plan says @agent → execute directly without Task tool | Always delegate via Task tool |
| Call project agent without its Task Skill workflow | Read SKILL.md → include in Task prompt |
| Accumulate all context → do everything yourself | Delegate to manage context window |
| Worker reports complete without `tests / lint / build` results | Request re-run with self-test; `N/A — <reason>` only when genuinely inapplicable |
| Skip full suite on complex task | Always run full suite after workers complete |
| fix-loop runs 4+ iterations without escalating | Stop at 3, escalate to @architect, then to user |
| Hard rule 영역 (ownership/invariants/failure modes) 에서 Architect 호출 skip | mandatory — modifier off 불가 |
| mode A 대상 청크에서 Codex 실패(좀비화 포함)를 fallback 으로 silent 종결 | 런타임 복구 확인 후 1회 재디스패치 — 실패 시 fallback 종결 + run log 명시 |
| anomaly 를 추상 표현 ("메타 변동" / "parallel 카운팅") 으로 dismiss | default = investigate. accept 시 수치 + root cause 명시 |
| Codex 를 `codex:codex-rescue` 서브에이전트로 위임 (또는 서브에이전트 안에서 중첩 호출) | companion 직접 호출 — 중첩은 실패를 은폐한다 |
| Reviewer miss 정황을 로그 없이 넘김 | `5d reviewer miss:` 한 줄 기록 |
| `/maestro` 진입 시 WORKFLOW.md 재읽기를 "이미 읽었다" 로 건너뜀 | 무조건 재읽기 — 요약 잔재는 로드 증거가 아니다 |
| 검증 축이 하나도 없는데 완료 선언 | 무엇을 확인 못 했는지 + 사용자가 직접 확인할 것을 보고 |

## Rationalization — 이 변명이 떠오르면 그 자체가 신호

| 변명 | 반박 |
|---|---|
| "simple task 니까 풀 스위트는 생략해도 돼" | 생략 조건은 (a) single-file edit (b) 테스트 스위트 부재 — 둘뿐 |
| "이 count delta 는 메타 변동 / 카운팅 차이일 거야" | default = investigate. 수치 + root cause 필수 |
| "워커가 잘했을 테니 self-test 보고 없이 넘어가자" | 출력 계약 없는 완료 보고는 검증이 아니다 |
| "이번 건 Codex 가 별 의미 없을 듯" | trigger 는 한 곳에서 이미 결정됐다. 조정은 사용자 modifier 로만 |
| "공격형 리뷰어가 뭔가 찾아왔으니 다 고쳐야 해" | 재현 게이트 통과 finding 만 fix 대상. 기각 사유는 로그에 |
| "리뷰 2사이클 연속 발견 0건 = 코드가 깨끗하다" | doubt-theater 신호. 각도를 바꾸거나 종료 근거를 명시 |
| "plan 에 적었지만 상황이 바뀌었으니 단계 조정은 내 재량" | 단계 조정은 사용자 가시 결정으로만 |
| "요약에 남아 있으니 WORKFLOW.md 다시 안 읽어도 돼" | 요약 잔재 ≠ 원문 |
| "테스트가 없는 프로젝트니 이 정도면 완료라고 해도 돼" | 검증 수단 부재는 완료의 사유가 아니라 미완료의 내용이다 |

> 두 표는 1인칭(변명)/3인칭(위반)으로 프레이밍이 다르고, 그 차이가 곧 기능이었다 (2026-07-29 병합 기각 — architect·Codex·본세션 3자).

---

## 관찰 중 — 반복되지만 아직 규약이 아닌 것

실운영 6런의 `놓친 것` 열 교차 분석(2026-08-08)에서 나온 패턴. **한 번 더 반복되면 `WORKFLOW.md` 강제 규약으로 승격한다.**

| 패턴 | 빈도 | 실제 사례 |
|---|---|---|
| **자기가 만든 검증 수단이 틀렸다** | 2/6런 | 대비 측정 스크립트가 반투명 배경을 불투명으로 읽고 `oklch` 를 파싱 못 해 **없는 결함을 보고할 뻔** · TODO "120자" 규칙의 검사 명령이 바이트를 세서 한국어는 실제 40자 제한이었다 |
| **조사가 규칙의 한쪽 면만 덮는다** | 3/6런 | "Sand 를 글씨로 쓰는 것"만 찾고 "Sand 위에 글씨를 얹는 것"은 안 찾음 · grep 출력이 20줄에서 잘린 걸 모르고 전수로 읽음 · `dependent: :destroy` 를 "무엇을 함께 지우나"로만 읽고 "무엇을 막고 있었나"로는 안 읽음 |

**적용할 것 (규약은 아니고 참고)**: 규칙을 만들면 *그 검증 수단이 규칙과 같은 것을 재는지* 확인한다. 조사할 때는 *규칙의 반대 방향*도 검색어에 넣고, 출력이 잘렸는지 본다.

---

## 발동 기록 — 이 표들이 실제로 일을 하는가

**측정 대상은 "재발이 없었다" 가 아니라 "이 표가 나를 붙잡은 적이 있는가" 다.** 전자는 표가 없어도 참일 수 있어 아무것도 증명하지 못한다.

`.agentic/maestro-runs.md` 에 런당 한 줄 (`WORKFLOW.md` §기록 참조). 이 표와 관련해 적을 것:

- **표가 붙잡은 것** — 이 문서를 읽고 판단을 되돌린 경우. **되돌린 그 순간에** 적는다 (완료 후 회상하면 놓친다). 해당 없으면 `없음`
- **사용자가 잡은 것** — 여기 없어서 놓친 것. 표의 커버리지 구멍이자 가장 값진 데이터

**정직 조항**: `없음` 이 정상이고 기대되는 값이다. **표가 없었으면 다르게 행동했을 경우만** 발동이다 — "표를 봐서 제대로 했다" 는 발동이 아니다. 부풀린 기록은 측정을 무의미하게 만든다.

**판정**:

| 누적 관찰 | 결론 |
|---|---|
| 10런에 발동 0건 | 두 표 삭제 — 아무것도 하지 않고 있다 |
| 특정 항목만 반복 발동 | 그 항목만 `WORKFLOW.md` 강제 규약으로 승격, 나머지 삭제 |
| `사용자가 잡은 것` 발생 | 해당 상황을 표에 추가하고, 반복되면 강제 규약으로 승격 |
