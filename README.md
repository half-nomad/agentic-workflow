# agentic-workflow

Claude Code를 위한 Maestro 오케스트레이션 시스템. 패턴 기반 에이전트 워크플로우로 복잡한 작업을 체계적으로 자동화합니다.

## 개요

agentic-workflow는 Claude Code CLI에 최적화된 **Maestro** 오케스트레이션 시스템입니다. Claude가 오케스트레이터 역할을 수행하여 작업을 분석하고, 적절한 패턴을 선택하고, 필요한 에이전트를 식별한 후 계획을 제출합니다.

이 저장소는 Maestro의 **배포본 소스**입니다. `git clone` 후 `install.sh` / `install.ps1`을 실행하면 저장소의 `CLAUDE.md`, `agents/`, `rules/`, `hooks/`, `skills/`가 사용자의 `~/.claude/`에 심볼릭 링크(Windows는 복사)로 연결됩니다. 배포된 설정은 곧 이 저장소의 워킹트리이므로, 갱신은 대부분 `git pull` 한 번으로 끝납니다 — 예외는 `settings.json` 뿐이며, 훅 등록은 최초 1회 수동으로 합니다 (아래 §훅 등록 참조).

## 주요 특징

- **단일 진입점 `/maestro`**: 모든 복잡 작업은 `/maestro`로 시작. autonomy / parallel / goal / codex는 자연어로 자동 분기
- **Plan agent 분리 + 5 Effect/Hard rule (v4.0)**: plan 작성은 built-in Plan agent (clean context) 위임. Architect 호출은 5 Effect 영역 prefilter + **Hard rule** (ownership / invariants / failure modes 변경 → mandatory, modifier off 불가) 로 결정
- **명시적 테스트 + lint 단계 (5b/5c)**: Worker self-test (output contract — `tests` / `lint` / `build` (+ 등록 axis) / `known_gaps`) + 오케스트레이터 full suite 실행 + **Anomaly Comparator** (mechanical baseline 비교 — 추상 표현 dismissal 금지). 적용 불가 axis 는 `N/A — <reason>` 명시
- **Framework-agnostic axis mechanism (v3.3)**: 검증 axis 는 프로젝트가 `.claude/maestro-axes.md` 로 opt-in 등록, 미등록 시 framework auto-detect fallback
- **프로젝트 에이전트 자동 발견**: `~/.claude/agents/` + `.claude/agents/` + `agents/` 3 위치 스캔 (session-once cache). 도메인 매칭 시 글로벌 에이전트 preempt (예: 프로젝트 `@code-reviewer` → 글로벌 `@architect` 대체)
- **Post-impl review (5d) — Reviewer·Codex#2 병렬 분업 (v4.0)**: orchestrator 가 Reviewer (코드 axis — project R1 첫 매칭 또는 `@architect` fallback) 와 Codex#2 (test axis) 를 직접 병렬 호출 → 두 출력 통합 → fix-loop max 3 → 초과 시 `@architect` escalation
- **Codex 이중 auto-trigger**: complex task 시 Codex#1 (plan adversarial, Phase 4) + Codex#2 (test verification, Phase 5d) 자동 invoke. user-explicit / stuck 5+ escalation 은 별도 카테고리
- **Dynamic Workflows 하이브리드 (v4.1, research-preview)**: ≥5 독립·사전명세·자기검증 항목의 대규모 병렬 EXECUTE 를 Workflow 툴로 위임 가능 (never auto-fire — Phase 4 승인 필수, 완료 후 5c/5d Hard 의무)
- **Skill 1차 시민화**: PATTERN 단계에서 사용 가능한 skill을 자동 매칭, 사용자 approval로 확정
- **선택적 Codex 통합**: `codex:codex-rescue` 미설치 환경에선 무음 fallback (architect 단독 흐름)
- **도구 기반 검증 (Phase 6)**: success criteria sign-off — 프로젝트에 `verify-*` 스킬이 있으면 활용, 없으면 `git diff` 리뷰 + 체크리스트 (테스트 실행은 5b/5c 에서 이미 완료)
- **순수 오케스트레이터 역할**: 메인은 위임만, 직접 파일 수정은 hooks로 차단
- **Context Embedding**: 서브에이전트에 스키마/패턴/제약 직접 주입 (5b output contract 요구사항 포함)
- **4+1 패턴**: Chaining, Parallelization, Routing, Orchestrator-Workers, Evaluator
- **4개 전문 에이전트**: architect (opus), frontend-engineer (opus), librarian (sonnet), document-writer (sonnet) + 자동 발견되는 프로젝트 에이전트
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

