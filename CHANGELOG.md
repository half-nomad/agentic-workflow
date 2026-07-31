# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added — Codex 직접 호출 규약 (mode 무관)
- **`CLAUDE.md` §Activation 에 2줄 신설** — 오케스트레이터가 Codex 를 부를 땐 `codex:codex-rescue` 서브에이전트 경유가 아니라 companion 직접 호출이 정본. 기존 Codex 규정이 전부 maestro 스코프(`rules/maestro-workflow.md` §Codex Integration · `skills/maestro/WORKFLOW.md` §Codex)라 **일반 대화에서의 호출은 정본이 아예 없었다** — 그 공백을 메운다.
- **근거 (2026-07-30 A/B 실측)** — 동일 프롬프트·동일 작업(프론트 단일 HTML · 백엔드 무의존 Node `http`)으로 두 경로 비교: **품질 동등**(양쪽 7/7, 백엔드는 서버 기동 후 6개 엔드포인트 curl 로 독립 검증) · **비용 ~30배**(네이티브 `subagent_tokens` 31~32k/회 vs 직접 ~1k) · **워크스페이스 고정**(서브에이전트는 `--cwd` 미전달로 세션 레포 밖 작업 불가 — 시도 시 30,890 tok 소모 후 DENIED·산출물 0) · **실패 시 침묵**(`agents/codex-rescue.md` 가 *"If the Bash call fails or Codex cannot be invoked, return nothing"* 을 규약으로 두고 `status`/`result` 호출도 금지 — 복잡 작업에서 응답이 끊긴 채 사용자가 수동 폴링해야 했던 원인).
- **프롬프트 전달은 stdin 또는 `--prompt-file` 로만** — `codex-companion.mjs` 의 `normalizeArgv` 가 argv 1개일 때 `splitRawArgumentString` 으로 재토크나이즈해 **개행→공백 · 인용부호 삭제**가 일어난다 (5개 런 전부 이 규칙에 일치, 재현 확인). maestro Codex#2 mode A 의 공격형 가드레일 4항은 축자 도달이 작동 조건이라, 이 훼손이 곧 가드 무력화다.
- **HOW/WHY 는 memory 로 분리** — `reference_codex_direct_call.md`(명령·경로) · `feedback_codex_transport.md`(실측 근거). `rules/memory-management.md` 의 WHAT/WHY/HOW 3분할에 맞춰 `CLAUDE.md` 에는 규약 2줄만 상주시킨다.

- **`rules/maestro-workflow.md` §Codex Integration 에 `**호출 형태 (Hard)**` 1줄 신설** — Codex#1/#2 도 stdin/`--prompt-file` 로 넘긴다. 구속 룰 정본이라 사용자 승인 후 반영.

### Changed — 중첩 위임 제거 (maestro 경량화)
- **`agents/architect.md` §Codex Second Opinion — 서브에이전트 중첩 → companion 직접 호출** — @architect 가 `Agent(subagent_type: "codex:codex-rescue")` 로 self-invoke 하던 경로를 Bash 직접 호출로 교체. **재량은 그대로 유지**하면서 (a) 호출당 ~31k tok 제거 (b) **중첩 침묵 해소** — 2단계 위임이라 Codex 실패가 orchestrator 에 보이지 않아 *"mode A 실패 시 1회 재디스패치"* Hard rule 이 구조적으로 발동할 수 없던 문제. `skills/maestro/WORKFLOW.md` §Codex 의 Architect discretion 줄도 동반 수정.
- **`CLAUDE.md` 규약에 스킬 우선 예외 1절** — 스킬이 호출 경로를 명시하면 그쪽이 우선. `codex-image` 는 서브에이전트의 `--write` 기본값에 의존하며, 직접 호출로 바꾸면 생성 파일이 `$CODEX_HOME/generated_images/` 밖으로 이동하지 못해 **조용히 실패**한다.
- **죽은 분기 정리 — `reviewer 가 Task tool 미보유` 계열 3곳** — Codex#2 가 orchestrator 직접 호출로 정의된 이상 reviewer 가 Codex#2 를 invoke 할 전제 자체가 없다. `WORKFLOW.md:126` 은 v4.0 병렬 분업 설계 시점부터 이미 *"Task tool 부재 fallback 불필요"* 라고 선언했는데 `rules` 두 곳과 `WORKFLOW.md` Fallback 표가 그 fallback 을 계속 들고 있었다. **Soft Violation 행은 삭제하지 않고 전환** — 죽은 전제(`reviewer Task tool 미보유`) 를 살아 있는 규범(`Codex#1/#2 를 서브에이전트로 위임/중첩 금지`) 으로 교체해 가드 슬롯을 잃지 않았다 (v4.4.0 §C 의 "표 축소로 가드 소실" 전례 회피). `rules` §Fallback 꼬리 문장과 `WORKFLOW.md` Fallback 표 행은 §호출 형태 와 중복이라 제거.
- **`rules` §Failure escalation — 의견 조회에서 사용자 경유 제거** — 이 룰의 원래 의도는 *"막혔을 때 Codex 의견을 얻는다"* 였고 `/codex:rescue` 는 당시 orchestrator 가 쓸 수 있는 유일한 수단이었다. 직접 호출이 가능해진 이상 **의견 조회에 사용자를 거칠 이유가 없다** — `5+ 시 Codex 직접 진단 조회(읽기전용) → 통합 → 그래도 막히면 blocker 보고` 으로 교정. 사용자 개입은 **구현 이관**(write-capable `/codex:rescue`) 에만 한정한다. `WORKFLOW.md` §Codex 동반 수정. (같은 배치 중간에 `사용자에게 /codex:rescue 제안` 으로 바꿨던 건 룰 의도를 수단으로 오독한 것 — 되돌렸다.)

### Fixed — §Codex Integration 내부 모순 2건
- **Codex#1 트리거** (`rules/maestro-workflow.md` Phase 4) — `complex AND …` 조건이 같은 파일 §Codex Integration 의 *"Architect mandatory 영역은 complexity 무관 항상"* 과 충돌해 simple+Hard rule 조합에서 양립 불가였다. Phase 4 조건을 `[complex 또는 Architect mandatory 영역]` 으로 교정 (v4.5.0 에서 의도적으로 복원된 §Codex Integration 쪽 서술을 정본으로 채택).
- **graceful skip ↔ Fallback (Hard)** — *"미설치 → 전체 graceful skip (경고 없이 우회)"* 와 *"미설치·호출 실패 시 @architect 가 대체"* 가 충돌. **조용한 건 경고이지 검증이 아니다** 로 정리 — 사용자 경고는 생략하되 @architect mode T 대체는 수행. 같은 줄의 stale 표현(`codex:codex-rescue` 미설치 → Codex 플러그인 미설치)도 동시 교정.

### Unchanged (의도적)
- **`README.md:22,200,201` 의 `codex:codex-rescue` 미설치 표현** — 서브에이전트가 플러그인에 딸려오므로 **여전히 참**이다. 정밀도만 미세하게 오르는 편집이라 편집 리스크가 이득보다 크다고 판단해 유지.

### Added — `codex-image` 정본 편입 + 직접 호출 전환
- **`skills/codex-image/` 를 레포로 편입** (기존엔 `~/.claude/skills/` 글로벌 전용, 버전 관리 밖). `README.md` Skills 표에 1행 등재.
- **rescue 경유 → companion 직접 호출** — `task --write --cwd "$DEST_DIR" --skip-git-repo-check --prompt-file` 형태. 이미지 1장당 ~31k tok 절감.
- **스킬 문서의 오진 교정** — 기존 문서는 `~/Downloads` 저장 실패 원인을 *read-only 샌드박스* 로 설명했으나, 실측 결과 **원인은 워크스페이스 범위**였다. `--write` 를 줘도 cwd 밖은 DENIED, `--cwd "$HOME/Downloads"` 로만 WROTE. 즉 **rescue 경유는 `--cwd` 를 전달하지 못해 세션 레포 밖에 저장할 수 없었다** — 직접 호출이 이 한계를 해소한다. 검증: 1254×1254 PNG 665,314 bytes 생성·이동 성공.
- **end-to-end 실행에서 버그 2건 발견·수정** (스킬을 실제 호출해 1536×1024 수묵화 생성, 2,553,001 bytes):
  - **`outputs/` 가 `.gitignore` 에 없어 생성물이 커밋 대상이 됨** — §4.4 기본 저장 경로(`{repo_root}/outputs/imagegen/`)가 추적 대상이라, 공개 레포에 MB 단위 이미지가 딸려 올라갈 수 있었다. `.gitignore` 에 `outputs/` 추가.
  - **`move` 가 구조적으로 불가능한데 문서는 필수라고 규정** — 원본 `$CODEX_HOME/generated_images/...` 는 `--cwd` 워크스페이스 밖이라 샌드박스가 **삭제를 거부**한다. Codex 는 거부를 보고한 뒤 copy 로 강등하므로, 모든 이미지가 **이중 저장**된다 (원본과 목적지 파일 바이트 동일 확인, 누적 83개/144MB). §6 을 "copy, not move" 로 교정하고 위임 프롬프트의 `move 해줘` → `복사해줘 (삭제 시도 금지)` 로 변경, §What NOT to do 에 1행 추가.

