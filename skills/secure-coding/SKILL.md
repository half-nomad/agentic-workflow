---
name: secure-coding
description: "Detailed secure-coding checklist (KISA + OWASP Top 10 + CWE matrix) for code that touches a security boundary. Load BEFORE writing code that handles: user input, HTTP request bodies/params, authentication, sessions, cookies, API tokens, passwords, SQL or ORM queries, filesystem paths built from user input, subprocess/shell invocation, cryptography or secret comparison, file upload or download, URLs derived from user input, deserialization, access control / multi-tenant scoping, or rate limiting. Also covers npm/pnpm supply-chain incident background. Korean triggers: 보안 검토, 취약점, 인증 구현, 파일 업로드, 경로 처리, 토큰 비교, SQL 인젝션, 시큐어 코딩, CWE, OWASP."
---

# Secure Coding — Detailed Checklist

> `rules/secure-coding.md` 의 Core Principles 7개는 이미 상주 중이다. 이 파일은 **경계에 닿는 코드를 쓸 때 펼쳐 보는 상세**다.

## CWE Quick Reference

| CWE | Vulnerability | Prevention |
|-----|---------------|-----------|
| CWE-20 | Improper Input Validation | Validate type, length, range, format |
| CWE-22 | Path Traversal | Canonicalize and verify path stays under base dir |
| CWE-78 | OS Command Injection | Never `shell=true` with user input; pass argv list |
| CWE-79 | XSS | Output-encode by default; CSP; avoid `innerHTML`/`html_safe` on user data |
| CWE-89 | SQL Injection | Parameterized queries / ORM bindings; no string concat |
| CWE-94 | Code Injection | No `eval()`, `exec()`, `Function()` on user input |
| CWE-287 | Improper Authentication | Use vetted auth framework; reset session on login |
| CWE-327 | Weak Cryptography | AES-256, RSA-2048+; no MD5/SHA-1 for security |
| CWE-352 | CSRF | CSRF tokens; SameSite cookies |
| CWE-434 | Unrestricted Upload | Whitelist extension + MIME + size; store outside webroot; UUID filenames |
| CWE-502 | Insecure Deserialization | JSON, not pickle/yaml.load; whitelist filter |
| CWE-611 | XXE | Disable external entities and DOCTYPE |
| CWE-798 | Hardcoded Credentials | Env vars or secret manager |
| CWE-916 | Weak Password Hash | bcrypt / Argon2 / PBKDF2 with cost factor ≥ 10 |
| CWE-918 | SSRF | Validate URLs; deny private/loopback/metadata IPs |

## By Concern

### Input validation
- Validate type, length, format, range — server-side, every request
- Use parameterized queries for any DB call
- Sanitize before path/command/HTML use
- Whitelist allowed values; reject everything else

### Authentication & session
- Hash passwords with bcrypt/Argon2/PBKDF2 (cost ≥ 10) — never plain SHA/MD5
- Reset session ID on login (`reset_session` / equivalent) before setting any user-id key
- Lock accounts after N failed attempts (default: 5 / 30min)
- Constant-time comparison for tokens, OTPs, API keys
- Cookies: `Secure`, `HttpOnly`, `SameSite=Lax|Strict`, explicit `expire_after`

### Data protection
- HTTPS/TLS 1.2+ for all transport; reject SSLv3/TLS 1.0/1.1
- Encrypt sensitive data at rest (AES-256-GCM)
- Mask PII in logs (passwords, tokens, secrets, phone, birthdate, email-for-OTP)
- No credentials in source — use env / 1Password CLI / secret manager
- `.env` and similar files in `.gitignore`

### Error handling
- Don't leak stack traces to users
- Log server-side, return generic message to client
- Don't reveal whether email/username exists (uniform "invalid credentials")

### Access control
- Enforce authorization on every request, not just first
- Scope queries to current_user / current_account; reject unscoped `find(params[:id])`
- RBAC or ABAC; verify resource ownership

### File upload
- Whitelist extension (`.jpg`, `.png`, `.pdf`...) AND MIME (don't trust `Content-Type` header alone)
- Limit file size (default: 10 MB)
- Store outside webroot, with UUID filenames, mode 0644
- Re-process images (strip metadata, resize) instead of serving raw uploads
- Refuse `application/octet-stream` and executable MIMEs
- **Serving back**: resolve the stored path from the DB row scoped to the authenticated principal. A request-supplied filename may set `Content-Disposition` only — never select which bytes are read.

### API
- JWT: verify `alg`, `exp`, `iss`; reject `alg: none`
- Rate-limit per user and per IP, on every endpoint (especially login, OTP, password reset)
- Validate input AND sanitize output
- HSTS, CORS allow-list, request-signing for sensitive ops
- Log access (who, what, when) — but never the secrets themselves

### Coding hygiene
- Avoid deprecated/unsafe functions (`gets`, `strcpy`, `eval`, `pickle.loads`, `yaml.load`)
- Close resources (files, connections) with `with` / `using` / RAII
- Handle null/undefined explicitly
- Bound recursion and loops

## Supply chain background

> 실행 정책표(무엇이 자동/승인인지)는 `rules/secure-coding.md` 에 상주한다. 여기는 **왜 그런 정책인지**의 근거.

### 최근 사고 패턴

| 시기 | 사고 | 다운로드/주 | 공통점 |
|---|---|---|---|
| 2025-09 | chalk/debug 외 18개 | 2.6B (합산) | 메인테이너 피싱 → wallet drainer |
| 2025-12 | Shai-Hulud 1.0 (`@bitwarden/cli` 등 500+) | 다수 | preinstall worm, GitHub API C2 |
| 2026-03 | axios 1.14.1 | 100M | postinstall RAT, 호스트 credential 탈취 (북한 Sapphire Sleet) |
| 2026-04~05 | Mini Shai-Hulud (`@tanstack/*` 등 170+) | TanStack 1.5M | OIDC 토큰 탈취 worm 자가복제 |

공통 벡터: postinstall 자동 실행 + 호스트 credential. 방어 = **postinstall 차단 + cooldown + 호스트 격리**.

### 권장 셋업

- 패키지 매니저 전역 설정: `ignoreScripts=true` + `minimumReleaseAge` 를 7일 이상으로 (postinstall 차단 + cooldown)
- 셸 레벨 confirm: `npm` / `npx` / `pnpm` 의 설치 계열 명령에 확인 프롬프트를 거는 wrapper 함수
- MCP 서버 등 일회성 실행은 `pnpm dlx` 경유 (cooldown·ignore-scripts 가 자동 적용됨)

### 새 패키지 도입 검증

- `npm view <pkg> --json | jq .dist.attestations` (provenance)
- Socket.dev / deps.dev 한 번 조회
- known publisher 확인 (`@apify`, `@anthropic-ai`, `@vercel`, `@tanstack` 등)
- 10M+/주 패키지 최근 publish 버전은 7일 cooldown 자동 적용됨
