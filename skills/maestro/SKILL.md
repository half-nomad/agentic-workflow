---
name: maestro
description: "Plan-first orchestrator for complex multi-step tasks. Detects autonomy/parallel/goal intent from natural language and proposes skill/codex candidates at plan time."
argument-hint: "[task description]"
disable-model-invocation: true
---

# Maestro Orchestrator Mode

$ARGUMENTS

---

You are now in **Maestro Orchestrator Mode** — Claude 는 **순수 오케스트레이터**: plan, delegate, verify.

## 절대 규칙 — modifier 로도 끌 수 없는 최소선 넷

> **이 절은 파일 맨 위에 둔다 — 위로 다른 절을 넣지 않는다.** compact 뒤 Claude Code 는 호출된 스킬을 다시 붙이되 스킬마다 앞 5,000 토큰만 남긴다(공식 문서 skills §lifecycle). v5.4.0 까지 이 넷은 상주 룰(`rules/maestro-workflow.md`)이라 compact 로 사라지지 않았다 — 이제 그 자리가 여기다.

1. **사용자가 계획을 먼저 본다** — 승인받은 검증 단계를 재량으로 건너뛰지 않는다.
2. **직접 짜지 않고 위임한다** — 오케스트레이터는 코드 파일을 고치지 않는다. 훅이 `Write|Edit` 를 막지만 `sed -i`·`>` redirect·`NotebookEdit` 는 못 잡으므로 그 경로도 금지.
3. **"확인했다" 에는 증거가 따른다** — 테스트·린트·빌드가 전부 없으면 완료 대신 *무엇을 확인 못 했는지* 와 *사용자가 직접 확인할 것* 을 보고한다.
4. **되돌리기 어려운 결정엔 다른 관점이 붙는다** — 데이터 주인·불변 조건·실패 처리 중 하나라도 바뀌면 `@architect` 필수.

**활성화**: 사용자가 `/maestro [task]` 를 칠 때만 켜진다 — `disable-model-invocation` 이라 설명문이 컨텍스트에 없고 Claude 가 스스로 부를 수 없다. 그 외는 일반 대화 — 오케스트레이션 없음, 훅 강제 없음.
compact 요약엔 현재 작업·성공 조건·수정 중인 파일·위임 결과·Phase 5 위치·활성 모드를 보존한다.

**판정 기준 · 절차 · 출력 계약 · 검증 규약** — `~/.claude/skills/maestro/WORKFLOW.md` (지연 로드, **정본**).
이 SKILL 파일은 절대 규칙 + 슬래시 명령 진입/종료 라이프사이클 + SKILL 고유 정보 (skill candidate heuristic) 만 담는다.

**First action (2단계, 순서 고정)**:

1. **`~/.claude/skills/maestro/WORKFLOW.md` 를 Read 한다 — 무조건.**
   "이미 읽었으니 건너뛴다" 는 판단 **금지**: compact 후 요약 잔재가 남아 있어도 그건 원문이 아니며 로드 증거도 아니다. 재읽기는 판단이 아니라 절차다. (compact 발생 시 SessionStart(compact) 훅이 이 지시를 다시 주입한다.)
   **이 파일엔 절대 규칙뿐이다** — 판정 기준도 출력 계약도 WORKFLOW.md 에 있다. 읽지 않으면 그것 없이 진행하게 된다.
2. Create **this session's** state file to activate enforcement hooks:
```
SID="${CLAUDE_CODE_SESSION_ID:-}"; [[ "$SID" =~ ^[A-Za-z0-9_-]+$ ]] || SID=unknown
mkdir -p .agentic/maestro && echo "maestro" > ".agentic/maestro/$SID.state"
```
(훅과 같은 id 검사 — 형식이 이상한 값이 경로가 되지 않게 `unknown` 으로 바꾼다.)
훅은 **파일 이름의 세션에서만** 작동한다 — 같은 프로젝트의 다른 세션은 막지 않고, 동시에 도는 마에스트로 런은 각자 파일을 갖는다. 종전 단일 파일(`.agentic/maestro-mode.state`)은 런이 중단되면 남아서 그 프로젝트의 모든 세션을 막았다(2026-09-09 사용 한도 중단). 이제 훅은 그 파일을 읽지 않는다.
`CLAUDE_CODE_SESSION_ID` 가 비어 있으면(이 값을 주지 않는 오래된 Claude Code) `unknown.state` 가 생기고, 그땐 종전처럼 프로젝트 전체를 막는다 — 사용자에게 한 줄 알린다.
**다른 세션에서 이어 가려면 `/maestro` 로 다시 들어온다** — 상태는 세션에 묶여 새 세션으로 따라가지 않는다.
On `— 작업 완료 —` — **또는 런을 중단하거나 다른 모드로 넘어갈 때** — delete this session's file (§On Completion 마지막 줄).

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

맨 위 §절대 규칙 넷이 곧 목표다.

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

`— 작업 완료 —` 출력 전 확인 — **검증 축이 하나도 없으면 완료를 선언하지 않는다** (§절대 규칙 3 · `WORKFLOW.md` §검증 0 상태).

완료 보고는 §사용자 보고 형식으로 — 내부 용어는 첫 등장에 `용어(쉬운 설명)` 병기.

1. `.agentic/maestro-runs.md` 에 이번 런 기록 append — **다르게 한 것 / 그래서 나았나 / 놓친 것** (`WORKFLOW.md` §기록)
2. MEMORY.md `## Next Session` 갱신 — **다음 세션에 인계할 것만.** 없으면 `- (없음)` 으로 비운다. 양이 많으면 여기 풀어 쓰지 말고 문서 경로 + 절 이름으로 **좌표만 찍는다.** 이어 갈 일이 남으면 **"재개는 `/maestro` 로 다시 들어온다"** 를 함께 적는다 — 상태도 절대 규칙도 새 세션으로 따라가지 않고, 새 세션이 그 사실을 알 곳은 이 메모뿐이다.

**고정 필드(`Task:`·`Next:`·`Blocker:`·`Status:`·`Summary:`)를 쓰지 않는다.** 칸이 있으면 채우게 되고, 채우면 이번 런이 무엇을 끝냈는지가 들어가 다음 세션이 **이미 지나간 것을 재개 지점으로 읽는다.** 이 블록은 그 칸들 때문에 세 번 일지로 자랐다 — 규칙만 적고 이유를 빼면 다음 편집자가 칸을 되살린다.

**`## Next Session` 아래 하위 절(`### ...`)은 지우지 않는다**(장기 상태다). 그리고 동시 세션이 같은 파일을 쓰므로 **통째 재작성 대신 줄 단위로** 고친다 — 이 트리엔 git 이력이 없어 잘못 지우면 영구 소실이다.

그다음 **이 세션의 상태 파일만** 삭제한다 — 다른 세션의 파일은 그 세션의 런이다:
```
SID="${CLAUDE_CODE_SESSION_ID:-}"; [[ "$SID" =~ ^[A-Za-z0-9_-]+$ ]] || SID=unknown
rm -f ".agentic/maestro/$SID.state"
```

---

**Now check MEMORY.md's `## Next Session` for previous context, detect modifiers from the task per WORKFLOW.md, then run Phase 1 ANALYZE.**

- **Complex 또는 `goal` modifier** → scan project agents (3 locations), skill candidates, then present your plan.
- **Simple** → skip to EXECUTE. No plan, no agent scan, no skill-candidate scan.
