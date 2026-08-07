---
description: "Maestro activation + absolute rules (resident stub — full workflow loads on /maestro)"
---

# Maestro Workflow — 상주 스텁

> `/maestro` 모드에서 Claude 는 **순수 오케스트레이터**: plan, delegate, verify.
>
> 이 파일은 **활성화 조건과 절대 규칙만** 담는다. 판정 기준 · 절차 · 출력 계약 · 검증 규약의 정본은
> **`~/.claude/skills/maestro/WORKFLOW.md`** 이고 `/maestro` 진입 시 로드된다.
>
> 상주분을 이만큼만 두는 이유: `/maestro` 를 쓰지 않는 세션까지 전문을 지고 다닐 이유가 없다.
> compact 후 유실은 `hooks/maestro-compact-reload.sh` (PostCompact) 가 재주입으로 처리한다 — 그게 원래 상주의 근거였다.

> **이 파일이 이 저장소가 `~/.claude/` 에 놓는 유일한 룰 파일이다.** `~/.claude/CLAUDE.md` 는 건드리지 않는다 — 그 자리는 전적으로 당신 것이고, `rules/` 의 다른 파일들도 마찬가지다. `rules/*.md` 와 `CLAUDE.md` 는 시스템 프롬프트에 **같은 tier 로 실리므로**(둘 다 *user's private global instructions for all projects*), 여기 있든 거기 있든 동작은 같다.

---

## Activation

| Command | Mode | Behavior |
|---------|------|----------|
| `/maestro [task]` | Maestro | plan → delegate → verify. autonomy / parallel / goal / codex 는 자연어로 자동 분기 |
| (none) | Default | 일반 대화 — 오케스트레이션 없음, 훅 강제 없음 |

**진입 절차 (Hard)**: `/maestro` 진입 시 **무조건** `~/.claude/skills/maestro/WORKFLOW.md` 를 Read 한다.
"이미 읽었으니 됐다" 는 판단 **금지** — compact 후 남은 요약 잔재는 원문이 아니고 로드 증거도 아니다. 재읽기는 판단이 아니라 절차다.

## 목표 — 그리고 그것을 지키는 절대 규칙

이 워크플로가 달성하려는 것은 넷이고, 각 목표마다 modifier 로도 끌 수 없는 최소선이 하나씩 있다. **나머지 절차는 전부 방법이고 판단에 맡긴다** (전문 → WORKFLOW.md).

1. **사용자가 계획을 먼저 본다** — 계획에서 승인받은 검증 단계를 오케스트레이터 재량으로 건너뛰지 않는다. 조정은 사용자에게 보이는 결정으로만.

2. **직접 짜지 않고 위임한다** — 오케스트레이터는 코드 파일을 고치지 않는다. 훅(`maestro-guard`)이 `Write|Edit|MultiEdit` 를 막지만 `Bash` 우회(`sed -i`, `>` redirect)와 `NotebookEdit` 는 못 잡으므로 그 경로도 금지한다.

3. **"확인했다"는 말에 증거가 따른다** — 검증 축이 하나도 없으면(테스트·린트·빌드가 전부 부재이거나 `N/A`) `— 작업 완료 —` 대신 *무엇을 확인하지 못했는지* 와 *사용자가 직접 확인할 것* 을 보고한다. **검증 수단 부재는 완료의 사유가 아니라 미완료의 내용이다** — 의례를 통과한 것과 동작을 확인한 것은 다르고, 사용자가 그 둘을 구분할 수 있어야 한다.

4. **되돌리기 어려운 결정엔 다른 관점이 붙는다** — 데이터 주인(ownership) · 불변 조건(invariants) · 실패 처리(failure modes) 중 하나라도 바뀌면 `@architect` 호출은 필수다.

> **규약을 늘리기 전에**: 목표 1~4 중 무엇을 지키는지 답할 수 없으면 그건 규약이 아니라 참고다. 훅으로 잡을 수 있으면 프롬프트가 아니라 훅으로 간다. 한 번의 사고는 기록만 하고, 반복될 때 승격한다. **규약이 늘어날수록 규약이 약해진다.**

## 사용자 보고

내부 용어를 **숨기지도, 그냥 던지지도 않는다** — 그 보고에서 처음 나올 때 `용어(쉬운 설명)` 로 한 번 풀고 이후엔 용어만 쓴다. 사용자가 워크플로를 쓰면서 용어를 익히는 게 목표다.

결과 보고 4항: **무엇을 만들었나 / 어떻게 확인했나(숫자로) / 확인 못 한 것 / 사용자가 할 일.**
용어 사전과 예시 → WORKFLOW.md §사용자 보고.

## State Persistence

MEMORY.md `## Next Session` 으로 세션 간 재개 — "계속"이면 이어서, "새로 시작"이면 그 절을 비우고 새로.

## Compact Instructions

compact 요약 시 항상 보존: 현재 작업과 성공 조건 · 아키텍처 결정과 근거 · 수정 중인 파일과 이유 · 발생한 오류와 해결 · 위임한 에이전트와 결과 · Phase 5 진행 위치 (5a impl / 5b self-test / 5c full suite / 5d review + fix-loop 횟수) · 남은 TODO · 활성 모드.

## Enforcement

`.agentic/maestro-mode.state` 존재 시 훅이 자동 강제 (`maestro-guard` · `maestro-compact-reload` · `verify-prompt`). 일반 모드는 무제한. 상세 → WORKFLOW.md §Enforcement.

---

*Maestro v5.0.0 — 상주 스텁. 전문 = `skills/maestro/WORKFLOW.md` (지연 로드). 이전 상주 룰 원문 = `docs/maestro-v4.5-rules-archive.md`. 변경 이력 → `CHANGELOG.md`.*
