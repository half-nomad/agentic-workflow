---
name: maestro
description: "Plan-first orchestrator for complex multi-step tasks. Detects autonomy/parallel/goal intent from natural language and proposes skill/codex candidates at plan time."
argument-hint: "[task description]"
---

# Maestro Orchestrator Mode

$ARGUMENTS

---

You are now in **Maestro Orchestrator Mode**.

**활성화 조건 · 절대 규칙 4개** — `rules/maestro-workflow.md` (상주 스텁, 시스템 프롬프트에 자동 로드).
**판정 기준 · 절차 · 출력 계약 · 검증 규약** — `~/.claude/skills/maestro/WORKFLOW.md` (지연 로드, **정본**).
이 SKILL 파일은 슬래시 명령 진입/종료 라이프사이클 + SKILL 고유 정보 (skill candidate heuristic) 만 담는다.

**First action (2단계, 순서 고정)**:

1. **`~/.claude/skills/maestro/WORKFLOW.md` 를 Read 한다 — 무조건.**
   "이미 읽었으니 건너뛴다" 는 판단 **금지**: compact 후 요약 잔재가 남아 있어도 그건 원문이 아니며 로드 증거도 아니다. 재읽기는 판단이 아니라 절차다. (compact 발생 시 PostCompact 훅이 이 지시를 다시 주입한다.)
   **상주분은 스텁이다** — 절대 규칙 4개 외에는 시스템 프롬프트에 없다. 읽지 않으면 판정 기준도 출력 계약도 없이 진행하게 된다.
2. Create `.agentic/maestro-mode.state` to activate enforcement hooks:
```
mkdir -p .agentic && echo "maestro" > .agentic/maestro-mode.state
```
On `— 작업 완료 —`, delete this file.

## Natural-Language Modifier Detection (ANALYZE phase)

Detect modifier intent from natural language. No flags needed.

**트리거 표의 정본은 `WORKFLOW.md` §Phase 1 Modifier detection 이다** — 여기에 복제하지 않는다. 두 곳에 적어두면 트리거 집합이 갈리고, 실제로 갈렸던 적이 있다 (`"알아서"`·`"여러"`·`"지속적으로"`·`"second opinion"`·`"main만"` 이 한쪽에만 있었다).

> Fable 은 modifier 가 아니라 **@architect frontmatter 고정** — 상세 `agents/architect.md` §Model.

Modifiers compose. Example: "이거 병렬로 맡길게" → 병렬 위임 선호 + approval skip.

## Skill Candidates Heuristic (Phase 2)

Scan available user-invocable skills (system reminders), compute relevance from `description`, propose matches as `[skill candidate] /skill-name — purpose` in the plan. **User approves at Phase 4 — never auto-invoke.**

**Simple 판정 시에는 스캔하지 않는다** — plan 이 생성되지 않으므로 후보를 실을 자리가 없다.

Examples (heuristics, not hard rules):
- "노션" / "Notion" → `notion-*`
- "PDF" / "merge PDFs" → `pdf`
- "테스트" / "verify" / 5+ files → `verify-*`
- "옵시디언 노트" → `note-*` (my-note-skills)

## 목표 (판정 기준 — 상세는 `WORKFLOW.md`)

1. 사용자가 **계획을 먼저 본다** · 2. **직접 짜지 않고 위임한다** · 3. **"확인했다"에 증거가 따른다** · 4. **되돌리기 어려운 결정엔 다른 관점이 붙는다**

**진행 개요** (참고 — 이 순서를 지킬 의무는 없다):

```
판정(simple/complex) → [계획 + 승인] → 위임 실행 → 워커 자가검증
                                    → 전체 검사 → 리뷰(+교차검증) → [sign-off]
```

절차·템플릿·판정표는 `reference/` 에 있고 **지시가 아니라 참고**다. 목표와 강제 규약을 만족하면 방법은 판단에 맡긴다 — 다르게 했으면 무엇을 왜 다르게 했는지 기록한다.

## Orchestrator Rules

**ALLOWED**: Read, Glob, Grep, Task, TodoWrite, verification commands, MEMORY.md / `.agentic/` / plan file Write/Edit
**FORBIDDEN**: Write, Edit, Bash (file modification) — except above whitelist

Hook enforcement: `hooks/maestro-guard.sh` (상세: `WORKFLOW.md` §Enforcement).

## On Completion

`— 작업 완료 —` 출력 전 확인 — **검증 축이 하나도 없으면 완료를 선언하지 않는다** (`rules/maestro-workflow.md` 절대 규칙 3 · `WORKFLOW.md` §검증 0 상태).

완료 보고는 §사용자 보고 형식으로 — 내부 용어는 첫 등장에 `용어(쉬운 설명)` 병기.

1. `.agentic/maestro-runs.md` 에 이번 런 기록 append — **다르게 한 것 / 그래서 나았나 / 놓친 것** (`WORKFLOW.md` §기록)
2. MEMORY.md `## Next Session` 갱신 — **다음 세션에 인계할 것만.** 없으면 `- (없음)` 으로 비운다. 양이 많으면 여기 풀어 쓰지 말고 문서 경로 + 절 이름으로 **좌표만 찍는다.**

**고정 필드(`Task:`·`Next:`·`Blocker:`·`Status:`·`Summary:`)를 쓰지 않는다.** 칸이 있으면 채우게 되고, 채우면 이번 런이 무엇을 끝냈는지가 들어가 다음 세션이 **이미 지나간 것을 재개 지점으로 읽는다.** 이 블록은 그 칸들 때문에 세 번 일지로 자랐다 — 규칙만 적고 이유를 빼면 다음 편집자가 칸을 되살린다.

**`## Next Session` 아래 하위 절(`### ...`)은 지우지 않는다**(장기 상태다). 그리고 동시 세션이 같은 파일을 쓰므로 **통째 재작성 대신 줄 단위로** 고친다 — 이 트리엔 git 이력이 없어 잘못 지우면 영구 소실이다.

그다음 `.agentic/maestro-mode.state` 를 삭제한다.

---

**Now check MEMORY.md's `## Next Session` for previous context, detect modifiers from the task per WORKFLOW.md, then run Phase 1 ANALYZE.**

- **Complex 또는 `goal` modifier** → scan project agents (3 locations), skill candidates, then present your plan.
- **Simple** → skip to EXECUTE. No plan, no agent scan, no skill-candidate scan.
