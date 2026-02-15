---
name: swarm
description: "Parallel execution mode. Launch multiple agents simultaneously for independent tasks."
---

# Swarm - Parallel Execution Mode

[SWARM MODE ACTIVATED]

$ARGUMENTS

---

## Execution Protocol

1. **IDENTIFY** - 독립적인 작업들 식별
2. **SPLIT** - 각 작업을 별도 Task로 분리
3. **DISPATCH** - 단일 메시지에서 여러 Task 병렬 호출
4. **COLLECT** - 모든 결과 수집
5. **SYNTHESIZE** - 결과 통합 및 보고

## Execution Pattern

```
┌→ Agent A (Task 1) ─┐
│→ Agent B (Task 2) ─┤→ Collect → Synthesize → Report
└→ Agent C (Task 3) ─┘
```

## Agents for Parallel Work

| Agent | Model | Best For |
|-------|-------|----------|
| `@librarian` | sonnet | 문서 리서치 |
| `Explore` | haiku | 코드베이스 탐색 |
| `general-purpose` | sonnet | 범용 작업 |

## Use Cases

- 여러 라이브러리 동시 조사
- 다중 파일 병렬 분석
- 여러 소스에서 정보 수집
- 독립적인 리팩토링 작업

## Rules

- 각 Task는 **독립적**이어야 함 (상호 의존성 없음)
- **단일 메시지**에서 여러 Task 호출 필수
- `run_in_background: true` 활용 권장
- 결과 수집 후 통합 보고
