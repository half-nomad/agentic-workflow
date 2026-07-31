---
name: session-summary
description: "Summarize the CURRENT session in-chat — what was actually done (work recap) plus which Claude Code features/tools/agents/skills were used and how — then refresh the ## Next Session block in the project's MEMORY.md so the next session can resume with '계속'. Use when the user says 세션 요약(해줘), 세션 정리, 이번 세션 뭐 했지, 기능 뭐 썼지, 기능 사용 요약, 다음 세션 준비, 상태 저장하고 마무리, session summary, or is about to close a session whose state should carry over. Stays in-chat and writes only MEMORY.md — it does not touch project files or external notes."
argument-hint: "[focus]  (optional — e.g. '기능만', '작업만', 'MEMORY 스킵')"
---

# Session Summary

$ARGUMENTS

Two-layer summary of **this session** — (1) work recap: what was actually done, (2) feature usage: which Claude Code capabilities were used — then persist resume-state to MEMORY.md `## Next Session`.

Output goes to chat; the only file touched is MEMORY.md. `$ARGUMENTS` narrows scope when given: `기능만` skips §1, `작업만` skips §2, `MEMORY 스킵` skips §4.

## 1. Work recap (작업 요약)

Summarize what was **actually accomplished this session**:

- Group by outcome: 구현 / 수정 / 조사·분석 / 결정 / 문서.
- Each bullet = what was done + how it ended (files touched, decision made, problem solved).
- This session only — never fabricate or pad. A near-empty session gets one honest line.

## 2. Feature usage (기능 사용)

List Claude Code features **actually invoked** in the conversation. Scan the real tool calls — the table below is grouping guidance, NOT a checklist to enumerate. Feature names change between releases (past casualties hardcoded in this very skill: /swarm, /ralph, /ultrawork), so report what you observe in the transcript, not what any list says.

| 카테고리 | 현재 예시 |
|---|---|
| Core tools | Agent(서브에이전트 위임), Skill(슬래시 커맨드), Workflow, TaskCreate/TodoWrite, AskUserQuestion, EnterPlanMode/ExitPlanMode, WebSearch/WebFetch, Artifact, 백그라운드 Bash/job |
| Subagents | Explore, Plan, general-purpose + 커스텀 (@architect, @librarian, @frontend-engineer, @document-writer, 프로젝트 에이전트) |
| Skills | /maestro, /goal(내장), 프로젝트 스킬, 플러그인 스킬 (codex, my-note-skills, firecrawl …) |
| MCP | context7, playwright, claude-in-chrome, Notion, apify … |

### 유용했을 기능 (optional)

Max 3, and only when a specific unused feature would have concretely helped this session — a learning point, not an inventory. No genuine match → omit the section entirely. Never enumerate everything that wasn't used.

## 3. Output format

ALWAYS this shape, in chat:

```markdown
## Session Summary

### 작업 요약
- [outcome group] ...

### 사용한 기능
| Feature | 용도 |
|---------|------|
| [name] | [how it was used, 1 line] |

### 이번 세션에 유용했을 기능   ← only if §2 found any
| Feature | 이유 |
|---------|------|

### Next Session → MEMORY.md 반영
[the exact block written in §4]
```

## 4. MEMORY.md `## Next Session` (state persistence)

CLAUDE.md §State Persistence depends on this block: in the next session, "계속"/"continue" resumes from it. MEMORY.md is the only memory file auto-loaded into the system prompt, so this is the one place resume-state actually reaches the next session.

- Target: the **current project's auto-memory** `MEMORY.md` — its path is stated in the system prompt's Memory section (`~/.claude/projects/<project-slug>/memory/MEMORY.md`).
- **Replace** an existing `## Next Session` section in place; create it at the bottom if missing. Never stack duplicates.
- Keep it ≤ 8 lines — MEMORY.md is an index with a truncation threshold (~200 lines), not a journal. Details belong in the chat output, not here.

```markdown
## Next Session
- **Task**: <main task worked on>
- **Status**: completed | in_progress | blocked
- **Summary**: <1-2 lines of what this session achieved>
- **Pending**: <remaining items, or "없음">
- **Resume**: <the single first action for the next session, or "없음">
```

## Instructions (order)

1. Scan the whole conversation: tool invocations, delegations, file edits, decisions, errors resolved.
2. Write the work recap (§1), then the feature table (§2) from actual invocations.
3. Assemble the output (§3) in chat.
4. Update MEMORY.md `## Next Session` (§4) and show the exact block written.
