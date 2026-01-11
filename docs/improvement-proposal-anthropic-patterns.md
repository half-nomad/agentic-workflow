# Improvement Proposal: Anthropic Agentic Patterns Integration

**Version**: 1.2
**Date**: 2026-01-11
**Status**: DRAFT v1.2
**Author**: @document-writer

---

## Executive Summary

This proposal outlines enhancements to the agentic-workflow system based on Anthropic's "Building Effective Agents" guide. The current system implements a solid 4-phase pipeline (Sisyphus) but lacks dynamic adaptation to task complexity. By integrating Anthropic's five core agentic patterns, we can achieve:

- **30-50% efficiency gains** through intelligent task routing
- **Reduced failure rates** via gate validation between phases
- **Better quality outputs** through evaluator-optimizer loops
- **Faster execution** via parallel TODO detection

**Key Recommendation**: Implement Task Router and Complexity Analyzer first (Phases 1-2) to unlock the highest impact improvements with moderate effort.

---

## Key Clarifications from Discussion

This section captures important clarifications from the review discussion that refine the proposal's concepts.

### 1. Complexity Ladder Clarification

Complexity refers to the **OPTIMAL EXECUTION PATH**, not task difficulty.

- A difficult task with a predictable path can use simple patterns
- An easy task requiring parallel searches needs complex patterns
- Complexity = LLM call orchestration optimization

**Example**: "Explain quantum computing" is intellectually difficult but has a trivial execution path (Level 1). "Add a button to the header" may be easy but requires exploration, planning, and verification (Level 3-4).

### 2. Task Router: Tiered Approach

**NOT every request needs LLM router intervention.** The router uses a three-tier system:

| Tier | Method | Token Cost | Examples |
|------|--------|------------|----------|
| Tier 1 | Keyword/Pattern Match | 0 tokens | Explicit commands: `/explorer`, `/ulw`, `@architect` |
| Tier 2 | Heuristic Rules | 0 tokens | File paths, error messages, library names in prompt |
| Tier 3 | LLM Classification | ~100 tokens | Ambiguous requests requiring interpretation |

**Note**: The current `keyword-detector.ps1` hook already serves as Tier 1. Tier 3 is only invoked when Tiers 1 and 2 cannot determine the execution path.

### 3. Sisyphus Compatibility

**No conflict with the existing system.** Sisyphus already implements Anthropic patterns:

| Anthropic Pattern | Sisyphus Implementation |
|-------------------|------------------------|
| Parallelization | EXPLORE phase (3+ parallel searches) |
| Prompt Chaining | Phase transitions (EXPLORE -> PLAN -> EXECUTE -> VERIFY) |
| Routing | Agent delegation table in CLAUDE.md |
| Orchestrator-Workers | EXECUTE phase + specialist agents |

**Enhancement Opportunity**: Add **Phase 0: ASSESS** for intelligent phase skipping.

```
INPUT -> [ASSESS] -> Skip to appropriate phase based on complexity
           |
           +-> Level 1-2: Skip to EXECUTE (or direct answer)
           +-> Level 3-4: Start at PLAN (exploration not needed)
           +-> Level 5-7: Full Sisyphus (start at EXPLORE)
```

### 4. Mode-Specific Behavior

The enhanced patterns respect the existing mode system:

| Mode | Sisyphus Phase | Ralph Loop | Hooks | Agent Delegation |
|------|---------------|------------|-------|------------------|
| Manual | Guidelines only | DISABLED | Advisory only | User explicit call |
| Semi-Auto | Auto per phase | DISABLED | Advisory + checkpoints | Auto delegation |
| Ultrawork | Fully automatic | ENABLED | Enforced | Fully automatic |

**Implication**: Task Router and Complexity Analyzer are advisory in Manual mode, enforced in Ultrawork mode.

### 5. PreToolUse Hook Bug

A known limitation affects hook implementation:

- `permissionDecision: "deny"` is currently broken in Claude Code CLI
- The documented deny mechanism does not properly block tool execution

**Workarounds**:
1. Use exit code 2 pattern to signal denial
2. Use Permission Rules in `settings.json` instead of hooks for blocking
3. Use hooks for advisory/logging purposes only

This affects Gate Validation implementation - gates should use Permission Rules for enforcement, hooks for logging.

---

## Baseline Measurement

**REQUIRED**: Before starting Phase 1 implementation, establish baseline metrics.

### Reference Document

All baseline metrics must be recorded in `.agentic/metrics/baseline.md`.

### Collection Procedure

1. Run 10-20 representative tasks across all complexity levels
2. Record metrics for each task execution
3. Calculate averages and standard deviations
4. Document the baseline before any enhancements

### Key Metrics to Collect

