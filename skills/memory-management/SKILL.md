---
name: memory-management
description: "Procedures for keeping memory/, rules/, CLAUDE.md, and SKILL.md free of duplication and drift. Use when writing or updating a memory file, adding or editing a global rule, modifying an existing SKILL.md, tidying the MEMORY.md index, or deciding where a piece of knowledge belongs. Korean triggers: 메모리 정리, 룰 추가, 룰 수정, 중복 점검, MEMORY.md 정리, 정본 어디에."
---

# Memory Management — Procedures

> 정본 원칙 (WHAT/WHY/HOW 분리 · drift 경보) 은 `rules/memory-management.md` 에 상주한다. 여기는 **실행 절차**.

## Cross-check 명령

**새 memory 작성 전** — 이미 rule 로 존재하는지:
```bash
grep -ri "<핵심 키워드>" ~/.claude/CLAUDE.md ~/.claude/rules/
```

**새 CLAUDE.md / rules/ 항목 추가 전** — 이미 memory 에 있는지:
```bash
grep -ri "<핵심 키워드>" ~/.claude/projects/*/memory/
```

**rules/ 또는 SKILL.md 변경 시** — 양쪽 inline 복제 점검:
```bash
grep -ri "<핵심 키워드>" ~/.claude/skills/*/SKILL.md ~/.claude/rules/
```

## 중복 발견 시 — 의도된 vs 우발

| 유형 | 판단 기준 | 액션 |
|---|---|---|
| **의도된 중복** | WHAT/WHY/HOW 분리 / 다른 검색 어휘 / 보안 critical 방어적 / 추상 vs 구체 표현 | 유지. 통합 시도 X |
| **우발 중복** | 단순 복사 / 의미 없는 paraphrase / 깜빡 두 번 작성 | 정본 1곳 + 다른 곳은 link |
| **애매** | 위 둘 모두 명확히 안 맞음 | 사용자에게 한 줄 질문 후 진행 |

## Promotion / Demotion

- **memory → rules/** (promotion): memory 가 generic 해져서 다른 사용자에게도 적용 가능하면 rules/ 로 이동. memory 엔 사용자 specific 디테일만 남긴다.
- **rules/ → memory** (demotion): rules/ 에 사용자 specific 사연 (특정 사고, 특정 시스템 경로, 특정 도구 이름) 이 섞이면 memory 로 분리. rules/ 엔 generic rule 만.

## MEMORY.md 인덱스 임계점

| 줄 수 | 액션 |
|---|---|
| ~20줄 | 그대로 |
| 20~50줄 | 카테고리 헤더 + 파일명 prefix (`sec_`, `lec_`, `pkm_`, `dev_` 등) 도입 |
| 50~150줄 | 중복 통합 + 오래된 메모리는 `memory/_archive/` 로 분리 |
| 150줄+ | 강제 정리 — 200줄 초과 시 시스템 프롬프트에서 truncated |

자가 점검: 새 메모리 추가할 때마다 MEMORY.md 줄 수 확인.

## auto-memory 형식 정합

auto-memory 가 쓰는 frontmatter 는 `name` / `description` / `metadata.type` (user·feedback·project·reference). 구형 평면 형식 (`type:` 최상위) 파일을 발견하면 `metadata:` 아래로 옮긴다 — 인덱스 스캔이 `metadata.type` 을 읽는다.
