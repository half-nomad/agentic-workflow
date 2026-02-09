# agentic-workflow

Claude Code를 위한 Maestro 오케스트레이션 시스템. 패턴 기반 에이전트 워크플로우로 복잡한 작업을 체계적으로 자동화합니다.

## 개요

agentic-workflow는 Claude Code CLI에 최적화된 **Maestro** 오케스트레이션 시스템입니다. Claude가 오케스트레이터 역할을 수행하여 작업을 분석하고, 적절한 패턴을 선택하고, 필요한 에이전트를 식별한 후 계획을 제출합니다.

## 주요 특징

- **Maestro 오케스트레이션**: `/maestro` 명령으로 패턴 기반 계획 수립
- **Swarm 모드**: `/swarm` 스킬로 병렬 에이전트 실행
- **순수 오케스트레이터 역할**: 메인 에이전트는 위임만, 직접 파일 수정 금지
- **Anthropic 5+1 패턴**: Chaining, Parallelization, Routing, Orchestrator-Workers, Swarm, Evaluator
- **4개 전문 에이전트**: 영역별 최적화 (architect, frontend, librarian, document-writer)
- **3가지 작업 모드**: Maestro (계획 기반), Swarm (병렬 실행), Ultrawork (완전 자동)
- **Ralph Loop**: 완료 시그널까지 자동 반복 실행
- **State Persistence**: boulder.json으로 세션 간 계획 상태 유지

## 설치 방법

### Windows (PowerShell)

```powershell
git clone https://github.com/half-nomad/agentic-workflow.git
cd agentic-workflow
.\install.ps1
```

### Linux / macOS

```bash
git clone https://github.com/half-nomad/agentic-workflow.git
cd agentic-workflow
chmod +x install.sh
./install.sh
```

설치 후 Claude Code를 재시작하세요.

## Maestro 워크플로우

### 사용법

```bash
/maestro [작업 설명]
```

### 워크플로우 단계

1. **ANALYZE** - 작업 복잡도 평가 (단순 vs 복잡)
2. **PATTERN** - 실행 패턴 선택
3. **[PLAN MODE]** - 복잡한 작업 시 Plan Mode에서 계획 수립 (v1.4)
4. **APPROVE** - 사용자 승인 요청
5. **EXECUTE** - 승인 후 실행

### 패턴 선택 가이드

| 패턴 | 사용 시점 | 예시 |
|------|----------|------|
| **Chaining** | 순차 의존 단계 | Build → Test → Deploy |
| **Parallelization** | 독립 병렬 작업 | 3개 API 동시 검색 |
| **Routing** | 조건부 분기 | 에러 타입별 핸들러 |
| **Orchestrator-Workers** | 복잡한 다중 도메인 | 전체 기능 구현 |
| **Swarm** | N개 에이전트 병렬 실행 | 다중 소스 리서치, 병렬 분석 |

### 오케스트레이터 역할 (v1.2)

Maestro/Ultrawork 모드에서 메인 에이전트는 **순수 오케스트레이터**로 동작합니다.

| 허용 | 금지 |
|------|------|
| Read, Glob, Grep (컨텍스트 수집) | Write, Edit (파일 수정) |
| Task tool (위임) | Bash (파일 생성/수정) |
| Bash (읽기 전용: `git status`, `npm test`) | 직접 코드 작성 |

**원칙**: 관찰, 위임, 검증. 직접 수정하지 않음.

### Plan Mode (v1.4)

복잡한 작업(3개 이상 파일 수정, 새 기능 구현) 시 Plan Mode를 활용합니다.

- **자동 전환**: 파일 수정 >= 3개, 아키텍처 변경 시
- **허용**: Explore 위임, Read, 계획 파일 작성, AskUserQuestion
- **금지**: 코드 파일 Write/Edit, Bash 수정 명령

**장점**: 대화 맥락 유지로 계획 품질 향상, 사용자 승인 프로세스 명확화

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

전문 에이전트가 없는 도메인(Backend, DevOps, Security 등)은 **동적 역할**로 생성됩니다.

#### 빌트인 에이전트

`Explore` (코드베이스 검색), `general-purpose` (동적 역할). 계획 수립은 Plan Mode에서 직접 수행.

### Skills (슬래시 커맨드)

| Skill | 설명 |
|-------|------|
| `/maestro` | 오케스트레이터 모드 활성화 |
| `/ultrawork` | 완전 자동화 모드 + Ralph Loop |
| `/swarm` | 병렬 에이전트 실행 |
| `/ralph start\|cancel` | Ralph Loop 제어 |
| `/session-summary` | 세션 기능 사용 요약 |

에이전트는 `@architect`, `@frontend-engineer`, `@librarian`, `@document-writer`로 직접 호출합니다.

### Operating Modes (작업 모드)

| 모드 | 활성화 | 특징 |
|------|--------|------|
| **Default** | (명령 없음) | 일반 Claude 상호작용 |
| **Maestro** | `/maestro` | 계획 수립 후 승인 필요 |
| **Swarm** | `/swarm` | 병렬 에이전트 실행 |
| **Ultrawork** | `/ultrawork` | 완전 자동화 + Ralph Loop |

### State Persistence (상태 유지)

세션 간 계획 상태는 `.agentic/boulder.json`에 자동 저장됩니다.

**사용 방법**:
- **계속하기**: "계속" 또는 "continue" 입력 시 이전 계획 재개
- **새로 시작**: "새로 시작" 또는 "new" 입력 시 상태 초기화

boulder.json은 세션 시작 시 자동 로드되고, 종료 시 자동 저장됩니다.

## 사용 예시

### 예시 1: 복잡한 기능 구현

```bash
/maestro 사용자 인증 기능 구현 (로그인, 회원가입, 비밀번호 재설정)
```

Claude가 Orchestrator-Workers 패턴을 선택하고, 필요한 에이전트와 단계를 계획하여 제출합니다.

### 예시 2: 전체 자동화

```bash
ulw API 라우트 작성하고 테스트까지 완료해줘
```

Ultrawork 모드에서 Ralph Loop가 활성화되어 `<promise>DONE</promise>`까지 자동 실행됩니다.

### 예시 3: 병렬 리서치

```bash
/maestro React, Vue, Angular의 에러 핸들링 베스트 프랙티스 비교 조사
```

Parallelization 패턴으로 3개 프레임워크를 동시에 조사합니다.

## 디렉토리 구조

```
agentic-workflow/
├── agents/           # 전문 에이전트 (4개)
├── skills/           # Skills (6개)
├── rules/            # 코딩 규칙
├── docs/             # 문서
├── CLAUDE.md         # Maestro 워크플로우 정의
├── settings.json     # Claude Code 설정
└── .mcp.json         # MCP 서버 설정
```

## 문제 해결

### Ralph Loop가 멈추지 않음

```bash
/ralph cancel
# 또는
rm .agentic/ralph-loop.state.md
```

### 에이전트가 작동하지 않음

```bash
# 재설치
./install.sh  # 또는 install.ps1
```

## 업데이트

```bash
cd agentic-workflow
git pull
./install.sh
```

## 라이선스

MIT

## 크레딧

- Anthropic "Building Effective Agents" 가이드 기반
- [Oh My OpenCode](https://github.com/code-yeongyu/oh-my-opencode) 프로젝트에서 영감

---

*Maestro Workflow v1.6.0 - 2026-02-09*