| Metric | Description | Collection Method |
|--------|-------------|-------------------|
| **Task Completion Rate** | Percentage of tasks reaching DONE signal | Count successes / total attempts |
| **Token Usage** | Average tokens per task type | Extract from API logs |
| **Execution Time** | Time from task start to DONE | Timestamp difference |
| **First-Try Success Rate** | Tasks succeeding without retry | Count no-retry / total |
| **Phase Transition Time** | Time spent in each Sisyphus phase | Phase timestamp deltas |
| **Agent Delegation Count** | Average agent calls per task | Count @agent invocations |
| **Failure Recovery Rate** | Successful recoveries / total failures | Track failure resolution |

### Baseline File Template

```markdown
# Baseline Metrics

**Collection Date**: YYYY-MM-DD
**Sample Size**: N tasks
**Collection Period**: X days

## Summary Statistics

| Metric | Mean | Std Dev | Min | Max |
|--------|------|---------|-----|-----|
| Completion Rate | X% | - | - | - |
| Token Usage | X | X | X | X |
| Execution Time | Xs | Xs | Xs | Xs |
| First-Try Success | X% | - | - | - |

## By Complexity Level

[Breakdown per level 1-7]

## Notes

[Any observations or anomalies]
```

**Important**: Do NOT proceed to Phase 1 without documented baseline. This enables accurate measurement of improvement impact.

---

## Table of Contents

