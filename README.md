# agentic-workflow

Claude Code를 위한 전문 에이전트 워크플로우 시스템. 토큰 효율적인 다중 에이전트 아키텍처로 복잡한 작업을 자동화합니다.

## 개요

agentic-workflow는 Claude Code CLI에 최적화된 작업 자동화 시스템입니다. 수동 작업부터 완전 자동화까지 3단계 모드를 제공하며, 6개의 전문 에이전트가 각자의 영역에서 최적화된 성능을 발휘합니다.

## 주요 특징

- **3가지 작업 모드**: Manual, Semi-Auto, Ultrawork
- **6개 전문 에이전트**: 작업 유형별 최적화된 모델 사용
- **13개 슬래시 커맨드**: 에이전트 호출, 모드 전환, 유틸리티
- **5개 자동화 훅**: 키워드 감지, 컨텍스트 모니터, TODO 추적, 실패 복구
- **2개 스킬**: codebase-analysis, deep-research
- **토큰 효율성**: 최대 96% 토큰 절감

## 설치 방법

### Windows (PowerShell)

```powershell
# 저장소 클론
git clone https://github.com/YOUR-USERNAME/agentic-workflow.git
cd agentic-workflow

# 설치 스크립트 실행
.\install.ps1
```

### Linux / macOS

```bash
# 저장소 클론
git clone https://github.com/YOUR-USERNAME/agentic-workflow.git
cd agentic-workflow

# 실행 권한 부여
chmod +x install.sh

# 설치 스크립트 실행
./install.sh
```

### 설치 확인

Claude Code를 재시작한 후 다음 명령어로 설치를 확인합니다.

```bash
# 에이전트 목록 확인
claude agents

# 커맨드 목록 확인
claude commands
```

## 구성 요소

### 1. Agents (에이전트)

각 에이전트는 특정 작업에 최적화된 모델과 도구를 사용합니다.

| 에이전트 | 모델 | 용도 | 사용 시점 |
|---------|------|------|-----------|
| `@codebase-explorer` | Haiku | 코드베이스 탐색 | 파일 찾기, 구조 파악 |
| `@librarian` | Sonnet | 문서 리서치 | 라이브러리 사용법, 공식 문서 검색 |
| `@architect` | Opus | 아키텍처 자문 | 2회 이상 실패 시, 중요한 설계 결정 |
| `@frontend-engineer` | Opus | UI/UX 작업 | 컴포넌트, 스타일링, 접근성 |
| `@document-writer` | Opus | 문서 작성 | README, API 문서, 주석 |
| `@task-planner` | Opus | 작업 계획 | 복잡한 기능 구현 전 계획 수립 |

### 2. Commands (슬래시 커맨드)

에이전트를 직접 호출하거나 워크플로우를 실행하는 명령어입니다.

#### 에이전트 호출
| 커맨드 | 설명 | 예시 |
|--------|------|------|
| `/codebase-explorer` | 코드베이스 검색 | `/codebase-explorer "find auth logic"` |
| `/librarian` | 문서 리서치 | `/librarian "React Query v5 usage"` |
| `/oracle` | 전략적 자문 (Architect) | `/oracle "how to fix this error"` |
| `/frontend` | UI/UX 작업 | `/frontend "create button component"` |

#### 워크플로우 실행
| 커맨드 | 설명 |
|--------|------|
| `/plan` | 작업 계획 수립 |
| `/execute` | 계획 실행 |
| `/ultrawork`, `/ulw` | 완전 자동화 모드 |

#### 모드 전환
| 커맨드 | 설명 |
|--------|------|
| `/manual` | 수동 모드 전환 |
| `/semi-auto` | 반자동 모드 전환 |
| `/ralph-start` | Ralph Loop 시작 |
| `/ralph-cancel` | Ralph Loop 중지 |

#### 유틸리티
| 커맨드 | 설명 |
|--------|------|
| `/session-summary` | 세션에서 사용된 기능 요약 |

### 3. Hooks (훅)

특정 이벤트에 반응하여 자동으로 실행되는 스크립트입니다.