### Fixed — `maestro-guard.ps1` 이 아무것도 차단하지 못하던 문제 (가드 전면 무력화)
- **`[Console]::In.ReadToEnd()` 가 빈 문자열을 반환** — 스크립트가 `powershell -File` 로 실행되면 PowerShell 이 stdin 파이프라인을 먼저 소비해 `[Console]::In` 이 비어 있다. 그 결과 `if (-not $input) { exit 0 }` 에서 **무조건 통과**했다 — 즉 Windows 에서 maestro 가드는 **파일 보호를 전혀 하지 않고 있었다**. `.sh` 는 `$(cat)` 이라 영향 없음. 이것이 traversal 우회가 Windows 쪽에서 드러나지 않은 이유이기도 하다 (가드 자체가 돌지 않았다).
- **수정**: `New-Object System.IO.StreamReader([Console]::OpenStandardInput())` 로 stdin 을 직접 읽는다. 아울러 변수명 `$input` → `$payload` — `$input` 은 **파이프라인 입력을 담는 예약 자동변수**라 거기에 할당하면 읽으려던 데이터를 덮어쓴다 (이중 결함).
- **검증 18/18** — macOS 에 `pwsh` 7.6.4 를 설치해 실제 훅을 end-to-end 실행. 우회 5건 BLOCK · 대조군 2건 BLOCK · 화이트리스트 9건 ALLOW · 서브에이전트 `agent_id` bypass 2건. **수정 전 동일 하네스는 10 PASS / 8 FAIL** (대조군 포함 전부 ALLOW).
- **남은 갭**: 검증은 macOS pwsh 7 기준이다. `settings.json` 은 Windows 에서 `powershell`(5.1, .NET Framework) 을 호출하므로 백슬래시 경로·5.1 런타임 차이는 여전히 미검증.

### Fixed — `maestro-guard` 화이트리스트 경로 정규화 우회
- **`hooks/maestro-guard.sh` · `.ps1`** — 화이트리스트가 **정규화되지 않은 원본 경로에 부분일치**로 걸려, `.agentic/` 나 `/memory/` 를 경유하는 traversal 이 가드를 통과했다. 재현 확인: `<repo>/.agentic/../rules/maestro-workflow.md` 는 ALLOW (같은 파일을 직접 지정하면 BLOCK), `<repo>/.agentic/../../../../etc/hosts` 도 ALLOW 로 **레포 밖까지 뚫렸다**. 2026-07-30 Codex 적대 감사가 지적 → 격리 샌드박스에서 실제 훅을 end-to-end 실행해 확정.
- **수정**: 매칭 전에 `.` / `..` 를 **어휘적으로**(realpath 아님 — 아직 존재하지 않는 파일도 처리해야 하므로) 접는 `normalize_path` 를 추가. `.ps1` 은 `[System.IO.Path]::GetFullPath()` + 실패 시 **fail closed**(exit 2).
- **검증 16/16** — 우회 5건 전부 BLOCK 전환, 대조군 2건 BLOCK 유지, 화이트리스트 9건(`MEMORY.md` · `memory/*.md` · `.agentic/` · `*.plan.md` · `~/.claude/plans/*.md` · `TODO.md` · `CHANGELOG.md` · `VERSION` · `.`/`..` 포함 정상 경로) 전부 ALLOW 유지.
- **부수 — `.ps1` 파리티 1건**: `~/.claude/plans/*.md` allow 룰이 `.sh` 에만 있어 Windows 에서 Plan Mode 계획 파일이 차단될 상태였다. 동일 룰 추가. `.ps1` 은 pwsh 미설치로 **실기 미검증** ([[project_windows_hook_verify]] 과제에 해당).

### Fixed — 배포 파이프라인 2건 (`~/.claude` drift 근본 원인)
- **`update.sh` · `uninstall.sh` CRLF → LF** — `set: -: invalid option` / `syntax error near unexpected token` 로 **macOS/Linux bash 에서 실행 자체가 불가능**했다 (HEAD 기준 119행 CRLF, `install.sh` 만 LF). 이것이 `~/.claude/agents/architect.md` 등이 레포와 어긋나 있던 **직접 원인** — 정본을 고쳐도 배포가 돌지 않았다. 재발 방지로 `.gitattributes` 신설 (`*.sh text eol=lf`).
- **`update.sh` settings 병합이 훅을 소실시키던 문제** — `jq -s '.[0] * .[1]'` 는 객체는 병합하지만 **배열은 교체**하고 `hooks` 값이 배열이라, 레포에 없는 글로벌 전용 훅이 조용히 사라졌다. 실측 시뮬레이션: `PreToolUse 2→1` (`gws-guard.sh` 소실 — Google Workspace 파괴적 작업 확인 게이트), `PostToolUse 3→2` (`declare-guard.sh` 소실). `install.sh:168` 이 이미 갖고 있던 **per-event 배열 병합 + `permissions.allow` npm 광범위 와일드카드 제거** 로직을 이식. 수정 후 훅 소실 0 · permissions 12개 보존 확인.

### Fixed — §Completion 이 5c 생략 조건과 양립 불가

- **`rules/maestro-workflow.md:296`** — 완료 게이트가 *"5b·5c·5d 전 단계 PASS"* 를 요구하는데 같은 파일 §5c(`:142`) 는 *"Skip 5c only when: (a) simple task, single-file edit, (b) 테스트 스위트 부재"* 로 생략을 허용한다. 생략하면 5c 는 영원히 PASS 가 아니므로 **규정을 문자 그대로 지키면 완료 선언이 불가능**하고, 모델은 규정을 무시하거나 **없는 5c PASS 를 지어내는** 쪽으로 몰린다 — silent skip 을 confident fabrication 으로 바꾸는 구조적 압력. `skills/maestro/WORKFLOW.md:76` 의 *"Simple task 면 N/A 한 줄로 대체 가능"* 은 더 넓은 예외라 충돌 폭이 더 크다.
- **수정**: 게이트 문장의 `PASS` 뒤에 *"생략 조건 해당 시 SKIPPED — <조건> 명시"* 절 추가. 생략은 허용하되 **침묵한 생략은 불가**. 가드 손실 0, 상주 비용 ~15자.
- **`PASS | SKIPPED | N/A | FAIL` 4상태 스키마 전면 도입은 기각** (Codex 권고안) — 한 줄짜리 충돌에 새 상태 모델을 세우는 건 `rules/global.md` §Simplicity First 가 경고하는 과잉. 필요해지면 그때 승격한다.

### Unchanged (의도적) — 블로그 재검토 2차 (2026-07-31)

- **maestro 20행 가드 (Soft Violation 12 + Rationalization 8) 전량 유지 재확인** — v4.4.0 §Unchanged 를 뒤집을 근거를 찾지 못했다. 이번 검토에서 *"금지 목록 → 필수 제출 항목(run-log) 전환 + Stop 훅 게이트"* 를 설계·검증했으나 **기각**: (a) 12행 중 2·3·12행은 필드로 **흡수 불가**, 부분 흡수 8행도 전부 불충분 (b) 자기보고 필드는 실행 여부가 아니라 *"실행했다고 말했는가"* 만 검사해 오히려 fabrication 압력을 높인다 (c) 블로그 기준으로도 genuine interface design 이 아니라 **compliance form 재포장**. 2026-07-31 Codex 적대 검증.
- **자율 이관 검토의 올바른 대상은 20행이 아니다** — v4.4.0 이 세운 구분선(capability constraint ↔ process compliance)이 곧 판별 기준이다. 블로그 shift 1 이 적용되는 자리는 `global.md` · `secure-coding.md` · `typescript.md` 이고, `maestro-workflow.md` 는 대상이 아니다 (모델 판단이 바로 그 실패 지점). 전자를 훑은 결과 실제 후보는 아래 1건뿐.
- **`rules/global.md` §Interpretation & Pushback ↔ 하네스 시스템 프롬프트 충돌 — 인지하되 미수정** — global.md 는 *"Stop and ask on … scope expansion"*, 시스템 프롬프트는 *"state the concern … then keep building"* 으로 같은 트리거에 반대 행동을 지시한다. 블로그가 지목한 conflicting guidance 의 실제 사례지만 같은 절의 *"not for trivial ambiguity"* + *"default-mode behavior"* 각주가 완충하고 있어 시급하지 않다고 판단. 실사용에서 오작동(불필요한 halt 또는 무단 진행) 관측 시 처리.

**후속 작업용 검증 사실 (Stop 훅)** — Stop/SubagentStop 은 `last_assistant_message` 를 받고 `{"decision":"block","reason":…}` 로 차단 + 사유 반환이 가능하다 (공식 문서 + `codex` 플러그인 `stop-review-gate-hook.mjs:49,169` 실동작 확인, Claude Code 2.1.220). SubagentStop block 은 **해당 서브에이전트**를 계속 돌린다. 단 Codex 가 주장한 *"8회 연속 차단 후 강제 종료"* · Stop 페이로드의 `stop_hook_active`/`background_tasks`/`session_crons` · SubagentStop 의 `agent_transcript_path` 는 **문서에 근거 없음** (미검증). 또한 `skills/maestro/SKILL.md:27` 이 완료 시 `.agentic/maestro-mode.state` 를 삭제하므로, 장차 Stop 훅이 이 파일로 모드를 판정하면 **훅 실행 시점엔 이미 없어 통과한다** — 삭제는 검증 성공 후 훅이 해야 한다.

### Removed / Changed — 오픈소스 편입 기준 적용 (개인·프로젝트 종속 제거)

정본은 **어떤 Claude 사용자든 설치할 수 있어야 한다**. (a) 개인 커스텀 (b) 특정 스택 한정 (c) 보안·유출 소지 (d) 로컬 전용 민감정보 는 들어가면 안 된다는 기준으로 전수 점검했다. 제거 대상은 사전에 개인 저장소로 이관·보관하고 해시 대조로 복원을 검증한 뒤 지웠다.