1. [Current State Analysis](#current-state-analysis)
2. [Anthropic Pattern Mapping](#anthropic-pattern-mapping)
3. [Gap Analysis](#gap-analysis)
4. [Proposed Architecture](#proposed-architecture)
5. [Implementation Roadmap](#implementation-roadmap)
6. [Risk Assessment](#risk-assessment)
7. [Appendix](#appendix)

---

## Current State Analysis

### System Overview

The agentic-workflow system is a token-efficient agent orchestration framework for Claude Code CLI. It provides:

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

### Current Execution Flow (Sisyphus Phase System)

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

### Current Strengths

| Strength | Description |
|----------|-------------|
| **Parallel Exploration** | Phase 1 launches 3+ parallel searches |
| **Specialist Agents** | 6 specialized agents with appropriate models |
| **Failure Recovery** | Automatic escalation to @architect after 2 failures |
| **Persistent Completion** | Ralph Loop ensures task completion |
| **Token Efficiency** | Up to 96% reduction in Manual mode |

### Current Limitations

| Limitation | Impact |
|------------|--------|
| **Static Pipeline** | All tasks follow same 4-phase flow regardless of complexity |
| **Keyword-Based Routing** | Agent selection based on keywords, not task classification |
| **No Complexity Assessment** | Simple and complex tasks treated identically |
| **Sequential TODO Execution** | Independent tasks not parallelized |
| **No Quality Feedback Loop** | Outputs not evaluated for improvement |
| **Missing Gate Validation** | Phase transitions lack quality gates |

---

## Anthropic Pattern Mapping

Anthropic identifies five core agentic workflow patterns. Here is how they map to our system:

### Pattern 1: Prompt Chaining

**Definition**: Sequential LLM calls where each step's output feeds the next, with optional quality gates.

```
+-------+     +-------+     +-------+     +-------+
| Step1 | --> | Gate1 | --> | Step2 | --> | Gate2 | --> ...
+-------+     +-------+     +-------+     +-------+
```

**Current State**: Partially implemented via Sisyphus phases
**Gap**: No gate validation between phases

### Pattern 2: Routing

**Definition**: Classify input and direct to specialized handlers.

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

**Current State**: Not implemented (keyword matching only)
**Gap**: No intelligent task classification or routing

### Pattern 3: Parallelization

**Definition**: Execute independent subtasks concurrently, then aggregate results.

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

**Current State**: Partially implemented (EXPLORE phase only)
**Gap**: EXECUTE phase processes TODOs sequentially

### Pattern 4: Orchestrator-Workers

**Definition**: Central orchestrator dynamically breaks down tasks and assigns to workers.

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

**Current State**: Static delegation via agent descriptions
**Gap**: No dynamic task decomposition based on input

### Pattern 5: Evaluator-Optimizer

**Definition**: Cyclic refinement where output is evaluated and improved iteratively.

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

**Current State**: Not implemented
**Gap**: No iterative quality improvement loop

---

## Gap Analysis

### Priority Matrix

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

### Gap Details

| Gap | Current Behavior | Target Behavior | Priority |
|-----|------------------|-----------------|----------|
| **Task Classification** | Keyword matching in hooks | Multi-dimensional classification (type, complexity, domain) | P1 |
| **Complexity Assessment** | None (all tasks treated equally) | 7-level complexity scale determining execution depth | P1 |
| **Dynamic Decomposition** | Static TODO creation | Input-aware task breakdown with dependency graph | P2 |
| **Gate Validation** | Implicit phase transitions | Explicit quality gates with pass/fail criteria | P3 |
| **Parallel TODO Execution** | Sequential processing | Dependency-aware parallel execution | P3 |
| **Quality Feedback Loop** | Single-pass execution | Iterative refinement until quality threshold met | P4 |

---

## Proposed Architecture

### Enhanced System Architecture

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

### Component Specifications

#### 1. Task Router

**Purpose**: Classify incoming tasks across three dimensions.

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

**Implementation Notes**:
- Lightweight LLM call (Haiku) for classification
- Caching for similar task patterns
- Fallback to full Sisyphus if uncertain

#### 2. Complexity Analyzer

**Purpose**: Determine execution depth based on task complexity.

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

#### 3. Dynamic Orchestrator

**Purpose**: Decompose tasks based on input characteristics.

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

#### 4. Gate Validation

**Purpose**: Ensure quality at phase transitions.

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

#### 5. Evaluator-Optimizer Loop

**Purpose**: Iterative quality improvement for complex outputs.

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

#### 6. Parallel TODO Execution

**Purpose**: Execute independent TODOs concurrently.

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

## Implementation Roadmap

### Overview

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

### Phase 1: Foundation (Weeks 1-2)

**Goal**: Implement basic task classification and routing.

#### Deliverables

| Item | Description | Files |
|------|-------------|-------|
| Task Router Agent | New agent for task classification | `agents/task-router.md` |
| Complexity Analyzer | Basic 7-level assessment | `hooks/complexity-analyzer.ps1` |
| Router Hook | Pre-execution classification | `hooks/task-router.ps1` |
| Updated CLAUDE.md | Integration documentation | `CLAUDE.global.md` |

#### Implementation Details

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

#### Success Criteria Phase 1

- [ ] Task Router correctly classifies 90% of common tasks
- [ ] Complexity levels map to appropriate execution paths
- [ ] Simple tasks (Level 1-2) bypass full Sisyphus
- [ ] No regression in existing functionality

### Phase 2: Intelligence (Weeks 3-4)

**Goal**: Dynamic task decomposition based on classification.

#### Deliverables

| Item | Description | Files |
|------|-------------|-------|
| Dynamic Orchestrator | Input-aware task breakdown | `agents/orchestrator.md` |
| Dependency Analyzer | TODO dependency detection | `hooks/dependency-analyzer.ps1` |
| Enhanced Planner | Dependency-aware planning | `agents/task-planner.md` (update) |

#### Success Criteria Phase 2

- [ ] Orchestrator produces valid dependency graphs
- [ ] Complex tasks decompose into 5-15 subtasks
- [ ] Dependency order is correct 95% of time
- [ ] Parallel opportunities identified

### Phase 3: Quality (Weeks 5-6)

**Goal**: Gate validation and parallel execution.

#### Deliverables

| Item | Description | Files |
|------|-------------|-------|
| Gate Validators | Phase transition checks | `hooks/gate-validator.ps1` |
| Parallel Executor | Concurrent TODO processing | `hooks/parallel-executor.ps1` |
| Enhanced Phases | Gate-aware phase system | `rules/sisyphus-phases.md` (update) |

#### Success Criteria Phase 3

- [ ] Gates catch 80% of incomplete phase transitions
- [ ] Parallel execution reduces time by 30% for 5+ TODOs
- [ ] No race conditions in file modifications
- [ ] Graceful degradation to sequential on failure

### Phase 4: Optimization (Weeks 7-8)

**Goal**: Quality feedback loop and performance tuning.

#### Deliverables

| Item | Description | Files |
|------|-------------|-------|
| Evaluator Agent | Quality assessment | `agents/evaluator.md` |
| Optimizer Hook | Feedback processing | `hooks/quality-optimizer.ps1` |
| Metrics Dashboard | Performance tracking | `.agentic/metrics/` |

#### Success Criteria Phase 4

- [ ] Evaluator catches 70% of quality issues
- [ ] Max 3 optimization iterations
- [ ] Overall task quality improves by 20%
- [ ] Token usage does not increase more than 15%

---

## Risk Assessment

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Classification errors route tasks incorrectly | Medium | High | Fallback to full Sisyphus; user override option |
| Parallel execution causes file conflicts | Low | High | Lock mechanism; sequential fallback |
| Evaluator loop increases token usage excessively | Medium | Medium | Hard limit on iterations; quality threshold tuning |
| Complexity analyzer misjudges task difficulty | Medium | Medium | Conservative defaults; user feedback loop |
| Breaking changes to existing workflows | Low | High | Feature flags; gradual rollout |

### Operational Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Increased system complexity reduces maintainability | Medium | Medium | Modular design; comprehensive documentation |
| Performance degradation under heavy use | Low | Medium | Caching; lazy evaluation |
| User confusion with new execution paths | Medium | Low | Clear mode indicators; transparent decisions |

### Risk Mitigation Strategy

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

### Rollback Procedures

When enhancements cause degradation, follow these rollback procedures. Reference `.agentic/metrics/baseline.md` for threshold comparisons.

#### Rollback Triggers

| Trigger | Threshold | Action |
|---------|-----------|--------|
| Task completion rate drop | >10% below baseline | Immediate rollback |
| Token usage spike | >50% above baseline | Investigate, then rollback if persistent |
| Execution time increase | >40% above baseline (complex tasks) | Rollback affected component |
| First-try success drop | >15% below baseline | Rollback and investigate |
| User-reported issues | 3+ similar reports | Pause rollout, investigate |
| System errors | Any critical error in new components | Immediate rollback |

#### 4-Step Rollback Procedure

**Step 1: DETECT**
```
- Compare current metrics against baseline.md thresholds
- Identify which component(s) are causing degradation
- Document the specific failure pattern
```

**Step 2: DISABLE**
```
- Set feature flag to false for affected component:
  - ENABLE_TASK_ROUTER: false
  - ENABLE_PARALLEL_EXECUTION: false
  - ENABLE_EVALUATOR_LOOP: false
- Changes take effect immediately (no restart needed)
```

**Step 3: VERIFY**
```
- Run 5 representative tasks
- Confirm metrics return to baseline levels
- Check no cascading effects on other components
```

**Step 4: DOCUMENT**
```
- Record rollback in .agentic/metrics/rollback-log.md:
  - Date/time of rollback
  - Component affected
  - Trigger condition met
  - Root cause (if known)
  - Planned remediation
```

#### Rollback Command Reference

```powershell
# Quick disable all enhancements
Set-Content .agentic/feature-flags.json '{"task_router":false,"parallel_exec":false,"evaluator":false}'

# Partial rollback (example: disable only parallel execution)
$flags = Get-Content .agentic/feature-flags.json | ConvertFrom-Json
$flags.parallel_exec = $false
$flags | ConvertTo-Json | Set-Content .agentic/feature-flags.json
```

---

## Appendix

### A. Anthropic Pattern Reference

Source: "Building Effective Agents" - Anthropic (2024)

| Pattern | Key Insight |
|---------|-------------|
| Prompt Chaining | Gates between steps catch errors early |
| Routing | Classification enables specialization |
| Parallelization | Independent tasks should run concurrently |
| Orchestrator-Workers | Dynamic decomposition beats static plans |
| Evaluator-Optimizer | Feedback loops improve quality |

### B. Current Agent Model Mapping

| Agent | Model | Cost Tier | Use Case |
|-------|-------|-----------|----------|
| Explorer | Haiku | Low | Fast codebase search |
| Librarian | Sonnet | Medium | Documentation research |
| Architect | Opus | High | Complex decisions |
| Frontend Engineer | Opus | High | UI/UX work |
| Document Writer | Opus | High | Technical writing |
| Task Planner | Opus | High | Strategic planning |

### C. Proposed New Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| Task Router | Haiku | Task classification (low cost) |
| Orchestrator | Sonnet | Dynamic decomposition |
| Evaluator | Haiku | Quality assessment |

### D. Configuration Schema

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

### E. Success Metrics

| Metric | Current | Target | Measurement | Measurement Method |
|--------|---------|--------|-------------|-------------------|
| Task completion rate | ~85% | >95% | Tasks reaching DONE signal | Count `<promise>DONE</promise>` outputs / total task attempts. Log in `.agentic/metrics/completion.log` |
| Token efficiency | Baseline | +15% | Tokens per successful task | Extract from Claude API response headers (`x-usage-*`). Calculate: total_tokens / successful_tasks |
| Execution time | Baseline | -30% | Time to DONE (complex tasks) | Timestamp at task start (UserPromptSubmit hook) minus timestamp at DONE signal. Filter for complexity >= 4 |
| First-try success | ~70% | >85% | Tasks succeeding without retry | Track via `failure-tracker.ps1` hook. Success = no failure escalation recorded |
| Quality score | N/A | >80% | Evaluator assessment | Evaluator agent scoring (0-100) based on: correctness (40%), completeness (25%), code quality (20%), performance (15%) |

---

## Conclusion

This proposal outlines a structured approach to integrating Anthropic's agentic patterns into the agentic-workflow system. The phased implementation allows for iterative validation while minimizing risk to existing functionality.

**Recommended Next Steps**:

1. Review and approve this proposal
2. Begin Phase 1 implementation (Task Router + Complexity Analyzer)
3. Establish baseline metrics for comparison
4. Schedule weekly progress reviews

**Expected Outcomes**:

- More intelligent task handling
- Faster execution through parallelization
- Higher quality outputs via feedback loops
- Better resource utilization through routing

---

*Document generated by @document-writer*
*Last updated: 2026-01-11*
