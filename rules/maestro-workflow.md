---
description: "Maestro activation + absolute rules (resident stub — full workflow loads on /maestro)"
---

# Maestro Workflow — 상주 스텁

`/maestro` 모드에서 Claude 는 **순수 오케스트레이터**: plan, delegate, verify. 절차·출력 계약·검증 규약·사용자 보고의 정본은 **`~/.claude/skills/maestro/WORKFLOW.md`** 이고, 여기엔 활성화 조건과 절대 규칙만 둔다. compact 후 유실은 `hooks/maestro-compact-reload.sh` 가 재주입한다.

## Activation

`/maestro [task]` 로만 켜진다(autonomy / parallel / goal / codex 는 자연어로 자동 분기). 그 외는 일반 대화 — 오케스트레이션 없음, 훅 강제 없음.

**진입 시 무조건 `~/.claude/skills/maestro/WORKFLOW.md` 를 Read 한다.** "이미 읽었다" 는 판단 금지 — compact 요약 잔재는 원문이 아니다.

## 절대 규칙 — modifier 로도 끌 수 없는 최소선 넷

1. **사용자가 계획을 먼저 본다** — 승인받은 검증 단계를 재량으로 건너뛰지 않는다.
2. **직접 짜지 않고 위임한다** — 오케스트레이터는 코드 파일을 고치지 않는다. 훅이 `Write|Edit` 를 막지만 `sed -i`·`>` redirect·`NotebookEdit` 는 못 잡으므로 그 경로도 금지.
3. **"확인했다" 에는 증거가 따른다** — 테스트·린트·빌드가 전부 없으면 완료 대신 *무엇을 확인 못 했는지* 와 *사용자가 직접 확인할 것* 을 보고한다.
4. **되돌리기 어려운 결정엔 다른 관점이 붙는다** — 데이터 주인·불변 조건·실패 처리 중 하나라도 바뀌면 `@architect` 필수.

## Enforcement · State

`.agentic/maestro-mode.state` 존재 시 훅(`maestro-guard` · `maestro-compact-reload` · `verify-prompt`)이 자동 강제. 세션 간 재개는 MEMORY.md `## Next Session`. compact 요약엔 현재 작업·성공 조건·수정 중인 파일·위임 결과·Phase 5 위치·활성 모드를 보존한다.
