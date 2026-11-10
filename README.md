# agentic-workflow

Claude Code 를 위한 **duo** 워크플로. Claude 가 직접 구현하고, Codex CLI 가 계획과 구현을 각각 한 번씩 검토하며, 계획 검토에는 `@architect` 가 병렬로 붙습니다.

## 개요

이 저장소는 duo 의 **배포본 소스**입니다. `git clone` 후 `install.sh` / `install.ps1` 을 실행하면 `skills/duo/`, 에이전트 `architect`, 훅 `claude-md-sync` 가 사용자의 `~/.claude/` 에 심볼릭 링크(Windows 는 복사)로 연결됩니다. 배포된 설정은 곧 이 저장소의 워킹트리이므로 갱신의 본질은 `git pull` 입니다 — 정확한 절차는 아래 §업데이트를 참고하세요.

**상주하는 것은 없습니다.** `~/.claude/rules/` 와 `~/.claude/CLAUDE.md` 에는 아무것도 놓지 않고, 필수 훅도 없습니다. duo 는 스킬이라 작업이 기준에 맞을 때만 로드됩니다. 코딩 규율·보안 정책·메모리 규약처럼 상시 적용되는 것은 사람마다 다르므로 배포하지 않습니다 — 그 자리는 여러분의 것이고, 설치·갱신·제거 어느 것도 건드리지 않습니다.

> **Maestro 는 v6.0.0 에서 은퇴했습니다.** 이 저장소가 원래 배포하던 오케스트레이션 워크플로(`/maestro`)와 그 가드 훅 3개를 뺐습니다. 마지막 상태는 git 태그 `maestro-final` 에 있고, 되살리는 법은 [`CHANGELOG.md`](CHANGELOG.md) v6.0.0 과 [`docs/migrations.md`](docs/migrations.md) 에 있습니다. 설계 기록은 `docs/` 에 역사로 남겨 두었습니다.
>
> 이전 버전에서 올라오신다면 → [`docs/migrations.md`](docs/migrations.md) — **훅 등록을 먼저 지워야 합니다.**

## duo 가 하는 일

**연주자는 Claude 와 Codex. 계획 검토에는 architect 가 함께 앉습니다.** 네이티브 plan mode 에 코덱스의 계획 검토와 구현 검토를 붙이고, 계획 검토에 `@architect` 를 병렬로 둔 것이 전부입니다. 그 사이는 Claude 자율입니다 — 훅도, 상태 파일도, 절차표도 없습니다.

- **켜는 판단은 Claude 가**: 작업이 기준에 맞으면 묻지 않고 켜고 한 줄로 알립니다(*"duo 로 진행합니다 — <이유>"*). 사용자는 언제든 멈출 수 있습니다. 경계선에서 안 켰을 때도 한 줄 남깁니다.
- **계획 검토 (승인 전)**: 코덱스에게 사용자 원 요청 원문 · 배경 · 계획 전문을 주고 세 가지를 받습니다 — 코드와 어긋나는 사실 주장(반증), 이 계획이 틀렸다면 대신 할 것(대안), 계획 밖(원 요청·기존 제품과의 차이, 계획에 없는 비용). 같은 자료로 `@architect` 가 데이터 주인 · 불변 조건 · 실패 처리를 봅니다. 채택 여부는 Claude 가 코드로 확인한 뒤 정합니다.
- **구현 검토 (완료 전)**: 읽기 검토와 변형 검사(mutation — 구현을 일부러 틀리게 바꿔 테스트가 실제로 죽는지 확인). 변형 검사는 격리된 worktree 에서 합니다. worktree 가 실제로 막혔을 때만 원래 작업 트리에서 하되, 변형할 파일을 먼저 백업하고 Claude 가 직접 변형·복원한 뒤 바이트 단위로 원본과 같은지 확인합니다. 둘 다 안 되면 변형 검사를 하지 않고 그렇다고 보고합니다. **고치는 것은 Claude 입니다** — 코덱스의 출력은 수정 지시가 아니라 수정 입력입니다.
- **되돌리기 어려운 작업**(보안 · 결제 · 운영 데이터 · 마이그레이션 · 삭제/이동 · 배포 · 공개 API · 외부 발송)에는 변형 검사 필수 · 지적 해결 확인 · 실행마다 사용자 승인이 더해집니다.
- **검증 축이 없으면 완료를 선언하지 않습니다**: 테스트·린트·빌드가 전부 없으면 무엇을 확인하지 못했는지와 직접 확인할 것을 알려 줍니다.
- **알아들을 수 있는 보고**: 내부 용어는 처음 나올 때 `용어(쉬운 설명)` 로 한 번 풀고, 결과는 **만든 것 / 확인한 방법 / 확인 못 한 것 / 할 일** 순서로 보고합니다.

