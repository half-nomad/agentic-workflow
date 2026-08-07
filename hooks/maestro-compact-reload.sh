#!/bin/bash
# maestro-compact-reload.sh
# PostCompact hook: maestro 모드에서 compact 발생 시 WORKFLOW.md 재읽기 지시를 재주입
#
# 왜 필요한가: 상주분(rules/maestro-workflow.md)은 활성화 조건과 절대 규칙 4개뿐인 스텁이다.
# 판정 기준·절차·출력 계약·검증 규약의 정본은 skills/maestro/WORKFLOW.md 이고 대화에 실려
# 있어 요약 과정에서 소실된다. 요약 잔재가 남으면 오히려 "이미 읽었다"는 오판을 유도하므로,
# 재읽기를 모델 판단이 아닌 기계적 재주입으로 보장한다.
#
# 이 훅이 상주분을 스텁으로 줄일 수 있게 해주는 장치다 — 여기가 죽으면 compact 후 워크플로가
# 절대 규칙만 남은 채 진행된다. 수정 시 그 점을 고려할 것.
#
# Non-blocking: always exit 0

INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.agentic/maestro-mode.state"
[ -f "$STATE_FILE" ] || exit 0   # maestro 모드가 아니면 조용히 통과

WORKFLOW="$HOME/.claude/skills/maestro/WORKFLOW.md"
[ -f "$WORKFLOW" ] || exit 0

# additionalContext 로 모델 컨텍스트에 재주입 (JSON 문자열 이스케이프 불요 — 고정 문구)
cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PostCompact",
    "additionalContext": "[maestro] 컨텍스트가 요약됐다. 진행 중인 오케스트레이션의 판정 기준·절차·출력 계약·검증 규약(~/.claude/skills/maestro/WORKFLOW.md)이 요약 과정에서 소실됐을 수 있다. 시스템 프롬프트에 남아 있는 것은 활성화 조건과 절대 규칙 4개뿐인 상주 스텁이므로, 그것만으로 진행하지 말 것. 다음 행동 전에 WORKFLOW.md 를 Read 로 다시 읽어라 — 요약본에 관련 내용이 남아 있어 보여도 원문이 아니고 로드 증거도 아니다."
  }
}
JSON

exit 0
