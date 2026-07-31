# Secure Coding Rules

> Always-loaded security defaults. Principles + triggers live here; the CWE matrix and per-concern checklists are in the **`secure-coding` skill** (progressive disclosure).
>
> Source: KISA CII 가이드라인 · OWASP Top 10 · CWE 매핑. (원본 스킬 `kesekit-guide` 흡수: 2026-05-03)

---

## Core Principles (binding, always)

1. **Validate at every boundary** — user input, external API, file paths, deserialization. Whitelist, not blacklist.
2. **Never trust client-side checks** — duplicate every validation server-side.
3. **Fail closed** — default to denying access; require explicit permission.
4. **Least privilege** — code runs with the minimum permissions it needs.
5. **No secrets in source** — credentials live in env vars or secret managers, never literals.
6. **Don't hand-roll crypto** — use vetted libraries (bcrypt/Argon2 for passwords, libsodium/AES-GCM for symmetric, well-known TLS).
7. **Constant-time comparison for tokens** — `==` on secrets leaks timing info; use `secure_compare` / `crypto.timingSafeEqual` / equivalent.

---

## Application — when to load the `secure-coding` skill

Touching **any** of the following means the detailed checklist is binding, not optional. **Load the `secure-coding` skill before writing the code** — don't work from memory of the matrix:

| Trigger | Skill section |
|---|---|
| User input (HTTP, CLI args, file uploads, form fields) | Input validation · CWE-20/79/89/94 |
| Authentication, sessions, cookies, tokens | Auth & session · CWE-287/798/916 |
| Database queries (any SQL or ORM call) | Input validation · CWE-89 |
| Filesystem paths built from user input | CWE-22 |
| Subprocess / shell invocation | CWE-78 |
| Crypto (hashing, encryption, signing, comparison) | CWE-327 · Core Principle 6·7 |
| File upload / download | File upload · CWE-434 |
| Network requests to user-derived URLs | CWE-918 |
| Deserialization of external data | CWE-502/611 |
| Access control / multi-tenant scoping | Access control |
| Error handling on an auth or data boundary | Error handling |

Generated code that violates these defaults must be flagged and corrected before being returned. If the skill can't be loaded, fall back to the Core Principles above and **say so explicitly** rather than shipping unchecked code.

Third-party package install/removal → §Supply chain below (resident, no skill load needed).

---

## Supply chain (npm/pnpm/yarn) — resident policy

**진행 중인 npm 공급망 공격(2026-05~) 대응.** 이 표는 매 명령을 게이트하므로 상주한다.

| 환경 | 명령 | 자동 |
|---|---|---|
| devcontainer 안 | `pnpm install --frozen-lockfile`, `pnpm dlx <known publisher>`, `pnpm run *` | ✅ |
| devcontainer 안 | `pnpm install` (lockfile 변경), `pnpm add/remove` | ⚠️ 알림 후 진행 |
| 호스트 직접 | `pnpm install --frozen-lockfile`, `pnpm dlx <known publisher>` | ⚠️ 알림 후 진행 (v11 cooldown 자동) |
| 호스트 직접 | `npm install`, `npx <anything>`, `pnpm install`, `pnpm add` | ❌ 사용자 승인 |
| 모든 환경 | `--ignore-scripts=false`, `--foreground-scripts`, lockfile 비활성화 | ❌ 사용자 승인 |
| 모든 환경 | `npm run *`, `pnpm run *` (lockfile 비변경) | ✅ |

**의심 / 사고 시**: 어떤 패키지·명령인지 즉시 명시 · 시크릿 점검은 마스킹 (값 출력 X) · 영향권 토큰은 사용자가 직접 회전.

**해제 조건**: 공격 종식 확인 + 사용자 명시 해제까지 유효. devcontainer 도입 후에도 호스트 직접 실행 룰 유지.

> 사고 이력 (chalk/debug · Shai-Hulud · axios RAT · Mini Shai-Hulud), 글로벌 셋업 상세, 새 패키지 도입 검증 절차 → `secure-coding` 스킬 §Supply chain background.