자세한 규칙과 근거는 [`skills/duo/SKILL.md`](skills/duo/SKILL.md) 가 정본입니다.

### 사용법

```bash
/duo [작업 설명]
```

직접 치지 않아도 Claude 가 기준에 맞으면 켭니다.

| 표현 | 적용 |
|---|---|
| `"코덱스 없이"` · `"main만"` | 계획 검토의 코덱스 off — 구현 검토는 남습니다 |
| `"맡길게"` · `"알아서"` · `"끝까지"` | 계획 승인 생략 — 계획은 보이되 자동 진행 |

### 운영 모드

| 모드 | 활성화 | 용도 |
|---|---|---|
| **기본** | (명령 없음) | 답이 하나로 정해져 있고, 실패해도 되돌리면 그만 |
| **Duo** | Claude 가 판단해 켜고 알림 · `/duo [task]` | 불확실한 설계 판단 · 모듈 경계/상태/공개 계약에 영향 · 독립 검토가 유용 · 재작업 비용이 큼 · 되돌리기 어려움 (하나라도) |

> **파일 수로 나누지 않습니다.** 20개 파일의 기계적 rename 은 저위험이고, 한 파일의 인증 변경은 고위험입니다.

### Codex 준비

duo 의 두 검토는 Codex CLI(`codex exec`)를 직접 호출합니다 — openai-codex 플러그인은 쓰지 않습니다. 명령의 정본은 [`skills/duo/reference/codex-cli.md`](skills/duo/reference/codex-cli.md) 입니다. Codex 가 없거나 응답하지 않으면 그 축을 `N/A — 코덱스 확인 실패` 로 보고에 남기고, 독립 축이 0 인 채로 완료를 선언하지 않습니다.

Codex 는 `~/.codex/AGENTS.md` 를 읽습니다. 그 파일은 **여러분의 것이라 이 저장소가 쓰지 않습니다.** Codex 에게 Claude 와 같은 전역 룰을 보이려면 거기에 한 줄을 추가하세요(선택):

```markdown
Also read ~/.claude/rules/*.md and apply those rules identically when working here.
```

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

Windows 는 심볼릭 링크에 개발자 모드(또는 관리자 권한)가 필요해 대신 파일을 **복사**합니다. 배포한 경로는 `~\.claude\.maestro-manifest.txt` 에 기록되고(이름은 이전 버전과의 호환을 위해 그대로입니다), 이후 `uninstall.ps1` 은 이 목록만 근거로 제거합니다.

설치 후 Claude Code 를 재시작하세요.

### 업데이트

**Linux / macOS / WSL**

```bash
git -C <repo 경로> pull && <repo 경로>/install.sh
```

`git pull` 만으로는 부족합니다 — 상류에 새로 추가된 파일은 아직 링크가 없고, 삭제되거나 이름이 바뀐 파일은 죽은 링크(dangling link)로 남습니다. `install.sh` 를 다시 실행하면 새 링크를 만들고 이 저장소를 가리키는 죽은 링크를 정리(sweep)합니다 — 이미 올바른 항목은 조용히 건너뛰므로 재실행은 언제나 안전합니다.

