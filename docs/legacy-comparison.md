# Legacy vs Maestro Workflow Comparison

**Date**: 2026-01-11
**Purpose**: Document the transition from Sisyphus to Maestro workflow

---

## Overview

| Aspect | Sisyphus (Legacy) | Maestro (New) |
|--------|-------------------|---------------|
| **Activation** | `/ultrawork`, `/ulw` only | `/maestro` for any task |
| **Structure** | Fixed 4-phase pipeline | Flexible pattern-based |
| **Phases** | EXPLORE→PLAN→EXECUTE→VERIFY | Analyze→Pattern→Agents→Approve→Execute |
| **Scope** | Complex automation only | All tasks (simple to complex) |

---

## Architectural Differences

### Sisyphus (Legacy)

```
INPUT → EXPLORE → PLAN → EXECUTE → VERIFY → DONE
         ↓         ↓        ↓         ↓
      @explorer  TodoWrite  Agents   Tests
      @librarian           Delegate  Verify
```

**Characteristics**:
- Rigid 4-phase structure
- Always runs all phases regardless of task complexity
- Tied to ultrawork mode only
- Phase gates with transition criteria
- Custom agents: `@codebase-explorer`, `@task-planner`

### Maestro (New)

```
INPUT → ANALYZE → PATTERN SELECT → AGENT ID → APPROVE → EXECUTE
           ↓            ↓              ↓          ↓
        Complexity   Chaining/      Built-in    User      Pattern
        Assessment   Parallel/      + Custom    Review    Execution
                     Routing/
                     Orchestrator
```

**Characteristics**:
- Flexible pattern-based approach
- Adapts to task complexity
- Works for all tasks via `/maestro`
- Anthropic 4+1 patterns
- Uses built-in agents (Explore, Plan) + custom specialists

---

## Pattern Mapping

| Sisyphus Phase | Maestro Pattern | When Used |
|----------------|-----------------|-----------|
| Full 4-phase | Orchestrator-Workers | Complex multi-domain tasks |
| EXPLORE only | (Built-in Explore) | Simple search queries |
| PLAN+EXECUTE | Chaining | Sequential multi-step tasks |
| Parallel EXPLORE | Parallelization | Independent concurrent tasks |
| Conditional flow | Routing | Branch-based execution |

---

## Agent Changes

### Removed (Replaced by Built-in)

| Legacy Agent | Built-in Replacement | Reason |
|--------------|---------------------|--------|
| `@codebase-explorer` | `Explore` subagent | Duplicate functionality |
| `@task-planner` | `Plan` subagent | Duplicate functionality |

### Retained

| Agent | Role | Notes |
|-------|------|-------|
| `@architect` | Strategic advisor | Escalation for complex decisions |
| `@frontend-engineer` | UI/UX specialist | MCP tools integration |
| `@librarian` | Documentation research | External docs, APIs |
| `@document-writer` | Documentation | README, guides |

---

## Command Changes

### Removed

| Command | Reason |
|---------|--------|
| `/plan` | Replaced by `/maestro` |
| `/execute` | Integrated into Maestro flow |
| `/codebase-explorer` | Use built-in Explore |

### Modified

| Command | Change |
|---------|--------|
| `/ultrawork` | Now triggers Maestro with full autonomy |
| `/ulw` | Alias for ultrawork |
| `/manual` | Sisyphus references removed |
| `/semi-auto` | Sisyphus references removed |

### Added

| Command | Purpose |
|---------|---------|
| `/maestro` | Orchestrator mode activation |

---

## Hook Changes

### Modified

| Hook | Change |
|------|--------|
| `keyword-detector.ps1/sh` | Updated for Maestro patterns |

### Unchanged

| Hook | Purpose |
|------|---------|
| `ralph-loop.ps1/sh` | Completion monitoring (generic) |
| `todo-enforcer.ps1/sh` | TODO tracking (generic) |
| `failure-tracker.ps1/sh` | Failure logging (generic) |
| `context-monitor.ps1/sh` | Context monitoring (generic) |

---

## File Inventory

### Deleted Files

```
agents/codebase-explorer.md     # → Built-in Explore
agents/task-planner.md          # → Built-in Plan
commands/plan.md                # → /maestro
commands/execute.md             # → Maestro integrated
commands/codebase-explorer.md   # → Built-in
docs/improvement-proposal-*.md  # Legacy proposals
docs/phase0-assess-design.md    # ASSESS concept abandoned
docs/agentic-workflow-guide.md  # Outdated guide
.agentic/metrics/baseline.md    # Legacy metrics
.agentic/failure-log.json       # Legacy log
CLAUDE.global.md                # Merged into CLAUDE.md
hooks/settings.local.json       # Duplicate
rules/sisyphus-phases.md        # → maestro-workflow.md
```

### New Files

```
CLAUDE.md                       # Main Maestro workflow definition
commands/maestro.md             # Orchestrator trigger
rules/maestro-workflow.md       # Detailed workflow rules
docs/legacy-comparison.md       # This document
```

---

## Migration Notes

1. **Legacy branch preserved**: `legacy/sisyphus-v1`
2. **Ralph Loop**: Unchanged - still monitors `<promise>DONE</promise>`
3. **TODO system**: Unchanged - TodoWrite still central
4. **Mode system**: Simplified - modes now affect Maestro autonomy level

---

## Key Improvements

| Area | Sisyphus | Maestro | Improvement |
|------|----------|---------|-------------|
| Flexibility | Fixed 4-phase | Pattern-based | +Adaptability |
| Scope | Ultrawork only | All tasks | +Coverage |
| Complexity | 7-level assessment | Simple/Complex | -Overhead |
| Agents | Custom duplicates | Built-in + specialists | -Redundancy |
| User control | Mode-based | Explicit `/maestro` | +Clarity |

---

*Document created: 2026-01-11*
*Legacy branch: `legacy/sisyphus-v1`*
