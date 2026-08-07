# 참조 — framework 별 검증 커맨드 (auto-detect fallback)

> **언제 읽나**: 프로젝트가 `.claude/maestro-axes.md` 로 axis 를 등록하지 않았고, 프로젝트 관례(`package.json` scripts · README · CLAUDE.md)에서도 커맨드를 못 찾았을 때만.
> **우선순위**: 프로젝트 등록 axis > 프로젝트 관례 > 이 표.

---

| Framework | 커맨드 |
|---|---|
| **Ruby / Rails** | `bin/test` / `bin/rails test` (unit) · `rubocop` (lint) · `brakeman` (security) · `srb tc` (type) |
| **Node / TypeScript** | `npm test` / `pnpm test` (unit) · `tsc --noEmit` (type) · `eslint` (lint) · `pnpm playwright test` (e2e) |
| **Next.js** | 위 Node + `pnpm next build` (build verify) · `pnpm lhci autorun` (perf/lighthouse, 선택) |
| **Astro** | `pnpm astro build` (build) · `pnpm astro check` (content_schema + type) · broken-link-check |
| **Python / FastAPI** | `pytest` (unit) · `mypy` (type) · `ruff` (lint) · `bandit` (security) · `schemathesis run <openapi>` (api_contract) |
| **Rust** | `cargo test` (unit) · `cargo clippy` (lint) |
| **Go** | `go test ./...` (unit) · `go vet` (lint) |

**axis 이름 예시** (프로젝트가 등록할 때 쓸 수 있는 것들):
`unit / type / lint / build / e2e / a11y / perf / content_schema / api_contract / security / gdpr_audit / event_schema`

> 이 표는 **출발점이지 정답이 아니다.** 프로젝트가 커스텀 스크립트를 쓰면 그쪽이 항상 우선한다. 표에 없는 스택이면 `package.json`·`Makefile`·CI 설정에서 찾는다.
