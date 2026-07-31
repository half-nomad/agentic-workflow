# Memory Management Rules

> auto-memory 가 파일 생성 · frontmatter · MEMORY.md 인덱싱을 자동 처리한다. 이 룰은 그게 **커버하지 않는 것** — 정본 위치 판단과 중복/drift 방지 — 만 담는다.
> 절차 (cross-check 명령, 중복 분류표, promotion/demotion, 인덱스 임계점) → **`memory-management` 스킬**.

## 정본 1곳 — WHAT / WHY / HOW 분리

| 위치 | 역할 | 예시 |
|---|---|---|
| `CLAUDE.md` / `rules/` | **WHAT** — generic rule (누구에게나 적용 가능) | "시크릿은 평문 X, env vars / secret manager" |
| `memory/feedback_*` | **WHY** — 사용자 specific 이유 / 사고 / 결정 | "<날짜> 토큰 노출 사고 → transcript 룰 도입" |
| `memory/reference_*` | **HOW** — 사용자 시스템 specific 구현 | "OS 키체인 + MCP wrapper 스크립트 + pnpm dlx" |

세 위치에 같은 정보가 들어가면 안 된다. **정본 1곳, 나머지는 link** (`see rules/<file>.md § <섹션>` 또는 `[[memory-name]]`).

## Drift 경보 (rules/ ↔ skills/ 복제)

`rules/` 또는 `SKILL.md` 를 고칠 때, 같은 룰이 양쪽에 inline 복제돼 있는지 확인한다. 한쪽만 갱신하면 다른 쪽이 옛 룰을 주입하는 **silent drift** 가 난다 (실제 사례: `Project Agent Discovery` 가 `rules/maestro-workflow.md` 와 `skills/maestro/SKILL.md` 양쪽에 박혀 있던 건 — 2026-05-26). 발견 시 한쪽을 link 로 압축한다.

## 적용

새 memory 작성 / 새 rule 추가 / SKILL.md 수정 / MEMORY.md 정리 시 binding. 상세 절차가 필요하면 `memory-management` 스킬을 로드한다.
