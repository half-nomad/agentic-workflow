# Maestro Workflow System 요약 문서

> Claude Code를 위한 패턴 기반 오케스트레이션 시스템

---

## 1. 개요 (Overview)

Maestro는 Claude Code CLI에 최적화된 **패턴 기반 에이전트 오케스트레이션 시스템**이다. `/maestro` 명령으로 활성화되며, Claude가 오케스트레이터 역할을 수행하여 작업을 분석하고, 적절한 실행 패턴을 선택하고, 필요한 에이전트를 식별한 후 계획을 제출한다.

핵심 아이디어는 "계획 우선(Plan-First)"이다. 바로 실행하는 대신, 먼저 작업의 성격을 파악하고 최적의 실행 전략을 수립한 후 사용자 승인을 받아 실행한다.

---

## 2. 동기 (Motivation)

### Sisyphus (레거시) 시스템의 한계점

| 문제 | 설명 |
|------|------|
| **경직된 구조** | 고정된 4단계(EXPLORE→PLAN→EXECUTE→VERIFY)를 모든 작업에 적용 |
| **과도한 오버헤드** | 단순 작업에도 전체 파이프라인 실행 필요 |
| **제한된 적용 범위** | `/ultrawork` 모드에서만 활성화 |
| **에이전트 중복** | `@codebase-explorer`, `@task-planner` 등 빌트인과 기능 중복 |
| **복잡한 복잡도 평가** | 7단계 복잡도 분류로 인한 불필요한 오버헤드 |

### 해결하고자 한 문제

1. **유연성 부족**: 작업 성격에 맞게 적응하는 패턴 기반 접근법 필요
2. **범용성 한계**: 단순 작업부터 복잡한 작업까지 모두 지원하는 통합 시스템 필요
3. **불필요한 복잡성**: 중복 에이전트 제거 및 빌트인 활용으로 간소화 필요

---

## 3. 영감 및 레퍼런스 (Inspiration & References)

### Anthropic "Building Effective Agents" 가이드

Anthropic의 공식 가이드에서 제시한 에이전트 설계 원칙을 채택했다. 특히 4+1 패턴 시스템은 이 가이드의 핵심 개념을 그대로 구현한 것이다.

### Oh My OpenCode 프로젝트

