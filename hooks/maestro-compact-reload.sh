#!/bin/bash
# maestro-compact-reload.sh
# PostCompact hook: maestro 모드에서 compact 발생 시 WORKFLOW.md 재읽기 지시를 재주입
#
# 왜 필요한가: 구속 룰(rules/maestro-workflow.md)은 시스템 프롬프트라 compact 후에도 살아남지만,
# 절차·템플릿(skills/maestro/WORKFLOW.md)은 대화에 실려 있어 요약 과정에서 소실될 수 있다.
# 요약 잔재가 남으면 오히려 "이미 읽었다"는 오판을 유도하므로, 재읽기를 모델 판단이 아닌
# 기계적 재주입으로 보장한다.
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
    "additionalContext": "[maestro] 컨텍스트가 요약됐다. 진행 중인 오케스트레이션의 절차·템플릿(~/.claude/skills/maestro/WORKFLOW.md)이 요약 과정에서 소실됐을 수 있다. 다음 행동 전에 그 파일을 Read 로 다시 읽어라 — 요약본에 관련 내용이 남아 있어 보여도 원문이 아니므로 재읽기를 건너뛰지 말 것. 구속 룰(가드·Hard rule·출력 계약)은 rules/maestro-workflow.md 에 그대로 살아 있다."
  }
}
JSON

exit 0
