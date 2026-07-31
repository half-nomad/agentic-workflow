# Agentic Workflow - Maestro

> Plan-first orchestration for complex tasks

---

## 🚨 보안 알림 — npm 공급망 공격 대응 (2026-05-13~ 진행 중)

매 세션 진입 시 환기. 핵심:
- **호스트 직접 `npm install` / `npx <anything>` / `pnpm install` (lockfile 변경) / `pnpm add` → ❌ 사용자 승인 필수** (sudo 비슷)
- 보호 무력화 명령 (`--ignore-scripts=false`, `--foreground-scripts`, lockfile 비활성화) → ❌ 사용자 승인 필수
- 권장 셋업: 패키지 매니저 전역 `ignoreScripts` + 7일 cooldown, 셸 wrapper 로 설치 명령 confirm, 일회성 실행은 `pnpm dlx` 경유

상세 (사고 기록 / 자동 실행 정책 표 / 새 패키지 도입 검증 / 의심·사고 대응): **`rules/secure-coding.md` §Supply chain** (정본).

이 룰은 공격 종식 확인 + 사용자 명시 해제까지 유효.

---

## Activation

| Command | Mode | Behavior |
|---------|------|----------|
| `/maestro [task]` | Maestro | Plan + delegate + skill chain. 자연어로 autonomy / parallel / goal / codex 자동 분기 (modifier 표는 `skills/maestro/SKILL.md` 참조) |
| (none) | Default | Normal interaction (no orchestration, no hooks) |

> Fable 은 modifier 가 아니라 @architect frontmatter 고정 — `agents/architect.md` §Model.

> 자율 반복은 Claude Code 내장 `/goal` 사용 (별도 `/ralph` 불필요).
> Codex는 **선택적** — 미설치 환경에선 자동으로 architect 단독 흐름으로 fallback.
> Obsidian 노트 스킬은 별도 플러그인 [`my-note-skills`](https://github.com/half-nomad/my-note-skills).

> **Codex 직접 호출** (mode 무관) — 오케스트레이터가 Codex 를 부를 땐 `codex:codex-rescue` 경유가 아니라 companion 직접 호출이 정본. 호출당 ~31k tok 절감 + 실패해도 job ID 로 회수 (서브에이전트는 실패 시 침묵이 규약이고 자기 잡도 못 꺼낸다).
> 프롬프트는 **stdin 또는 `--prompt-file` 로만** — 단일 인자 `task "..."` 는 재토크나이즈로 인용부호·개행이 소실된다. 명령·경로 → `memory/reference_codex_direct_call.md`. **스킬이 호출 경로를 명시하면 그쪽이 우선** (`codex-image` 는 `--write` 기본값 때문에 서브에이전트 경유가 필수).

---

## Rules

항상 로드되는 건 **얇게**, 상세는 스킬로 내린다 (progressive disclosure). `rules/` 는 자동 로드:

| Rule (상주) | 담는 것 | 지연 로드 |
|---|---|---|
| `rules/maestro-workflow.md` | **구속 룰 정본** — 가드 · Hard rule · 판정 기준 · 출력 계약 | `skills/maestro/WORKFLOW.md` (절차·템플릿·근거). `/maestro` 진입 시 **무조건** 재읽기 — compact 시 PostCompact 훅이 재주입 |
| `rules/secure-coding.md` | Core Principles 7 + 트리거 표 + 공급망 실행 정책 | `secure-coding` 스킬 (CWE 매트릭스 · concern별 체크리스트 · 공급망 사고 배경) |
| `rules/memory-management.md` | 정본 1곳 원칙 (WHAT/WHY/HOW) + drift 경보 | `memory-management` 스킬 (cross-check 명령 · 중복 분류 · 인덱스 임계점) |
| `rules/global.md` | 모델 기본 판단으로 안 나오는 것만 — Simplicity / Surgical Changes / 커밋 스타일 | — |
| `rules/typescript.md` | 취향이 갈리는 컨벤션만 (path-conditional: `**/*.ts`, `**/*.tsx`) | — |
| `rules/personal.md` | **사용자 소유 — 이 레포가 배포하지 않는다.** 개인 훅·환경 특이사항 등 나에게만 해당하는 것 | — |

> **개인 설정은 `~/.claude/rules/personal.md` 에.** 설치·갱신은 레포가 소유한 파일만 덮어쓰고 그 외에는 손대지 않으므로, 이 파일은 재설치해도 유지된다. 전 프로젝트에 로드되니 **행동을 바꾸는 것만 짧게** 적는다 (조회성 정보는 memory 나 스킬로).
> 전역 `CLAUDE.md` 에 직접 쓸 때는 이 레포가 관리하는 블록 **바깥에** 쓴다 (파일 안의 BEGIN/END 주석 마커 참고) — 블록 안은 갱신 시 교체된다.

> **룰을 늘리기 전에**: 그게 모델이 이미 아는 것인지 먼저 따진다. 일반 코딩 상식을 다시 적으면 시스템 프롬프트와 상충 지시가 되어 오히려 품질이 떨어진다. 주기적으로 `/doctor` 로 CLAUDE.md·스킬 크기를 점검한다.

---

## State Persistence

Sessions resume via MEMORY.md `## Next Session` section (auto-loaded into system prompt):
- "계속" / "continue": Resume from Next Session context
- "새로 시작" / "new": Clear `## Next Session`, fresh start

---

## Compact Instructions

When summarizing this session during /compact, always preserve:
- Current task and its success criteria
- Architectural decisions made and their reasoning
- Files being modified and why
- Errors encountered and how they were resolved
- Which agents were delegated what work and their results
- Phase 5 substep status if mid-execution (5a impl / 5b self-test / 5c full suite / 5d review with fix-loop iteration count)
- Next steps remaining (TODO items)
- Active mode (Maestro/default)

---

*Maestro Workflow v4.5.0 — 변경 이력은 `CHANGELOG.md`.*