**Windows (PowerShell)**

```powershell
git pull
.\install.ps1
```

Windows 는 복사 방식이라 `git pull` 이 상류를 자동으로 추적하지 않습니다 — 두 단계 모두 매번 필요합니다.

### 제거

**Linux / macOS / WSL**

```bash
./uninstall.sh
```

이 저장소 안쪽을 가리키는 심볼릭 링크만 제거합니다. 실제 파일은 `-type l` 검사에서 걸러지고, 다른 곳을 가리키는 링크는 저장소 경로 접두사 매칭에서 걸러지므로 여러분이 직접 둔 파일이나 개인 훅은 **구조적으로** 삭제될 수 없습니다.

**Windows (PowerShell)**

```powershell
.\uninstall.ps1
```

`~\.claude\.maestro-manifest.txt` 에 기록된 경로만 제거합니다. 매니페스트가 없으면 파일명으로 추측하지 않고 **실행을 거부**합니다.

## 훅 등록 (선택, 최초 1회)

duo 는 훅이 필요 없습니다. 이 저장소가 배포하는 훅은 `claude-md-sync` 하나이고, **CLAUDE.md 를 고칠 때 같은 폴더의 AGENTS.md 를 다시 만드는** 도구입니다(Codex 는 CLAUDE.md 대신 AGENTS.md 를 읽습니다). AGENTS.md 안 어디에든 `<!-- maestro-codex: sync-from-claude -->` 표시가 있는 폴더에서만 동작하고(훅이 첫 줄에 이 표시를 써 넣습니다), 파일 어디에도 표시가 없으면 아무것도 하지 않습니다. 동기화를 끊으려면 이 표시를 파일에서 모두 지우세요. 쓰지 않으면 등록하지 않아도 됩니다.

어떤 스크립트도 `settings.json` 을 쓰지 않습니다. 이 파일은 개인 키와 개인 훅이 섞여 있는 자리라, 병합 로직이 한 번만 잘못돼도 보안 훅이 실제로 발동하는지를 결정하는 그 파일이 망가집니다. 아래 블록을 `~/.claude/settings.json` 의 `hooks` 에 **이어붙이세요** — `hooks` 값 전체를 덮어쓰면 보안 훅을 포함한 자신의 훅이 **조용히** 꺼집니다.

### Linux / macOS / WSL (Git Bash 포함)

`settings.json` 에 실제로 들어 있는 `hooks` 값을 그대로 옮긴 것입니다 (아래 블록과 저장소 원본이 어긋나면 버그입니다):

```json
{
  "PostToolUse": [
    {
      "matcher": "Edit|Write|MultiEdit",
      "hooks": [
        {
          "type": "command",
          "command": "sh -c 'if command -v powershell >/dev/null 2>&1; then powershell -NoProfile -ExecutionPolicy Bypass -File \"$HOME/.claude/hooks/claude-md-sync.ps1\"; else bash \"$HOME/.claude/hooks/claude-md-sync.sh\"; fi'"
        }
      ]
    }
  ]
}
```

`sh -c 'if command -v powershell ... else bash ... fi'` 형태를 단순한 `bash ...` 호출로 줄이지 마세요 — `sh` 와 `powershell` 이 둘 다 있는 Windows 위 Git Bash 환경을 구분하는 디스패처입니다.

### Windows (네이티브 PowerShell)

```json
{
  "PostToolUse": [
    {
      "matcher": "Edit|Write|MultiEdit",
      "hooks": [
        {
          "type": "command",
          "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.claude\\hooks\\claude-md-sync.ps1\""
        }
      ]
    }
  ]
}
```

> 이 네이티브 Windows 스니펫은 실제 Windows 에서 검증되지 않았습니다 — macOS 의 pwsh 7 에서 실행만 확인했습니다. 훅 `command` 에서 `%USERPROFILE%` 이 전개되지 않으면 절대 경로로 바꿔 써야 합니다.

