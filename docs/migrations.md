# 버전 간 마이그레이션 기록

**Date**: 2026-08-01 (수집)
**Purpose**: 이전 버전에서 올라오는 사용자를 위한 변경 대응표. 원래 `README.md` 에 있었으나, README 는 처음 설치하는 사람을 위한 문서라 여기로 옮겼다.
**Status**: 각 절은 해당 버전 전환 시점의 기록이며 고쳐 쓰지 않는다. 현재 동작은 `rules/maestro-workflow.md` 와 `README.md` 가 정본.

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

## v4.1 → v4.5

| 변경 영역 | v4.1 | v4.5 |
|---|---|---|
| 배포 방식 | 복사 (`install.sh` + `update.sh`) | **심볼릭 링크** — 배포본이 곧 저장소 워킹트리. `update.sh` 제거, `git pull && install.sh` |
| 배포 범위 | `rules/` 5개 + `skills/` 6개 | **`rules/maestro-workflow.md` 1개 + `skills/maestro` 1개.** 코딩 규율·보안 정책·메모리 규약은 사용자 소유로 이관 |
| `rules/` 배치 | glob (`rules/*`) | **allowlist** — 나중에 같은 이름이 추가돼도 사용자 파일을 밀어내지 않음 |
| `settings.json` | 저장소가 권한·훅 모두 제시 | 훅 등록만 안내. 패키지 매니저 권한 정책은 각자의 보안 태세 |

이전 버전에서 올라온다면: `git pull` 후 `install.sh` 를 한 번 실행하면 됩니다. 복사본으로 깔려 있던 파일은 `~/.claude/.maestro-backup-<타임스탬프>/` 로 밀려나고 그 자리에 링크가 들어섭니다 — 지워지는 것은 없습니다. `rules/` 에 직접 적어둔 개인 지시가 있다면 그대로 유지됩니다.
