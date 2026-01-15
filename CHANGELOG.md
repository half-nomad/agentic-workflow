# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-01-15

### Added
- **Agent Priority System**: Project Agents > Global Agents > Dynamic Roles
- **Dynamic Role Template**: Create specialist roles on-demand for domains without pre-defined agents
- **Delegation Rules (MANDATORY)**: Enforce Task tool usage when agents identified in plan
- Color indicators for global agents (🔵🟢🟡🟣)

### Changed
- **CLAUDE.md simplified**: 193 → 67 lines (65% reduction), detailed rules moved to `rules/maestro-workflow.md`
- **Agent tools expanded**: `@architect`, `@frontend-engineer`, `@document-writer` now use `tools: *` (all tools)
- **@librarian**: Kept limited tools (research-only, no file modification)
- `rules/maestro-workflow.md`: v1.1 with delegation rules, agent priority, anti-patterns
- `docs/maestro-summary.md`: v1.1 with updated agent system documentation

### Fixed
- Context accumulation issue: Added mandatory delegation to distribute context across sub-agents

---

## [1.0.1] - 2026-01-11

### Added
- `docs/maestro-summary.md`: Comprehensive Maestro workflow documentation

### Removed
- `commands/manual.md`: Redundant (default mode is manual)
- `commands/semi-auto.md`: Redundant (merged into Maestro/Ultrawork)
- `skills/codebase-analysis/`: Replaced by built-in Explore + @architect
- `skills/deep-research/`: Replaced by @librarian agent

### Changed
- **Mode system simplified**: Default / Maestro / Ultrawork (was 3 modes)
- Updated README.md and CLAUDE.md to reflect mode changes

---

## [1.0.0] - 2026-01-11

### Added
- **Maestro Workflow**: New pattern-based orchestration system
  - 5 Anthropic patterns: Chaining, Parallelization, Routing, Orchestrator-Workers, Evaluator
  - 5-phase execution: ANALYZE → PATTERN → AGENTS → APPROVE → EXECUTE
  - `/maestro` command for explicit orchestrator activation
- `rules/maestro-workflow.md`: Detailed workflow rules and pattern selection guide
- `docs/legacy-comparison.md`: Migration documentation from Sisyphus

### Changed
- **CLAUDE.md**: Complete rewrite for Maestro workflow
- **Mode system**: Manual/Semi-Auto/Ultrawork now affect Maestro autonomy level
- **Keyword detector hooks**: Updated to inject Maestro patterns on ultrawork activation
- `frontend-engineer` agent: Added MCP tool permissions (chrome-devtools, playwright, hyperbrowser)

### Removed
- `agents/codebase-explorer.md`: Replaced by built-in `Explore` subagent
- `agents/task-planner.md`: Replaced by built-in `Plan` subagent
- `commands/plan.md`: Replaced by `/maestro`
- `commands/execute.md`: Integrated into Maestro flow
- `rules/sisyphus-phases.md`: Replaced by `maestro-workflow.md`
- Legacy Sisyphus 4-phase system (EXPLORE→PLAN→EXECUTE→VERIFY)

### Migration
- Legacy workflow preserved in `legacy/sisyphus-v1` branch
- See `docs/legacy-comparison.md` for detailed migration notes
