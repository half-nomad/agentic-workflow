# Global Claude Code Rules

> Copy this file to `~/.claude/CLAUDE.md` for global application

---

## Core Principles

### Simplicity First
- Prefer simple solutions over clever ones
- Remove code rather than commenting it out
- One thing should do one thing

### Clean Code
- Self-documenting code over comments
- Small, focused functions
- Consistent formatting

### Communication
- Dense and useful beats long and thorough
- Lead with the answer, then explain
- Include file paths with line numbers

---

## Sisyphus Phase System

A 4-phase approach to structured task execution.

### Phase 1: EXPLORE
- Launch 3+ parallel searches using Task tool
- Use `@explorer` for codebase, `@librarian` for docs
- Output: Files found, patterns, constraints

### Phase 2: PLAN
- Create TODO list with TodoWrite
- Define success criteria and risks
- Output: Actionable task list with dependencies

### Phase 3: EXECUTE
- Work through TODO items systematically
- Delegate to specialists when needed
- Recovery: Retry -> Alternative -> `@architect`

### Phase 4: VERIFY
- Run tests, verify success criteria
- Check for regressions
- Output: `<promise>DONE</promise>` when complete

---

## Agent Delegation

| Agent | Role | Use When |
|-------|------|----------|
| `@explorer` | Codebase search (Haiku) | Find files, locate implementations |
| `@librarian` | Documentation research (Sonnet) | Library docs, API references, OSS examples |
| `@architect` | Strategic advisor (Opus) | Stuck 2+ times, major decisions |
| `@frontend-engineer` | UI specialist (Opus) | Visual/UI work |
| `@document-writer` | Documentation (Opus) | README, docs updates |
| `@planner` | Task planning (Opus) | Complex task breakdown |

---

## Operating Modes

### Manual Mode (`/manual`)
- Full user control, no automation
- Ralph Loop: DISABLED
- User confirmation required for each step

### Semi-Auto Mode (`/semi-auto`)
- Balanced automation with checkpoints
- Autonomous within phases
- Pauses at phase transitions for confirmation

### Ultrawork Mode (`/ultrawork`, `/ulw`)
- Full autonomous execution
- Ralph Loop: ENABLED
- 100% completion guaranteed
- No stopping until `<promise>DONE</promise>`

| Phase | Manual | Semi-Auto | Ultrawork |
|-------|--------|-----------|-----------|
| EXPLORE | With guidance | Autonomous | Autonomous |
| PLAN | User review | Checkpoint | Autonomous |
| EXECUTE | Step approval | Autonomous | Autonomous |
| VERIFY | User review | Checkpoint | Autonomous |

---

## Ralph Loop

Autonomous continuation system for task completion.

### Start
```
/ralph-start
```
Creates `.agentic/ralph-loop.state.md` with:
- `active: true`
- `max_iterations: 50`
- Original request preserved

### How It Works
1. Monitors for `<promise>DONE</promise>` at Stop event
2. If not detected: Triggers continuation prompt
3. If detected: Loop terminates successfully
4. If max iterations: Terminates with warning

### Stop
```
/ralph-cancel
```
Or output completion signal:
```
<promise>DONE</promise>
```

---

## Completion Signal

**CRITICAL**: Only output when task is truly complete:
```
<promise>DONE</promise>
```

Requirements before signaling:
- All TODO items marked complete
- Tests pass (if applicable)
- Success criteria met
- No known issues remaining

---

## Anti-Patterns

1. **Skipping Exploration** - Never jump to implementation
2. **Incomplete Planning** - Vague TODOs lead to scope creep
3. **Ignoring Failures** - Escalate to `@architect` after 2 failures
4. **Premature Completion** - Verify before claiming done
5. **Single Sequential Search** - Always run parallel searches

---

## Extended Documentation Triggers

상세한 규칙이 필요할 때 `docs/rules/` 디렉토리의 문서를 참조합니다.

### TypeScript 작업 시
TypeScript/TSX 파일 작업 시 → `docs/rules/typescript.md` 참조
- 타입 안전성, strict mode, null handling
- import 구조, async/await 패턴

### 코드 품질 규칙
품질/스타일 가이드 필요 시 → `docs/rules/global.md` 참조
- Simplicity First 원칙
- Clean Code 규칙
- Communication 스타일

### Sisyphus Phase 상세
Phase 시스템 상세 규칙 필요 시 → `docs/rules/sisyphus-phases.md` 참조
- 각 Phase별 상세 프로토콜
- 모드별 동작 차이
- Recovery 전략