| 훅 | 이벤트 | 기능 |
|----|--------|------|
| `keyword-detector` | UserPromptSubmit | ultrawork/ulw 키워드 감지 및 모드 활성화 |
| `context-monitor` | UserPromptSubmit | 컨텍스트 키워드 감지 (search, analyze, docs 등) |
| `failure-tracker` | PostToolUse | 반복 실패 감지 및 복구 전략 제안 |
| `todo-enforcer` | Stop | 미완료 TODO 확인 및 계속 진행 유도 |
| `ralph-loop` | Stop | 자동 반복 실행 (완료 시그널까지) |

※ Windows: `.ps1`, Linux/macOS: `.sh` 확장자 사용

### 4. Skills (스킬)

재사용 가능한 복잡한 워크플로우입니다.

| 스킬 | 설명 |
|------|------|
| `codebase-analysis` | 체계적인 코드베이스 탐색 및 이해 |
| `deep-research` | 여러 소스를 활용한 심층 조사 |

### 5. Operating Modes (작업 모드)

#### Mode 1: Manual (수동)

직접 커맨드를 호출하여 작업을 제어합니다.

```bash
# 코드 찾기
/explorer "API 라우터 위치"

# 문서 검색
/librarian "Prisma 트랜잭션 사용법"

# UI 작업
/frontend "로그인 폼 스타일 수정"
```

**토큰 사용량**: ~500/호출 (기존 대비 96% 절감)

#### Mode 2: Semi-Auto (반자동)

계획을 수립하고 검토한 후 실행합니다.

```bash
# 1단계: 계획 수립
/plan "사용자 프로필 페이지 구현"

# 2단계: 생성된 계획 검토 (.claude/plans/에서 확인)

# 3단계: 계획 실행
/execute
```

**토큰 사용량**: ~3K/세션 (기존 대비 75% 절감)

#### Mode 3: Ultrawork (완전 자동)

키워드로 전체 자동화를 트리거합니다.

```bash
# Trigger keywords
ultrawork implement all features and test
ulw complete all TODOs and verify
finish everything
complete all
```

**토큰 사용량**: ~36K/세션 (기존 대비 67% 절감)

**자동 실행 흐름**:
1. EXPLORE - 병렬 탐색 (@codebase-explorer, @librarian)
2. PLAN - TODO 리스트 작성
3. EXECUTE - 작업 수행, 전문가에게 위임
4. VERIFY - 결과 검증, 테스트 실행

**완료 시그널**: 모든 작업이 완료되면 `<promise>DONE</promise>` 출력

## 사용 시나리오

### 시나리오 1: 새 라이브러리 사용법 확인

```bash
/librarian "NextAuth.js v5 GitHub OAuth 설정 방법"
```

Librarian이 공식 문서와 실제 GitHub 코드 예제를 찾아 정리해 제공합니다.

### 시나리오 2: 코드베이스에서 기능 찾기

```bash
/explorer "결제 로직이 어디 구현되어 있어?"
```

Explorer가 병렬 검색으로 관련 파일과 함수를 빠르게 찾아 절대 경로와 줄 번호로 제공합니다.

### 시나리오 3: 복잡한 기능 구현

```bash
# 1. 계획 수립
/plan "사용자 대시보드 페이지 구현 (차트, 필터, 페이지네이션)"

# 2. 계획 검토 후 실행
/execute
```

### 시나리오 4: 전체 자동화

```bash
ulw API 라우트 작성하고 Prisma 스키마 업데이트하고 타입 생성하고 테스트 작성해줘
```

Ralph Loop가 활성화되어 모든 작업이 완료될 때까지 자동으로 계속 진행됩니다.

### 시나리오 5: 버그 해결

```bash
# 첫 시도
"이 버그 고쳐줘"

# 2번 실패 후
/oracle "이 방법들을 시도했는데 안 됩니다. 다른 접근법 추천해주세요"
```

Architect가 상황을 분석하고 대안을 제시합니다.

## 토큰 효율성

기존 Oh My OpenCode 패턴 대비 대폭 개선된 토큰 효율:

| 모드 | 기존 | agentic-workflow | 절감률 |
|------|------|------------------|--------|
| Manual | ~12K | ~500 | **96%** |
| Semi-Auto | ~12K | ~3K | **75%** |
| Ultrawork | ~44K | ~36K | **67%** |

## 커스터마이징

### 에이전트 수정

