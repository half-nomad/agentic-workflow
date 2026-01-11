# 개선 제안서: Anthropic Agentic 패턴 통합

**버전**: 1.2
**날짜**: 2026-01-11
**상태**: 초안 v1.2
**작성자**: @document-writer
**언어**: 한국어 (Korean)

---

## 요약

본 제안서는 Anthropic의 "Building Effective Agents" 가이드를 기반으로 agentic-workflow 시스템의 개선 사항을 설명합니다. 현재 시스템은 견고한 4단계 파이프라인(Sisyphus)을 구현하고 있지만, 작업 복잡도에 따른 동적 적응 기능이 부족합니다. Anthropic의 5가지 핵심 에이전트 패턴을 통합함으로써 다음과 같은 성과를 달성할 수 있습니다:

- **30-50% 효율성 향상**: 지능형 작업 라우팅을 통한 개선
- **실패율 감소**: 단계 간 게이트 검증을 통한 개선
- **출력 품질 향상**: 평가자-최적화 루프를 통한 개선
- **실행 속도 향상**: 병렬 TODO 감지를 통한 개선

**핵심 권장 사항**: 가장 높은 영향력과 적절한 노력으로 개선을 달성하기 위해 Task Router (작업 라우터)와 Complexity Analyzer (복잡도 분석기)를 우선 구현하십시오 (1-2단계).

---

## 논의를 통한 주요 명확화

본 섹션은 제안서 검토 과정에서 논의된 주요 명확화 사항을 정리합니다.

### 1. Complexity Ladder 명확화

- Complexity는 작업 난이도가 아닌 **최적 실행 경로**를 의미
- 어려운 작업이라도 예측 가능한 경로면 단순 패턴 사용 가능
- 쉬운 작업이라도 병렬 검색이 필요하면 복잡한 패턴 필요
- Complexity = LLM 호출 오케스트레이션 최적화

### 2. Task Router: 계층적 접근

- 모든 요청에 LLM 라우터 개입 불필요
- 3단계 시스템:
  - **Tier 1**: 키워드/패턴 매칭 (0 토큰) - `/explorer`, `ulw` 등 명시적 명령
  - **Tier 2**: 휴리스틱 규칙 (0 토큰) - 파일 경로, 에러 메시지, 라이브러리명
  - **Tier 3**: LLM 분류 (애매할 때만)
- 현재 keyword-detector가 이미 Tier 1 역할 수행

### 3. Sisyphus 호환성

- 기존 시스템과 충돌 없음
- Sisyphus가 이미 Anthropic 패턴 구현:
  - **Parallelization** -> EXPLORE 단계
  - **Prompt Chaining** -> Phase 전환
  - **Routing** -> Agent 위임 테이블
  - **Orchestrator-Workers** -> EXECUTE + 전문가
- 개선점: **Phase 0: ASSESS** 추가로 Phase 건너뛰기 허용

### 4. 모드별 동작

| 모드 | Sisyphus Phase | Ralph Loop | 훅 | 에이전트 위임 |
|------|---------------|------------|-----|--------------|
| Manual | 가이드라인만 | 비활성화 | 권고만 | 사용자 명시적 호출 |
| Semi-Auto | Phase별 자동 | 비활성화 | 권고 + 체크포인트 | 자동 위임 |
| Ultrawork | 완전 자동 | 활성화 | 강제 | 완전 자동 |

### 5. PreToolUse 훅 버그

- `permissionDecision: "deny"`가 현재 Claude Code CLI에서 버그로 작동 안 함
- 우회 방법: exit code 2 패턴 사용
- 대안: settings.json의 Permission Rules 사용

---

## 기준선 측정

구현 시작 전에 현재 시스템의 성능을 측정하여 기준선을 수립해야 합니다. 상세한 지표 정의 및 수집 방법은 `.agentic/metrics/baseline.md`를 참조하십시오.

### 필수 요구사항

**Phase 1 구현 시작 전에 기준선 측정을 완료해야 합니다.** 이는 개선 효과를 정량적으로 평가하기 위한 필수 단계입니다.

### 수집할 핵심 지표

| 범주 | 지표 | 설명 |
|------|------|------|
| **작업 완료** | 작업 완료율 | `<promise>DONE</promise>`에 도달하는 작업 비율 |
| **작업 완료** | 첫 시도 성공률 | @architect 에스컬레이션 없이 성공하는 작업 |
| **작업 완료** | 실패 에스컬레이션율 | 2회 이상 재시도가 필요한 작업 |
| **토큰 효율성** | 단순 작업당 토큰 | Level 1-2 작업의 평균 토큰 사용량 |
| **토큰 효율성** | 복잡 작업당 토큰 | Level 5-7 작업의 평균 토큰 사용량 |
| **토큰 효율성** | 에이전트 위임 오버헤드 | 라우팅에 소비되는 토큰 비율 |
| **실행 시간** | 단순 작업 소요 시간 | Level 1-2 작업의 입력부터 DONE까지 시간 |
| **실행 시간** | 복잡 작업 소요 시간 | Level 5-7 작업의 입력부터 DONE까지 시간 |
| **품질** | Phase 게이트 실패율 | EXPLORE/PLAN/EXECUTE/VERIFY 게이트 거부율 |
| **품질** | 재작업률 | VERIFY 후 수정이 필요한 작업 비율 |