이 저장소 안쪽을 가리키는 심볼릭 링크만 제거합니다. 실제 파일은 `-type l` 검사에서 걸러지고, 다른 곳을 가리키는 링크는 저장소 경로 접두사 매칭에서 걸러지므로 `rules/personal.md`나 개인 훅 같은 사용자 파일은 구조적으로 삭제될 수 없습니다.

**Windows (PowerShell)**

```powershell
.\uninstall.ps1
```

`~\.claude\.maestro-manifest.txt`에 기록된 경로만 제거합니다. 매니페스트가 없으면 파일명으로 추측하지 않고 **실행을 거부**합니다.

## 훅 등록 (최초 1회)

어떤 스크립트도 `settings.json`을 쓰지 않습니다. 이 파일은 사용자의 개인 키를 담고 개인 훅과 이 저장소의 훅이 뒤섞여 있는 자리라, 병합 로직이 단 한 번만 잘못돼도 정작 보안 훅이 실제로 발동하는지를 결정하는 그 파일이 망가집니다. 한 번 붙여넣는 블록이 한 번 잘못될 수 있는 스크립트보다 안전합니다. 아래 블록을 `~/.claude/settings.json`의 `hooks`에 한 번만 등록하면 이후로는 다시 손댈 필요가 없습니다 — 훅 경로는 심볼릭 링크를 가리키고, 그 링크는 항상 저장소의 최신 파일로 해석되기 때문입니다.

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

이미 `PreToolUse` / `PostToolUse` 항목이 있다면 교체하지 말고 기존 배열에 이어붙이세요.

**제거 시**: `command`에 `maestro-guard` / `maestro-compact-reload` / `claude-md-sync` / `verify-prompt`가 들어간 네 항목을 지우고, 비어버린 배열은 함께 지우세요. 빈 배열을 남겨두면 스크립트가 사라진 뒤로 매칭되는 모든 도구 호출이 에러를 냅니다.

## 주의사항

1. **심볼릭 링크는 "통과해서" 쓰고, 절대 덮어쓰지 마세요.** `~/.claude/rules/global.md`는 저장소 안쪽을 가리키는 링크이므로, 그 파일을 편집하는 것이 곧 저장소를 편집하는 것입니다 — 이게 원래 의도입니다. 하지만 `sed -i`나, 임시 파일에 쓴 뒤 원래 이름으로 rename하며 저장하는 에디터는 **링크 자체를 일반 파일로 바꿔버립니다.** 그 순간 배포본이 저장소에서 조용히 갈라지고 이후 업데이트를 받지 못합니다. `find ~/.claude -maxdepth 2 -type f`로 링크여야 하는데 일반 파일이 된 것을 찾을 수 있고, `install.sh`를 재실행하면 다시 링크로 되돌립니다.
2. **배포된 skill 디렉터리 안쪽에는 절대 쓰지 마세요.** `~/.claude/skills/maestro`는 저장소의 `skills/maestro` 그 자체이므로, 거기에 쓴 것은 무엇이든 git 워킹트리에 그대로 들어갑니다.
3. **저장소를 옮기면 제거가 깨집니다.** 링크는 절대 경로를 기억하고, 제거 스크립트는 그 경로 접두사로 자신이 만든 링크인지 판별합니다. 체크아웃 위치를 옮기면 아무것도 매칭되지 않아 아무것도 지워지지 않습니다 (조용히 넘어가지 않고 명확히 알립니다). 옮기기 전에 제거하거나, 새 위치에서 `install.sh`를 다시 실행하세요.
4. **`~/.claude/rules/personal.md`는 사용자의 것입니다.** 이 저장소는 이 파일을 배포하지도, 덮어쓰지도, 지우지도 않습니다 — `CLAUDE.md`와 똑같이 모든 프로젝트에 로드되므로, 이 머신에만 해당하거나 개인적인 지시는 여기에 적으세요. 설치 과정에서 밀려나는 파일은 전부 `~/.claude/.maestro-backup-<타임스탬프>/`로 옮겨지고 경로가 출력됩니다 — 조용히 지워지는 것은 없습니다. `~/.claude/CLAUDE.md`에 이미 사용자 고유의 지시가 들어 있다면, 설치는 그걸 덮어쓰지 않고 **중단**됩니다.

