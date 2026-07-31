---
name: multi-worktree-safety
description: Claude agents view 다중 백그라운드 job 운영 시 worktree 충돌 최소화 룰 가이드. 사용 시점 — (1) 여러 worktree 동시 작업, (2) 키워드 "worktree" / "agents view" / "다중" / "멀티 작업" / "병렬 세션" / "충돌" / "동시 작업" 언급 시, (3) git worktree / EnterWorktree 명령 호출 전, (4) 공통 파일 (TODO/CHANGELOG/VERSION/MEMORY) 수정 작업 진입 시, (5) 사용자가 /multi-worktree-safety 명시 호출 시. 평시 토큰 부담 0 — 트리거 시점에만 본문 로드. **사용자가 키워드를 직접 언급하지 않더라도 다중 백그라운드 job 환경 (`$CLAUDE_JOB_DIR` 설정됨 + jobs 디렉터리에 다른 active job 존재) 이거나 git worktree 작업이 예상되면 반드시 이 skill을 사전 로드해서 충돌 방지 룰 적용하세요.**
---

# Multi-worktree Safety Rules

> **컨텍스트**: Claude agents view = 다중 백그라운드 job UI. 시스템이 새 대화를 background job으로 자동 등록 + EnterWorktree 격리 강제. 충돌은 필연 — 빈도 최소화 룰.

## Core Rules (4가지)

### Rule 1 — Task별 1 worktree, 같은 task 분할 금지
- 같은 task의 sub-work를 여러 session/worktree에 쪼개지 X
- 다른 task끼리만 동시 운영
- 같은 task = 같은 의도 = 같은 파일 수정 빈도 ↑ → 직렬화로 충돌 0

### Rule 2 — 공통 파일 함께 작성, 단 섹션/라인 분리
누락 방지 위해 처음부터 공통 파일도 같이 수정. 충돌 빈도는 섹션 분리로 최소화.

| 파일 | 정책 |
|------|------|
| `docs/TODO.md` | task별 sub-섹션 신설 (같은 섹션 안 동시 수정 X) → 자동 머지 가능 |
| `docs/CHANGELOG.md` | 시간순 최상단 append. 충돌 시 양쪽 entry 살림 (5초 작업) |
| `VERSION` | task가 직접 bump X → **머지 시점에 사용자 결정** |
| `MEMORY.md` / `feedback_*.md` | 섹션/파일 분리. 같은 sub-memory 동시 수정 X |

### Rule 3 — 머지 순서: 작은 → 큰
- 작은 변경 먼저 머지
- 큰 변경 task가 conflict 해결 책임자
- 의존성 (A가 모델 추가 → B가 호출) 있으면 dependency 먼저

### Rule 4 — 같은 라인 충돌 시 git conflict marker로 명시 해결
- "미루기" (1-task primary 정책) 금지 — 누락 위험
- conflict marker 보이면 5초~1분 작업으로 통합
- `git rerere` 활성화 시 반복 패턴 자동 적용

## Setup (한 번만)

```bash
# 반복 충돌 패턴 자동 기억 + 재적용
git config rerere.enabled true
```

TODO/CHANGELOG 처럼 같은 파일의 같은 위치를 반복 수정하는 레포에서 효과가 크다.

## Task 시작 전 체크리스트

1. **활성 worktree 확인**:
   ```bash
   git worktree list
   ```

2. **다른 active job 영역 확인**:
   ```bash
   jobs_root="${CLAUDE_JOB_DIR:+$(dirname "$CLAUDE_JOB_DIR")}"
   jobs_root="${jobs_root:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/jobs}"
   for state in "$jobs_root"/*/state.json; do
     [[ "${state%/state.json}" == "$CLAUDE_JOB_DIR" ]] && continue
     [[ -f "$state" ]] || continue
     active=$(jq -r '.state' "$state" 2>/dev/null)
     [[ "$active" == "done" ]] && continue
     intent=$(jq -r '.intent // .name' "$state" 2>/dev/null)
     echo "[active] $(dirname "$state" | xargs basename): $intent"
   done
   ```

3. **겹치는 task면 직렬화**: 해당 task 머지 완료 후 진입

## 머지 시점 체크리스트

1. `git pull --rebase origin "$(git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||')"` (다른 task 변경분 먼저 가져오기 — 기본 브랜치 자동 감지)
2. conflict 발생 시:
   - 같은 섹션/라인 → 명시 통합 (양쪽 살림)
   - rerere 활성화면 → 같은 패턴 자동 적용
3. VERSION bump 결정 (이번 task가 minor/patch 자격인지)
4. CHANGELOG entry 시간순 최상단 추가
5. `git push origin main`

## 트러블슈팅

### "EnterWorktree first" 에러
백그라운드 job 환경에서 첫 파일 변경 시 자동 차단. 다음 중 하나:
- `EnterWorktree` 호출 후 작업 (안전)
- 단순 작업이면 포그라운드 대화로 전환 (worktree 강제 안 됨)

### worktree 머지 안 됨 (fast-forward 불가)
worktree branch가 main의 부분 집합인 경우 (worktree에 main이 모르는 commit X) → no-op. uncommitted 변경 가져오려면 먼저 worktree에서 commit 필요.

### worktree에 commit 있는데 ExitWorktree action: remove 거부
안전 가드. 두 가지 선택:
- `action: keep` → main 복귀 + cherry-pick으로 commit 가져오기 → 그 후 worktree remove
- `discard_changes: true` 명시 (작업 손실, 신중하게)

## 사용자 슬래시 호출

`/multi-worktree-safety` — 트리거 키워드 없이도 본문 강제 로드.