`~/.claude/agents/` 디렉토리의 마크다운 파일을 편집하여 에이전트 동작을 수정할 수 있습니다.

```markdown
---
name: codebase-explorer
description: "설명 수정 가능"
model: haiku  # haiku, sonnet, opus 중 선택
tools: Read, Grep, Glob, Bash  # 사용 가능한 도구
---

# 프롬프트 내용 수정 가능
```

### 커맨드 추가

`~/.claude/commands/` 디렉토리에 새 마크다운 파일을 추가합니다.

```markdown
---
description: "내 커스텀 커맨드"
model: sonnet
---

# /mycommand - Custom Command

$ARGUMENTS
```

### 훅 비활성화

`~/.claude/settings.json`에서 특정 훅을 제거하거나 주석 처리합니다.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      // 이 훅을 비활성화하려면 제거
      {
        "matcher": "ultrawork|ulw",
        "hooks": [...]
      }
    ]
  }
}
```

### 권한 설정

프로젝트별 보안을 위해 `~/.claude/settings.json`의 permissions를 수정합니다.

```json
{
  "permissions": {
    "allow": [
      "Read(**/*)",
      "Bash(git:*)",
      "Bash(npm:*)"
    ]
  }
}
```

## 디렉토리 구조

```
agentic-workflow/
├── agents/                 # 에이전트 정의 (6개)
│   ├── architect.md
│   ├── codebase-explorer.md
│   ├── document-writer.md
│   ├── frontend-engineer.md
│   ├── librarian.md
│   └── task-planner.md
│
├── commands/               # 슬래시 커맨드 (13개)
│   ├── codebase-explorer.md
│   ├── execute.md
│   ├── frontend.md
│   ├── librarian.md
│   ├── manual.md
│   ├── oracle.md
│   ├── plan.md
│   ├── ralph-cancel.md
│   ├── ralph-start.md
│   ├── semi-auto.md
│   ├── session-summary.md
│   ├── ultrawork.md
│   └── ulw.md
│
├── hooks/                  # 훅 스크립트 (5종 x 2 플랫폼)
│   ├── context-monitor.ps1/.sh
│   ├── failure-tracker.ps1/.sh
│   ├── keyword-detector.ps1/.sh
│   ├── ralph-loop.ps1/.sh
│   └── todo-enforcer.ps1/.sh
│
├── rules/                  # 코딩 규칙
│   ├── global.md
│   ├── sisyphus-phases.md
│   └── typescript.md
│
├── skills/                 # 재사용 가능한 스킬
│   ├── codebase-analysis/
│   └── deep-research/
│
├── settings.json           # Claude Code 설정
├── .mcp.json              # MCP 서버 설정
├── CLAUDE.global.md       # 글로벌 규칙 템플릿
├── install.ps1            # Windows 설치 스크립트
├── install.sh             # Linux/macOS 설치 스크립트
├── update.ps1/.sh         # 업데이트 스크립트
├── uninstall.ps1/.sh      # 제거 스크립트
└── README.md
```

## MCP 도구

grep.app 검색을 위한 MCP 서버가 필요합니다.

```bash
# uv 설치 (없는 경우)
pip install uv

# grep_app_mcp 설치
uvx --from git+https://github.com/ai-tools-all/grep_app_mcp grep-app-mcp
```

## 문제 해결

### 에이전트가 작동하지 않음

```bash
# 설치 확인
ls ~/.claude/agents/

# 재설치
./install.sh
```

### 훅이 실행되지 않음

1. `~/.claude/settings.json`에서 hooks 설정 확인
2. PowerShell 실행 정책 확인 (Windows)
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```

### Ralph Loop가 멈추지 않음

```bash
# 수동으로 중지
rm .agentic/ralph-loop.state.md

# 또는 <promise>DONE</promise> 출력
```

## 업데이트

프로젝트를 업데이트하려면 저장소를 pull하고 재설치합니다.

```bash
cd agentic-workflow
git pull
./install.sh  # 또는 install.ps1
```

기존 설정은 백업되며 병합됩니다.

## 라이선스

MIT

## 크레딧

[Oh My OpenCode](https://github.com/code-yeongyu/oh-my-opencode) 프로젝트에서 영감을 받아 Claude Code에 최적화했습니다.

## 기여

이슈와 PR을 환영합니다.

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request
