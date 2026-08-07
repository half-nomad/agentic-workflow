# 참조 — Codex companion 호출 명령

> **언제 읽나**: 실제로 Codex 를 호출하기 직전. trigger 판정(누구를 언제 부르는가)은 `WORKFLOW.md` §Codex Integration 에 있고 그건 매 런 로드된다.

---

companion 경로는 플러그인 버전이 박혀 있으므로 glob 으로 해결한다 (업데이트 시 깨지지 않게):

```bash
CX=$(ls -d ~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs | tail -1)
```

| 용도 | 명령 |
|---|---|
| 즉답 (10~20s) | `echo "질문" \| node "$CX" task` |
| 장시간 발주 | `node "$CX" task --background --prompt-file spec.md` → job ID 즉시 반환 |
| 완료 대기 | `node "$CX" status <job-id> --wait` — 백그라운드 Bash 로 실행하면 완료 시 자동 재호출 |
| 결과 수거 | `node "$CX" result <job-id>` |
| 워크스페이스 지정 | `--cwd <dir>` — 잡 스토어도 워크스페이스 단위라 **조회할 때도 같은 `--cwd`** |
| 후속 턴 | `--resume-last` (스레드 유지) / `--fresh` (새 스레드) |

## 운영 주의

- 쓰기가 필요할 때만 `--write`. 안 주면 읽기전용이라 안전하게 떠볼 수 있다.
- 샌드박스는 cwd 워크스페이스 밖 쓰기를 막는다. 다른 디렉터리에 작업시키려면 `--cwd` 로 지정한다.
- `status --wait` 는 Bash 시간 상한에 걸릴 수 있지만 **잡은 계속 살아 있다** — 다시 걸면 이어받는다. 조기 반환하는 경우도 있어 `result` 를 체이닝하면 미완료 잡에서 실패한다 (잡 사망 아님).
- **로그 정지 ≠ 좀비.** 로그가 수십 분 안 움직여도 긴 추론 구간일 수 있다. 취소 전에 `result` 를 먼저 시도하고, 좀비 판정은 런타임 재시작 정황이 있을 때만. 좀비 판정·정리는 `/codex:status` · `/codex:cancel`.
- 병렬 호출 시 프롬프트 임시 파일은 고정 경로 대신 `mktemp` — 동시에 뜬 에이전트끼리 충돌한다.

> **호출 형태는 구속 룰이다** (`WORKFLOW.md` §Codex Integration): companion **직접 호출** + 프롬프트는 **stdin 또는 `--prompt-file`**. 서브에이전트 경유 금지, 단일 인자 `task "..."` 금지.