[Oh My OpenCode](https://github.com/code-yeongyu/oh-my-opencode) 프로젝트에서 슬래시 커맨드 시스템과 에이전트 구조에 대한 영감을 받았다.

### 4+1 에이전트 패턴

Anthropic이 제안한 5가지 핵심 패턴:

| 패턴 | 구조 | 적용 상황 |
|------|------|----------|
| **Chaining** | A → B → C | 순차적 의존 단계 |
| **Parallelization** | A ∥ B ∥ C → Merge | 독립적 병렬 작업 |
| **Routing** | Input → Handler(조건) | 조건부 분기 |
| **Orchestrator-Workers** | 오케스트레이터 → 워커들 | 복잡한 다중 도메인 |
| **Evaluator** | Execute → Evaluate → Iterate | 품질 검증 필요 |

---

## 4. 핵심 기능 (Key Features)

### 4.1 패턴 기반 접근법

작업 성격에 따라 최적의 실행 패턴을 자동 선택한다.

```
단일 단계, 명확한 액션?     → 직접 실행 (/maestro 불필요)
순차적 다단계 작업?         → Chaining
독립적 병렬 작업?           → Parallelization
조건부 분기?                → Routing
복잡한 다중 도메인?         → Orchestrator-Workers
```

### 4.2 5단계 워크플로우

```
1. ANALYZE    → 작업 복잡도 평가 (단순 vs 복잡)
2. PATTERN    → 실행 패턴 선택
3. AGENTS     → 필요한 에이전트/도구 식별
4. APPROVE    → 사용자 승인 요청
5. EXECUTE    → 승인 후 실행
```

### 4.3 작업 모드

| 모드 | 활성화 | 특징 |
|------|--------|------|
| **Default** | (명령 없음) | 일반 Claude 상호작용 |
| **Maestro** | `/maestro` | 계획 수립 후 승인 필요 |
| **Ultrawork** | `/ultrawork`, `/ulw` | 완전 자동화 + Ralph Loop |

### 4.4 Ralph Loop 자동 완료 시스템

`/ralph-start`로 활성화되는 자율 반복 시스템:

1. Stop 이벤트에서 `<promise>DONE</promise>` 모니터링
2. 미감지 시: 계속 프롬프트 트리거
3. 감지 시: 루프 성공 종료
4. 최대 50회 반복 후 강제 종료

### 4.5 에이전트 시스템

#### 전문 에이전트 (Custom)

| 에이전트 | 모델 | 역할 |
|---------|------|------|
| `@architect` | Opus | 전략적 자문, 아키텍처 결정 |
| `@frontend-engineer` | Opus | UI/UX, 컴포넌트, MCP 도구 |
| `@librarian` | Sonnet | 문서 리서치, API 레퍼런스 |
| `@document-writer` | Sonnet | README, 가이드 문서 작성 |

#### 빌트인 에이전트

| 에이전트 | 역할 |
|---------|------|
| `Explore` | 빠른 코드베이스 검색 |
| `Plan` | 구현 계획 수립 |
| `general-purpose` | 다단계 리서치 |

---

## 5. 작업 내용 (What Was Done)

### 5.1 Sisyphus에서 Maestro로 마이그레이션

레거시 Sisyphus 시스템을 완전히 새로운 Maestro 워크플로우로 대체했다.

| 측면 | Sisyphus (Before) | Maestro (After) |
|------|-------------------|-----------------|
| 구조 | 고정 4단계 파이프라인 | 유연한 패턴 기반 |
| 활성화 | `/ultrawork`만 | `/maestro`로 모든 작업 |
| 단계 | EXPLORE→PLAN→EXECUTE→VERIFY | Analyze→Pattern→Agents→Approve→Execute |

### 5.2 제거된 것들

| 항목 | 이유 |
|------|------|
| `agents/codebase-explorer.md` | 빌트인 `Explore`로 대체 |
| `agents/task-planner.md` | 빌트인 `Plan`으로 대체 |
| `commands/plan.md` | `/maestro`로 대체 |
| `commands/execute.md` | Maestro 플로우에 통합 |
| `rules/sisyphus-phases.md` | `maestro-workflow.md`로 대체 |
| 7단계 복잡도 평가 | 2단계(Simple/Complex)로 간소화 |

### 5.3 추가된 것들

| 항목 | 목적 |
|------|------|
| `/maestro` 명령어 | 오케스트레이터 모드 활성화 |
| 5가지 Anthropic 패턴 | 작업 성격에 맞는 실행 전략 |
| `rules/maestro-workflow.md` | 상세 워크플로우 규칙 |
| `docs/legacy-comparison.md` | 마이그레이션 문서 |

### 5.4 간소화된 것들

| 측면 | Before | After | 개선 |
|------|--------|-------|------|
| 복잡도 평가 | 7단계 | 2단계 (Simple/Complex) | -오버헤드 |
| 에이전트 수 | 6개 (중복 포함) | 4개 + 빌트인 | -중복 |
| 모드 시스템 | 3개 (복잡한 전환) | 명확한 역할 분리 | +명확성 |

---

## 6. 향후 계획 (Future Plans)

### 6.1 /commit 명령어 (CHANGELOG 자동화)

커밋 시 CHANGELOG.md를 자동으로 업데이트하는 명령어 추가 가능:

```bash
/commit "feat: Add user authentication"
```

예상 동작:
1. 변경 사항 분석
2. CHANGELOG.md에 엔트리 추가
3. 커밋 메시지 생성 및 실행

### 6.2 추가 전문 에이전트

| 에이전트 후보 | 역할 |
|--------------|------|
| `@backend-engineer` | API, 데이터베이스, 서버 로직 |
| `@tester` | 테스트 작성 및 검증 전문 |
| `@security-auditor` | 보안 취약점 분석 |
| `@performance-analyst` | 성능 최적화 제안 |

### 6.3 패턴 확장

- **Evaluator 패턴 강화**: 자동 품질 검증 루프
- **Hybrid 패턴**: 여러 패턴 조합 지원
- **Custom 패턴**: 사용자 정의 워크플로우 패턴

### 6.4 메트릭 및 모니터링

- 작업 완료 시간 추적
- 패턴별 성공률 분석
- 에이전트 활용 통계

---

## 7. 버전 정보

### 현재 버전

**v1.0 - 2026-01-11**

- Maestro 워크플로우 시스템 최초 릴리스
- Anthropic 4+1 패턴 도입
- 5단계 워크플로우 구현
- 4개 전문 에이전트 + 빌트인 에이전트 지원

### 레거시 브랜치

레거시 Sisyphus 시스템은 다음 브랜치에 보존되어 있다:

```
legacy/sisyphus-v1
```

필요시 이 브랜치를 참조하여 이전 시스템의 동작을 확인할 수 있다.

---

## 참고 문서

| 문서 | 경로 | 설명 |
|------|------|------|
| 메인 워크플로우 | `CLAUDE.md` | Maestro 핵심 정의 |
| 상세 규칙 | `rules/maestro-workflow.md` | 패턴 및 단계별 규칙 |
| 레거시 비교 | `docs/legacy-comparison.md` | Sisyphus와의 차이점 |
| 변경 이력 | `CHANGELOG.md` | 버전별 변경 사항 |

---

*Maestro Workflow Summary v1.0 - 2026-01-11*
