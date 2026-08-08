# 참조 — 룰의 근거 (왜 이렇게 돼 있는가)

> **언제 읽나**: 룰을 바꾸려 할 때, 왜 이 단계가 있는지 의심될 때. 실행에는 필요 없다.
> 여기 있는 건 **근거**지 지시가 아니다. 지시는 전부 `WORKFLOW.md` 에 있다.

---

## 왜 오케스트레이터의 쓰기를 막나 (2026-08-08)

**비용 때문이 아니다** — 방향이 갈린다. 코드 한 줄 수정은 위임이 더 비싸고(컨텍스트 임베딩 + diff 재확인, 게다가 `frontend-engineer`=opus·`architect`=fable 이라 서브에이전트가 늘 싸지도 않다), 문서는 위임이 싸다(출력이 큰 일인데 `document-writer`=sonnet).

진짜 이유는 **저자와 검증자의 분리**다. 오케스트레이터가 코드를 쓰면 리뷰 지적의 수용 여부를 판단하고 완료를 선언하는 주체가 저자와 같아진다. **목표 3이 구조적으로 성립하는 근거가 이 차단**이고, 프롬프트가 아니라 훅이라 재량으로 못 뚫는다 (3문항 게이트 2번).

화이트리스트(계획서·MEMORY·CHANGELOG·런 기록)가 예외인 건 그게 오케스트레이터 자신의 산출물이라, 위임하려면 런 이력 전체를 재임베딩해야 하기 때문이다.

## mode A (구현 공격) 는 왜 생겼나 — 실운영 사례

표준 5d 3축이 전부 PASS 한 뒤 공격형 QA 가 내부 리뷰가 놓친 실결함 2건을 회수했다:

- **MAJOR**: 정규화된 상한값을 상태 복원 함수가 되돌리지 않아 Back/Forward 후 필터 조건이 조용히 소실. 내부 리뷰어는 **같은 지점을 보고도 도달성을 오판**했다.
- **MINOR**: 클라이언트 저장소의 UI 선호가 단방향이라 캐시 스냅샷이 최신 선호를 덮어씀.

동시에 공격 표면 7개 중 5개는 `no finding` 으로 반환됐고 1건은 설계 근거로 기각됐다 — **가드레일 4항이 "반대를 위한 반대" 변질을 막았다는 실증**이다. 공격형 리뷰는 가드레일 없이 켜면 노이즈 생성기가 된다.

## mode A 재디스패치가 Hard rule 인 이유 — 실운영 사례

Codex 컴패니언 런타임 재시작으로 Codex#1/#2 잡이 좀비화됐다. @architect fallback 은 test-adequacy(mode T)만 대체하므로 **교차벤더 적대 축이 비어 있는 채로 종결될 뻔했다.** 런타임 복구 후 재디스패치가 내부 리뷰가 놓친 실결함 2건을 회수했다.

그래서 **fallback 종결 전 1회 재디스패치**가 Hard rule 이 됐다. 조용한 fallback 은 경고이지 검증이 아니다.

## Codex 를 서브에이전트로 부르지 않는 이유 — A/B 실측

| | 서브에이전트 경유 | companion 직접 호출 |
|---|---|---|
| 품질 | 동등 | 동등 |
| 비용 | 호출당 ~31k tok 추가 | 기준 |
| 실패 시 | **침묵이 규약** — 자기 잡도 못 꺼낸다 | job ID 로 회수 가능 |
| 프롬프트 | `normalizeArgv` 재토크나이즈로 인용부호·개행 소실 | stdin/`--prompt-file` 로 보존 |

실패가 orchestrator 에 안 보이면 **재디스패치 Hard rule 이 발동하지 못한다** — 이게 중첩 금지의 진짜 이유다. 비용은 부차적이다.

## @architect 가 Fable 인 이유

`claude-fable-5` = Anthropic 최상위 범용 모델. Opus 2× 비용 + safety classifier refusal(사이버보안 콘텐츠 오탐) 리스크가 있어 **설계 지점에만** 상시 상향한다 — 저볼륨이라 절대 비용이 미미하고 오판 비용이 가장 큰 지점이기 때문. Codex(교차벤더 검증)와 직교한다.

적용 룰 정본 → `agents/architect.md` §Model.

## Codex trigger 를 조건화한 이유 (2026-08-07)

이전 규약은 complex 판정만으로 Codex 를 런당 2회 자동 호출했다. 실적이 확인된 축은 mode A(구현 공격)였고, 루틴 청크의 mode T 는 5d Reviewer 와 중복이었다. 조건화로 루틴 complex 런의 호출이 2회 → 0회가 되고, 오판 비용이 큰 지점(Hard rule 영역 · 되돌리기 어려운 변경 · mode A 대상)은 그대로 유지된다.

## 왜 5d 를 병렬 분업으로 바꿨나

v3.x 에서는 Reviewer 가 Codex#2 를 invoke 할 책임을 졌는데, **Reviewer(서브에이전트)에게는 Task tool 이 없어서** 호출이 조용히 누락되는 사고가 있었다. 그리고 Reviewer 가 Codex raw output 을 번역·요약하면서 정보가 깎였다.

orchestrator 가 둘 다 직접 병렬 호출하면 책임이 분리되고(Reviewer = 코드 축 / Codex#2 = test 또는 공격 축), raw output 을 직접 받으므로 visibility 가 자동 보장된다.

## 왜 Plan 을 별도 에이전트에 맡기나

orchestrator 는 세션이 길어질수록 컨텍스트가 누적 오염된다. built-in Plan agent 는 clean context 에서 시작하므로 앞선 시행착오·기각된 접근에 끌려가지 않는다.

단 Plan agent 에게는 Task tool 이 없다 — 그래서 Architect 호출은 orchestrator 가 fallback 으로 직접 한다.

## 전체 흐름 예시

```
User: "/maestro Implement user authentication"

Phase 1 ANALYZE — complex, 5 Effect 매칭 (Security/guard, Boundary/data — Hard rule "ownership" 매칭 → Architect mandatory)
Phase 2 스캔 — project @code-reviewer 발견
Phase 3 PLAN MODE
  - Plan agent (clean context) plan 작성, Architect mandatory 마킹
  - orchestrator → @architect 호출 → 설계 통합
Phase 4 APPROVE
  - Codex#1 (Architect mandatory 영역이므로 auto) → plan adversarial → 2 edge cases → plan 통합
  - 사용자 승인 (Hard rule 영역이라 Architect off 불가)
Phase 5 EXECUTE
  5a. workers 병렬 (@frontend-engineer, dynamic backend role, @document-writer)
  5b. 각 worker self-test (tests / lint / build 보고)
  5c. orchestrator 풀 슈트 + Anomaly Comparator → 회귀 1건 → fix → PASS
  5d. Reviewer (@code-reviewer) 코드 axis + Codex#2 mode A (세션/상태 로직이라 해당) 병렬
      → orchestrator 가 통합 → security 이슈 1 → fix → re-review PASS
Phase 6 VERIFY — verify-implementation skill → PASS
사용자 보고 — "로그인/회원가입이 됩니다 / 테스트 58개 통과 · 화면 폰·PC 확인 / 비밀번호 재설정은 이번 범위 밖입니다"
`.agentic/maestro-runs.md` 에 런 기록 1줄 append
```