## Maestro 워크플로우

### 사용법

```bash
/maestro [작업 설명]
```

### 워크플로우 단계

1. **ANALYZE** - 작업 복잡도 평가 + 자연어 modifier 감지 + Architect prefilter (5 Effect + Hard rule)
2. **PATTERN** - 실행 패턴 선택 + 프로젝트 에이전트 자동 발견 (3 위치) + skill candidates
3. **[PLAN MODE]** - built-in Plan agent (clean context) 가 plan 작성 + Architect mandatory/on/skip 마킹 → orchestrator 가 Architect 호출
4. **APPROVE** - Codex#1 adversarial review (자동, complex task) + 사용자 승인
5. **EXECUTE** - 5a 구현 → 5b worker self-test → 5c full suite + Anomaly Comparator → 5d Reviewer·Codex#2 병렬 분업 (fix-loop max 3)
6. **[VERIFY]** - success criteria sign-off (프로젝트에 `verify-*` 스킬이 있으면 활용)

### 패턴 선택 가이드

| 패턴 | 사용 시점 | 예시 |
|------|----------|------|
| **Chaining** | 순차 의존 단계 | Build → Test → Deploy |
| **Parallelization** | 독립 병렬 작업 (이전 `/swarm` 흡수) | 3개 API 동시 검색, 다중 소스 리서치 |
| **Routing** | 조건부 분기 | 에러 타입별 핸들러 |
| **Orchestrator-Workers** | 복잡한 다중 도메인 | 전체 기능 구현 |
| **Evaluator** | 실행 결과 품질 검증 | 프로젝트가 `verify-*` 스킬을 제공하면 연동, PR 전 검증 |

### 자연어 Modifier (Phase 1 ANALYZE에서 자동 감지)

| 표현 | 적용되는 동작 |
|------|---|
| `"맡길게"` / `"autonomous"` / `"끝까지"` | approval skip — 계획 후 바로 실행 |
| `"병렬로"` / `"동시에"` | Parallelization 패턴 우선 선택 |
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

→ `"끝까지"` + `"맡길게"` 감지 → approval skip + `/goal` 자동 활성화로 완료까지 자율 반복

### 예시 3: 병렬 리서치 (이전 `/swarm` 대체)

```bash
/maestro React, Vue, Angular 에러 핸들링 동시에 비교 조사
```

→ `"동시에"` 감지 → Parallelization 패턴 강제 → 3개 @librarian 병렬 → 결과 합성

### 예시 4: Codex 교차 검증

```bash
/maestro 이 PR 아키텍처 리뷰, 코덱스에게도 의견 받아
```

→ `@architect` 리뷰 + `codex:codex-rescue` second opinion → 두 의견 통합 보고
(`codex:codex-rescue` 미설치 시 자동으로 architect 단독 흐름)

## 디렉토리 구조

