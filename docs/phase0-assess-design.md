# Phase 0: ASSESS Specification

**Version**: 1.0
**Date**: 2026-01-11
**Status**: Design
**Author**: @task-planner

---

## Overview

Phase 0: ASSESS is a pre-execution gate that determines the optimal execution path before entering the Sisyphus 4-phase pipeline. It enables intelligent phase skipping for simple tasks while ensuring complex tasks receive full treatment.

```
INPUT -> [PHASE 0: ASSESS] -> Execution Path Decision
              |
              +-> Level 1-2: Direct Execute (skip EXPLORE/PLAN)
              +-> Level 3-4: Start at PLAN (skip EXPLORE)
              +-> Level 5-7: Full Sisyphus (start at EXPLORE)
```

---

## Integration with Sisyphus

### Current Flow (v1.x)

```
INPUT -> EXPLORE -> PLAN -> EXECUTE -> VERIFY -> DONE
```

### Enhanced Flow (v2.0 with ASSESS)

```
INPUT -> ASSESS -> [Route] -> ... -> VERIFY -> DONE
            |
            +-> Level 1-2: EXECUTE -> VERIFY
            +-> Level 3-4: PLAN -> EXECUTE -> VERIFY
            +-> Level 5-7: EXPLORE -> PLAN -> EXECUTE -> VERIFY
```

---

## ASSESS Components

### 1. Complexity Classifier

Determines execution depth using signal analysis.

| Signal | Low (1-2) | Medium (3-4) | High (5-7) |
|--------|-----------|--------------|------------|
| File count | 1 file | 2-5 files | 6+ files |
| Domain crossover | Single | 2 domains | 3+ domains |
| Dependencies | None | Internal only | External |
| Risk level | Reversible | Moderate | Breaking |
| Exploration needed | No | Maybe | Yes |

**Algorithm**:
```
complexity = 0
complexity += file_signal_score      // 0-2
complexity += domain_signal_score    // 0-2
complexity += dependency_signal_score // 0-1
complexity += risk_signal_score      // 0-1
complexity += exploration_signal     // 0-1

final_level = clamp(complexity, 1, 7)
```

### 2. Type Classifier

Categorizes the task for agent selection.

| Type | Keywords | Primary Agent |
|------|----------|---------------|
| search | find, where, locate, show | @codebase-explorer |
| implement | create, build, add, make | (based on domain) |
| debug | fix, error, broken, issue | @architect |
| refactor | improve, optimize, clean | @architect |
| document | readme, explain, describe | @document-writer |
| analyze | understand, how, what | @librarian |

### 3. Domain Classifier

Identifies relevant domains for agent delegation.

| Domain | Signals | Agent |
|--------|---------|-------|
| frontend | .tsx, .css, UI, component | @frontend-engineer |
| backend | .ts (non-UI), API, server | (main) |
| database | schema, migration, query | (main) |
| devops | docker, CI, deploy | (main) |
| docs | .md, README, documentation | @document-writer |
| testing | test, spec, jest | (main) |

---

## Execution Paths

### Path A: Direct Execute (Level 1-2)

**When**: Single file, clear action, no exploration needed

```
ASSESS -> EXECUTE -> VERIFY -> DONE
```

**Examples**:
- "Fix typo in README"
- "Add console.log to debug"
- "What is the project structure?"

**Skipped**: EXPLORE, PLAN

### Path B: Plan First (Level 3-4)

**When**: Multi-file but predictable, pattern exists

```
ASSESS -> PLAN -> EXECUTE -> VERIFY -> DONE
```

**Examples**:
- "Add a new API endpoint"
- "Create a React component"
- "Update error handling"

**Skipped**: EXPLORE

### Path C: Full Sisyphus (Level 5-7)

**When**: Complex, unknown scope, multiple domains

```
ASSESS -> EXPLORE -> PLAN -> EXECUTE -> VERIFY -> DONE
```

**Examples**:
- "Implement user authentication"
- "Refactor the payment system"
- "Migrate to new database"

**Skipped**: None

---

## Implementation

### Hook: assess-task.ps1