- **`skills/session-wrapup/` 제거** — Obsidian vault 디렉터리 구조뿐 아니라 **실제 사업 운영 수치**(회원 수·발송 건수·연결 쌍)가 본문에 있었다. 일반화해도 남는 골격이 적어 통째로 개인 저장소로 이관. `session-summary` 의 상호 참조 2곳은 죽은 참조가 되므로 문구에서 제거.
- **`skills/multi-worktree-safety/`** — 절대 홈 경로 하드코딩 2곳(frontmatter description + 본문 셸 루프) 제거. jobs root 를 `$CLAUDE_JOB_DIR` 의 부모에서 유도하도록 변경(`$HOME/.claude` 고정도 설치 형태에 따라 틀릴 수 있다). 특정 프로젝트명 예시 · `main` 브랜치 고정도 제거(기본 브랜치 자동 감지).
- **`skills/codex-image/`** — 특정 레포의 `marketing/content/**` 디렉터리 규약이 **예시가 아니라 실제 기본 저장 규칙**이었다. "content 폴더 옆 `images/`" 라는 일반 규칙으로 대체하고, 프로젝트별 규약은 그 프로젝트 `CLAUDE.md` 에서 덮어쓰도록 명시. 개인 머신 실측치(누적 PNG 수·용량)와 제품 slug 예시도 교체.
- **`CLAUDE.md`·`AGENTS.md`·`skills/secure-coding/` 공급망 §** — 개인 머신 셋업 서술(특정 pnpm 버전 · 개인 zshrc 함수명 · 특정 MCP wrapper)을 **권장 셋업**의 일반 서술로 교체. 정책 표 자체는 범용이라 유지.
- **`rules/memory-management.md`** — 예시에 박혀 있던 실제 사고 날짜·벤더명·개인 구현 파일명을 일반 표현으로.
- **`skills/maestro/WORKFLOW.md`** — mode A 근거의 실제 세션 코드명과 내부 결함 서술을 일반화(근거의 논지는 유지).
- **`CHANGELOG.md`** — 과거 항목의 비공개 프로젝트·제품명·개인 vault 경로 3곳 교체. *"과거 이력이라 예외"* 는 성립하지 않는다 — CHANGELOG 도 공개 배포물이다.

### Fixed — 설치·갱신이 사용자 파일을 백업 없이 덮어쓰던 문제

- **`install.sh` · `update.sh`** — `agents/`·`rules/`·`hooks/`·`skills/` 를 `cp -f` 로 덮어쓰면서 **같은 이름의 사용자 파일을 백업 없이 소실**시켰다. 개인정보 노출은 아니지만 *"다른 사람이 설치하면 문제되는 것"* 에 해당한다. 덮어쓰기 전 `~/.claude/backups/<install|update>-<타임스탬프>/` 로 보존하고(내용이 같으면 생략), 완료 시 백업 경로를 출력하도록 수정.
- **jq 부재 경로** — `settings.json` 과 `~/.mcp.json` 을 병합 없이 단순 덮어쓰던 분기도 동일하게 백업 후 진행 + 경고 문구 명확화.
- **`set -e` 하에서 `((VAR++))` 가 값 0일 때 exit 1** 을 반환해 스크립트가 조용히 중단되던 문제를 도입 직후 실사격에서 발견·수정(`VAR=$((VAR+1))`). 수정 후 전 디렉터리 동기화 완주 + 백업 6건 생성 확인.

### Removed — 공개 범위를 maestro 하네스로 축소
- **`skills/{codex-image,session-summary,multi-worktree-safety}/` 제거** — 오픈소스 편입 기준 4개(개인 커스터마이징 / 특정 스택·로케일 종속 / 보안·유출 노출 / 로컬 민감정보) 중 하나 이상에 걸린다. 공개 레포는 **maestro · secure-coding · memory-management** 3개 하네스 스킬만 배포한다. 세 스킬은 개인 저장소로 이관돼 사라지지 않는다 (같은 배치에서 버전 관리 밖에 있던 스킬 18개도 함께 편입). 죽은 참조 6곳(`README.md` 표 3행 + 디렉터리 트리 1곳, `docs/maestro-summary.md` 세션 종료 1곳, `CLAUDE.md`·`AGENTS.md` 의 Codex 호출 예시) 동시 정리. `CHANGELOG` 기존 항목은 판단 기록이라 남긴다.

### Fixed — `verify-*` / `manage-skills` 를 배포물처럼 서술하던 문서 10곳
- **선택 의존성으로 문구 교정** — `rules/maestro-workflow.md` Phase 6 은 처음부터 *"프로젝트에 있으면 위임, 없으면 `git diff` 리뷰"* 로 올바르게 쓰여 있었는데 `README.md`(7곳)·`docs/maestro-summary.md`(3곳)만 이 레포가 제공하는 것처럼 읽혔다. **스킬을 배포하는 게 아니라 문구를 고친다** — `verify-compliance-kisa` 는 KISA 규제(로케일 종속), `verify-infrastructure` 는 호스트 하드닝(스택 종속)이라 배포 기준에 맞지 않는다.
- **`settings.json` 의 무효 항목 `Write(.agentic/*)` 제거** — 파일 권한 체크는 `Edit` 룰만 매칭하므로 이 항목은 처음부터 효력이 없었다. `Edit(.agentic/*)` 는 이미 있었으므로 실제 권한은 그대로다 (오케스트레이터가 `.agentic/maestro-mode.state` 를 쓰는 경로). headless 실행이 뱉은 경고로 발견.
- **`/maestro` 활성화가 새 프로젝트에서 조용히 실패하던 문제** — `skills/maestro/SKILL.md` 의 `echo > .agentic/maestro-mode.state` 가 `.agentic/` 부재 시 실패하고, 가드는 상태 파일이 없으면 비활성이라 **강제 메커니즘 자체가 안 켜졌다**. `.agentic/` 는 gitignore 대상이라 모든 새 클론이 해당된다. `mkdir -p` 선행으로 수정.
- **Phase 6 의 조건과 동작 불일치** — 조건은 `verify-*` 일반인데 동작은 `verify-implementation` 고정이라, 다른 `verify-*` 만 가진 프로젝트가 Yes 분기로 들어가 읽을 파일이 없고 fallback 도 못 탔다. `skills/maestro/WORKFLOW.md`·`SKILL.md` 를 조건에 맞춰 일반화 (`rules/` 는 원래 올바랐다).

## [4.5.0] - 2026-07-29

> 사용자 지시: *"기능을 상실시키는 게 아니라 군더더기·중언부언·긴 표현을 간결화하라"* → 이후 *"무조건 줄이라는 게 아니라 불필요한 게 있다면 줄이라는 것, 더 좋은 방향이면 추가도 검토"*. 3배치 중 2개 적용 · 1개 기각, 기각 근거는 순증으로 기록. **상주 −153 tok / 지연 −763 tok.**

### Changed — 배치 1: 크로스파일 중복 · dangling reference 제거
- **Fable fallback 단일화** (`agents/architect.md` §Model) — refusal/한도 2분기와 "1회 재시도" 를 폐기하고 **"Fable 실패 시 사유 불문 즉시 `model: opus` 재위임"** 한 줄로 병합. orchestrator 가 실패 원인을 진단해야 하는 오판 지점이 사라진다. `⏳ 한시적` 태그 제거 (태그를 `(영구)` 로 바꾸는 게 아니라 태그 자체를 삭제 — frontmatter `model: fable` 이 이미 사실을 진술한다).
- **`5d reviewer miss:` 기록 신설** (`rules/maestro-workflow.md` §5d + Soft Violation 1행) — Reviewer PASS 후 다른 축이 결함을 발견했거나 Codex#2 단독 발견 finding 이 있으면 run log 에 한 줄. **처리 변경 없음** — miss 원인이 프롬프트(가드레일 1 자기검열)인지 모델 역량인지 가릴 데이터부터 모은다.
- **dangling reference 교정 (3곳)** — `rules/maestro-workflow.md §Fable Integration` 은 v4.4.0 에 삭제됐는데 `CLAUDE.md` · `AGENTS.md` · `skills/maestro/SKILL.md` 포인터가 잔존. `agents/architect.md` §Model 로 교정. `rules/` 의 Agents 표 셀 `§Fable` 도 동일.
- **크로스파일 중복 제거** — `CLAUDE.md` 자연어 modifier 예시 4줄 (정본은 `SKILL.md` modifier 표, 같은 표의 Activation 행이 이미 그리로 포인터) · `SKILL.md §Session Resume` (`CLAUDE.md §State Persistence` 상주 + 같은 파일 말미 지시와 3중 중복) · `rules/` §5d 의 Codex#2 trigger 문단 (§Codex Integration 정본으로 포인터) · `agents/architect.md` Decision Framework 의 `Simplicity First` (`rules/global.md` 동명 섹션이 상주).
- **`agents/librarian.md` 101 → 52 줄** — Core Mission 예시 질문 · Request Classification 표 · grep.app 예시 3종 · Rules 6항 + Anti-Patterns 5항을 도구 우선순위 + 출력 계약 + 규칙 4줄로 압축. 행동을 바꾸지 않는 서술만 삭제. `frontend-engineer.md` · `document-writer.md` 의 기존 밀도에 맞춤.
- **포인터 축약 중 기능 손실 1건 자체 검출 후 복원** — §5d 의 Codex#2 trigger 를 §Codex Integration 포인터로 줄이자 *"Architect mandatory 영역은 complexity 무관 항상 invoke"* 가 증발(참조 대상이 그 항목을 담고 있지 않았음). §Codex Integration 트리거 줄에 복원. **포인터로 중복을 줄일 때는 참조 대상이 원문의 모든 항목을 담는지 먼저 확인한다.**

