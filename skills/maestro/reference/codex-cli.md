# 참조 — Codex CLI 호출 명령 (유일한 정본)

> **언제 읽나**: 실제로 Codex 를 호출하기 직전. **언제·누가 부르는가는 부르는 쪽 워크플로가 정한다** (maestro `WORKFLOW.md` §Codex Integration · duet `SKILL.md` §관문). 이 파일은 *어떻게* 만 갖는다 — 다른 문서는 명령을 복제하지 않고 여기를 가리킨다. 사본이 여럿이면 한쪽만 고쳐진다.

**2026-09-28 부터 CLI 직접 호출만 쓴다.** openai-codex 플러그인(companion `codex-companion.mjs` · `codex:codex-rescue` 서브에이전트 · `/codex:*` 명령)은 쓰지 않는다 — 플러그인이 빠지자 그 경로를 고정해 둔 문서들이 빈 경로로 멈췄다.

---

| 용도 | 명령 |
|---|---|
| 읽기 전용 검토 (기본) | `codex exec -s read-only -C <repo> -o <result.md> - < prompt.md > <log> 2>&1` |
| 쓰기가 필요한 일 (변형 검사 등) | `-s workspace-write -C <격리 worktree>` — 이 CLI 에는 `--full-auto` 가 없다 |
| 완료 대기 | 위 명령을 **백그라운드 Bash** 로 실행 → 끝나면 자동 재호출. 폴링하지 않는다 |
| 세션 id | **자기 실행 로그** 머리의 `session id: <uuid>` — 보고에 `codex resume <uuid>` 로 한 줄 남긴다. 로그를 남기지 않았다고 `~/.codex/sessions` 의 최근 파일에서 고르지 않는다 — 동시에 도는 다른 세션의 id 를 집는다 |
| 같은 스레드 후속 | `codex exec resume <uuid> - < followup.md` (지적 해결 확인 등) |

## 구속 규칙

- **프롬프트는 stdin(`-`)으로만 넘긴다.** 인자 하나로 넘기면 인용부호·개행이 깨질 수 있다 (companion 시절 실측. CLI 에서도 같은지는 재지 않았다 — 안전한 쪽으로 고정).
- **서브에이전트를 거치지 않고 직접 부른다.** 경유하면 실패가 침묵돼 복구 규정이 발동하지 못한다.
- 프롬프트 임시 파일은 `mktemp` 로 — 고정 경로는 동시에 뜬 세션끼리 충돌한다.

## 운영 주의

- 기본은 `-s read-only`. 쓰기가 필요하면 **격리 worktree 를 `-C` 로** 주고 `-s workspace-write` — 사용자 작업 트리에 쓰기 권한을 주지 않는다.
- `-o` 파일은 마지막 메시지만 담는다. 중간 명령·추론은 로그에 있다.
- **로그 정지 ≠ 멈춤.** 수십 분 안 움직여도 긴 추론 구간일 수 있다. 프로세스가 살아 있으면 기다린다.
- 모델·추론 강도는 `~/.codex/config.toml` 기본값을 쓴다. 바꿀 땐 `-m <model>` · `-c model_reasoning_effort=<level>`.
