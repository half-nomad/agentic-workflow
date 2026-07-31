# agentic-workflow

Claude Code를 위한 Maestro 오케스트레이션 시스템. 패턴 기반 에이전트 워크플로우로 복잡한 작업을 체계적으로 자동화합니다.

## 개요

agentic-workflow는 Claude Code CLI에 최적화된 **Maestro** 오케스트레이션 시스템입니다. Claude가 오케스트레이터 역할을 수행하여 작업을 분석하고, 적절한 패턴을 선택하고, 필요한 에이전트를 식별한 후 계획을 제출합니다.

이 저장소는 Maestro의 **배포본 소스**입니다. `git clone` 후 `install.sh` / `install.ps1`을 실행하면 저장소의 `CLAUDE.md`, `rules/`, `agents/`, `skills/`, `hooks/`, `settings.json`이 사용자의 `~/.claude/`로 복사되어 시스템 전역에 적용됩니다.

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
- **도구 기반 검증 (Phase 6)**: `verify-implementation` skill 로 success criteria sign-off (테스트 실행은 5b/5c 에서 이미 완료, Phase 6 는 최종 sanity 만)
- **순수 오케스트레이터 역할**: 메인은 위임만, 직접 파일 수정은 hooks로 차단
- **Context Embedding**: 서브에이전트에 스키마/패턴/제약 직접 주입 (5b output contract 요구사항 포함)
- **4+1 패턴**: Chaining, Parallelization, Routing, Orchestrator-Workers, Evaluator
- **4개 전문 에이전트**: architect (opus), frontend-engineer (opus), librarian (sonnet), document-writer (sonnet) + 자동 발견되는 프로젝트 에이전트
- **State Persistence**: MEMORY.md로 세션 간 컨텍스트 유지

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

1. **ANALYZE** - 작업 복잡도 평가 + 자연어 modifier 감지 + Architect prefilter (5 Effect + Hard rule)
2. **PATTERN** - 실행 패턴 선택 + 프로젝트 에이전트 자동 발견 (3 위치) + skill candidates
3. **[PLAN MODE]** - built-in Plan agent (clean context) 가 plan 작성 + Architect mandatory/on/skip 마킹 → orchestrator 가 Architect 호출
4. **APPROVE** - Codex#1 adversarial review (자동, complex task) + 사용자 승인
5. **EXECUTE** - 5a 구현 → 5b worker self-test → 5c full suite + Anomaly Comparator → 5d Reviewer·Codex#2 병렬 분업 (fix-loop max 3)
6. **[VERIFY]** - `verify-implementation` skill 로 success criteria sign-off

### 패턴 선택 가이드

| 패턴 | 사용 시점 | 예시 |
|------|----------|------|
| **Chaining** | 순차 의존 단계 | Build → Test → Deploy |
| **Parallelization** | 독립 병렬 작업 (이전 `/swarm` 흡수) | 3개 API 동시 검색, 다중 소스 리서치 |
| **Routing** | 조건부 분기 | 에러 타입별 핸들러 |
| **Orchestrator-Workers** | 복잡한 다중 도메인 | 전체 기능 구현 |
| **Evaluator** | 실행 결과 품질 검증 | verify-* 스킬 연동, PR 전 검증 |

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
[verify-implementation final sanity sign-off]
```

- **오케스트레이터**: 관찰, 위임, 5c 풀 스위트 실행, 5d 병렬 호출·통합. 직접 파일 수정은 hooks가 차단
- **워커 서브에이전트**: 위임받은 작업을 직접 실행 (파일 수정 가능) + required axes 실행 후 5b output contract 보고
- **리뷰어 (5d)**: 프로젝트 `*-reviewer.md` R1 매칭 우선, 없으면 `@architect` fallback. Codex#2 는 리뷰어가 아닌 **orchestrator 가 병렬로 직접 invoke** (v4.0 분업)
- **Phase 6 VERIFY**: `verify-implementation` skill 이 success criteria sign-off (테스트 실행은 5b/5c 에서 이미 완료)

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
| `/multi-worktree-safety` | 다중 worktree 동시 작업 시 충돌 방지 룰 (트리거 기반 on-demand) |
| `/session-summary` | 세션 기능 사용 요약 |
| `/codex-image` | Codex 내장 `image_gen` 으로 이미지 생성 — companion CLI 직접 호출 (`--write --cwd`), OpenAI API 키 불필요 |

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

→ @architect 설계 → APPROVE → 구현 에이전트 위임 → @architect 리뷰 → verify-* 검증

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
├── agents/           # 전문 에이전트 (architect, frontend, librarian, document-writer)
├── skills/           # Skills (maestro, multi-worktree-safety, session-summary)
├── rules/            # 워크플로우 규칙 + 코딩 규칙 (secure-coding 포함)
├── hooks/            # Hook 스크립트 (maestro-guard, verify-prompt) — .ps1 + .sh 크로스 플랫폼
├── docs/             # 설계 문서 (v4.0 과최적화 진단, Dynamic Workflows 하이브리드 feasibility 등)
├── CLAUDE.md         # 진입점 — 활성화 명령, 상태 관리
├── install.ps1       # Windows 설치 스크립트
├── install.sh        # Linux/macOS 설치 스크립트
├── settings.json     # Claude Code 설정 (hooks, permissions)
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
| Phase 6 VERIFY | 테스트 실행 포함 가능 | narrow: `verify-implementation` skill 로 **최종 sanity sign-off 만** |

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

*Maestro Workflow v4.1.4*