### Changed — 배치 2: 재진술 · 근거 문단 제거
- **`rules/` §Mode Behavior 표(4×4) 삭제** — 4행 중 3행이 Phase 1·2·5·6 정의의 재진술이었고, `approval skip` 열은 Phase 4 §Skip conditions 와 중복. 유일하게 그 표에만 있던 **"`goal` 시 APPROVE 는 최초 1회"** 는 1줄로 보존.
- **`rules/` §Completion 요건 나열 삭제** — TODO / 5b / 5c / 5d / success criteria / 회귀 6항목은 전부 해당 Phase 에 정의돼 있다. 게이트 자체(전 단계 PASS 시에만 출력)만 1줄로 남김.
- **`rules/global.md` §Git Commit Style 근거·역예시 삭제** — §Why 문단(옵시디언 볼트·`git log --oneline` 가독성)과 Bad 예시 블록은 §Forbidden 4항목이 이미 명시하는 내용의 재시연. 룰·프리픽스·Good 예시는 전량 유지 (v4.4.0 에서 이 섹션을 의도적으로 존치한 결정 존중).
- **`skills/maestro/WORKFLOW.md` Phase 2 ASCII 패턴 다이어그램 4종 삭제** — `rules/` §Phase 2 패턴 표의 시각적 재진술. 결정 트리는 절차라 유지. Fable §배경의 v4.1.x→v4.2.0 modifier 이력 1문단도 삭제 (CHANGELOG 소관).
  - **감사 목록에서 철회한 항목**: `"왜 선행 임베딩이 토큰을 아끼는가"` · `"Bad vs Good"` · `"왜 병렬 분업인가"` 는 삭제하지 않았다. WORKFLOW.md 는 파일 헤더가 스스로 *"절차 · 템플릿 · 예시 · 사고 근거"* 를 담는다고 선언한 **근거 보관소**라, 근거 삭제는 v4.3.0 의 상시/지연 분할 설계를 깨는 행위다. 이 파일에서는 *중복과 이력*만 제거한다.

### Unchanged (의도적) — 배치 3 기각
- **Soft Violation ↔ Rationalization 두 표 병합 기각** — 3자 검토(@architect · Codex · 본세션) 만장일치 반대. (a) 표 B 는 `7c3a626`(v4.1.2) 의 **의도적 형식 이식**이고 1인칭 변명 형식 자체가 기능이다 — 표 A 는 사후 감사용 3인칭 체크리스트, 표 B 는 행동 직전의 내적 합리화를 잡는 패턴. (b) 1:1 대응은 최초 추정 5쌍 → 실측 4쌍 → Codex 검증 **2쌍**으로 줄었고, 나머지 2쌍(`5c 풀 스위트`·`5b 출력 계약`)은 예외 조건이 비대칭이라 병합 시 규범 소실 위험. (c) 순 절감 ~150–200 tok 은 v4.4.0 이 자체 측정한 *"상주 절감은 캐시 읽기라 요청당 $0.0012"* 규모의 1/10. (d) **v4.4.0 §Unchanged 가 이미 두 표를 이름까지 적어 존치 결정**했고, `docs/maestro-v4-overoptimization-analysis.md` §C 에 Soft Violation 표 17→8행 축소로 가드가 실제 소실된 전례가 있다.
- **기각 사실을 표 옆 각주로 기록 (실측 +133 tok, 순증)** — 최초 +55 tok 으로 추정했으나 실측 +133 tok (한국어 2줄, 534B). 배치 1·2 절감분의 47% 를 되쓴다. 그럼에도 유지 — v4.4.0 의 존치 결정은 CHANGELOG 에만 있었고 이번 감사가 그걸 놓쳐 동일 제안을 재상정했다. 기록은 편집자가 실제로 보는 자리(표 바로 아래)에 둔다. 감사 절차 교훈: **구조 변경 전 CHANGELOG `Unchanged (의도적)` 항목을 먼저 조회**한다 — 배치 2 의 `global.md` 에는 이 확인을 했으나 가드 표에는 하지 않았다.

## [4.4.0] - 2026-07-27

> 근거: Anthropic, ["The new rules of context engineering for Claude 5 generation models"](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models) (2026-07-24). Claude Code 시스템 프롬프트 80%+ 삭제에도 코딩 eval 손실 없음 — 원인은 **overconstraining**. 6개 전환축 중 우리에게 해당하는 것만 적용.

### Changed
- **상주 컨텍스트 11,343 → 8,962 est. tok (−21%)** — 전 세션·전 프로젝트에 걸리는 비용.
- **`rules/global.md` §Comments · §Clean Code · §Workflow(1–3) · §Communication 삭제** — 현행 시스템 프롬프트가 이미 *"Write code that reads like the surrounding code: match its comment density, naming, and idiom"* 을 담고 있어, 그 위에 `Never comment: Obvious code` 를 덧씌우면 블로그가 지적한 **상충 지시**("leave documentation as appropriate" ↔ "DO NOT add comments")가 그대로 재현된다. 유지: Simplicity First · Surgical Changes · Interpretation & Pushback · Git Commit Style (전부 모델 기본값이 아닌 사용자 고유 의견).
- **`rules/typescript.md` 축소 (594 → 233 tok)** — `strict: true`, `any` 회피, optional chaining, `Promise.all`, import 그룹핑은 블로그가 말한 *"the obvious things Claude should know"*. 취향이 갈리는 5줄만 남김.
- **agent 3종 보일러플레이트 제거** (`architect` −398 / `frontend-engineer` −381 / `document-writer` −335 tok) — "❌ 분석만 하고 돌려보내지 마라" 류 구세대 가드와 "보라 그라데이션 금지" 같은 취향 룰은 모델 기본 동작·`artifact-design` 스킬 관할. **`architect` 의 Plan-Stage Constraint 는 유지** (판단 문제가 아니라 워크플로우 고유 제품 룰).
- **버전 푸터 압축** — CLAUDE.md / `rules/maestro-workflow.md` / `WORKFLOW.md` 3곳에 중복되던 릴리스 나열을 CHANGELOG 링크 한 줄로.

### Added — progressive disclosure
- **`secure-coding` 스킬 신설** (`rules/secure-coding.md` 2,140 → 1,016 tok) — CWE 매트릭스 15행 + concern별 체크리스트 + 공급망 사고 배경을 스킬로 이관. **상주에 남긴 것**: Core Principles 7개 · **트리거 표**(무엇을 건드리면 스킬을 로드해야 하는가) · **공급망 실행 정책표**(매 npm/pnpm 명령을 게이트하므로 조회성이 아님). 스킬 로드 실패 시 Core Principles 로 폴백하되 **그 사실을 명시**하도록 규정 — 조용한 미적용 차단.
- **`memory-management` 스킬 신설** (`rules/memory-management.md` 814 → 415 tok) — cross-check 명령·중복 분류표·인덱스 임계점·promotion/demotion 을 이관. 상주엔 정본 1곳 원칙(WHAT/WHY/HOW)과 rules↔SKILL drift 경보만. auto-memory 가 생성·frontmatter·인덱싱을 담당하게 된 현실 반영 + 구형 평면 frontmatter 정정 절차 추가.
- **`agents/architect.md` §Model** — `rules/maestro-workflow.md` §Fable Integration 을 대상 파일로 이관 (−480 tok 의 일부). Hard 서브룰(새 인스턴스 스폰 · refusal 재시도→Opus · 자율 상향 금지)은 문구 그대로 유지.

### Added — rich references (rubrics)
- **`skills/maestro/rubrics/visual-axis.md`** — Phase 5d 시각 axis 를 산문 지시에서 **V1~V8 채점표 + 출력 계약**으로. 실렌더·375px·스크린샷 근거를 PASS 조건으로 명문화하고, 미수행 항목을 PASS 로 보고하지 못하게 막음.
- **`skills/maestro/rubrics/success-criteria.md`** — Phase 6 sign-off 를 **S1~S6 채점표**로. criterion 1:1 지목 · verified/unverified 분리 · 미해결 항목의 사용자 summary 노출을 강제.
- 블로그의 *"Simple specs → Rich references"* 적용. 검증자 에이전트가 재현 가능한 형식으로 답하게 하는 것이 목적.

### Unchanged (의도적)
- **maestro 의 process-compliance 가드 전량 유지** — Hard rule · Soft Violation 표(12행) · Rationalization 반박표(8행) · Anomaly Comparator · plan-binding · 승인 판별 · mode A 재디스패치. 블로그의 *"rules → judgment"* 는 **capability constraint**(코드를 어떻게 쓸지)에 대한 것이고, 우리 가드는 **process compliance**(풀 스위트 돌렸나·위임했나)다. 후자는 모델 판단이 바로 그 실패 지점이며, `docs/maestro-v4-overoptimization-analysis.md` §3 과 `memory/feedback_maestro_silent_skip_history.md` 가 "root mechanism 대체 없이 가드만 제거 → 재발"을 이미 실증했다.

## [4.3.0] - 2026-07-26

### Changed
- **maestro 룰 상시/지연 분할** (`rules/maestro-workflow.md` 재작성 + `skills/maestro/WORKFLOW.md` 신설) — 47,004자(~11.7k tok)가 전 프로젝트·전 세션에 상주하던 것을 둘로 분리. **`rules/` = 구속 룰 정본**(가드 · Hard rule · 판정 기준 · 출력 계약, 22.8k자 ~5.7k tok, 항상 로드) / **`skills/maestro/WORKFLOW.md` = 절차·템플릿·예시·사고 근거**(15.1k자 ~3.8k tok, 지연 로드). `/maestro` 미사용 세션(측정 50세션 중 80%)에서 **~6.1k est. 토큰/세션 절감**, 사용 세션도 중복 제거로 총량이 원본보다 소폭 감소.
  - **분할 기준은 "가드냐 절차냐"가 아니라 "정확성을 떠받치느냐"** — Codex 교차검토(2026-07-26)에서 원안의 오분류가 드러나 수정. Anomaly Comparator 표, mode A 트리거 4 + 공격형 가드레일 4항, 5b 출력 계약, Fable Hard 서브룰 2개, Codex fallback 담당자 매핑, Context Embedding 요구 항목은 **상주**로 유지 — 이들이 지연 쪽으로 가면 "가드는 살아 있는데 실행 정의가 없는" **확신에 찬 오작동**(dangling reference)이 발생하고, 이는 룰이 아예 없는 것보다 위험하다.
  - 충돌 시 **`rules/` 우선** — 양쪽 파일 헤더에 정본 관계 명시 (drift 방지).