### 수집 기간

- **기준선 수집**: Phase 1 구현 전 2주
- **비교 수집**: 각 Phase 완료 후 2주
- **최종 평가**: Phase 4 완료 후 4주

---

## 목차

1. [현재 상태 분석](#현재-상태-분석)
2. [Anthropic 패턴 매핑](#anthropic-패턴-매핑)
3. [갭 분석](#갭-분석)
4. [제안 아키텍처](#제안-아키텍처)
5. [구현 로드맵](#구현-로드맵)
6. [위험 평가](#위험-평가)
7. [부록](#부록)

---

## 현재 상태 분석

### 시스템 개요

agentic-workflow 시스템은 Claude Code CLI를 위한 토큰 효율적인 에이전트 오케스트레이션 프레임워크입니다. 다음을 제공합니다:

```
+------------------+     +------------------+     +------------------+
|     6 Agents     | --> |   13 Commands    | --> |    5 Hooks       |
+------------------+     +------------------+     +------------------+
| - Explorer       |     | - /codebase-*    |     | - keyword-detect |
| - Librarian      |     | - /librarian     |     | - context-monitor|
| - Architect      |     | - /oracle        |     | - failure-tracker|
| - Frontend Eng   |     | - /ultrawork     |     | - todo-enforcer  |
| - Doc Writer     |     | - /plan          |     | - ralph-loop     |
| - Task Planner   |     | - /execute       |     +------------------+
+------------------+     +------------------+
```

### 현재 실행 흐름 (Sisyphus Phase System)

```
                    +-------------+
                    |   INPUT     |
                    | (User Task) |
                    +------+------+
                           |
                           v
              +------------------------+
              |   PHASE 1: EXPLORE     |
              | - 3+ parallel searches |
              | - @codebase-explorer   |
              | - @librarian           |
              +------------------------+
                           |
                           v
              +------------------------+
              |   PHASE 2: PLAN        |
              | - Create TODO list     |
              | - Define success       |
              | - Identify risks       |
              +------------------------+
                           |
                           v
              +------------------------+
              |   PHASE 3: EXECUTE     |
              | - Work TODO items      |
              | - Delegate to agents   |
              | - Failure recovery     |
              +------------------------+
                           |
                           v
              +------------------------+
              |   PHASE 4: VERIFY      |
              | - Run tests            |
              | - Check criteria       |
              | - Output DONE signal   |
              +------------------------+
```

### 현재 강점

| 강점 | 설명 |
|------|------|
| **병렬 탐색** | Phase 1에서 3개 이상의 병렬 검색 실행 |
| **전문 에이전트** | 적절한 모델을 갖춘 6개의 전문화된 에이전트 |
| **실패 복구** | 2회 실패 후 자동으로 @architect에게 에스컬레이션 |
| **지속적 완료** | Ralph Loop가 작업 완료를 보장 |
| **토큰 효율성** | Manual 모드에서 최대 96% 감소 |

### 현재 한계

| 한계 | 영향 |
|------|------|
| **정적 파이프라인** | 복잡도와 관계없이 모든 작업이 동일한 4단계 흐름을 따름 |
| **키워드 기반 라우팅** | 작업 분류가 아닌 키워드를 기반으로 에이전트 선택 |
| **복잡도 평가 없음** | 단순 작업과 복잡한 작업이 동일하게 처리됨 |
| **순차적 TODO 실행** | 독립적인 작업이 병렬화되지 않음 |
| **품질 피드백 루프 없음** | 개선을 위한 출력 평가가 없음 |
| **게이트 검증 없음** | 단계 전환에 품질 게이트가 없음 |

---

## Anthropic 패턴 매핑

Anthropic은 5가지 핵심 에이전트 워크플로우 패턴을 식별합니다. 다음은 이들이 우리 시스템에 어떻게 매핑되는지 설명합니다:

### 패턴 1: Prompt Chaining (프롬프트 체이닝)

**정의**: 각 단계의 출력이 다음 단계에 입력되는 순차적 LLM 호출로, 선택적 품질 게이트를 포함합니다.

```
+-------+     +-------+     +-------+     +-------+
| Step1 | --> | Gate1 | --> | Step2 | --> | Gate2 | --> ...
+-------+     +-------+     +-------+     +-------+
```

**현재 상태**: Sisyphus 단계를 통해 부분적으로 구현됨
**갭**: 단계 간 게이트 검증 없음

### 패턴 2: Routing (라우팅)

**정의**: 입력을 분류하고 전문화된 핸들러로 라우팅합니다.

```
                    +-------------+
                    |   INPUT     |
                    +------+------+
                           |
                    +------v------+
                    |  CLASSIFIER |
                    +------+------+
                           |
         +-----------------+-----------------+
         |                 |                 |
   +-----v-----+     +-----v-----+     +-----v-----+
   |  Handler  |     |  Handler  |     |  Handler  |
   |     A     |     |     B     |     |     C     |
   +-----------+     +-----------+     +-----------+
```

**현재 상태**: 구현되지 않음 (키워드 매칭만 사용)
**갭**: 지능형 작업 분류 또는 라우팅 없음

### 패턴 3: Parallelization (병렬화)

**정의**: 독립적인 하위 작업을 동시에 실행한 후 결과를 집계합니다.

```
                    +-------------+
                    |   INPUT     |
                    +------+------+
                           |
         +-----------------+-----------------+
         |                 |                 |
   +-----v-----+     +-----v-----+     +-----v-----+
   |  Subtask  |     |  Subtask  |     |  Subtask  |
   |     1     |     |     2     |     |     3     |
   +-----+-----+     +-----+-----+     +-----+-----+
         |                 |                 |
         +-----------------+-----------------+
                           |
                    +------v------+
                    |  AGGREGATE  |
                    +-------------+
```

**현재 상태**: 부분적으로 구현됨 (EXPLORE 단계에서만)
**갭**: EXECUTE 단계에서 TODO를 순차적으로 처리

### 패턴 4: Orchestrator-Workers (오케스트레이터-워커)

**정의**: 중앙 오케스트레이터가 작업을 동적으로 분해하고 워커에게 할당합니다.

```
                    +---------------+
                    | ORCHESTRATOR  |
                    +-------+-------+
                            |
              +-------------+-------------+
              |             |             |
        +-----v-----+ +-----v-----+ +-----v-----+
        |  Worker   | |  Worker   | |  Worker   |
        |     1     | |     2     | |     3     |
        +-----------+ +-----------+ +-----------+
```

**현재 상태**: 에이전트 설명을 통한 정적 위임
**갭**: 입력 기반 동적 작업 분해 없음

### 패턴 5: Evaluator-Optimizer (평가자-최적화기)

**정의**: 출력이 평가되고 반복적으로 개선되는 순환 정제 프로세스입니다.

```
        +-------------+
        |  GENERATE   |
        +------+------+
               |
               v
        +------+------+
        |  EVALUATE   |<-----+
        +------+------+      |
               |             |
        [Pass?]----No------->+
               |
              Yes
               v
        +------+------+
        |   OUTPUT    |
        +-------------+
```

**현재 상태**: 구현되지 않음
**갭**: 반복적 품질 개선 루프 없음

---

## 갭 분석

### 우선순위 매트릭스

```
                    HIGH IMPACT
                         |
    Task Router      [X] | [X]  Dynamic Orchestrator
    Complexity       [X] | [X]
    Analyzer             |
                         |
  LOW EFFORT ------------+------------ HIGH EFFORT
                         |
    Gate             [X] | [X]  Evaluator-Optimizer
    Validation           |
    Parallel         [X] |
    Execution            |
                         |
                    LOW IMPACT
```

### 갭 상세 내용

| 갭 | 현재 동작 | 목표 동작 | 우선순위 |
|----|----------|----------|---------|
| **작업 분류** | 훅에서 키워드 매칭 | 다차원 분류 (유형, 복잡도, 도메인) | P1 |
| **복잡도 평가** | 없음 (모든 작업 동일 처리) | 실행 깊이를 결정하는 7단계 복잡도 척도 | P1 |
| **동적 분해** | 정적 TODO 생성 | 의존성 그래프를 포함한 입력 인식 작업 분해 | P2 |
| **게이트 검증** | 암시적 단계 전환 | 통과/실패 기준이 있는 명시적 품질 게이트 | P3 |
| **병렬 TODO 실행** | 순차 처리 | 의존성 인식 병렬 실행 | P3 |
| **품질 피드백 루프** | 단일 패스 실행 | 품질 임계값 충족까지 반복 정제 | P4 |

---

## 제안 아키텍처

### 향상된 시스템 아키텍처

```
+------------------------------------------------------------------+
|                         TASK ROUTER                               |
|  +------------+  +------------------+  +----------------------+   |
|  |   Type     |  |   Complexity     |  |      Domain          |   |
|  | Classifier |  |    Analyzer      |  |    Classifier        |   |
|  +------------+  +------------------+  +----------------------+   |
+------------------------------------------------------------------+
         |                  |                      |
         +------------------+----------------------+
                            |
                            v
+------------------------------------------------------------------+
|                    DYNAMIC ORCHESTRATOR                           |
|  +------------------------------------------------------------+  |
|  |  Input-Aware Task Decomposition with Dependency Graph       |  |
|  +------------------------------------------------------------+  |
+------------------------------------------------------------------+
                            |
         +------------------+------------------+
         |                                     |
         v                                     v
+------------------+                   +------------------+
| SISYPHUS PHASES  |                   |  SIMPLE PATH    |
| (Complex Tasks)  |                   | (Quick Tasks)   |
+------------------+                   +------------------+
| EXPLORE -> GATE  |                   | Direct Execute  |
| PLAN    -> GATE  |                   +------------------+
| EXECUTE -> GATE  |
| VERIFY  -> DONE  |
+------------------+
         |
         v
+------------------------------------------------------------------+
|                    EVALUATOR-OPTIMIZER                            |
|  +------------------------------------------------------------+  |
|  |  Quality Assessment -> Feedback -> Refinement Loop          |  |
|  +------------------------------------------------------------+  |
+------------------------------------------------------------------+
```

### 컴포넌트 사양

#### 1. Task Router (작업 라우터)

**목적**: 들어오는 작업을 3가지 차원에서 분류합니다.

```
+------------------------------------------------------------------+
|                         TASK ROUTER                               |
+------------------------------------------------------------------+
|                                                                   |
|  INPUT: User task description                                     |
|                                                                   |
|  +------------------------+                                       |
|  | TYPE CLASSIFIER        |                                       |
|  +------------------------+                                       |
|  | - search: Find info    |                                       |
|  | - implement: Build     |                                       |
|  | - debug: Fix issues    |                                       |
|  | - refactor: Improve    |                                       |
|  | - document: Write docs |                                       |
|  | - analyze: Understand  |                                       |
|  +------------------------+                                       |
|                                                                   |
|  +------------------------+                                       |
|  | COMPLEXITY ANALYZER    |                                       |
|  +------------------------+                                       |
|  | Level 1: Trivial       | -> Direct response                    |
|  | Level 2: Simple        | -> Single agent                       |
|  | Level 3: Moderate      | -> 2-phase execution                  |
|  | Level 4: Complex       | -> Full Sisyphus                      |
|  | Level 5: Very Complex  | -> Sisyphus + Review                  |
|  | Level 6: Major         | -> Sisyphus + Evaluation              |
|  | Level 7: Critical      | -> Full pipeline + Approval gates     |
|  +------------------------+                                       |
|                                                                   |
|  +------------------------+                                       |
|  | DOMAIN CLASSIFIER      |                                       |
|  +------------------------+                                       |
|  | - frontend             |                                       |
|  | - backend              |                                       |
|  | - database             |                                       |
|  | - devops               |                                       |
|  | - documentation        |                                       |
|  | - testing              |                                       |
|  +------------------------+                                       |
|                                                                   |
|  OUTPUT: {type, complexity, domain, recommended_agents}           |
|                                                                   |
+------------------------------------------------------------------+
```

**구현 참고사항**:
- 분류를 위한 경량 LLM 호출 (Haiku)
- 유사한 작업 패턴에 대한 캐싱
- 불확실한 경우 전체 Sisyphus로 폴백

#### 2. Complexity Analyzer (복잡도 분석기)

**목적**: 작업 복잡도에 따라 실행 깊이를 결정합니다.

```
+------------------------------------------------------------------+
|                      COMPLEXITY ANALYZER                          |
+------------------------------------------------------------------+
|                                                                   |
|  SIGNALS ANALYZED:                                                |
|  +------------------------+                                       |
|  | - File count involved  | (1 file = low, 10+ = high)           |
|  | - Domain crossover     | (single = low, multiple = high)      |
|  | - Dependencies         | (none = low, external = high)        |
|  | - Risk level           | (reversible = low, breaking = high)  |
|  | - Estimated tokens     | (<1K = low, 10K+ = high)             |
|  +------------------------+                                       |
|                                                                   |
|  COMPLEXITY MAPPING:                                              |
|  +-------+------------------+-----------------------------------+ |
|  | Level | Execution Path   | Example                           | |
|  +-------+------------------+-----------------------------------+ |
|  |   1   | Direct answer    | "What is X?"                      | |
|  |   2   | Single agent     | "Find all API routes"             | |
|  |   3   | 2-phase          | "Add a new endpoint"              | |
|  |   4   | Full Sisyphus    | "Implement user auth"             | |
|  |   5   | Sisyphus+Review  | "Refactor payment system"         | |
|  |   6   | Sisyphus+Eval    | "Build real-time notifications"   | |
|  |   7   | Full+Approvals   | "Migrate database schema"         | |
|  +-------+------------------+-----------------------------------+ |
|                                                                   |
+------------------------------------------------------------------+
```

#### 3. Dynamic Orchestrator (동적 오케스트레이터)

**목적**: 입력 특성에 따라 작업을 분해합니다.

```
+------------------------------------------------------------------+
|                     DYNAMIC ORCHESTRATOR                          |
+------------------------------------------------------------------+
|                                                                   |
|  INPUT: Classified task + context                                 |
|                                                                   |
|  DECOMPOSITION STRATEGY:                                          |
|  +------------------------+                                       |
|  | 1. Analyze input scope |                                       |
|  | 2. Identify subtasks   |                                       |
|  | 3. Map dependencies    |                                       |
|  | 4. Assign agents       |                                       |
|  | 5. Create exec graph   |                                       |
|  +------------------------+                                       |
|                                                                   |
|  DEPENDENCY GRAPH EXAMPLE:                                        |
|                                                                   |
|      [Schema Update]                                              |
|            |                                                      |
|      +-----+-----+                                                |
|      |           |                                                |
|      v           v                                                |
|  [API Route]  [Types]                                             |
|      |           |                                                |
|      +-----+-----+                                                |
|            |                                                      |
|            v                                                      |
|      [Integration]                                                |
|            |                                                      |
|            v                                                      |
|       [Tests]                                                     |
|                                                                   |
|  OUTPUT: Execution graph with parallel opportunities              |
|                                                                   |
+------------------------------------------------------------------+
```

#### 4. Gate Validation (게이트 검증)

**목적**: 단계 전환 시 품질을 보장합니다.

```
+------------------------------------------------------------------+
|                       GATE VALIDATION                             |
+------------------------------------------------------------------+
|                                                                   |
|  GATE STRUCTURE:                                                  |
|  +------------------------------------------------------------+  |
|  |  PHASE OUTPUT  -->  GATE CHECK  -->  PASS/FAIL/RETRY       |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  EXPLORE GATE:                                                    |
|  +------------------------+                                       |
|  | - Core problem clear?  | Yes/No                                |
|  | - Files identified?    | Count >= 1                            |
|  | - Constraints known?   | Listed                                |
|  +------------------------+                                       |
|  | FAIL ACTION: Re-explore with broader scope                   | |
|  +------------------------+                                       |
|                                                                   |
|  PLAN GATE:                                                       |
|  +------------------------+                                       |
|  | - TODO list complete?  | Count >= 1                            |
|  | - Steps actionable?    | Each has file path                    |
|  | - Success criteria?    | Defined                               |
|  +------------------------+                                       |
|  | FAIL ACTION: Refine plan with @task-planner                  | |
|  +------------------------+                                       |
|                                                                   |
|  EXECUTE GATE:                                                    |
|  +------------------------+                                       |
|  | - All TODOs complete?  | 100%                                  |
|  | - No failures pending? | failure_count = 0                     |
|  | - Files modified?      | As per plan                           |
|  +------------------------+                                       |
|  | FAIL ACTION: Continue execution or escalate                  | |
|  +------------------------+                                       |
|                                                                   |
|  VERIFY GATE:                                                     |
|  +------------------------+                                       |
|  | - Tests pass?          | exit_code = 0                         |
|  | - Criteria met?        | All checked                           |
|  | - No regressions?      | Confirmed                             |
|  +------------------------+                                       |
|  | FAIL ACTION: Debug and retry or report                       | |
|  +------------------------+                                       |
|                                                                   |
+------------------------------------------------------------------+
```

#### 5. Evaluator-Optimizer Loop (평가자-최적화기 루프)

**목적**: 복잡한 출력에 대한 반복적 품질 개선을 수행합니다.

```
+------------------------------------------------------------------+
|                    EVALUATOR-OPTIMIZER                            |
+------------------------------------------------------------------+
|                                                                   |
|  ACTIVATION: Complexity Level >= 5                                |
|                                                                   |
|  +------------------------------------------------------------+  |
|  |                                                             |  |
|  |    +----------+     +-----------+     +----------+         |  |
|  |    | GENERATE |---->| EVALUATE  |---->| FEEDBACK |         |  |
|  |    +----------+     +-----------+     +----+-----+         |  |
|  |         ^                                   |               |  |
|  |         |                                   |               |  |
|  |         +-----------------------------------+               |  |
|  |                    (if quality < threshold)                 |  |
|  |                                                             |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  EVALUATION CRITERIA:                                             |
|  +------------------------+                                       |
|  | - Correctness (40%)    | Does it work as intended?             |
|  | - Completeness (25%)   | All requirements addressed?           |
|  | - Code quality (20%)   | Clean, maintainable?                  |
|  | - Performance (15%)    | Efficient implementation?             |
|  +------------------------+                                       |
|                                                                   |
|  QUALITY THRESHOLD: 80% (configurable)                            |
|  MAX ITERATIONS: 3 (prevent infinite loops)                       |
|                                                                   |
+------------------------------------------------------------------+
```

#### 6. Parallel TODO Execution (병렬 TODO 실행)

**목적**: 독립적인 TODO를 동시에 실행합니다.

```
+------------------------------------------------------------------+
|                   PARALLEL TODO EXECUTION                         |
+------------------------------------------------------------------+
|                                                                   |
|  TODO LIST ANALYSIS:                                              |
|  +------------------------------------------------------------+  |
|  | 1. Parse TODO items                                         |  |
|  | 2. Identify file dependencies                               |  |
|  | 3. Build dependency graph                                   |  |
|  | 4. Calculate parallel groups                                |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  EXAMPLE:                                                         |
|                                                                   |
|  TODO List:                            Execution Groups:          |
|  [ ] Update schema        ----\                                   |
|  [ ] Create API route     ----|---> Group 1 (parallel)           |
|  [ ] Add frontend page    ----/                                   |
|  [ ] Write integration test ------> Group 2 (after Group 1)      |
|                                                                   |
|  EXECUTION:                                                       |
|  +------------------------+                                       |
|  | Group 1: [Schema] [API] [Frontend]  <-- parallel               |
|  |              |        |       |                                |
|  |              +--------+-------+                                |
|  |                       |                                        |
|  |                       v                                        |
|  | Group 2:      [Integration Test]    <-- sequential             |
|  +------------------------+                                       |
|                                                                   |
+------------------------------------------------------------------+
```

---

## 구현 로드맵

### 개요

```
+------------------------------------------------------------------+
|                    IMPLEMENTATION TIMELINE                        |
+------------------------------------------------------------------+
|                                                                   |
|  Phase 1 (Weeks 1-2): FOUNDATION                                  |
|  +------------------------------------------------------------+  |
|  | - Task Router (Type Classifier)                             |  |
|  | - Complexity Analyzer (Basic)                               |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  Phase 2 (Weeks 3-4): INTELLIGENCE                                |
|  +------------------------------------------------------------+  |
|  | - Dynamic Orchestrator                                      |  |
|  | - Complexity Analyzer (Advanced)                            |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  Phase 3 (Weeks 5-6): QUALITY                                     |
|  +------------------------------------------------------------+  |
|  | - Gate Validation                                           |  |
|  | - Parallel TODO Execution                                   |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  Phase 4 (Weeks 7-8): OPTIMIZATION                                |
|  +------------------------------------------------------------+  |
|  | - Evaluator-Optimizer Loop                                  |  |
|  | - Performance Tuning                                        |  |
|  +------------------------------------------------------------+  |
|                                                                   |
+------------------------------------------------------------------+
```

### Phase 1: Foundation (1-2주차)

**목표**: 기본 작업 분류 및 라우팅을 구현합니다.

#### 산출물

| 항목 | 설명 | 파일 |
|------|------|------|
| Task Router Agent | 작업 분류를 위한 새 에이전트 | `agents/task-router.md` |
| Complexity Analyzer | 기본 7단계 평가 | `hooks/complexity-analyzer.ps1` |
| Router Hook | 실행 전 분류 | `hooks/task-router.ps1` |
| Updated CLAUDE.md | 통합 문서 | `CLAUDE.global.md` |

#### 구현 상세

**1. Task Router Agent** (`agents/task-router.md`)

```markdown
---
name: task-router
description: "Classifies incoming tasks by type, complexity, and domain to optimize execution path"
model: haiku
tools: Read, Grep, Glob
---

# Task Router

## Classification Dimensions

### Type Classification
- search: Information retrieval
- implement: New feature creation
- debug: Issue resolution
- refactor: Code improvement
- document: Documentation tasks
- analyze: Code understanding

### Complexity Classification
- Level 1-2: Simple (direct execution)
- Level 3-4: Moderate (standard Sisyphus)
- Level 5-7: Complex (enhanced pipeline)

### Domain Classification
- frontend, backend, database, devops, docs, testing

## Output Format
{
  "type": "implement",
  "complexity": 4,
  "domain": ["backend", "database"],
  "recommended_path": "sisyphus",
  "agents": ["@codebase-explorer", "@librarian", "@task-planner"]
}
```

**2. Router Hook** (`hooks/task-router.ps1`)

```powershell
# Trigger: UserPromptSubmit
# Classify task before execution

$prompt = $env:USER_PROMPT

# Quick classification via patterns
$patterns = @{
    'search' = 'find|search|locate|where|show me'
    'implement' = 'create|build|add|implement|make'
    'debug' = 'fix|debug|error|issue|broken|not working'
    'refactor' = 'refactor|improve|optimize|clean'
    'document' = 'document|readme|explain|describe'
    'analyze' = 'analyze|understand|how does|what is'
}

# Complexity signals
$complexitySignals = @{
    'high' = 'and|also|then|after|multiple|full|complete'
    'low' = 'simple|quick|just|only'
}

# Route to appropriate execution path
# Output classification for orchestrator consumption
```

#### Phase 1 성공 기준

- [ ] Task Router가 일반적인 작업의 90%를 정확하게 분류함
- [ ] 복잡도 수준이 적절한 실행 경로에 매핑됨
- [ ] 단순 작업 (Level 1-2)이 전체 Sisyphus를 우회함
- [ ] 기존 기능에 회귀가 없음

### Phase 2: Intelligence (3-4주차)

**목표**: 분류에 기반한 동적 작업 분해를 구현합니다.

#### 산출물

| 항목 | 설명 | 파일 |
|------|------|------|
| Dynamic Orchestrator | 입력 인식 작업 분해 | `agents/orchestrator.md` |
| Dependency Analyzer | TODO 의존성 감지 | `hooks/dependency-analyzer.ps1` |
| Enhanced Planner | 의존성 인식 계획 | `agents/task-planner.md` (업데이트) |

#### Phase 2 성공 기준

- [ ] 오케스트레이터가 유효한 의존성 그래프 생성
- [ ] 복잡한 작업이 5-15개 하위 작업으로 분해됨
- [ ] 의존성 순서가 95%의 정확도를 보임
- [ ] 병렬 기회가 식별됨

### Phase 3: Quality (5-6주차)

**목표**: 게이트 검증 및 병렬 실행을 구현합니다.

#### 산출물

| 항목 | 설명 | 파일 |
|------|------|------|
| Gate Validators | 단계 전환 검사 | `hooks/gate-validator.ps1` |
| Parallel Executor | 동시 TODO 처리 | `hooks/parallel-executor.ps1` |
| Enhanced Phases | 게이트 인식 단계 시스템 | `rules/sisyphus-phases.md` (업데이트) |

#### Phase 3 성공 기준

- [ ] 게이트가 불완전한 단계 전환의 80%를 포착함
- [ ] 5개 이상의 TODO에서 병렬 실행이 시간을 30% 단축함
- [ ] 파일 수정에서 레이스 컨디션이 없음
- [ ] 실패 시 순차적으로 정상적인 저하 발생

### Phase 4: Optimization (7-8주차)

**목표**: 품질 피드백 루프 및 성능 튜닝을 구현합니다.

#### 산출물

| 항목 | 설명 | 파일 |
|------|------|------|
| Evaluator Agent | 품질 평가 | `agents/evaluator.md` |
| Optimizer Hook | 피드백 처리 | `hooks/quality-optimizer.ps1` |
| Metrics Dashboard | 성능 추적 | `.agentic/metrics/` |

#### Phase 4 성공 기준

- [ ] 평가자가 품질 이슈의 70%를 포착함
- [ ] 최대 3회의 최적화 반복
- [ ] 전체 작업 품질이 20% 향상됨
- [ ] 토큰 사용량이 15% 이상 증가하지 않음

---

## 위험 평가

### 기술적 위험

| 위험 | 가능성 | 영향 | 완화 방안 |
|------|--------|------|----------|
| 분류 오류로 작업이 잘못 라우팅됨 | 중간 | 높음 | 전체 Sisyphus로 폴백; 사용자 오버라이드 옵션 |
| 병렬 실행이 파일 충돌을 일으킴 | 낮음 | 높음 | 잠금 메커니즘; 순차적 폴백 |
| 평가자 루프가 토큰 사용량을 과도하게 증가시킴 | 중간 | 중간 | 반복 횟수 제한; 품질 임계값 튜닝 |
| 복잡도 분석기가 작업 난이도를 잘못 판단함 | 중간 | 중간 | 보수적 기본값; 사용자 피드백 루프 |
| 기존 워크플로우에 대한 호환성 파괴 변경 | 낮음 | 높음 | 기능 플래그; 점진적 롤아웃 |

### 운영적 위험

| 위험 | 가능성 | 영향 | 완화 방안 |
|------|--------|------|----------|
| 시스템 복잡도 증가로 유지보수성 감소 | 중간 | 중간 | 모듈화 설계; 포괄적인 문서화 |
| 높은 사용량 하에서 성능 저하 | 낮음 | 중간 | 캐싱; 지연 평가 |
| 새로운 실행 경로로 인한 사용자 혼란 | 중간 | 낮음 | 명확한 모드 표시기; 투명한 결정 |

### 위험 완화 전략

```
+------------------------------------------------------------------+
|                    RISK MITIGATION LAYERS                         |
+------------------------------------------------------------------+
|                                                                   |
|  Layer 1: CONSERVATIVE DEFAULTS                                   |
|  +------------------------------------------------------------+  |
|  | - Unknown complexity -> Level 4 (Full Sisyphus)             |  |
|  | - Uncertain classification -> Ask user                      |  |
|  | - Parallel conflict detected -> Sequential fallback         |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  Layer 2: FEATURE FLAGS                                           |
|  +------------------------------------------------------------+  |
|  | - ENABLE_TASK_ROUTER: true/false                            |  |
|  | - ENABLE_PARALLEL_EXECUTION: true/false                     |  |
|  | - ENABLE_EVALUATOR_LOOP: true/false                         |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  Layer 3: USER OVERRIDES                                          |
|  +------------------------------------------------------------+  |
|  | - /force-simple: Skip complex execution                     |  |
|  | - /force-full: Use full Sisyphus                            |  |
|  | - /force-sequential: Disable parallel                       |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  Layer 4: MONITORING                                              |
|  +------------------------------------------------------------+  |
|  | - Log all routing decisions                                 |  |
|  | - Track classification accuracy                             |  |
|  | - Alert on unusual patterns                                 |  |
|  +------------------------------------------------------------+  |
|                                                                   |
+------------------------------------------------------------------+
```

### 롤백 절차

지표가 임계값 이하로 저하될 경우 기능을 롤백해야 합니다. 상세한 임계값은 `.agentic/metrics/baseline.md`를 참조하십시오.

#### 롤백 트리거

| 지표 | 롤백 임계값 | 조치 |
|------|------------|------|
| 작업 완료율 | 기준선 대비 <70% | Task Router 비활성화 |
| 토큰 사용량 | >150% 증가 | Evaluator Loop 비활성화 |
| 실행 시간 | >200% 증가 | Parallel Execution 비활성화 |
| 사용자 오버라이드 | >30% 빈도 | Manual 모드 기본값으로 복귀 |

#### 4단계 롤백 절차

1. **즉시 조치**: `.agentic/config.yaml`에서 해당 기능 플래그를 `false`로 설정
2. **로깅**: 실패 조건을 `.agentic/metrics/rollback-log.md`에 기록
3. **분석**: 재활성화 전 근본 원인 식별
4. **재활성화**: 25% -> 50% -> 100% 트래픽으로 점진적 롤아웃

---

## 부록

### A. Anthropic 패턴 참조

출처: "Building Effective Agents" - Anthropic (2024)

| 패턴 | 핵심 통찰 |
|------|----------|
| Prompt Chaining | 단계 사이의 게이트가 오류를 조기에 포착함 |
| Routing | 분류가 전문화를 가능하게 함 |
| Parallelization | 독립적인 작업은 동시에 실행되어야 함 |
| Orchestrator-Workers | 동적 분해가 정적 계획보다 우수함 |
| Evaluator-Optimizer | 피드백 루프가 품질을 향상시킴 |

### B. 현재 에이전트 모델 매핑

| 에이전트 | 모델 | 비용 티어 | 사용 사례 |
|---------|------|----------|----------|
| Explorer | Haiku | 낮음 | 빠른 코드베이스 검색 |
| Librarian | Sonnet | 중간 | 문서 조사 |
| Architect | Opus | 높음 | 복잡한 결정 |
| Frontend Engineer | Opus | 높음 | UI/UX 작업 |
| Document Writer | Opus | 높음 | 기술 문서 작성 |
| Task Planner | Opus | 높음 | 전략적 계획 |

### C. 제안된 신규 에이전트

| 에이전트 | 모델 | 목적 |
|---------|------|------|
| Task Router | Haiku | 작업 분류 (저비용) |
| Orchestrator | Sonnet | 동적 분해 |
| Evaluator | Haiku | 품질 평가 |

### D. 구성 스키마

```yaml
# .agentic/config.yaml

task_router:
  enabled: true
  model: haiku
  cache_ttl: 3600  # seconds

complexity:
  enabled: true
  default_level: 4
  thresholds:
    simple: 2
    moderate: 4
    complex: 6

parallel_execution:
  enabled: true
  max_concurrent: 3
  conflict_strategy: sequential_fallback

evaluator:
  enabled: true
  quality_threshold: 0.8
  max_iterations: 3
  activation_level: 5  # complexity level

gates:
  explore:
    require_files: true
    min_files: 1
  plan:
    require_todos: true
    require_criteria: true
  execute:
    require_completion: 100
  verify:
    require_tests: false  # optional
```

### E. 성공 지표

| 지표 | 현재 | 목표 | 측정 방법 |
|------|------|------|----------|
| 작업 완료율 | ~85% | >95% | `<promise>DONE</promise>` 도달 작업 수 / 전체 작업 수 |
| 토큰 효율성 | 기준선 | +15% | 성공 작업당 평균 토큰 (입력 + 출력) / 기준선 토큰 |
| 실행 시간 | 기준선 | -30% | Level 5-7 작업의 입력 시점 ~ DONE 시점 소요 시간 |
| 첫 시도 성공률 | ~70% | >85% | @architect 에스컬레이션 없이 성공한 작업 수 / 전체 작업 수 |
| 품질 점수 | N/A | >80% | Evaluator 에이전트의 정확성(40%) + 완전성(25%) + 코드품질(20%) + 성능(15%) 가중 평균 |

---

## 결론

본 제안서는 Anthropic의 에이전트 패턴을 agentic-workflow 시스템에 통합하기 위한 구조화된 접근 방식을 설명합니다. 단계적 구현을 통해 기존 기능에 대한 위험을 최소화하면서 반복적인 검증이 가능합니다.

**권장 다음 단계**:

1. 본 제안서 검토 및 승인
2. Phase 1 구현 시작 (Task Router + Complexity Analyzer)
3. 비교를 위한 기준선 지표 수립
4. 주간 진행 상황 검토 일정 수립

**기대 성과**:

- 더 지능적인 작업 처리
- 병렬화를 통한 더 빠른 실행
- 피드백 루프를 통한 더 높은 품질의 출력
- 라우팅을 통한 더 나은 리소스 활용

---

*본 문서는 @document-writer가 작성하였습니다*
*최종 업데이트: 2026-01-11 (v1.2 - 기준선 측정, 롤백 절차, 측정 방법론 추가)*