**제거 시**: `command` 에 `claude-md-sync` 가 들어간 항목을 지우고, 비어버린 배열은 함께 지우세요. 등록이 남은 채 스크립트가 사라지면 매칭되는 모든 도구 호출이 에러를 냅니다.

## 주의사항

1. **심볼릭 링크는 "통과해서" 쓰고, 절대 덮어쓰지 마세요.** `~/.claude/hooks/claude-md-sync.sh` 는 저장소 안쪽을 가리키는 링크이므로, 그 파일을 편집하는 것이 곧 저장소를 편집하는 것입니다. 하지만 `sed -i` 나, 임시 파일에 쓴 뒤 rename 하며 저장하는 에디터는 **링크 자체를 일반 파일로 바꿔버립니다.** 그 순간 배포본이 저장소에서 조용히 갈라지고 이후 업데이트를 받지 못합니다. 판단이 서지 않으면 `install.sh` 를 재실행하세요 — 이미 올바른 항목은 건드리지 않고, 갈라진 것은 백업한 뒤 링크로 되돌립니다.
2. **배포된 skill 디렉터리 안쪽에는 절대 쓰지 마세요.** `~/.claude/skills/duo` 는 저장소의 `skills/duo` 그 자체이므로, 거기에 쓴 것은 무엇이든 git 워킹트리에 그대로 들어갑니다.
3. **저장소를 옮기면 배포 전체가 깨집니다.** 체크아웃을 옮기는 순간 `~/.claude/` 에 심어둔 링크 전부가 죽은 링크가 되고, 등록한 훅이 있으면 매칭되는 모든 도구 호출이 에러를 냅니다. 제거 스크립트도 경로 접두사로 자기 링크를 판별하므로 아무것도 지우지 못합니다(조용히 넘어가지 않고 알립니다). 옮기기 전에 제거하거나, 새 위치에서 `install.sh` 를 다시 실행하세요.
4. **`~/.claude/rules/` 와 `~/.claude/CLAUDE.md` 는 전부 사용자의 것입니다.** 이 저장소는 거기에 아무것도 놓지 않습니다. 설치 과정에서 밀려나는 파일은 전부 `~/.claude/.maestro-backup-<타임스탬프>/` 로 옮겨지고 경로가 출력됩니다 — 조용히 지워지는 것은 없습니다. 이 저장소의 `CLAUDE.md` 는 기여자용 지침입니다.
5. **저장소 워킹트리가 곧 라이브 설정입니다.** 이 체크아웃에서 하는 모든 git 작업 — 다른 브랜치로 `checkout`, `rebase`, `stash`, `reset --hard`, 커밋하지 않은 편집까지 — 이 `~/.claude` 가 서빙하는 내용을 **즉시** 바꿉니다. 실험적 브랜치는 별도 clone(또는 worktree)에서 작업하고, 브랜치를 옮긴 뒤에는 `install.sh` 를 다시 실행하세요.

## 구성 요소

### 에이전트

| 에이전트 | 모델 | 용도 |
|---|---|---|
| 🔵 `@architect` | Fable 5.2 (effort high) | 설계 판단·검토 — duo 계획 검토에 상시 병렬 |

모델과 깊이는 에이전트 정의 파일이 정합니다 — 부를 때 `model` 을 적으면 정의를 덮어씁니다. 다른 역할이 필요하면 general-purpose 에 역할·맥락을 담아 부릅니다. 프로젝트의 `.claude/agents/` 에 있는 에이전트는 Claude Code 가 자동으로 찾습니다.

### 스킬

| 스킬 | 설명 |
|---|---|
| `/duo [task]` | 기본 워크플로(v0.6.0). 네이티브 구현 + 코덱스 CLI 의 계획 검토·구현 검토 + 계획 검토에 `@architect` 병렬 |