### Added
- **WORKFLOW.md 재로드 보장** (`skills/maestro/SKILL.md` First action + `hooks/maestro-compact-reload.sh`/`.ps1` + `settings.json` PostCompact 등록) — 지연 로드분은 대화에 실리므로 `/compact` 시 요약돼 소실될 수 있다. 이중 방어: ① `/maestro` 진입 시 **무조건** 재읽기(“이미 읽었다” 판단 금지 — 요약 잔재는 로드 증거가 아니며 오히려 오판을 유도) ② **PostCompact 훅**이 maestro 모드(`.agentic/maestro-mode.state`)에서만 재읽기 지시를 기계적으로 재주입 — 모델 판단 의존 제거. 실사격 검증: 모드 OFF 무출력 통과 / 모드 ON 유효한 `additionalContext` JSON 출력.

### Changed
- **Fable baked-in — modifier 폐기** (`agents/architect.md` frontmatter `model: fable`, `rules/maestro-workflow.md` §Fable Integration 재작성, Phase 1 modifier 표·SKILL.md·CLAUDE.md 의 fable 줄 제거) — v4.1.4 의 "페이블" opt-in modifier 를 폐기하고 **@architect 를 상시 Fable 로 상향** (설계 = 저볼륨·고레버리지라 2× 단가 정당). 리뷰(5d)는 교차 검증 구조(Reviewer + Codex#2)가 품질 담보하므로 기본 Opus 유지 — 예외는 리뷰어 부재 프로젝트의 architect fallback 리뷰(수용). **Codex#1/#2 fallback 은 설계 컨텍스트에 주입하지 않고 새 인스턴스 스폰** (clean context — 셀프 컨펌 차단). **Refusal 은 한도 여유 시 Fable 1회 재시도 → Opus 재위임**. 회귀 = frontmatter 1줄 + 문서 2곳. (같은 미출시 창구의 "fable modifier Architect 강제" 룰은 baked-in 으로 대체되어 제거 — modifier 자체가 사라져 무의미.)

### Added
- **Codex#2 이중 모드 (mode T/A) + 공격형 가드레일 4항 + mode A 재디스패치 룰** (`rules/maestro-workflow.md` §5d, §Codex Integration Fallback, Soft Violation Guard, Rationalization 반박표) — 근거: 실운영 사례 (표준 3축 전부 PASS 후 공격형 QA 가 실결함 2건 회수, 공격 표면 7개 중 5개 no-finding 으로 가드레일이 변질 방지 입증). mode T(test-adequacy, 기본) / mode A(implementation-attack — 공격 표면 명시 임베딩, 고파급 청크 한정). 가드레일 4항: file:line+재현 경로 필수 · no-finding 허용 선언 · 수용 전 재현 게이트 · 심각도 정직. fallback 한계 명시: @architect fallback 은 mode T 등가 대체뿐 — mode A 대상 청크에서 Codex 실패(좀비화 포함) 시 런타임 복구 확인 후 **1회 재디스패치**, 실패 시에만 fallback 종결 + run log 명시.
- **claude-md-sync hook** (`hooks/claude-md-sync.sh` / `.ps1`, PostToolUse `Edit|Write|MultiEdit`) — CLAUDE.md 저장 시 AGENTS.md 자동 싱크. ① 같은 디렉토리 `AGENTS.md` 는 **이미 존재할 때만** 갱신 (프로젝트별 opt-in), ② 전역 `~/.claude/CLAUDE.md` 저장 시 `~/.codex/AGENTS.md` (Codex 전역 지침) 로도 싱크. 정본 repo 에 `AGENTS.md` 신설 (헤더 주석 + CLAUDE.md 본문 미러). 헤더에 rules 포인터 지시 포함 — 소비 에이전트(Codex 등)가 `~/.claude/rules/*.md` 를 읽고 동일 적용하도록 (자동 주입 보장 + 포인터 커버리지 절충). 근거: AGENTS.md 표준(agents.md) — 파일명 복수형 `AGENTS.md`, Codex 전역 위치 `~/.codex/AGENTS.md`(빈 파일은 스킵됨), 지침 총량 32 KiB 캡. Claude Code 는 AGENTS.md 를 네이티브로 읽지 않으므로(공식 문서 확인) CLAUDE.md 정본 유지 + 훅 단방향 싱크 채택. matcher 문자열을 `Edit|Write|MultiEdit` 로 둔 것은 의도적 — install.sh 훅 병합이 동일 matcher 를 교체하므로 사용자 개인 훅(`Write|Edit|MultiEdit`)과 충돌하지 않게 분리.

## [4.1.4] - 2026-07-02

### Added
- **Fable 한시적 opt-in modifier** (`rules/maestro-workflow.md` §Fable Integration, `skills/maestro/SKILL.md` modifier 표) — `claude-fable-5` 를 default OFF 인 런타임 modifier(`"페이블"` / `"fable로"` / `"최고 성능으로"`)로 도입. fable on 시 orchestrator 가 **@architect 설계(Hard rule/5 Effect) · Phase 4 적대검토 · Phase 5d 코드리뷰 axis + fix-loop escalation** Task 에만 `model: fable` 상향 (라우팅 지점 외 — 세션 모델·librarian·document-writer·verifier·frontend 시각 axis·일반 5a 워커 — 는 현행 유지).
  - **Refusal fallback (Hard)**: Fable safety classifier 거부(사이버보안 오탐 등) 시 orchestrator 가 같은 작업을 Opus 로 재위임 (Claude Code 서브에이전트엔 API server-side `fallbacks` 부재 → 유일한 방어선).
  - **⏳ 한시적 룰 — 회귀 예정**: Fable 은 한시적 가용 기간에만 사용. 사용 규칙상 사용이 어려워지면 §Fable Integration + Phase 1/SKILL.md 의 fable 줄 제거로 현행(Opus/sonnet) 무손상 회귀. baked-in(agent frontmatter·세션 모델) 대신 modifier 방식을 택한 이유.

## [4.1.3] - 2026-07-02

### Added
- **Phase 5d 시각(visual) axis** — frontend-engineer 가 Reviewer·Codex#2 와 병렬로 3번째 검증자 합류. UI-bearing 청크 (`app/views/**`·Stimulus·CSS/디자인 토큰) 변경 시 변경 페이지를 실제 렌더 (모바일 375px + 데스크톱 스크린샷) → 프로젝트 디자인 레퍼런스 (DESIGN_SYSTEM / 와이어프레임 / 기존 페이지) 와 대조. "code-reviewer PASS ≠ 시각 PASS" 원칙 + fix-loop 연동. 디자인 레퍼런스·뷰포트는 프로젝트 공급, 글로벌은 메커니즘만 정의 (§Axis Mechanism 동일 원칙). (`rules/maestro-workflow.md` §5d, `skills/maestro/SKILL.md`)
  - 배경: 전역 `~/.claude/` 에만 존재하고 정본 repo 에 미커밋된 드리프트를 백포트 — 같은 v4.1.2 라벨이 두 콘텐츠를 가리키던 버전 무결성 문제 해소

## [4.1.2] - 2026-06-12

### Added
- **agent-skills 형식 이식 3건** (출처: [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) 비교 분석 — Claude + architect 독립 2차, Codex 한도로 fallback):
  - §Soft Violation Guard 에 **Rationalization 반박표** — 훅이 잡지 못하는 검증 단계 runtime 재량 skip (5c 생략 / anomaly dismiss / self-test 미수신 / Codex#2 재량 skip / doubt-theater / plan 이탈) 의 프롬프트 가드. v4.0 가드 후퇴 3영역 (overoptimization 분석 "재발 거의 확실") 의 저비용 보강
  - Phase 4 **승인 판별 (explicit affirmative only)** — 명시적 긍정만 승인, 애매한 긍정 ("괜찮아 보이네") 은 미승인 처리 후 재확인
  - Delegation 템플릿 Self-test 에 **RED-first** — 신규 testable behavior 는 실패 테스트 먼저 (RED) 후 구현 (GREEN)

### Rationale
- 비교 분석 결론: agent-skills 플러그인 병용은 과최적화 (user-as-orchestrator 철학이 maestro 와 정면 충돌 + 스킬 자동발동의 이중 프로세스 지시 + 24개 description 상시 토큰) → **maestro 골격 유지, 형식만 흡수**. 나머지 지식은 필요 시 해당 SKILL.md 단발 임베딩 (기존 Skill Handling 룰 경로). 기록: memory `reference_agent_skills`

## [4.1.1] - 2026-06-12

### Security
- **settings.json 공급망 권한 정합** — `Bash(npm:*)` / `Bash(npx:*)` / `Bash(pnpm:*)` / `Bash(yarn:*)` 와일드카드 allow 가 `rules/secure-coding.md` §Supply chain ("호스트 직접 npm install / npx → 사용자 승인 필수") 을 권한 레이어에서 무력화하던 충돌 해소:
  - allow 는 lockfile-비변경 부분집합만: `npm run` / `npm test` / `pnpm run` / `pnpm test` / `yarn run`
  - `npm install|i|ci|exec` / `npx` / `pnpm install|add|remove|dlx` / `yarn install|add|dlx` → **ask** (defaultMode 무관하게 프롬프트 강제)
  - 판단 근거: 공격 진행 중 재확인 (2026-05-11 TanStack OIDC wave, 05-19 AntV 323 pkg, 06-01 Red Hat Miasma worm — 유효 SLSA provenance 위조, 06월 node-gyp binding.gyp 57 pkg)
- **`install.sh` / `install.ps1` merge 보강** — permissions.allow union 병합만으론 기존 글로벌의 구 wildcard 가 잔존 → 회수 목록 (`npm:*` / `npx:*` / `pnpm:*` / `yarn:*`) 차감 + `permissions.ask` union 병합 추가 (드라이런 검증: 기존 사용자 설정·훅·플러그인 보존)

### Fixed
- `maestro-guard.sh` / `.ps1` — MEMORY.md 화이트리스트 regex 경계 (`(^|/)MEMORY\.md$`): `XMEMORY.md` 류 오매칭 차단
- `install.sh` hooks merge — 기존 설정 위 재설치 시 같은 matcher 의 훅이 이벤트당 중복 등록되던 버그 (훅 2회 실행). matcher 기준 dedupe 로 `.ps1` 과 동작 정합 (드라이런: 중복 0 + declare-guard 등 사용자 추가 훅 보존 + 멱등성 확인)

### Docs
- **README v3.1.1 → v4.1.1 동기화** — 5 Effect/Hard rule, 5d Reviewer·Codex#2 병렬 분업, Codex#1/#2 이중 auto-trigger, axis mechanism + Anomaly Comparator, Dynamic Workflows 하이브리드 반영 (기존 내용은 v3.1 세계관)
- **CHANGELOG 소급 기입** — git 커밋으로만 존재하던 v3.2.0 ~ v4.0.0 엔트리 추가
- `rules/maestro-workflow.md` §Enforcement — 훅 화이트리스트의 `~/.claude/plans/*.md` 명시 (훅↔룰 문서 불일치 해소) + **Known limitation** 명시 (guard 는 Write/Edit/MultiEdit 만 — Bash 경유 변조·NotebookEdit 는 rule-enforced only)

## [4.1.0] - 2026-06-06

### Added
- **Dynamic Workflows 하이브리드 연동 (MVP, research-preview)** — 대규모 병렬 EXECUTE 를 Claude 공식 Dynamic Workflows 로 위임하는 *rule 레벨* 경로:
  - `rules/maestro-workflow.md` §5a — Workflow 위임 trigger 술어 (≥5 독립·사전명세·self-verifiable 항목, `/goal` off, never auto-fire — Phase 4 승인 = opt-in) + **Post-workflow Hard 의무** (완료 후 5c/5d 강제; workflow 완료는 hookable 하지 않으므로 이 rule 이 유일 강제선)
  - 근거·실현가능성·한계: `docs/maestro-vs-dynamic-workflows.md` (비교) + `docs/maestro-hybrid-feasibility.md` (적대적 검증 + ship-blocker probe case B + build log + 훅 제거 결정)
  - ⚠️ `verify-workflow` PostToolUse 훅을 빌드했다가 **제거** — launch 시점에만 발동(완료 hookable 불가)이라 always-loaded rule 대비 증분 가치 없음 + false-confidence 비용 (상세: feasibility §10)

### Rationale
- silent-skip 은 모델 주도 제어 흐름의 증상 — 코드 주도 Workflow 는 5a/5b fan-out 내부의 skip 을 구조적으로 제거 (root-mechanism 교정). 진입 결정과 5c/5d 경계는 모델 주도로 남으므로 rule 의 Hard 의무로 강제
- ship-blocker (workflow-agent write 가 maestro-guard 에 막힘) 는 probe 로 배제 — workflow 에이전트는 `agent_id` 보유해 정상 bypass (case B)

> 아래 v3.2.0 ~ v4.0.0 엔트리는 2026-06-12 (v4.1.1) 에 git 커밋 기록 기반으로 소급 기입.

## [4.0.0] - 2026-05-27

### Changed (paradigm shift, 824 → 702줄)
- **판단을 정적 게이트에서 Phase 1~3 동적 결정으로 이동**:
  - Plan 작성을 built-in **Plan agent 로 분리** (clean context — orchestrator 누적 세션 컨텍스트 오염 회피). Architect 호출은 orchestrator 가 fallback 수행 (Plan agent 는 Task tool 없음)
  - Architect Decision Gate (keyword 사전 + 5문항 self-review) → **5 Effect 영역 prefilter + Hard rule** (ownership / invariants / failure modes 변경 → mandatory, modifier off 불가). 5문항 self-review 폐기 (motivated reasoning 으로 NO 처리 가능했던 흠 제거)
  - 5d 재편: Reviewer 가 Codex#2 호출 책임지던 구조 → **Reviewer (코드 axis) + Codex#2 (test axis) 병렬 분업**, orchestrator 가 raw output 직접 받아 통합 (v3.3.1 의 reviewer Task-tool 부재 silent-skip 문제를 책임 분리로 근본 해결)

### Removed (가드 후퇴 — `docs/maestro-v4-overoptimization-analysis.md` 진단)
- Codex#2 Elevated risk 신호 4 → 1 + skip evidence 강제 삭제, plan-binding deviation 강제 흐름 삭제, Soft Violation 표 17 → 8 — root mechanism 대체 없이 제거된 3개 영역은 silent-skip 재발 관찰 시 v4.0.1 patch 후보로 문서화

## [3.3.1] - 2026-05-27

### Fixed
- **Codex#2 trigger gap patch** (실 운영 silent-skip 사고 대응) — Elevated risk auto-invoke 승격 + reviewer Task-tool 부재 시 orchestrator 직접 invoke Fallback + plan "권장" 라인 plan-committed strength

## [3.3.0] - 2026-05-27

### Changed
- **Framework-agnostic axis mechanism** — 5b/5c 검증의 Rails 종속 제거. 프로젝트별 axis 등록 (`.claude/maestro-axes.md`, opt-in) + 미등록 시 framework auto-detect fallback

## [3.2.1] - 2026-05-27

### Changed
- Codex#2 Architect-Gate auto-trigger + Codex 부재 Fallback 분담 표 + SKILL.md 슬림화 (rules 와의 중복 제거)

## [3.2.0] - 2026-05-26

### Added
- **plan-binding Verification 표 + 5c Anomaly Comparator** — orchestrator 의 conditional 단계 motivated-skip 차단 (count delta / failure count mechanical 비교, dismissal 은 사용자 summary 에 노출)

## [3.1.1] - 2026-05-19

### Changed
- **5b Worker self-test output contract 확장 — lint 추가**:
  - 기존: `tests_run` / `results` / `not_run_reason` / `known_gaps`
  - 신규: `tests_run` / `test_results` / **`lint_run`** / **`lint_results`** / `not_run_reason` / `known_gaps`
  - `results` → `test_results` 키 이름 명확화 (lint_results 와 대칭)
- **5b 정의 보강**: "spec/test 실행" → "spec/test **AND static analysis (lint/typecheck)** 실행". Lint 가 catch 하는 결함 (스타일 / unused import / **타입 mismatch — `tsc --noEmit`, mypy, Sorbet** / anti-pattern) 은 test 만으로 못 잡음을 명시
- **Soft Violation Guard 업데이트**: "worker without `tests_run`" → "worker without `tests_run` or `lint_run`" (둘 다 mandatory, 단 inapplicable 시 `N/A — <reason>` 허용)
- **5c full suite 노트 추가**: 프로젝트 test command 가 lint 포함하면 5c 가 redundant 안전망, 아니면 5b per-worker lint 가 유일한 lint signal
- **Delegation Prompt Template Self-test 섹션** 업데이트 (lint_run / lint_results 명시)

### Rationale
- v3.1.0 의 5b/5c 는 test 실행만 명시, lint 는 프로젝트 test command 의 묶음에 의존 — 묶지 않은 프로젝트에선 누락 위험
- Lint 는 cheap (수초~분) + test 가 못 잡는 결함 다수 catch (특히 타입 mismatch)
- 줄다리기 trade-off — 별도 phase 신설 (sprawl) 대신 기존 5b contract 한 줄 확장으로 최소 변경 max value

### Compatibility
- v3.1.0 plan / agent 와 호환 유지 — `results` 키를 쓰는 기존 worker output 도 reviewer 가 `test_results` 로 해석 가능 (semantic 동일)
- 새 worker delegation 부터는 신규 키 사용 권장

## [3.1.0] - 2026-05-19

### Added
- **Phase 5 substep 명시화 (5a/5b/5c/5d)**: EXECUTE 가 4개 sub-step 으로 분리
  - **5a Implementation** — worker delegation (기존과 동일)
  - **5b Worker self-test (mandatory)** — 각 worker 는 자기 spec 실행 후 output contract 보고 필수: `tests_run` / `results` / `not_run_reason` / `known_gaps`. `tests_run` 없는 보고는 soft violation
  - **5c Full suite run (orchestrator)** — 모든 worker 완료 후 프로젝트 표준 test command 실행 (auto-detect: `bin/test`, `pytest`, `npm test` 등). 회귀 발견 시 해당 worker 에 fix 위임 후 재실행
  - **5d Post-Impl Review (with fix-loop)** — `impl-review → optional Codex#2 test verification → fix-loop decision` 순서. max 3 iteration, 초과 시 `@architect` escalation
- **Project agent auto-discovery (Phase 2 PATTERN)**: `.claude/agents/*.md` 및 `agents/*.md` 자동 스캔 (session-once cache). 도메인 매칭 시 글로벌 에이전트 preempt (예: 프로젝트 `@code-reviewer` → 글로벌 `@architect` 대체). Surface-only, 자동 위임 X — 사용자가 Phase 4 에서 승인
- **Codex#1 adversarial review (Phase 4 APPROVE 자동 trigger)**: complex task (Phase 1 ANALYZE 기준) 시 plan 발표 직전 `codex:codex-rescue` 가 adversarial axis (assumptions / missing edges / conflicting decisions) 로 자동 invoke. Findings 가 plan 에 반영된 후 사용자가 보게 됨. `"코덱스 없이"` modifier 또는 미설치 시 graceful skip
- **Plan template "Verification" 5행**: Phase 4 APPROVE plan template 에 `5a Impl / 5b Self-test / 5c Full suite / 5d Review / 6 Sanity` 5행 명시. 사용자가 plan 발표 단계에서 누락 즉시 발견 가능. Simple task 는 "N/A" 한 줄로 대체
- **Soft Violation Guard 4건 추가**:
  - Worker 보고에 `tests_run` 필드 누락 → re-run 요청
  - 5c full suite skip (complex task) → 항상 실행 필수
  - 발견된 project agent 를 사용자 승인 없이 자동 위임 → candidate 으로만 surface
  - fix-loop 4+ iteration 후에도 escalation 안 함 → max 3 에서 `@architect` escalation

### Changed
- **Phase 6 VERIFY narrow**: `verify-implementation` skill **호출 전용** 으로 좁힘. 테스트 실행은 5b/5c 에서 이미 완료 — Phase 6 는 success criteria sign-off 만. Basic fallback ("git diff, run tests") 도 success criteria checklist 중심으로 변경
- **Codex 자동 trigger 2개 → 1개**: v3.0 의 (1) 사용자 키워드 매칭 (2) stuck 5+ 두 trigger 를 정리 → 자동은 **Codex#1 adversarial 1개만**. 사용자 키워드는 "user-explicit invocation" 으로, stuck 5+ 는 "escalation" 으로 별도 카테고리 분리. fix-loop max 3 초과도 escalation 카테고리에 추가
- **Post-impl review**: `@architect` 강제 → **project reviewer R1 첫 매칭 우선**, 없을 때만 `@architect` fallback. Reviewer 가 Codex#2 (test verification) 를 자체 판단으로 invoke 가능 (자동 trigger 아님)
- **`@architect` role 확장**: post-impl review fallback + fix-loop escalation handler 가 mission 에 명시. `agents/architect.md` Core Mission + Codex Second Opinion 섹션 업데이트
- **Worker output contract 강제**: Delegation Rules > Context Embedding > Prompt Template 에 "Self-test (mandatory before reporting complete)" 섹션 추가. Result Integration 시 5b output contract 확인 단계 명시
- `rules/maestro-workflow.md` v3.0.0 → v3.1.0, `skills/maestro/SKILL.md` 동기화, `agents/architect.md` 보강, `CLAUDE.md` compact instructions 에 Phase 5 substep status 보존 항목 추가, `README.md` Features + Pipeline + v3.0→v3.1 마이그레이션 표 추가

### Removed
- (없음) — v3.0 plan / agent / skill 은 그대로 동작. v3.1 은 추가 가시화 + 누락 방어 layer

### Notes
- 본 릴리스는 실제 프로젝트에서 v3.0 워크플로우 사용 중 발견한 2 결함 대응: (1) project agent 무시 — 프로젝트별 `@<domain>-engineer`, `@code-reviewer` 등을 plan 에 못 surface (2) test 검증 누락 — orchestrator 가 spec design / 실행 / 검증 흐름을 매번 임시 결정
- Architect 및 Codex (codex:codex-rescue task subcommand) 양측 의견 수렴: 둘 다 "Approve with refinements" — Codex#2 흡수 + fix-loop max 3 합의, Phase 6 narrow 도 채택
- 호환성: v3.0 호환 100% — 새 layer 가 추가될 뿐 기존 동작 변경 없음

## [3.0.0] - 2026-05-19

### Breaking
- **`/ultrawork`, `/swarm`, `/ralph` skill 완전 삭제**. 모두 `/maestro` 단일 진입점에 흡수.
  - 자율 모드(이전 `/ultrawork`): `/maestro [task] ... 맡길게` (자연어 modifier로 approval skip + `/goal` 활성화)
  - 병렬 모드(이전 `/swarm`): `/maestro [task] ... 병렬로` (Parallelization 패턴 자동 선택)
  - 자율 반복(이전 `/ralph`): Claude Code 내장 `/goal`로 대체. self-judge → 독립 fast model 검증으로 false completion 위험 감소
  - `.agentic/ralph-loop.state.md` 더 이상 사용 안 함
- **CLAUDE.md Activation 표 4줄 → 1줄**: 단일 명령 + 자연어 modifier 안내로 통일

### Added
- **자연어 modifier 자동 감지** (`skills/maestro/SKILL.md`, `rules/maestro-workflow.md`):
  - `"맡길게"` / `"autonomous"` / `"끝까지"` → approval skip
  - `"병렬로"` / `"동시에"` → Parallelization 패턴 우선
  - `"완료될 때까지"` / `"until done"` → `/goal` 자동 활성화
  - `"코덱스에게도"` / `"교차 검증"` → Codex candidate ON
  - `"코덱스 없이"` → Codex 제외
- **Skill 1차 시민화**: PATTERN 단계에서 사용 가능한 user-invocable skill을 자동 매칭하여 plan에 candidate으로 제시. 사용자 approval에서 확정 (옵션 c 방식)
- **선택적 Codex 통합 (Light mode)**: `codex:codex-rescue` subagent가 가용한 경우에만 활성. 미설치 환경에선 silently skip되어 architect 단독 흐름으로 자연스럽게 fallback
  - 자동 trigger 2개만: (1) 사용자 키워드 매칭, (2) 5+ 시도 stuck 시 강력 권유
  - `agents/architect.md`에 "high-risk / ambiguous 리뷰 시 codex second opinion 재량 호출" 룰 추가
- **README v2.x → v3.0 마이그레이션 표**

### Changed
- `rules/maestro-workflow.md`: Workflow 헤더, Phase 1 ANALYZE(modifier 감지), Phase 2 PATTERN(skill candidate), Phase 5 EXECUTE(architect codex 재량), Mode Behavior 표 단일화, Codex Integration 섹션 신설. v2.0.2 → v3.0.0
- `skills/maestro/SKILL.md`: 완전 재작성 — 단일 진입점으로서의 modifier / skill candidate / codex graceful 룰 명문화
- `README.md` / `CLAUDE.md`: 4모드 → 1모드 + modifier 예시 4개

### Removed
- `skills/ultrawork/`, `skills/swarm/`, `skills/ralph/` 디렉토리 (3개 완전 삭제, deprecate marker 없음)

### Notes
- 본 릴리스는 사용자 실제 패턴 분석 결과 95% 이상 `/maestro`만 사용한다는 점 + `/ultrawork`/`/swarm`이 `/maestro`의 modifier에 불과하다는 점 + `/ralph`의 self-judge가 Claude Code 내장 `/goal`의 독립 검증으로 대체 가능하다는 점에 따라 결정
- 코드 중복 제거 + 사용자 학습 부담 감소 + 신규 modifier 추가 위치 명확화

### Added (prior)
- **`rules/secure-coding.md` 추가**: 글로벌 `~/.claude/rules/`에만 존재하던 보안 코딩 룰을 repo로 backport (KISA + OWASP + CWE 기반). `CLAUDE.md`의 룰 인덱스에도 한 줄 추가. 다음 install/update 시 글로벌과 정합

## [2.0.2] - 2026-05-02

### Changed
- **완료 시그널 토큰 변경**: `<promise>DONE</promise>` → `— 작업 완료 —` (가시성 개선, 사용자 피드백)
  - `rules/maestro-workflow.md`, `skills/maestro/SKILL.md`, `skills/ralph/SKILL.md`, `skills/ultrawork/SKILL.md`, `docs/maestro-summary.md`, `docs/legacy-comparison.md`
  - `ralph` 상태 파일의 `completion_promise` 값도 `"DONE"` → `"작업 완료"`
- **`rules/global.md`에 Git Commit Style 섹션 추가**: 한 줄 커밋 강제, `Co-Authored-By` 금지, `Add:/Update:/Clean:/Fix:/Refactor:` 프리픽스, HEREDOC 지양 — 사용자 Obsidian vault 커밋 스타일 일치

### Removed
- **`skills/note-new`, `skills/note-update` 제거** (deprecate): 별도 플러그인 [`my-note-skills`](https://github.com/half-nomad/my-note-skills)로 분리됨
  - 신규 플러그인은 `~/.claude/my-note-skills/config.json` 기반으로 vault 경로 자동 감지 (구버전은 vault 경로 하드코딩)
  - `note-setup`, `note-summary` 스킬 추가 제공
  - `CLAUDE.md` Activation 표에서도 두 항목 제거

### Notes
- 이번 릴리스는 글로벌 설치본(`~/.claude/`)에 이미 적용되어 있던 변경사항을 repo로 backport하면서, note-* 스킬을 외부 플러그인으로 분리한 것

## [2.0.1] - 2026-04-21

### Fixed
- **Maestro 훅 서브에이전트 차단 버그**: `maestro-guard`가 Task 위임된 서브에이전트의 Write/Edit/MultiEdit까지 차단해 워크플로우 진행 불가였던 문제 해결
  - stdin JSON의 `agent_id` 필드 존재 여부로 메인 오케스트레이터 / 서브에이전트 구분 (실증 확인)
  - 서브에이전트 컨텍스트(`agent_id` 있음) → 통과, 메인 오케스트레이터(`agent_id` 없음) → 기존대로 화이트리스트만 허용
- **메모리 경로 화이트리스트 확장**: `MEMORY.md` 정확 일치만 허용하던 것을 `**/memory/*.md` 전체로 확장
  - `project_*.md`, `feedback_*.md`, `user_*.md`, `reference_*.md` 등 모든 메모리 파일 수정 가능
  - 대소문자 구분 유지 (`/memorY/` 등은 차단), `.md` 확장자 필수

### Changed
- `rules/maestro-workflow.md`: Enforcement 섹션에 allow rules 상세화, `.sh`/`.ps1` 크로스플랫폼 표기
- 버전 통일: Maestro Workflow Rules v2.0.1

## [2.0.0] - 2026-04-08

### Added
- **macOS/Linux bash hook 스크립트**: PowerShell 전용이던 hooks를 크로스 플랫폼 지원
  - `hooks/maestro-guard.sh` — Maestro 모드 파일 수정 차단 (bash 포팅)
  - `hooks/verify-prompt.sh` — Agent 완료 후 검증 리마인더 (bash 포팅)

### Changed
- **install.sh**: `.mcp.json` 없을 시 스킵 처리 + MCP 가이드 조건부 표시
- **update.sh**: `.mcp.json` 없을 시 스킵 처리
- **`.mcp.json`**: 기본 MCP 서버 제거, 빈 구조로 변경 (플러그인으로 대체)
- 버전 통일: README.md, CLAUDE.md, CHANGELOG.md 모두 v2.0.0

---

## [1.8.0] - 2026-02-18

### Added
- **Evaluator 패턴 구현**: `verify-*` 스킬 연동으로 실행 결과 품질 검증
- **Phase 6: VERIFY (Conditional)**: 워크플로우에 조건부 검증 단계 추가
  - 에이전트 2개+, 파일 3개+ 시 자동 제안
  - `verify-*` 스킬 존재 시 자동 실행
  - Ultrawork 모드에서 자동 검증
- **verify-* 스킬 통합 가이드**: `manage-skills`, `verify-implementation` 스킬과의 연동 규칙

### Changed
- Workflow: `ANALYZE → PATTERN → AGENTS → APPROVE → EXECUTE → [VERIFY]`
- Integration with Modes: VERIFY behavior specified per mode (Default/Maestro/Ultrawork)
- Evaluator pattern: from declaration-only to concrete implementation
- `maestro-workflow.md`: Semi-Auto Mode removed (non-existent mode), replaced with actual mode definitions
- `maestro-workflow.md`: All Korean text converted to English prompts
- `boulder.json` restored via skill prompts (replaces deleted hooks mechanism)
  - `maestro/SKILL.md`: Read boulder.json on start, write on completion
  - `ultrawork/SKILL.md`: Same read/write behavior
  - `session-summary/SKILL.md`: Also writes boulder.json for non-orchestrated sessions

### Fixed
- `ultrawork/SKILL.md`: Removed deprecated `/ulw` alias reference
- `README.md`: Changed `/ulw` example to `/ultrawork`
- `README.md`: Added `/note-new`, `/note-update` missing from v1.7

---

## [1.7.0] - 2026-02-15

### Added
- `/note-new` 스킬: Obsidian 새 노트 생성 + 파일 Inbox 복사 + 템플릿 지원
- `/note-update` 스킬: Obsidian 볼트 관련 문서 검색 + 업데이트
- `argument-hint` 프론트매터 필드 활용 (note-new, note-update)

### Changed
- `/mynote` → `/note-new`로 대체 (기능 확장)

### Fixed
- 5개 기존 스킬에서 비공식 `invocation: user` 프론트매터 제거

---

## [1.6.0] - 2026-02-09

### Removed
- `hooks/` 폴더 전체 삭제 (skill 시스템으로 대체)
- 글로벌/프로젝트 settings.json hooks 설정 전체 제거
- `~/.claude/hooks/` 글로벌 hook 스크립트 8개 삭제
- `explanatory-output-style` 플러그인 비활성화 (Windows .sh 비호환)
- `/frontend`, `/librarian`, `/oracle` skills 삭제 (Task tool 직접 호출과 중복)
- `/ulw` skill 삭제 (`/ultrawork`의 불필요한 alias)

### Fixed
- 글로벌 + 프로젝트 hooks 이중 실행 문제 (매 프롬프트 12개 PowerShell 프로세스 → 0개)

---

## [1.5.0] - 2026-02-03

### Changed
- **commands → skills 마이그레이션**: Claude Code v2.1.3 skills 시스템으로 전환
- **Skills 구조**: `skills/{name}/SKILL.md` 형식으로 변경
- `/ralph-start` + `/ralph-cancel` → `/ralph start|cancel`로 통합

### Removed
- `commands/` 폴더 전체 (skills로 대체)
- `/frontend`, `/librarian`, `/oracle` commands (에이전트 직접 호출로 대체)
- `ulw.md` + `ultrawork.md` 중복 제거

### Added
- `skills/maestro/SKILL.md`
- `skills/ultrawork/SKILL.md`
- `skills/ulw/SKILL.md` (alias)
- `skills/swarm/SKILL.md`
- `skills/ralph/SKILL.md` (start/cancel 통합)
- `skills/session-summary/SKILL.md`

### Fixed
- 설치 스크립트 업데이트 (commands → skills)

---

## [1.4.0] - 2026-01-28

### Changed
- Planning 방식 변경: Built-in Plan 에이전트 → Plan Mode 직접 수행
- 워크플로우: ANALYZE → PATTERN → [PLAN MODE] → APPROVE → EXECUTE

### Added
- Plan Mode Integration 섹션 (maestro-workflow.md)
- EnterPlanMode/ExitPlanMode 도구 활용 가이드
- Plan Mode 허용/금지 작업 명시

### Rationale
- 복잡한 작업에서 대화 맥락 유지로 계획 품질 향상
- 사용자 승인 프로세스 명확화
- 탐색은 여전히 Explore에 위임하여 컨텍스트 절약

---

## [1.3.0] - 2026-01-27

### Added
- **Swarm Mode**: `/swarm` 또는 `swarm:` 키워드로 병렬 에이전트 실행
- **boulder.json**: 세션 간 계획 상태 유지 메커니즘
- `hooks/boulder-manager.ps1/sh`: 상태 로드/저장 훅

### Changed
- `hooks/keyword-detector.ps1/sh`: swarm 키워드 감지 추가
- `settings.json`: 새 훅 등록
- **Patterns**: 4+1 → 5+1 (Swarm 추가)

---

## [1.2.0] - 2026-01-26

### Added
- **Orchestrator Role Definition (CRITICAL)**: Explicit allowed/forbidden actions for orchestrator
- **Tool Permissions Table**: Clear matrix of which tools orchestrator vs sub-agents can use
- **Self-Check Checklist**: Mental interrupt before using forbidden tools

### Changed
- **commands/maestro.md**: Simplified from 63 → 23 lines, removes duplication with rules
- **Delegation loophole removed**: "Single domain, < 3 files → Direct execution OK" changed to require delegation
- **Handle Failures**: Now specifies delegation attempts, not direct execution
- **Result Integration**: Clarified that modifications must be delegated, not done directly
- **Chaining Pattern example**: Updated to show proper delegation

### Fixed
- Main agent tendency to directly execute code/document CRUD instead of delegating
- Information duplication between `commands/maestro.md` and `rules/maestro-workflow.md`

---

## [1.1.1] - 2026-01-23

### Changed
- **Agent tools 설정 수정**: `tools: *` / `tools: all` 제거, 모든 도구 상속 방식으로 변경
- **permissionMode 추가**: `acceptEdits`로 Write/Edit 자동 승인 설정

### Fixed
- 공식 Claude Code 문서에 맞지 않는 tools 필드 문법 수정 (`*`, `all` → 필드 생략)

---

## [1.1.0] - 2026-01-15

### Added
- **Agent Priority System**: Project Agents > Global Agents > Dynamic Roles
- **Dynamic Role Template**: Create specialist roles on-demand for domains without pre-defined agents
- **Delegation Rules (MANDATORY)**: Enforce Task tool usage when agents identified in plan
- Color indicators for global agents (🔵🟢🟡🟣)

### Changed
- **CLAUDE.md simplified**: 193 → 67 lines (65% reduction), detailed rules moved to `rules/maestro-workflow.md`
- **Agent tools expanded**: `@architect`, `@frontend-engineer`, `@document-writer` now use `tools: *` (all tools)
- **@librarian**: Kept limited tools (research-only, no file modification)
- `rules/maestro-workflow.md`: v1.1 with delegation rules, agent priority, anti-patterns
- `docs/maestro-summary.md`: v1.1 with updated agent system documentation

### Fixed
- Context accumulation issue: Added mandatory delegation to distribute context across sub-agents

---

## [1.0.1] - 2026-01-11

### Added
- `docs/maestro-summary.md`: Comprehensive Maestro workflow documentation

### Removed
- `commands/manual.md`: Redundant (default mode is manual)
- `commands/semi-auto.md`: Redundant (merged into Maestro/Ultrawork)
- `skills/codebase-analysis/`: Replaced by built-in Explore + @architect
- `skills/deep-research/`: Replaced by @librarian agent

### Changed
- **Mode system simplified**: Default / Maestro / Ultrawork (was 3 modes)
- Updated README.md and CLAUDE.md to reflect mode changes

---

## [1.0.0] - 2026-01-11

### Added
- **Maestro Workflow**: New pattern-based orchestration system
  - 5 Anthropic patterns: Chaining, Parallelization, Routing, Orchestrator-Workers, Evaluator
  - 5-phase execution: ANALYZE → PATTERN → AGENTS → APPROVE → EXECUTE
  - `/maestro` command for explicit orchestrator activation
- `rules/maestro-workflow.md`: Detailed workflow rules and pattern selection guide
- `docs/legacy-comparison.md`: Migration documentation from Sisyphus

### Changed
- **CLAUDE.md**: Complete rewrite for Maestro workflow
- **Mode system**: Manual/Semi-Auto/Ultrawork now affect Maestro autonomy level
- **Keyword detector hooks**: Updated to inject Maestro patterns on ultrawork activation
- `frontend-engineer` agent: Added MCP tool permissions (chrome-devtools, playwright, hyperbrowser)

### Removed
- `agents/codebase-explorer.md`: Replaced by built-in `Explore` subagent
- `agents/task-planner.md`: Replaced by built-in `Plan` subagent
- `commands/plan.md`: Replaced by `/maestro`
- `commands/execute.md`: Integrated into Maestro flow
- `rules/sisyphus-phases.md`: Replaced by `maestro-workflow.md`
- Legacy Sisyphus 4-phase system (EXPLORE→PLAN→EXECUTE→VERIFY)

### Migration
- Legacy workflow preserved in `legacy/sisyphus-v1` branch
- See `docs/legacy-comparison.md` for detailed migration notes