```powershell
# Trigger: UserPromptSubmit
# Runs BEFORE keyword-detector.ps1

param()

$prompt = $env:USER_PROMPT

# Skip assessment for explicit commands
if ($prompt -match "^/(explorer|librarian|oracle|plan|ultrawork)") {
    exit 0
}

# Signal detection
$signals = @{
    files = 0
    domains = 0
    dependencies = 0
    risk = 0
    exploration = 0
}

# File count signals
if ($prompt -match "all|every|across|multiple") { $signals.files = 2 }
elseif ($prompt -match "files|several") { $signals.files = 1 }

# Domain signals
$domainMatches = 0
if ($prompt -match "frontend|UI|component|CSS") { $domainMatches++ }
if ($prompt -match "backend|API|server") { $domainMatches++ }
if ($prompt -match "database|schema|migration") { $domainMatches++ }
if ($prompt -match "test|spec") { $domainMatches++ }
$signals.domains = [Math]::Min($domainMatches, 2)

# Dependency signals
if ($prompt -match "library|package|external|integration") { $signals.dependencies = 1 }

# Risk signals
if ($prompt -match "migrate|refactor|breaking|critical") { $signals.risk = 1 }

# Exploration signals
if ($prompt -match "understand|investigate|explore|find out") { $signals.exploration = 1 }

# Calculate complexity
$complexity = $signals.files + $signals.domains + $signals.dependencies + $signals.risk + $signals.exploration
$level = [Math]::Max(1, [Math]::Min(7, $complexity + 1))

# Determine path
$path = switch ($level) {
    { $_ -le 2 } { "direct" }
    { $_ -le 4 } { "plan" }
    default { "full" }
}

# Output assessment
Write-Output @"
[PHASE 0: ASSESS]
Complexity Level: $level/7
Execution Path: $path
Signals: files=$($signals.files), domains=$($signals.domains), deps=$($signals.dependencies), risk=$($signals.risk), explore=$($signals.exploration)

$(switch ($path) {
    "direct" { "ROUTING: Skip to EXECUTE phase (simple task detected)" }
    "plan" { "ROUTING: Skip EXPLORE, start at PLAN phase" }
    "full" { "ROUTING: Full Sisyphus pipeline (complex task detected)" }
})
"@
```

### CLAUDE.md Integration

Add to Phase System section:

```markdown
## Phase 0: ASSESS (Pre-execution)

Before starting Sisyphus phases, assess task complexity:

### Complexity Signals
- **Files**: 1 file (low) vs multiple files (high)
- **Domains**: Single domain (low) vs cross-domain (high)
- **Dependencies**: Internal (low) vs external (high)
- **Risk**: Reversible (low) vs breaking change (high)
- **Exploration**: Known solution (low) vs unknown (high)

### Execution Paths
| Level | Path | Phases |
|-------|------|--------|
| 1-2 | Direct | EXECUTE -> VERIFY |
| 3-4 | Plan | PLAN -> EXECUTE -> VERIFY |
| 5-7 | Full | EXPLORE -> PLAN -> EXECUTE -> VERIFY |

### Override
Use explicit commands to force specific paths:
- `/force-simple` - Use Level 1-2 path
- `/force-full` - Use Level 5-7 path (full Sisyphus)
```

---

## Mode Compatibility

| Mode | ASSESS Behavior |
|------|-----------------|
| Manual | Advisory only - suggests path, user decides |
| Semi-Auto | Auto-routes, checkpoints at phase transitions |
| Ultrawork | Fully automatic routing, no confirmation |

---

## Success Criteria

- [ ] ASSESS correctly classifies 85% of tasks
- [ ] Simple tasks (Level 1-2) complete 40% faster
- [ ] No regression in complex task quality
- [ ] User can override with explicit commands
- [ ] Mode-specific behavior works correctly

---

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `hooks/assess-task.ps1` | Create | Main assessment hook |
| `settings.json` | Modify | Add ASSESS hook to UserPromptSubmit |
| `CLAUDE.md` | Modify | Add Phase 0 documentation |
| `rules/sisyphus-phases.md` | Modify | Update phase flow diagram |
| `commands/force-simple.md` | Create | Override to simple path |
| `commands/force-full.md` | Create | Override to full path |

---

## Next Steps

1. Implement `assess-task.ps1` hook
2. Add hook registration to `settings.json`
3. Update CLAUDE.md with Phase 0 rules
4. Create override commands
5. Test with sample tasks across complexity levels
6. Measure impact against baseline

---

*Specification created: 2026-01-11*
