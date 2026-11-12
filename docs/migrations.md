# 버전 간 마이그레이션 기록

**Date**: 2026-08-01 (수집)
**Purpose**: 이전 버전에서 올라오는 사용자를 위한 변경 대응표. 원래 `README.md` 에 있었으나, README 는 처음 설치하는 사람을 위한 문서라 여기로 옮겼다.
**Status**: 각 절은 해당 버전 전환 시점의 기록이며 고쳐 쓰지 않는다. 현재 동작은 `skills/duo/SKILL.md` 와 `README.md` 가 정본 (maestro 는 v6.0.0 에서 은퇴 — 태그 `maestro-final`).

---

## v2.x → v3.0

| 이전 (v2.x) | 신규 (v3.0) |
|---|---|
| `/ultrawork [task]` | `/maestro [task] ... 맡길게` (또는 `... autonomous`) |
| `/swarm [task]` | `/maestro [task] ... 병렬로` (또는 `... 동시에`) |
| `/ralph start` | `/maestro [task] ... 완료될 때까지` (내장 `/goal` 자동 활성화) |
| `/ralph cancel` | `/goal` 자체 명령으로 해제 (이전 `.agentic/ralph-loop.state.md`는 더 이상 사용 X) |

자율 반복 backend가 모델 self-judge(`/ralph`) → 독립 fast model 검증(`/goal`)으로 바뀌어 false completion 위험이 줄었습니다.

## v3.0 → v3.1

| 변경 영역 | v3.0 | v3.1 |
|---|---|---|
| 테스트 실행 | 암묵적 (Phase 6 fallback 한 줄) | **5b worker self-test + 5c orchestrator full suite** (first-class) |
| Worker output | 자유 형식 | **output contract** (`tests_run` / `results` / `not_run_reason` / `known_gaps`) 필수 |
| Post-impl review | `@architect` 강제 | **project reviewer R1 우선** (자동 발견), `@architect` fallback |
| Fix-loop | 무제한 | **max 3** + `@architect` escalation |
| Project agents | 글로벌 4개만 인지 | **`.claude/agents/*.md` 자동 발견** (session-once cache, surface-only) |
| Codex 자동 trigger | 2개 (사용자 발화 / stuck 5+) | **1개** (Plan adversarial). 나머지는 user-explicit / review-internal / stuck 5+ escalation |
| Plan template | Verification 행 없음 | **5a~5d + Phase 6 명시 5행** |
| Phase 6 VERIFY | 테스트 실행 포함 가능 | narrow: **최종 sanity sign-off 만** (`verify-*` 있으면 위임) |

호환성: v3.0 에 작성된 plan / agent / skill 은 그대로 동작. v3.1 는 추가 가시화 + 누락 방어 layer.

## v3.1 → v4.1

