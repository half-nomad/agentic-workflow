# Changelog

All notable changes to this project will be documented in this file.

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
