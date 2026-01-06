# Hierarchical CLAUDE.md Guide

프로젝트별 컨텍스트를 Claude Code에 주입하는 계층적 CLAUDE.md 활용 가이드.

## 개요

CLAUDE.md는 Claude Code가 세션 시작 시 자동으로 읽는 컨텍스트 파일입니다.
계층적 구조를 활용하면 전역/프로젝트/디렉토리별 맞춤 지침을 제공할 수 있습니다.

## 계층 구조

```
~/.claude/CLAUDE.md              # 전역 (모든 프로젝트 공통)
~/projects/my-app/CLAUDE.md      # 프로젝트 루트
~/projects/my-app/src/CLAUDE.md  # 하위 디렉토리 (선택)
```

**우선순위**: 하위 -> 상위 (하위가 상위를 오버라이드)

## 전역 CLAUDE.md 템플릿

```markdown
# Global Instructions

## Coding Style
- 한글 주석 사용
- 들여쓰기: 2 spaces
- 세미콜론 필수 (JS/TS)

## Git Conventions
- Conventional Commits 사용
- feat/fix/docs/refactor/test

## Preferred Tools
- 테스트: 프레임워크별 기본 (RSpec, Jest 등)
- 린터: 프로젝트 설정 따름
```

## 프로젝트별 CLAUDE.md 예시

### Ruby on Rails

```markdown
# Project: My Rails App

## Stack
- Ruby 3.2 / Rails 7.1
- PostgreSQL
- Hotwire (Turbo + Stimulus)

## Architecture
- app/services/ - 비즈니스 로직
- app/queries/ - 복잡한 쿼리
- app/components/ - ViewComponent

## Conventions
- Fat Model 지양, Service Object 사용
- N+1 쿼리 주의 (bullet gem 활용)
- I18n 필수
```

### Astro

```markdown
# Project: My Astro Site

## Stack
- Astro 4.x
- React (islands)
- Tailwind CSS

## Structure
- src/pages/ - 라우팅
- src/components/ - 공유 컴포넌트
- src/layouts/ - 레이아웃

## Conventions
- 정적 우선, 필요시 client:load
- Image 컴포넌트 사용
```

### Next.js

```markdown
# Project: My Next.js App

## Stack
- Next.js 14 (App Router)
- TypeScript
- Tailwind CSS

## Structure
- app/ - App Router
- components/ - UI 컴포넌트
- lib/ - 유틸리티

## Conventions
- Server Components 기본
- 'use client' 최소화
- Zod로 유효성 검증
```

## 활용 팁

### 1. 에이전트 활성화 조건 명시
```markdown
## Agent Triggers
- API 작업 시 -> backend-engineer
- UI 작업 시 -> frontend-engineer
- 막힐 때 -> oracle
```

### 2. 금지 사항 명시
```markdown
## DO NOT
- console.log 커밋 금지
- any 타입 사용 금지
- 테스트 없이 PR 금지
```

### 3. 자주 사용하는 명령어
```markdown
## Common Commands
- dev: `bin/dev` (Rails) / `npm run dev` (Node)
- test: `bundle exec rspec` / `npm test`
- lint: `bundle exec rubocop` / `npm run lint`
```

## 디렉토리별 오버라이드

특정 디렉토리에서만 다른 규칙 적용:

```markdown
# src/legacy/CLAUDE.md

## Legacy Code Rules
- 리팩토링 최소화
- 기존 패턴 유지
- 변경 시 테스트 필수
```

## 체크리스트

- [ ] 전역 CLAUDE.md 생성 (~/.claude/CLAUDE.md)
- [ ] 프로젝트별 CLAUDE.md 생성 (프로젝트 루트)
- [ ] 스택/아키텍처 명시
- [ ] 컨벤션 명시
- [ ] 금지 사항 명시

---

*Generated: 2025-01-05*
