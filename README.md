# agentic-workflow

Claude Code를 위한 Maestro 오케스트레이션 시스템. 패턴 기반 에이전트 워크플로우로 복잡한 작업을 체계적으로 자동화합니다.

## 개요

agentic-workflow는 Claude Code CLI에 최적화된 **Maestro** 오케스트레이션 시스템입니다. Claude가 오케스트레이터 역할을 수행하여 작업을 분석하고, 적절한 패턴을 선택하고, 필요한 에이전트를 식별한 후 계획을 제출합니다.

이 저장소는 Maestro의 **배포본 소스**입니다. `git clone` 후 `install.sh` / `install.ps1`을 실행하면 에이전트 4개, 훅, `rules/maestro-workflow.md`, `skills/maestro/` 가 사용자의 `~/.claude/`에 심볼릭 링크(Windows는 복사)로 연결됩니다. 배포된 설정은 곧 이 저장소의 워킹트리이므로, 갱신의 본질은 `git pull`입니다 — 정확한 절차와 왜 그것만으로 부족한지는 아래 §업데이트를 참고하세요. 훅 등록은 최초 1회 수동으로 합니다 (아래 §훅 등록 참조).

**이 저장소가 배포하는 것은 Maestro 하나입니다.** `~/.claude/rules/` 에 놓는 파일은 `maestro-workflow.md` 뿐이고, 코딩 규율·보안 정책·메모리 규약처럼 상시 적용되는 것은 사람마다 다르므로 배포하지 않습니다 — 그 자리는 여러분의 것이고, 설치·갱신·제거 어느 것도 건드리지 않습니다.

**그 한 파일도 ~60줄짜리 스텁입니다.** 목표 4개와 그것을 지키는 절대 규칙만 상주하고, 나머지는 `/maestro` 를 호출할 때 스킬로 로드됩니다. `/maestro` 를 쓰지 않는 세션까지 전문을 지고 다닐 이유가 없기 때문입니다 — compact 후 유실은 PostCompact 훅이 재주입으로 처리합니다.

## Maestro 가 달성하려는 것

**이 넷이 목표이고, 동시에 모든 규약의 판정 기준입니다.**

1. **사용자가 계획을 먼저 본다** — 통제권이 사용자에게 있습니다
2. **오케스트레이터는 직접 짜지 않고 위임한다** — 컨텍스트를 관리하고 전문성을 씁니다
3. **"확인했다"는 말에 증거가 따른다** — 거짓 완료를 막습니다
4. **되돌리기 어려운 결정에는 다른 관점이 붙는다** — 단일 시점의 오판을 막습니다

강제되는 것은 목표당 최소선 하나씩이고, **절차·템플릿·판정표는 지시가 아니라 참고**(`skills/maestro/reference/`)입니다. 목표를 만족한다면 방법은 모델의 판단에 맡깁니다 — 다르게 했으면 무엇을 왜 다르게 했는지 기록하고, 그 기록으로 참고를 고치거나 강제로 승격시킵니다.

> **왜 이렇게 바꿨나**: 이전 버전은 사고가 날 때마다 지시를 추가해 상주 348줄까지 왔습니다. 안정성은 얻었지만 그 대가로 성능을 제한했습니다 — 지시가 늘수록 개별 지시의 구속력이 떨어지고, 모델이 더 나은 방법을 알아도 절차가 막습니다. 그래서 판정 기준을 *"이 지시가 있으면 더 안전한가"*(답이 거의 항상 yes 라 규칙이 무한히 쌓입니다)에서 **"이 지시가 없으면 목표가 깨지는가"** 로 바꿨습니다. 매 런 로드량은 35,447자 → 12,904자가 됐고, 내려간 절차는 삭제된 게 아니라 참조에 그대로 있습니다.