```
agentic-workflow/
├── agents/           # 전문 에이전트 (architect, frontend, librarian, document-writer) — 파일 단위로 ~/.claude/agents/ 에 링크
├── skills/           # Skills (maestro, secure-coding, memory-management) — 디렉터리 단위로 ~/.claude/skills/ 에 링크
├── rules/            # 워크플로우 규칙 + 코딩 규칙 (secure-coding 포함) — 파일 단위로 ~/.claude/rules/ 에 링크
├── hooks/            # Hook 스크립트 (maestro-guard, verify-prompt 등) — .ps1 + .sh 크로스 플랫폼, 파일 단위로 ~/.claude/hooks/ 에 링크
├── docs/             # 설계 문서 (v4.0 과최적화 진단, Dynamic Workflows 하이브리드 feasibility 등)
├── CLAUDE.md         # 진입점 — 활성화 명령, 상태 관리. ~/.claude/CLAUDE.md 로 통째 링크
├── install.sh        # Linux/macOS/WSL 설치·업데이트 스크립트 (심볼릭 링크 방식)
├── install.ps1       # Windows 설치·업데이트 스크립트 (복사 + 매니페스트 기록)
├── uninstall.sh      # Linux/macOS/WSL 제거 스크립트 (저장소 안쪽 링크만 제거)
├── uninstall.ps1     # Windows 제거 스크립트 (매니페스트 기반)
├── settings.json     # Claude Code 설정 (hooks, permissions) — 링크·자동 병합 대상 아님, 훅 등록은 수동 (§훅 등록)
└── .mcp.json         # MCP 서버 설정 (context7, grep-app)
```

## v2.x → v3.0 마이그레이션

| 이전 (v2.x) | 신규 (v3.0) |
|---|---|
| `/ultrawork [task]` | `/maestro [task] ... 맡길게` (또는 `... autonomous`) |
| `/swarm [task]` | `/maestro [task] ... 병렬로` (또는 `... 동시에`) |
| `/ralph start` | `/maestro [task] ... 완료될 때까지` (내장 `/goal` 자동 활성화) |
| `/ralph cancel` | `/goal` 자체 명령으로 해제 (이전 `.agentic/ralph-loop.state.md`는 더 이상 사용 X) |

자율 반복 backend가 모델 self-judge(`/ralph`) → 독립 fast model 검증(`/goal`)으로 바뀌어 false completion 위험이 줄었습니다.

## v3.0 → v3.1 마이그레이션

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

## v3.1 → v4.1 마이그레이션

| 변경 영역 | v3.1 | v4.0 / v4.1 |
|---|---|---|
| Plan 작성 | orchestrator 직접 (누적 컨텍스트) | **built-in Plan agent 분리** (clean context) |
| Architect 호출 | Decision Gate (keyword + 5문항 self-review) | **5 Effect prefilter + Hard rule** (ownership/invariants/failure modes → mandatory, modifier off 불가) |
| 5d review | reviewer → 재량 Codex#2 invoke | **Reviewer (코드 axis) + Codex#2 (test axis) 병렬 분업**, orchestrator 가 통합 |
| Codex auto-trigger | 1개 (Codex#1 plan adversarial) | **2개** (Codex#1 + Codex#2, complex auto) |
| 검증 단위 | test / lint 고정 | **framework-agnostic axis** (프로젝트 opt-in) + 5c Anomaly Comparator |
| 대규모 병렬 EXECUTE | Task 위임만 | **Dynamic Workflows 위임 후보** (≥5 독립·사전명세, research-preview) |
| 공급망 권한 (v4.1.1) | `npm:*` / `npx:*` 등 wildcard allow | run/test 부분집합만 allow, **install/add/dlx/npx 는 ask** (secure-coding §Supply chain 정합) |

상세 근거: `docs/maestro-v4-overoptimization-analysis.md` (v4.0 진단) + `docs/maestro-hybrid-feasibility.md` (v4.1 하이브리드).

## 문제 해결

### 에이전트가 작동하지 않음

```bash
# 재설치
./install.sh  # 또는 install.ps1
```

## 라이선스

MIT

## 크레딧

- Anthropic "Building Effective Agents" 가이드 기반
- [Oh My OpenCode](https://github.com/code-yeongyu/oh-my-opencode) 프로젝트에서 영감

---

*Maestro Workflow v4.1.4*
