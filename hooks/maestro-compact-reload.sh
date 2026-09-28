#!/bin/bash
# maestro-compact-reload.sh
# PostCompact hook: maestro 모드에서 compact 발생 시 SKILL.md·WORKFLOW.md 재읽기 지시를 재주입
#
# 왜 필요한가: v5.5.0 부터 상주 룰이 없다. 절대 규칙 넷은 skills/maestro/SKILL.md 맨 위에,
# 판정 기준·절차·출력 계약·검증 규약의 정본은 skills/maestro/WORKFLOW.md 에 있고 둘 다 대화에
# 실려 있어 요약 과정에서 소실된다(Claude Code 는 호출된 스킬을 다시 붙이지만 스킬마다 앞
# 5,000 토큰까지다). 요약 잔재가 남으면 오히려 "이미 읽었다"는 오판을 유도하므로, 재읽기를
# 모델 판단이 아닌 기계적 재주입으로 보장한다.
#
# 이 훅이 상주 룰 없이 가게 해주는 장치다 — 여기가 죽으면 compact 후 워크플로가 요약 잔재만
# 남은 채 진행된다. 수정 시 그 점을 고려할 것.
#
# Non-blocking: always exit 0

INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

# JSON parser: jq preferred, python3 fallback (macOS ships with python3)
json_get() {
    local json="$1" key="$2"
    if command -v jq &>/dev/null; then
        echo "$json" | jq -r "$key // empty" 2>/dev/null
    else
        echo "$json" | python3 -c "
import sys, json, functools, operator
d = json.load(sys.stdin)
keys = '$key'.strip('.').split('.')
try:
    val = functools.reduce(operator.getitem, keys, d)
    print(val if val is not None else '')
except (KeyError, TypeError):
    print('')
" 2>/dev/null
    fi
}

# 세션별 상태 파일 — 근거는 maestro-guard.sh 의 같은 블록. 세 훅이 같은 판정을 쓴다.
maestro_active() {
    local dir="${CLAUDE_PROJECT_DIR:-.}/.agentic/maestro" sid="${CLAUDE_CODE_SESSION_ID:-}"
    [ -z "$sid" ] && sid=$(json_get "$INPUT" ".session_id")
    [[ "$sid" =~ ^[A-Za-z0-9_-]+$ ]] || sid=""
    [ -f "$dir/unknown.state" ] && return 0
    if [ -n "$sid" ]; then
        [ -f "$dir/$sid.state" ]
    else
        compgen -G "$dir/*.state" >/dev/null
    fi
}

maestro_active || exit 0   # 이 세션이 maestro 가 아니면 조용히 통과

WORKFLOW="$HOME/.claude/skills/maestro/WORKFLOW.md"
[ -f "$WORKFLOW" ] || exit 0

# additionalContext 로 모델 컨텍스트에 재주입 (JSON 문자열 이스케이프 불요 — 고정 문구)
cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PostCompact",
    "additionalContext": "[maestro] 컨텍스트가 요약됐다. 진행 중인 오케스트레이션의 절대 규칙(~/.claude/skills/maestro/SKILL.md 맨 위)과 판정 기준·절차·출력 계약·검증 규약(~/.claude/skills/maestro/WORKFLOW.md)이 요약 과정에서 소실됐거나 잘렸을 수 있다 — 시스템 프롬프트에 상주하는 마에스트로 룰은 없다. 다음 행동 전에 SKILL.md 와 WORKFLOW.md 를 Read 로 다시 읽어라 — 요약본에 관련 내용이 남아 있어 보여도 원문이 아니고 로드 증거도 아니다."
  }
}
JSON

exit 0