자율 반복은 Claude Code 내장 `/goal` 을 씁니다. Obsidian 노트 스킬은 별도 플러그인 [`my-note-skills`](https://github.com/half-nomad/my-note-skills).

## 디렉토리 구조

```
agentic-workflow/
├── agents/           # architect 하나 — 파일 단위로 ~/.claude/agents/ 에 링크
├── skills/duo/       # duo 스킬 (+ reference/codex-cli.md — 코덱스 호출 명령 정본) — 디렉터리 단위로 ~/.claude/skills/ 에 링크
├── hooks/            # claude-md-sync (.sh + .ps1) — 파일 단위로 ~/.claude/hooks/ 에 링크, 등록은 선택
├── docs/             # 시점 기록 — 은퇴한 maestro 의 설계 기록 포함. 각 문서의 판단을 그때 그대로 둡니다 (현재 동작은 skills/ 와 이 README 가 정본)
├── CLAUDE.md         # 이 저장소 기여자용 지침 — 사용자 환경에 배포하지 않음 (AGENTS.md 는 여기서 생성)
├── install.sh        # Linux/macOS/WSL 설치·업데이트 (심볼릭 링크 방식)
├── install.ps1       # Windows 설치·업데이트 (복사 + 매니페스트 기록)
├── uninstall.sh      # Linux/macOS/WSL 제거 (저장소 안쪽 링크만)
├── uninstall.ps1     # Windows 제거 (매니페스트 기반)
├── settings.json     # Claude Code 설정 예시 (permissions, 선택 훅) — 링크·자동 병합 대상 아님
└── .mcp.json         # MCP 서버 설정 (비어 있음)
```

## 문제 해결

### 스킬이나 에이전트가 보이지 않음

```bash
./install.sh  # 또는 install.ps1 — 재설치 후 Claude Code 재시작
```

## 알려진 한계

### Windows 경로는 실제 Windows 에서 검증되지 않았습니다

`install.ps1` · `uninstall.ps1` 과 `hooks/*.ps1` 은 **macOS 의 pwsh 7 에서만** 실행 검증됐습니다. POSIX 쪽(`install.sh` · `uninstall.sh`)은 심볼릭 링크·백업·멱등·언인스톨을 격리된 `$HOME` 에서 실측했지만, Windows 경로는 그 환경에서 재현되지 않는 부분이 남아 있습니다.

| 항목 | 왜 macOS 에서 확인이 안 되나 |
|---|---|
| **PowerShell 5.1** | Windows 기본 셸. `ResolveLinkTarget` 이 없어 `claude-md-sync.ps1` 이 심볼릭 링크를 해석하지 못하고, 이 경우 미러링을 **건너뛰도록** 만들어 뒀다. 그 분기가 실제로 발동하는지 미확인 |
| **백슬래시 경로** | macOS 의 `Join-Path` 는 `/` 를 만든다. `\` 환경에서 경로 비교·봉쇄 로직이 같게 동작하는지 미확인 |
| **`%USERPROFILE%` 전개** | 위 네이티브 PowerShell 훅 스니펫이 이 변수를 쓴다. 전개되지 않으면 절대 경로로 바꿔 써야 한다 |
| **manifest 경로 봉쇄** | `uninstall.ps1` 은 manifest 의 각 경로를 정규화해 배포 루트 안인지 검사한 뒤에만 지운다. `..\` 를 포함한 항목이 실제로 거부되는지 확인 필요 |
| **manifest 지문 검사** | `install.ps1` 은 배포한 파일의 해시를 기록하고, 재설치·제거 시 해시가 다르면 **지우지 않고 백업**한다. NTFS 에서 같게 동작하는지 확인 필요 |

## 라이선스

MIT

## 크레딧

- Anthropic "Building Effective Agents" 가이드 기반
- [Oh My OpenCode](https://github.com/code-yeongyu/oh-my-opencode) 프로젝트에서 영감

---

*agentic-workflow v6.0.0 — duo v0.6.0*