| 변경 영역 | v3.1 | v4.0 / v4.1 |
|---|---|---|
| Plan 작성 | orchestrator 직접 (누적 컨텍스트) | **built-in Plan agent 분리** (clean context) |
| Architect 호출 | Decision Gate (keyword + 5문항 self-review) | **5 Effect prefilter + Hard rule** (ownership/invariants/failure modes → mandatory, modifier off 불가) |
| 5d review | reviewer → 재량 Codex#2 invoke | **Reviewer (코드 axis) + Codex#2 (test axis) 병렬 분업**, orchestrator 가 통합 |
| Codex auto-trigger | 1개 (Codex#1 plan adversarial) | **2개** (Codex#1 + Codex#2, complex auto) |
| 검증 단위 | test / lint 고정 | **framework-agnostic axis** (프로젝트 opt-in) + 5c Anomaly Comparator |
| 대규모 병렬 EXECUTE | Task 위임만 | **Dynamic Workflows 위임 후보** (≥5 독립·사전명세, research-preview) |

상세 근거: `maestro-v4-overoptimization-analysis.md` (v4.0 진단) + `maestro-hybrid-feasibility.md` (v4.1 하이브리드).

## v4.5 → v5.0

**설치 절차는 바뀌지 않습니다.** `git pull && ./install.sh` 로 끝나고, 배포되는 경로도 그대로입니다(`rules/maestro-workflow.md` 1개 + `skills/maestro` 1개 + 에이전트 4 + 훅 4). 바뀐 건 **그 안의 구조**입니다.

| 변경 영역 | v4.5 | v5.0 |
|---|---|---|
| 판정 기준 | 없었음 — 사고가 날 때마다 지시 추가 | **목표 4개 명시.** 이 넷이 곧 모든 규약의 판정 기준 |
| `rules/maestro-workflow.md` | 348줄 구속 룰 전량 상주 | **~60줄 스텁** — 목표 4개 + 그것을 지키는 절대 규칙 |
| 절차·판정표·템플릿 | 구속 룰로 상주 | **`skills/maestro/reference/` 6개 — 지시가 아니라 참고.** 목표를 만족하면 다른 방법을 써도 된다 |
| 두 훈계 표 | 매 런 주입 | 참조로 이동 — **삭제가 아니라 주입 중단.** 재발 여부를 관찰해 존치/삭제/승격을 결정 |
| 교차검증(Codex) | complex 면 자동 2회 | **계획은 기본 on / 구현은 표적** (공유 컴포넌트·클라이언트 상태·요청 간 상태·Hard rule 인접·절차와 다르게 판단한 런) |
| 매 런 로드량 | 35,447자 | **13,274자** (−62.6%) |

**왜 바꿨나**: 이 워크플로는 사고가 날 때마다 지시를 추가해 v4.5에 이르렀습니다. 안정성은 얻었지만 그 대가로 성능을 제한했습니다 — 지시가 늘수록 개별 지시의 구속력이 떨어지고, 모델이 더 나은 방법을 알아도 절차가 막습니다. 그래서 판정 기준을 *"이 지시가 있으면 더 안전한가"*(답이 거의 항상 yes 라 무한히 쌓입니다)에서 **"이 지시가 없으면 목표가 깨지는가"** 로 바꿨습니다.

**내려간 것은 지워지지 않았습니다.** 5 Effect 표 · Phase 절차 · mode T/A · Anomaly Comparator 절차 · 위임 템플릿은 전부 `reference/` 에 원문 그대로 있고, `/maestro` 중에 필요하면 읽습니다. v4.5 상주 룰 원문 전체도 [`maestro-v4.5-rules-archive.md`](maestro-v4.5-rules-archive.md) 에 되돌리는 방법과 함께 보존돼 있습니다.

**새로 생기는 파일**: 첫 `/maestro` 런에서 프로젝트에 `.agentic/maestro-runs.md` 가 만들어집니다 — 런당 `다르게 한 것 / 그래서 나았나 / 놓친 것` 한 줄이 쌓입니다. `놓친 것` 이 반복되는 지점은 참고에서 강제로 승격하고, `다르게 한 것` 이 반복해서 나은 지점은 참고 자체를 고치는 근거가 됩니다.

## v4.1 → v4.5

| 변경 영역 | v4.1 | v4.5 |
|---|---|---|
| 배포 방식 | 복사 (`install.sh` + `update.sh`) | **심볼릭 링크** — 배포본이 곧 저장소 워킹트리. `update.sh` 제거, `git pull && install.sh` |
| 배포 범위 | `rules/` 5개 + `skills/` 6개 | **`rules/maestro-workflow.md` 1개 + `skills/maestro` 1개.** 코딩 규율·보안 정책·메모리 규약은 사용자 소유로 이관 |
| **`~/.claude/CLAUDE.md`** | 저장소가 덮어씀 (마커 블록으로 병합) | **건드리지 않음.** Maestro 규약은 룰 파일로 배포 — `rules/*.md` 와 `CLAUDE.md` 는 같은 tier 라 동작이 같다 |
| **`~/.codex/AGENTS.md`** | 저장소가 배포 | **건드리지 않음.** 필요하면 한 줄 직접 추가 (README §Codex) |
| `rules/` 배치 | glob (`rules/*`) | **allowlist** — 나중에 같은 이름이 추가돼도 사용자 파일을 밀어내지 않음 |
| `settings.json` | 저장소가 권한·훅 모두 제시 | 훅 등록만 안내. 패키지 매니저 권한 정책은 각자의 보안 태세 |

**`CLAUDE.md` 를 덮어쓰지 않게 된 이유**가 이 릴리스에서 가장 큰 단순화입니다. 덮어쓰기 때문에 사용자 내용을 지키려 마커 블록 병합이 필요했고, 그게 두 언어 152줄이었으며, 그걸 걷어내자 *"개인 지시는 `rules/personal.md` 에"* 라는 별도 관리 대상이 생겼습니다 — **전부 "덮어쓴다"는 한 선택의 파생**이었습니다. 룰 파일은 여러 개가 그냥 공존하므로 병합할 것이 애초에 없습니다.

**이전 설치에서 올라온다면**: `~/.claude/CLAUDE.md` 와 `~/.codex/AGENTS.md` 가 이 저장소를 가리키는 링크(또는 복사본)로 남아 있을 수 있습니다. 새 `install.sh` 는 그 경로를 더 이상 관리하지 않으므로 자동으로 정리되지 않습니다 — 직접 지우면 그 자리가 여러분에게 돌아옵니다.

```bash
# 이 저장소를 가리키고 있을 때만 지운다
readlink ~/.claude/CLAUDE.md ~/.codex/AGENTS.md   # 확인 후
rm -f ~/.claude/CLAUDE.md ~/.codex/AGENTS.md
```

이전 버전에서 올라온다면: `git pull` 후 `install.sh` 를 한 번 실행하면 됩니다. 복사본으로 깔려 있던 파일은 `~/.claude/.maestro-backup-<타임스탬프>/` 로 밀려나고 그 자리에 링크가 들어섭니다 — 지워지는 것은 없습니다. `rules/` 에 직접 적어둔 개인 지시가 있다면 그대로 유지됩니다.

### 복사 시절에 깔렸지만 지금은 배포하지 않는 것

위 문단은 *같은 자리에 링크가 들어서면서 밀려나는* 파일 얘기입니다. 그런데 **더 이상 배포하지 않는 파일은 새 `install.sh` 가 아예 방문하지 않으므로 밀려나지도 않고 그대로 남습니다.** v4.1 이하에서 설치했다면 `~/.claude/` 에 아래가 복사본으로 있을 수 있습니다:

```
rules/global.md  rules/secure-coding.md  rules/memory-management.md  rules/typescript.md
skills/secure-coding/  skills/memory-management/
skills/codex-image/  skills/session-summary/  skills/multi-worktree-safety/
```

**그대로 두셔도 됩니다** — 이제 그 자리는 여러분 것이고, 룰은 소유자와 무관하게 로드되므로 계속 동작합니다. 저장소가 갱신해 주지 않을 뿐입니다. 원치 않으면 지우면 되고, 계속 쓰고 싶으면 손대지 마세요.

또 v4.1 이하의 인스톨러가 만들던 관리 파일 두 개가 남아 있을 수 있습니다. 현재 스크립트는 이 이름을 **읽지도 쓰지도 않으므로 스스로 사라지지 않습니다** — 안심하고 지우면 됩니다:

```bash
rm -f ~/.claude/.agentic-workflow-source ~/.claude/.agentic-workflow-manifest
```

## v5.4 → v5.5 (2026-09-28)

**업그레이드**: `git pull && ./install.sh` (Windows 는 `git pull` 후 `install.ps1`). **설치 계약이 바뀐다** — `~/.claude/rules/` 로 아무것도 배포하지 않는다.

| 이전 (v5.4) | 신규 (v5.5) |
|---|---|
| `rules/maestro-workflow.md` 상주 스텁 — 매 세션 로드 | 삭제. 절대 규칙 넷은 `skills/maestro/SKILL.md` 맨 위. 스킬은 `disable-model-invocation` 이라 설명문도 컨텍스트에 안 실리고 `/maestro` 로만 켜진다 |
| 에이전트 4개 | `architect` 하나. frontend-engineer · librarian · document-writer 은퇴 — 역할은 general-purpose 에 담아 부른다 |
| `permission-mode:` 프런트매터 | 삭제. 공식 필드명이 `permissionMode` 라 처음부터 조용히 무시되고 있었다(동작 불변) |
| compact 재주입 훅을 `PostCompact` 에 등록 | **`SessionStart` + matcher `compact`** 로 등록. PostCompact 는 컨텍스트를 넣지 못하는 이벤트라(공식 문서) 옛 등록으로는 재주입이 모델에 닿지 않는다 |

**재설치가 무엇을 치우고 무엇을 남기나** — 은퇴한 경로 4개(`rules/maestro-workflow.md`, `agents/` 3개) 기준:

| 설치 상태 | 재설치 결과 | 할 일 |
|---|---|---|
| macOS/Linux, 이 체크아웃을 가리키는 링크 | 끊긴 링크로 제거, `removed dangling …` 출력 | 없음 |
| macOS/Linux, 링크가 일반 파일로 바뀐 경우(rename 저장 에디터) 또는 다른 체크아웃을 가리키는 링크 | 지우지 않고 `NOTE: … is no longer shipped` 출력 — 지문이 없어 사용자 파일과 구별할 수 없다 | 이 저장소에서 온 것이면 직접 삭제 (예: `rm ~/.claude/rules/maestro-workflow.md`) |
| Windows, 설치 때 그대로인 사본 | 백업 폴더로 이동, `RETIRED: … -> <backup>` 출력 | 없음 |
| Windows, 수정한 사본 또는 지문 없는 구형 manifest | 그대로 두고 `RETIRED: … kept in place` 출력 | 확인 후 직접 삭제 |

**훅 등록은 손으로 옮긴다** — `settings.json` 은 어떤 스크립트도 쓰지 않는다. `hooks` 의 `PostCompact` 항목 중 `maestro-compact-reload` 를 부르는 것을 지우고, README §훅 등록의 `SessionStart` 블록(matcher `compact`)을 이어붙인다. 옮기지 않아도 오류는 없다 — 새 스크립트는 `source` 가 `compact` 가 아니면 조용히 끝나므로 옛 등록 아래선 아무것도 하지 않는다(옛 등록으로는 원래도 효과가 없었다).

남은 옛 룰은 매 세션 "상주 스텁" 을 자처하며 로드되고, 새 SKILL.md 는 상주 룰이 없다고 말한다 — 두 진술이 충돌하므로 알림이 나오면 지우는 것이 맞다.

## duet → duo (2026-11-10)

| 이전 | 이후 |
|---|---|
| `/duet [task]` · `skills/duet/` | `/duo [task]` · `skills/duo/` |
| 런 기록 `.agentic/duet-runs.md` | 그대로 — 기존 기록과 이어 쓴다 |

`git pull` 뒤 `./install.sh`(Windows 는 `install.ps1`)를 다시 실행한다. 옛 `~/.claude/skills/duet` 은 위 v5.4 → v5.5 표와 같은 방식으로 치워진다(macOS/Linux 는 끊긴 링크 제거, Windows 는 그대로인 사본을 백업 폴더로). 개인 룰이나 CLAUDE.md 에 `/duet` 을 적어 두었다면 `/duo` 로 고친다.

## 런 기록 파일 이름 (2026-11-12)

| 이전 | 이후 |
|---|---|
| `.agentic/duet-runs.md` | `.agentic/duo-runs.md` |

각 프로젝트에서 `mv .agentic/duet-runs.md .agentic/duo-runs.md`. 안 옮겨도 duo 가 다음 런에서 옛 파일을 보고 이름을 바꿔 이어 쓴다. 위 duet → duo 표의 "그대로" 는 그 시점의 결정이다.

## v5.5 → v6.0 (2026-11-10) — maestro 은퇴

| 이전 | 이후 |
|---|---|
| `/maestro [task]` · `skills/maestro/` | 없음 — duo(`/duo`)가 기본이자 유일한 워크플로 |
| 훅 `maestro-guard` · `verify-prompt` · `maestro-compact-reload` (`.sh` · `.ps1`) | 없음 — `claude-md-sync` 하나만 남고 등록은 선택 |
| 코덱스 명령 정본 `skills/maestro/reference/codex-cli.md` | `skills/duo/reference/codex-cli.md` |
| `tests/hooktest.sh` | 없음 (시험 대상 훅이 모두 은퇴) |

**순서가 중요하다 — 훅 등록을 먼저 지운다.** v5.5 의 compact 훅 이전과 달리, 이번에는 스크립트 자체가 사라진다. `settings.json` 에 등록이 남은 채 `git pull` 하면 등록된 명령이 없는 파일을 부르게 되어(종료 코드 127) 매칭되는 도구 호출 — 파일 편집 · 서브에이전트 호출 · compact — 마다 훅 오류가 난다.

1. `~/.claude/settings.json` 의 `hooks` 에서 `command` 에 `maestro-guard` · `verify-prompt` · `maestro-compact-reload` 가 들어간 **항목만** 지운다. 같은 matcher 아래 다른 훅이 있으면 그 훅은 남긴다. 비어버린 배열은 함께 지운다. 프로젝트 `.claude/settings.json` 에 같은 등록을 해 두었다면 거기서도 지운다.
2. `git pull` 후 `./install.sh`(Windows 는 `install.ps1`).
3. 열려 있는 Claude Code 세션을 모두 재시작한다 — 세션이 시작할 때 읽은 훅 등록을 계속 쓸 수 있다.
4. 개인 스킬·에이전트·CLAUDE.md 가 `skills/maestro/reference/codex-cli.md` 를 가리키고 있으면 `skills/duo/reference/codex-cli.md` 로 고친다. `/maestro` 를 언급하는 개인 지시도 정리한다.

**재설치가 무엇을 치우나** — v5.4 → v5.5 표와 같은 규칙이다: macOS/Linux 에서 이 체크아웃을 가리키는 링크는 끊긴 링크로 제거되고, 일반 파일로 바뀌었거나 다른 체크아웃을 가리키는 것은 지우지 않고 `NOTE: … (retired in v6.0.0)` 로 알린다. Windows 는 설치 때 그대로인 사본을 백업 폴더로 옮기고, 수정한 사본은 남기고 알린다.

**되살리는 법** — 마지막 상태는 git 태그 `maestro-final` 이다.

1. `git checkout maestro-final -- skills/maestro hooks/maestro-guard.sh hooks/maestro-guard.ps1 hooks/maestro-compact-reload.sh hooks/maestro-compact-reload.ps1 hooks/verify-prompt.sh hooks/verify-prompt.ps1 tests/hooktest.sh`
2. `skills/maestro/reference/codex-cli.md` 는 복원하지 말거나 복원 후 지운다 — 정본은 `skills/duo/reference/codex-cli.md` 하나로 둔다. maestro 문서가 옛 경로를 가리키면 새 경로로 고친다.
3. `agents/architect.md` 의 maestro 전용 줄(Phase 3 설계 위임 · Phase 5d 리뷰 대체 · fix-loop escalation)은 `git diff maestro-final -- agents/architect.md` 를 보고 필요한 것만 되돌린다.
4. `git show maestro-final:settings.json` 의 `hooks` 에서 세 훅의 등록 블록**만** `~/.claude/settings.json` 에 이어붙인다 — 파일을 통째로 덮어쓰면 그 뒤의 개인 변경까지 되돌아간다.
5. `./install.sh` 후 Claude Code 재시작.
