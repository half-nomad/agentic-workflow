<!-- AUTO-SYNCED from CLAUDE.md — edit CLAUDE.md, not this file. (hooks/claude-md-sync) -->
<!-- Also read ~/.claude/rules/*.md (maestro-workflow.md ships with this repo; the rest are the user's) and apply those rules identically when working here. -->

# Agentic Workflow - Maestro

> Plan-first orchestration for complex tasks

---

## Activation

| Command | Mode | Behavior |
|---------|------|----------|
| `/maestro [task]` | Maestro | Plan + delegate + skill chain. 자연어로 autonomy / parallel / goal / codex 자동 분기 (modifier 표는 `skills/maestro/SKILL.md` 참조) |
| (none) | Default | Normal interaction (no orchestration, no hooks) |

> Fable 은 modifier 가 아니라 @architect frontmatter 고정 — `agents/architect.md` §Model.

> 자율 반복은 Claude Code 내장 `/goal` 사용 (별도 `/ralph` 불필요).
> Codex는 **선택적** — 미설치 환경에선 자동으로 architect 단독 흐름으로 fallback.

> **Codex 직접 호출** (mode 무관) — 오케스트레이터가 Codex 를 부를 땐 `codex:codex-rescue` 경유가 아니라 companion 직접 호출이 정본. 호출당 ~31k tok 절감 + 실패해도 job ID 로 회수 (서브에이전트는 실패 시 침묵이 규약이고 자기 잡도 못 꺼낸다).
> 프롬프트는 **stdin 또는 `--prompt-file` 로만** — 단일 인자 `task "..."` 는 재토크나이즈로 인용부호·개행이 소실된다. 명령·경로 → `skills/maestro/WORKFLOW.md` §Codex. **스킬이 호출 경로를 명시하면 그쪽이 우선** (예: 서브에이전트의 `--write` 기본값에 의존하는 스킬은 직접 호출로 바꾸면 조용히 실패한다).

---

## Rules

이 레포는 룰을 **하나만** 배포한다. `~/.claude/rules/` 의 나머지 파일은 전부 당신 것이며, install·update·uninstall 이 건드리지 않는다.

| Rule (상주) | 담는 것 | 지연 로드 |
|---|---|---|
| `rules/maestro-workflow.md` | **구속 룰 정본** — 가드 · Hard rule · 판정 기준 · 출력 계약 | `skills/maestro/WORKFLOW.md` (절차·템플릿·근거). `/maestro` 진입 시 **무조건** 재읽기 — compact 시 PostCompact 훅이 재주입 |

> **개인 전역 지시는 `~/.claude/rules/` 아무 파일에나.** `rules/` 는 전부 자동 로드되고 로딩은 소유권과 무관하다. 인스톨러는 위 한 파일만 배치하므로 나머지는 재설치해도 유지된다. 전 프로젝트에 로드되니 **행동을 바꾸는 것만 짧게** 적는다 (조회성 정보는 memory 나 스킬로).
>
> ⚠️ **`~/.claude/CLAUDE.md` 에는 개인 메모를 쓰지 마라.** 그건 이 레포 `CLAUDE.md` 로의 심볼릭 링크이고 관리 블록이 없다 — **거기 쓰면 레포 워킹트리가 수정된다.** 내가 안 한 변경이 `git status` 에 뜨고, 모르고 push 하면 개인 메모가 **공개된다.** 설치 시 그 자리에 실제 파일이 있었다면 다른 경로와 같은 규칙으로 `.maestro-backup-<타임스탬프>/` 로 밀려난다 (지워지지 않는다).
>
> ⚠️ **이 레포의 워킹트리가 곧 라이브 설정이다.** 심볼릭 링크 배포라 복사 시절의 완충이 없다 — 이 레포에서 `rules/maestro-workflow.md` 나 `hooks/` 를 고치거나, 브랜치를 갈아타거나, `stash`·`reset --hard` 를 하면 **전역 룰과 가드 훅이 그 즉시 바뀐다.** 실행 중인 모든 세션·모든 프로젝트에서. 실험용 브랜치는 별도 클론(또는 worktree)에서, 브랜치 전환 후에는 `install.sh` 재실행으로 추가·삭제된 파일을 다시 링크한다.
> 설치 스크립트를 고칠 때는 **실제 `$HOME` 에 대고 실행하지 마라** — 가짜 `$HOME` 으로 테스트한다 (`HOME=/tmp/fake ./install.sh`).

> **왜 하나뿐인가**: 이 레포는 *maestro 라는 오케스트레이션 워크플로우* 를 배포한다. 코딩 규율·보안 정책·메모리 규약처럼 상시 적용되는 것은 사용자마다 다르고 시한부인 경우도 있어 배포 대상이 아니다 — 각자의 `rules/` 에 둔다.

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
