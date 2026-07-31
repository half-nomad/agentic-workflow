---
description: "Global coding and workflow rules that always apply"
---

# Global Rules

> 여기엔 **모델 기본 판단으로 안 나오는 것만** 둔다. 주석 밀도 · 명명 · 포맷 · "작은 함수" 같은 일반 코딩 상식은 시스템 프롬프트와 모델 판단이 이미 처리한다 — 여기 다시 적으면 상충 지시가 되어 오히려 품질이 떨어진다.

## Simplicity First

- Don't add features that weren't requested
- No abstraction for single-use code; no flexibility/configurability that wasn't requested
- No error handling for impossible scenarios
- If the same behavior fits in half the lines clearly, rewrite it. Ask: "Would a senior reviewer call this overengineered?"

> Security validation (`secure-coding.md`) is never "speculative" — boundary checks, fail-closed, and null handling stay even when simplifying.

## Surgical Changes

> When editing existing code, this section overrides Simplicity First: "shorten / restyle / delete-dead-code" urges apply only to code *you* author or orphan — not to pre-existing code you're passing through.

- Modify only the files and lines the request needs. Every changed line must trace directly to the user's request or its verification.
- Don't "improve" adjacent code, comments, or formatting. Don't refactor or rename things that aren't broken.
- Unrelated dead code: mention it, don't delete it. Remove only the orphans (imports/variables/functions) that *your* change made unused.
- Allowed: changes the request and its verification directly need — fixing a test, adjusting a type, updating a call site.

## Interpretation & Pushback

- If two or more interpretations exist, don't pick silently — present them. If a clearly simpler approach exists, propose it with the reason (push back).
- Stop and ask on requirement conflict, safety concern, scope expansion, or hard-to-reverse change — not for trivial ambiguity.

> **default-mode** behavior. In `/maestro` this judgment is front-loaded into PLAN/APPROVE (Phase 1–4 + Codex#1); autonomous / `approval skip` / `goal` runs surface interpretations in the plan and do **not** halt mid-execution.

## Git Commit Style

### Format
- **One line only.** Subject line is the entire message — no body, no bullet list, no detailed breakdown.
- **Prefix**: `Add:` / `Update:` / `Clean:` / `Fix:` / `Refactor:` followed by a space.
- **Subject content**: A concise description of *what* changed and *why* it matters in one sentence. Use `—` (em dash) to append a short qualifier when useful.
- **Language**: Korean is fine; mixed Korean/English is fine.

### Forbidden
- **Do NOT add `Co-Authored-By:` lines.** The user does not co-author commits with the model and does not want the line.
- **Do NOT add a body** with bullet points enumerating files or changes. The diff already shows that.
- **Do NOT mention the model name** (Sonnet, Opus, etc.) anywhere in the commit message.
- **Do NOT use HEREDOC** for trivial single-line messages — `git commit -m "..."` is fine.

### Examples

```
Update: 결제 웹훅 재시도 정책 — 지수 백오프 + 최대 5회
Add: 주간 리포트 생성 배치 — 매주 월요일 09:00 KST
Clean: 사용하지 않는 레거시 어댑터 3종 삭제
Fix: 로그인 후 리다이렉트가 쿼리 파라미터를 잃던 문제
```