**`~/.claude/CLAUDE.md` 도 건드리지 않습니다.** `rules/*.md` 와 `CLAUDE.md` 는 시스템 프롬프트에 같은 tier 로 실리므로(둘 다 *user's private global instructions for all projects*), 룰 파일로 배포해도 동작이 같습니다. 덮어쓸 이유가 없으니 덮어쓰지 않습니다 — 여러분의 전역 지시는 그대로 유지됩니다.

### Codex 를 함께 쓴다면 (선택, 최초 1회)

Codex 는 `~/.codex/AGENTS.md` 를 읽습니다. 그 파일도 **여러분의 것이라 이 저장소가 쓰지 않습니다.** Codex 에게 Claude 와 같은 룰을 보이려면 거기에 한 줄만 추가하세요:

```markdown
Also read ~/.claude/rules/*.md and apply those rules identically when working here.
```

Maestro 의 Codex 교차검증(Codex#1 / Codex#2)은 프로젝트 디렉터리에서 실행되므로 이 설정 없이도 동작합니다. 위 한 줄은 Codex 가 **전역 룰까지** 보게 하려는 경우에만 필요합니다.

> 이전 버전에서 올라오신다면 → [`docs/migrations.md`](docs/migrations.md)

## 주요 특징

- **단일 진입점 `/maestro`**: 모든 복잡 작업은 `/maestro`로 시작. autonomy / parallel / goal / codex는 자연어로 자동 분기
- **Plan agent 분리 + 5 Effect/Hard rule**: plan 작성은 built-in Plan agent (clean context) 위임. Architect 호출은 5 Effect 영역 prefilter + **Hard rule** (ownership / invariants / failure modes 변경 → mandatory, modifier off 불가) 로 결정
- **명시적 테스트 + lint 단계 (5b/5c)**: Worker self-test (output contract — `tests` / `lint` / `build` (+ 등록 axis) / `known_gaps`) + 오케스트레이터 full suite 실행 + **Anomaly Comparator** (mechanical baseline 비교 — 추상 표현 dismissal 금지). 적용 불가 axis 는 `N/A — <reason>` 명시
- **Framework-agnostic axis mechanism**: 검증 axis 는 프로젝트가 `.claude/maestro-axes.md` 로 opt-in 등록, 미등록 시 framework auto-detect fallback
- **프로젝트 에이전트 자동 발견**: `~/.claude/agents/` + `.claude/agents/` + `agents/` 3 위치 스캔 (session-once cache). 도메인 매칭 시 글로벌 에이전트 preempt (예: 프로젝트 `@code-reviewer` → 글로벌 `@architect` 대체)
- **Post-impl review (5d) — Reviewer·Codex#2 병렬 분업**: orchestrator 가 Reviewer (코드 axis — project R1 첫 매칭 또는 `@architect` fallback) 와 Codex#2 (test axis) 를 직접 병렬 호출 → 두 출력 통합 → fix-loop max 3 → 초과 시 `@architect` escalation
- **Codex 교차검증 — 계획은 기본 on, 구현은 표적**: 계획 적대 검토는 complex 로 계획을 만들었으면 기본 실행합니다(끄는 경우는 셋 — 사용자 modifier·확립된 패턴의 단순 확장·simple 판정). **계획이 틀리면 그 뒤 작업이 전부 낭비이므로 여기가 가장 싸고 이익이 큽니다.** 구현 공격(mode A)은 공유 컴포넌트·클라이언트 상태·요청 간 상태 이동·Hard rule 인접, 그리고 **절차와 다르게 판단한 런**에만 겁니다 — 이미 만든 것이 대상이라 늦고 비싸기 때문입니다. user-explicit / stuck 5+ escalation 은 별도 카테고리
- **Dynamic Workflows 하이브리드**: ≥5 독립·사전명세·자기검증 항목의 대규모 병렬 EXECUTE 를 Workflow 툴로 위임 가능 (never auto-fire — Phase 4 승인 필수, 완료 후 5c/5d Hard 의무)
- **Skill 1차 시민화**: 스캔 단계에서 사용 가능한 skill을 자동 매칭, 사용자 approval로 확정
- **선택적 Codex 통합**: companion CLI 직접 호출. 미설치 환경에선 무음 fallback (architect 단독 흐름 — 단 mode T 등가 대체일 뿐 교차벤더 적대 축은 미충족으로 남습니다)
- **도구 기반 검증 (Phase 6)**: success criteria sign-off — 프로젝트에 `verify-*` 스킬이 있으면 활용, 없으면 `git diff` 리뷰 + 체크리스트 (테스트 실행은 5b/5c 에서 이미 완료)
- **순수 오케스트레이터 역할**: 메인은 위임만, 직접 파일 수정은 hooks로 차단
- **Context Embedding**: 서브에이전트에 스키마/패턴/제약 직접 주입 (5b output contract 요구사항 포함)
- **알아들을 수 있는 보고**: 내부 용어를 숨기지도 그냥 던지지도 않습니다 — 처음 나올 때 `용어(쉬운 설명)` 로 한 번 풀어 쓰고, 결과는 **만든 것 / 확인한 방법 / 확인 못 한 것 / 할 일** 네 가지로 보고합니다
- **검증 축이 없으면 완료를 선언하지 않음**: 테스트·린트·빌드가 전부 없는 프로젝트에서 `— 작업 완료 —` 를 출력하지 않습니다. 대신 무엇을 확인하지 못했는지와 직접 확인할 것을 알려줍니다 — 검증 수단 부재는 완료의 사유가 아니라 미완료의 내용이기 때문입니다
- **4개 전문 에이전트**: architect (fable), frontend-engineer (opus), librarian (sonnet), document-writer (sonnet) + 자동 발견되는 프로젝트 에이전트
- **State Persistence**: MEMORY.md로 세션 간 컨텍스트 유지

## 설치 방법

### Linux / macOS / WSL

```bash
git clone https://github.com/half-nomad/agentic-workflow.git
cd agentic-workflow
chmod +x install.sh
./install.sh
```

### Windows (PowerShell)

```powershell
git clone https://github.com/half-nomad/agentic-workflow.git
cd agentic-workflow
.\install.ps1
```

Windows는 심볼릭 링크에 개발자 모드(또는 관리자 권한)가 필요해 대신 파일을 **복사**합니다. 배포한 경로는 `~\.claude\.maestro-manifest.txt`에 기록되고, 이후 `uninstall.ps1`은 이 목록만 근거로 제거합니다.

설치 후 Claude Code를 재시작하세요.

### 업데이트

**Linux / macOS / WSL**

```bash
git -C <repo 경로> pull && <repo 경로>/install.sh
```

`git pull`만으로는 부족합니다 — 상류에 새로 추가된 파일은 아직 링크가 없고, 삭제되거나 이름이 바뀐 파일은 죽은 링크(dangling link)로 남습니다. 죽은 링크는 `rules/`에 있으면 해당 룰이 조용히 로드를 멈추고, `hooks/`에 있으면 그 링크와 매칭되는 모든 도구 호출이 에러를 냅니다. `install.sh`를 다시 실행하면 새 링크를 만들고 죽은 링크를 정리(sweep)합니다 — 이미 올바른 항목은 조용히 건너뛰므로 재실행은 언제나 안전하고 비용이 없습니다.

**Windows (PowerShell)**

```powershell
git pull
.\install.ps1
```

Windows는 복사 방식이라 `git pull`이 상류를 자동으로 추적하지 않습니다 — 두 단계 모두 매번 필요합니다.

### 제거

**Linux / macOS / WSL**

```bash
./uninstall.sh
```

이 저장소 안쪽을 가리키는 심볼릭 링크만 제거합니다. 실제 파일은 `-type l` 검사에서 걸러지고, 다른 곳을 가리키는 링크는 저장소 경로 접두사 매칭에서 걸러지므로 여러분이 `rules/`에 직접 둔 파일이나 개인 훅은 **구조적으로** 삭제될 수 없습니다.

**Windows (PowerShell)**

```powershell
.\uninstall.ps1
```

`~\.claude\.maestro-manifest.txt`에 기록된 경로만 제거합니다. 매니페스트가 없으면 파일명으로 추측하지 않고 **실행을 거부**합니다.

## 훅 등록 (최초 1회)

어떤 스크립트도 `settings.json`을 쓰지 않습니다. 이 파일은 사용자의 개인 키를 담고 개인 훅과 이 저장소의 훅이 뒤섞여 있는 자리라, 병합 로직이 단 한 번만 잘못돼도 정작 보안 훅이 실제로 발동하는지를 결정하는 그 파일이 망가집니다. 한 번 붙여넣는 블록이 한 번 잘못될 수 있는 스크립트보다 안전합니다. 아래 블록을 `~/.claude/settings.json`의 `hooks`에 한 번만 등록하면 이후로는 다시 손댈 필요가 없습니다 — 훅 경로는 심볼릭 링크를 가리키고, 그 링크는 항상 저장소의 최신 파일로 해석되기 때문입니다.

**교체가 아니라 이어붙이기입니다.** `PreToolUse` / `PostCompact` / `PostToolUse` 중 하나라도 이미 항목이 있다면, 아래 블록으로 `hooks` 값 전체를 덮어쓰지 말고 각 이벤트의 기존 배열에 이어붙이세요. 자기 훅을 이미 등록해 둔 사람일수록 이 실수를 저지르기 쉽고, 통째로 덮어쓰면 보안 훅을 포함한 자신의 훅이 **조용히** 꺼집니다 — 이 섹션에서 나올 수 있는 최악의 결과입니다.

### Linux / macOS / WSL (Git Bash 포함)

`settings.json`에 실제로 들어 있는 `hooks` 값을 그대로 옮긴 것입니다 (아래 블록과 저장소 원본이 어긋나면 버그입니다):

```json
{
  "PreToolUse": [
    {
      "matcher": "Write|Edit|MultiEdit",
      "hooks": [
        {
          "type": "command",
          "command": "sh -c 'if command -v powershell >/dev/null 2>&1; then powershell -NoProfile -ExecutionPolicy Bypass -File \"$HOME/.claude/hooks/maestro-guard.ps1\"; else bash \"$HOME/.claude/hooks/maestro-guard.sh\"; fi'"
        }
      ]
    }
  ],
  "PostCompact": [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "sh -c 'if command -v powershell >/dev/null 2>&1; then powershell -NoProfile -ExecutionPolicy Bypass -File \"$HOME/.claude/hooks/maestro-compact-reload.ps1\"; else bash \"$HOME/.claude/hooks/maestro-compact-reload.sh\"; fi'"
        }
      ]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "Edit|Write|MultiEdit",
      "hooks": [
        {
          "type": "command",
          "command": "sh -c 'if command -v powershell >/dev/null 2>&1; then powershell -NoProfile -ExecutionPolicy Bypass -File \"$HOME/.claude/hooks/claude-md-sync.ps1\"; else bash \"$HOME/.claude/hooks/claude-md-sync.sh\"; fi'"
        }
      ]
    },
    {
      "matcher": "Agent",
      "hooks": [
        {
          "type": "command",
          "command": "sh -c 'if command -v powershell >/dev/null 2>&1; then powershell -NoProfile -ExecutionPolicy Bypass -File \"$HOME/.claude/hooks/verify-prompt.ps1\"; else bash \"$HOME/.claude/hooks/verify-prompt.sh\"; fi'"
        }
      ]
    }
  ]
}
```

`sh -c 'if command -v powershell ... else bash ... fi'` 형태를 단순한 `bash ...` 호출로 줄이지 마세요 — `sh`와 `powershell`이 둘 다 있는 Windows 위 Git Bash 환경을 구분하는 디스패처입니다. 단순화하면 지금 정상 동작 중인 사용자 환경이 깨집니다.

### Windows (네이티브 PowerShell)

`sh -c`와 `$HOME`이 없는 환경이라 별도 스니펫이 필요합니다:

```json
{
  "PreToolUse": [
    {
      "matcher": "Write|Edit|MultiEdit",
      "hooks": [
        {
          "type": "command",
          "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.claude\\hooks\\maestro-guard.ps1\""
        }
      ]
    }
  ],
  "PostCompact": [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.claude\\hooks\\maestro-compact-reload.ps1\""
        }
      ]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "Edit|Write|MultiEdit",
      "hooks": [
        {
          "type": "command",
          "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.claude\\hooks\\claude-md-sync.ps1\""
        }
      ]
    },
    {
      "matcher": "Agent",
      "hooks": [
        {
          "type": "command",
          "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.claude\\hooks\\verify-prompt.ps1\""
        }
      ]
    }
  ]
}
```

> 이 네이티브 Windows 스니펫은 실제 Windows에서 검증되지 않았습니다 — macOS의 pwsh 7에서 실행만 확인했습니다. 훅 `command`에서 `%USERPROFILE%`이 전개되지 않으면 절대 경로로 바꿔 써야 합니다.

**제거 시**: `command`에 `maestro-guard` / `maestro-compact-reload` / `claude-md-sync` / `verify-prompt`가 들어간 네 항목을 지우고, 비어버린 배열은 함께 지우세요. 빈 배열을 남겨두면 스크립트가 사라진 뒤로 매칭되는 모든 도구 호출이 에러를 냅니다.

## 주의사항

1. **심볼릭 링크는 "통과해서" 쓰고, 절대 덮어쓰지 마세요.** `~/.claude/rules/maestro-workflow.md`는 저장소 안쪽을 가리키는 링크이므로, 그 파일을 편집하는 것이 곧 저장소를 편집하는 것입니다 — 이게 원래 의도입니다. 하지만 `sed -i`나, 임시 파일에 쓴 뒤 원래 이름으로 rename하며 저장하는 에디터는 **링크 자체를 일반 파일로 바꿔버립니다.** 그 순간 배포본이 저장소에서 조용히 갈라지고 이후 업데이트를 받지 못합니다. `find ~/.claude -maxdepth 2 -type f`로 후보를 찾을 수 있지만, 이 명령은 `settings.json`이나 `rules/`의 사용자 파일들, 개인 훅처럼 **원래부터 일반 파일이어야 하는 것들도 그대로 나열**하므로 결과는 걸러서 봐야 합니다 — 찾는 대상은 "원래 링크여야 하는데 일반 파일이 된 것"뿐입니다. 어느 쪽이든 판단이 서지 않으면 `install.sh`를 재실행하세요 — 이미 올바른 항목은 건드리지 않고, 갈라진 것만 링크로 되돌립니다.
2. **배포된 skill 디렉터리 안쪽에는 절대 쓰지 마세요.** `~/.claude/skills/maestro`는 저장소의 `skills/maestro` 그 자체이므로, 거기에 쓴 것은 무엇이든 git 워킹트리에 그대로 들어갑니다.
3. **저장소를 옮기면 제거가 깨지는 것보다 먼저 배포 전체가 깨집니다.** 체크아웃을 옮기는 순간 `~/.claude/`에 심어둔 링크 전부가 죽은 링크(dangling link)가 됩니다 — `rules/`가 조용히 로드를 멈추고(`secure-coding`도 예외가 아니므로 이는 곧 소리 없는 보안 회귀입니다), `hooks/`를 가리키던 모든 도구 호출이 에러를 내기 시작합니다 (증상은 §업데이트에서 설명한 것과 동일합니다). 그 위에 제거 스크립트도 깨집니다: 링크는 절대 경로를 기억하고, 제거 스크립트는 그 경로 접두사로 자신이 만든 링크인지 판별하는데, 체크아웃 위치를 옮기면 아무것도 매칭되지 않아 아무것도 지워지지 않습니다 (조용히 넘어가지 않고 명확히 알립니다). 옮기기 전에 제거하거나, 새 위치에서 `install.sh`를 다시 실행하세요.
4. **`~/.claude/rules/`의 나머지 파일은 전부 사용자의 것입니다.** 이 저장소가 `rules/`에 놓는 것은 **`maestro-workflow.md` 하나뿐**이고, 인스톨러는 그 한 파일만 allowlist로 배치합니다 — glob이 아니라서, 나중에 이 저장소에 같은 이름의 룰이 추가돼도 당신 파일을 밀어내지 않습니다. `rules/`의 파일은 소유자와 무관하게 전부 `CLAUDE.md`처럼 모든 프로젝트에 로드되므로, 머신 한정이거나 개인적인 지시는 거기에 아무 이름으로나 적으면 됩니다. 설치 과정에서 밀려나는 파일은 전부 `~/.claude/.maestro-backup-<타임스탬프>/`로 옮겨지고 경로가 출력됩니다 — 조용히 지워지는 것은 없습니다. `~/.claude/CLAUDE.md`도 예외가 아닙니다 — 거기에 사용자 고유의 지시가 들어 있더라도 다른 모든 경로와 **똑같은 규칙**으로 백업되고(원본 바이트 그대로 남습니다), 그 자리에는 저장소를 가리키는 링크가 들어섭니다. 설치가 중단되지는 않습니다.
5. **저장소 워킹트리가 곧 라이브 설정입니다.** 복사 방식은 "저장소 상태"와 "배포 상태" 사이에 완충 지대를 뒀지만, 심볼릭 링크는 그 완충을 의도적으로 없앴습니다. 이 체크아웃에서 하는 모든 git 작업 — 다른 브랜치로 `checkout`, `rebase`, `stash`, `reset --hard`, 심지어 커밋하지 않고 저장만 한 편집까지 — 이 `~/.claude`가 서빙하는 내용을 **즉시** 바꿉니다. 가드 훅과 보안 룰을 포함해서, 모든 프로젝트·모든 실행 중인 세션에 동시에요. 이 저장소 자체를 작업 대상으로 삼고 있다면 자신의 전역 설정이 지금 작업 중인 브랜치를 따라 함께 움직인다고 예상하세요 — 그걸 원치 않는 실험적 브랜치는 별도 clone(또는 worktree)에서 작업하고, 브랜치를 옮긴 뒤에는 항상 `install.sh`를 다시 실행해 추가·삭제된 파일을 재연결하세요.

## Maestro 워크플로우

### 사용법

```bash
/maestro [작업 설명]
```

### 워크플로우 단계

1. **ANALYZE** - 작업 복잡도 평가 + 자연어 modifier 감지 + Architect prefilter (5 Effect + Hard rule)
   → **simple 판정이면 여기서 바로 5. EXECUTE 로 직행**합니다 (plan 없음). 아래 2~4 는 complex 이거나 `goal` modifier 가 있을 때만 거칩니다.
2. **스캔** - 프로젝트 에이전트 자동 발견 (3 위치) + skill candidates
3. **[PLAN MODE]** - built-in Plan agent (clean context) 가 plan 작성 + Architect mandatory/on/skip 마킹 → orchestrator 가 Architect 호출
4. **APPROVE** - Codex#1 adversarial review (Hard rule 영역 또는 되돌리기 어려운 변경일 때) + 사용자 승인
5. **EXECUTE** - 5a 구현 → 5b worker self-test → 5c full suite + Anomaly Comparator → 5d Reviewer·Codex#2 병렬 분업 (fix-loop max 3)
6. **[VERIFY]** - success criteria sign-off (프로젝트에 `verify-*` 스킬이 있으면 활용)

### 자연어 Modifier (Phase 1 ANALYZE에서 자동 감지)

| 표현 | 적용되는 동작 |
|------|---|
| `"맡길게"` / `"autonomous"` / `"끝까지"` | approval skip — 계획 후 바로 실행 |
| `"병렬로"` / `"동시에"` | 독립 항목의 병렬 위임 선호 |
| `"완료될 때까지"` / `"until done"` | Claude Code 내장 `/goal` 자동 활성화 |
| `"코덱스에게도"` / `"교차 검증"` / `"second opinion"` | Codex candidate ON (설치 시) |
| `"코덱스 없이"` / `"main만"` | Codex 제외 |

### 실행 파이프라인 (Phase 5 substeps)

Maestro 모드의 EXECUTE 단계는 다음 4 sub-step 으로 구성:

```
5a 구현 (worker delegation — ≥5 독립·사전명세 항목은 Workflow 위임 후보)
  ↓
5b worker self-test (output contract: tests / lint / build / known_gaps)
  ↓
5c orchestrator full suite run + Anomaly Comparator (회귀 0 확인)
  ↓
5d post-impl review — 병렬 분업 (orchestrator 가 직접 호출·통합)
   ├─ Reviewer: 코드 axis (project R1 첫 매칭 or @architect fallback)
   ├─ Codex#2: test axis (complex auto — Codex 부재 시 @architect 분담)
   └─ fix-loop (max 3, 초과 시 @architect escalation)
  ↓
[final sanity sign-off — verify-* 스킬 있으면 그것으로]
```

- **오케스트레이터**: 관찰, 위임, 5c 풀 스위트 실행, 5d 병렬 호출·통합. 직접 파일 수정은 hooks가 차단
- **워커 서브에이전트**: 위임받은 작업을 직접 실행 (파일 수정 가능) + required axes 실행 후 5b output contract 보고
- **리뷰어 (5d)**: 프로젝트 `*-reviewer.md` R1 매칭 우선, 없으면 `@architect` fallback. Codex#2 는 리뷰어가 아닌 **orchestrator 가 병렬로 직접 invoke** (v4.0 분업)
- **Phase 6 VERIFY**: success criteria sign-off — `verify-*` 스킬이 있으면 그것으로 (테스트 실행은 5b/5c 에서 이미 완료)

## 구성 요소

### Agents (에이전트)

#### 에이전트 우선순위

```
1️⃣ Project Agents   → 프로젝트 agents/ 폴더 우선
2️⃣ Global Agents    → 전역 에이전트
3️⃣ Dynamic Roles    → 동적 역할 생성
```

#### 전역 에이전트

| 에이전트 | 모델 | Tools | 용도 |
|---------|------|-------|------|
| 🔵 `@architect` | Opus | inherited | 전략적 자문, 아키텍처 결정 |
| 🟢 `@frontend-engineer` | Opus | inherited | UI/UX, 컴포넌트, 스타일링 |
| 🟡 `@librarian` | Sonnet | limited | 문서 리서치, API 레퍼런스 |
| 🟣 `@document-writer` | Sonnet | inherited | README, 가이드 문서 작성 |

#### 동적 역할

프로젝트 에이전트와 전역 에이전트 모두에 해당 도메인 전문가가 없을 때만 **동적 역할**로 생성됩니다.

#### 빌트인 에이전트

`Explore` (코드베이스 검색), `general-purpose` (동적 역할). 계획 수립은 Plan Mode에서 직접 수행.

### Skills (슬래시 커맨드)

| Skill | 설명 |
|-------|------|
| `/maestro [task]` | 단일 오케스트레이터 진입점. 자연어 modifier로 autonomy / parallel / goal / codex 자동 분기 |

> `verify-*` · `manage-skills` 는 이 레포가 배포하지 않습니다 — 프로젝트에 있으면 Phase 6 에서 활용하고, 없으면 `git diff` 리뷰로 대체합니다 (선택 의존성).

에이전트는 `@architect`, `@frontend-engineer`, `@librarian`, `@document-writer`로 직접 호출합니다.
자율 반복은 Claude Code 내장 `/goal`을 사용 (별도 ralph loop 불필요).
Obsidian 노트 스킬은 별도 플러그인 [`my-note-skills`](https://github.com/half-nomad/my-note-skills).

### Operating Mode (단일)

| 모드 | 활성화 | 특징 | 용도 |
|------|--------|------|------|
| **Default** | (명령 없음) | 일반 Claude 상호작용 | 단순 작업, 직접 지시 |
| **Maestro** | `/maestro [task]` | 계획→승인→위임→리뷰→검증. 자연어 modifier로 동작 변화 | 복잡한 구현, 리스크 있는 변경 |

### State Persistence (상태 유지)

세션 간 컨텍스트는 MEMORY.md의 `## Next Session` 섹션에 저장됩니다. MEMORY.md는 시스템 프롬프트에 자동 로드되므로 별도의 Read가 필요 없습니다.

**사용 방법**:
- **계속하기**: "계속" 또는 "continue" 입력 시 이전 컨텍스트에서 재개
- **새로 시작**: "새로 시작" 또는 "new" 입력 시 `## Next Session` 초기화

## 사용 예시

### 예시 1: 복잡한 기능 구현 (기본 — approval 있음)

```bash
/maestro 사용자 인증 기능 구현
```

→ @architect 설계 → APPROVE → 구현 에이전트 위임 → @architect 리뷰 → 검증

### 예시 2: 자율 모드 (이전 `/ultrawork` 대체)

```bash
/maestro TODO 목록 전부 처리하고 테스트까지 끝까지 맡길게
```

→ `"끝까지"` + `"맡길게"` 감지 → **approval skip** (둘 다 같은 modifier 입니다). `/goal` 을 함께 켜려면 `"완료될 때까지"` / `"until done"` 처럼 **완료 조건을 말하는 표현**을 씁니다 — 트리거가 별개입니다

### 예시 3: 병렬 리서치 (이전 `/swarm` 대체)

```bash
/maestro React, Vue, Angular 에러 핸들링 동시에 비교 조사
```

→ `"동시에"` 감지 → Parallelization 패턴 **우선 선택**(강제가 아니라 preferred) → 3개 @librarian 병렬 → 결과 합성

### 예시 4: Codex 교차 검증

```bash
/maestro 이 PR 아키텍처 리뷰, 코덱스에게도 의견 받아
```

→ `@architect` 리뷰 + Codex second opinion (companion 직접 호출) → 두 의견 통합 보고
(Codex 미설치 시 자동으로 architect 단독 흐름)

## 디렉토리 구조

```
agentic-workflow/
├── agents/           # 전문 에이전트 (architect, frontend, librarian, document-writer) — 파일 단위로 ~/.claude/agents/ 에 링크
├── skills/           # Skills (maestro) — 디렉터리 단위로 ~/.claude/skills/ 에 링크
├── rules/            # maestro-workflow.md 하나뿐 — allowlist 로 ~/.claude/rules/ 에 링크 (나머지 rules/ 는 사용자 것)
├── hooks/            # Hook 스크립트 (maestro-guard, verify-prompt 등) — .ps1 + .sh 크로스 플랫폼, 파일 단위로 ~/.claude/hooks/ 에 링크
├── docs/             # 시점 기록 — 각 문서 상단에 작성일이 있고, 그때의 판단을 그대로 둡니다 (현재 동작은 rules/ 와 이 README 가 정본)
├── CLAUDE.md         # 진입점 — 활성화 명령, 상태 관리. ~/.claude/CLAUDE.md 로 통째 링크
├── install.sh        # Linux/macOS/WSL 설치·업데이트 스크립트 (심볼릭 링크 방식)
├── install.ps1       # Windows 설치·업데이트 스크립트 (복사 + 매니페스트 기록)
├── uninstall.sh      # Linux/macOS/WSL 제거 스크립트 (저장소 안쪽 링크만 제거)
├── uninstall.ps1     # Windows 제거 스크립트 (매니페스트 기반)
├── settings.json     # Claude Code 설정 (hooks, permissions) — 링크·자동 병합 대상 아님, 훅 등록은 수동 (§훅 등록)
└── .mcp.json         # MCP 서버 설정 (context7, grep-app)
```

## 문제 해결

### 에이전트가 작동하지 않음

```bash
# 재설치
./install.sh  # 또는 install.ps1
```

## 알려진 한계

### Windows 경로는 실제 Windows 에서 검증되지 않았습니다

`install.ps1` · `uninstall.ps1` 과 `hooks/*.ps1` 은 **macOS 의 pwsh 7 에서만** 실행 검증됐습니다. POSIX 쪽(`install.sh` · `uninstall.sh`)은 심볼릭 링크·백업·멱등·언인스톨을 격리된 `$HOME` 에서 전부 실측했지만, Windows 경로는 그 환경에서 재현되지 않는 부분이 남아 있습니다.

Windows 에서 쓰시거나 검증에 기여하실 수 있다면, 아래가 확인이 필요한 지점입니다:

| 항목 | 왜 macOS 에서 확인이 안 되나 |
|---|---|
| **PowerShell 5.1** | Windows 기본 셸. `ResolveLinkTarget` 이 없어 `claude-md-sync.ps1` 이 심볼릭 링크를 해석하지 못하고, 이 경우 Codex 미러링을 **건너뛰도록** 만들어 뒀다 (잘못 추측해 링크 너머로 쓰는 것보다 안전). 그 분기가 실제로 발동하는지 미확인 |
| **백슬래시 경로** | macOS 의 `Join-Path` 는 `/` 를 만든다. `\` 환경에서 경로 비교·봉쇄 로직이 같게 동작하는지 미확인 |
| **`%USERPROFILE%` 전개** | README 의 네이티브 PowerShell 훅 스니펫이 이 변수를 쓴다. 훅 `command` 안에서 전개되지 않으면 절대 경로로 바꿔 써야 한다 |
| **manifest 경로 봉쇄** | `uninstall.ps1` 은 manifest 의 각 경로를 정규화해 배포 루트 안인지 검사한 뒤에만 지운다. `..\` 를 포함한 항목이 실제로 거부되는지 확인 필요 |
| **manifest 지문 검사** | `install.ps1` 은 배포한 파일의 해시를 기록하고, 재설치·제거 시 해시가 다르면 **지우지 않고 백업**한다. `Get-FileHash` 동작과 디렉터리 지문 계산이 NTFS 에서 같은지 확인 필요 |

Windows 는 심볼릭 링크에 개발자 모드가 필요해 **복사 + manifest** 방식으로 배포합니다. POSIX 의 링크 방식과 구조가 다르므로, 위 항목은 POSIX 쪽 검증으로 대체되지 않습니다.

## 라이선스

MIT

## 크레딧

- Anthropic "Building Effective Agents" 가이드 기반
- [Oh My OpenCode](https://github.com/code-yeongyu/oh-my-opencode) 프로젝트에서 영감

---

*Maestro Workflow v5.1.0*
