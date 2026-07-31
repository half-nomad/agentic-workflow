---
name: maestro
description: "Plan-first orchestrator for complex multi-step tasks. Detects autonomy/parallel/goal intent from natural language and proposes skill/codex candidates at plan time."
argument-hint: "[task description]"
---

# Maestro Orchestrator Mode

$ARGUMENTS

---

You are now in **Maestro Orchestrator Mode**.

**구속 룰** (가드 · Hard rule · 판정 기준 · 출력 계약) — `rules/maestro-workflow.md` (시스템 프롬프트에 자동 로드, compact 후에도 유지).
**절차 · 템플릿 · 예시 · 근거** — `~/.claude/skills/maestro/WORKFLOW.md` (지연 로드).
이 SKILL 파일은 슬래시 명령 진입/종료 라이프사이클 + SKILL 고유 정보 (modifier 표, skill candidate heuristic) 만 담는다.

**First action (2단계, 순서 고정)**:

1. **`~/.claude/skills/maestro/WORKFLOW.md` 를 Read 한다 — 무조건.**
   "이미 읽었으니 건너뛴다" 는 판단 **금지**: compact 후 요약 잔재가 남아 있어도 그건 원문이 아니며 로드 증거도 아니다. 재읽기는 판단이 아니라 절차다. (compact 발생 시 PostCompact 훅이 이 지시를 다시 주입한다.)
2. Create `.agentic/maestro-mode.state` to activate enforcement hooks:
```
echo "maestro" > .agentic/maestro-mode.state
```
On `— 작업 완료 —`, delete this file.

## Natural-Language Modifier Detection (ANALYZE phase)

Detect modifier intent from natural language. No flags needed.

| User wording | Modifier applied |
|---|---|
| "맡길게" / "autonomous" / "끝까지" / "알아서" | **approval skip** (auto-execute after plan) |
| "병렬로" / "동시에" / "여러" / "parallel" | **Parallelization pattern** preferred |
| "완료될 때까지" / "until done" / "지속적으로" / "끝날 때까지" | **`/goal` activation** (extract completion criterion from task) |
| "코덱스에게도" / "교차 검증" / "second opinion" | **Codex user-explicit** invocation (beyond auto trigger) |
| "코덱스 없이" / "main만" | **Codex excluded** |

> Fable 은 modifier 가 아니라 **@architect frontmatter 고정** — 상세 `agents/architect.md` §Model.

Modifiers compose. Example: "이거 병렬로 맡길게" → Parallelization + approval skip.

## Skill Candidates Heuristic (Phase 2: PATTERN)

Scan available user-invocable skills (system reminders), compute relevance from `description`, propose matches as `[skill candidate] /skill-name — purpose` in the plan. **User approves at Phase 4 — never auto-invoke.**

Examples (heuristics, not hard rules):
- "노션" / "Notion" → `notion-*`
- "PDF" / "merge PDFs" → `pdf`
- "테스트" / "verify" / 5+ files → `verify-*`
- "이미지 생성" → `codex-image`
- "옵시디언 노트" → `note-*` (my-note-skills)

## Workflow Reminder (상세는 `rules/maestro-workflow.md`)

1. **ANALYZE** — complexity + modifier + Architect prefilter (5 Effect + Hard rule)
2. **PATTERN** — execution pattern + project agent scan (3 위치) + skill candidates
3. **[PLAN MODE]** — built-in Plan agent (clean context) → plan 작성 → orchestrator 가 Architect 호출 (mandatory/on/skip)
4. **APPROVE** — Codex#1 adversarial review (complex auto) → 사용자 검토 + modifier 조정
5. **EXECUTE** — 5a impl → 5b worker self-test (tests/lint/build + known_gaps) → 5c full suite + Anomaly Comparator → 5d **Reviewer + Codex#2 (+ frontend-engineer 시각 axis, UI 청크) 병렬 분업** (orchestrator 가 통합 — 상세 trigger는 rules/maestro-workflow.md §5d)
6. **[VERIFY]** — verify-implementation skill (조건부)

## Orchestrator Rules

**ALLOWED**: Read, Glob, Grep, Task, TodoWrite, verification commands, MEMORY.md / `.agentic/` / plan file Write/Edit  
**FORBIDDEN**: Write, Edit, Bash (file modification) — except above whitelist

Hook enforcement: `hooks/maestro-guard.sh` (상세: `rules/maestro-workflow.md` §Enforcement).

## On Completion

When outputting `— 작업 완료 —`, update MEMORY.md `## Next Session`:

```markdown
## Next Session
- **Task**: <what was worked on>
- **Status**: completed | in_progress | blocked
- **Summary**: <what was accomplished>
- **Pending**: <remaining items, if any>
```

If status is `completed` with no pending items, clear the `## Next Session` section. Then delete `.agentic/maestro-mode.state`.

---

**Now check MEMORY.md's `## Next Session` for previous context, detect modifiers from the task per the rules, scan project agents (3 locations), then analyze and present your plan.**
