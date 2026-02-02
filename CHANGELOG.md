# Changelog

All notable changes to this project will be documented in this file.

## [1.4.0] - 2026-02-03

### Changed
- **commands → skills 마이그레이션**: Claude Code v2.1.3 skills 시스템으로 전환
- **Skills 구조**: `skills/{name}/SKILL.md` 형식으로 변경
- `/ralph-start` + `/ralph-cancel` → `/ralph start|cancel`로 통합

### Removed
- `commands/` 폴더 전체 (skills로 대체)
- `/frontend`, `/librarian`, `/oracle` commands (에이전트 직접 호출로 대체)
- `ulw.md` + `ultrawork.md` 중복 제거

### Added
- `skills/maestro/SKILL.md`
- `skills/ultrawork/SKILL.md`
- `skills/ulw/SKILL.md` (alias)
- `skills/swarm/SKILL.md`
- `skills/ralph/SKILL.md` (start/cancel 통합)
- `skills/session-summary/SKILL.md`

### Fixed
- 설치 스크립트 업데이트 (commands → skills)

---

## [1.3.0] - 2026-01-27

### Added
- **Swarm Mode**: `/swarm` 또는 `swarm:` 키워드로 병렬 에이전트 실행
- **boulder.json**: 세션 간 계획 상태 유지 메커니즘
- `hooks/boulder-manager.ps1/sh`: 상태 로드/저장 훅

### Changed
- `hooks/keyword-detector.ps1/sh`: swarm 키워드 감지 추가
- `settings.json`: 새 훅 등록
- **Patterns**: 4+1 → 5+1 (Swarm 추가)

---

## [1.2.0] - 2026-01-26

### Added
- **Orchestrator Role Definition (CRITICAL)**: Explicit allowed/forbidden actions for orchestrator
- **Tool Permissions Table**: Clear matrix of which tools orchestrator vs sub-agents can use
- **Self-Check Checklist**: Mental interrupt before using forbidden tools

### Changed
- **commands/maestro.md**: Simplified from 63 → 23 lines, removes duplication with rules
- **Delegation loophole removed**: "Single domain, < 3 files → Direct execution OK" changed to require delegation
- **Handle Failures**: Now specifies delegation attempts, not direct execution
- **Result Integration**: Clarified that modifications must be delegated, not done directly
- **Chaining Pattern example**: Updated to show proper delegation

### Fixed
- Main agent tendency to directly execute code/document CRUD instead of delegating
- Information duplication between `commands/maestro.md` and `rules/maestro-workflow.md`

---

## [1.1.1] - 2026-01-23

### Changed
- **Agent tools 설정 수정**: `tools: *` / `tools: all` 제거, 모든 도구 상속 방식으로 변경
- **permissionMode 추가**: `acceptEdits`로 Write/Edit 자동 승인 설정

### Fixed
- 공식 Claude Code 문서에 맞지 않는 tools 필드 문법 수정 (`*`, `all` → 필드 생략)

---

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
