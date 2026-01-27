#!/bin/bash
# Boulder Manager Hook
# Manages session state persistence via .agentic/boulder.json

ACTION="${1:-load}"
STATE_DIR=".agentic"
BOULDER_PATH="$STATE_DIR/boulder.json"

initialize_state_dir() {
    if [ ! -d "$STATE_DIR" ]; then
        mkdir -p "$STATE_DIR"
    fi
}

load_boulder() {
    if [ -f "$BOULDER_PATH" ]; then
        status=$(jq -r '.plan.status // empty' "$BOULDER_PATH" 2>/dev/null)

        if [ "$status" = "in_progress" ]; then
            name=$(jq -r '.plan.name // "Unknown"' "$BOULDER_PATH")
            pattern=$(jq -r '.plan.pattern // "Unknown"' "$BOULDER_PATH")
            current_step=$(jq -r '.plan.current_step // 1' "$BOULDER_PATH")
            updated_at=$(jq -r '.updated_at // "Unknown"' "$BOULDER_PATH")

            steps=$(jq -r '.plan.steps[] | "  [\(if .status == "completed" then "OK" elif .status == "in_progress" then ">>" else "  " end)] Step \(.id): \(.desc)"' "$BOULDER_PATH" 2>/dev/null)

            cat << EOF
[PLAN RECOVERY] 이전 세션의 계획이 발견되었습니다.

계획: $name
패턴: $pattern
상태: $status
현재 단계: Step $current_step
마지막 업데이트: $updated_at

진행 상황:
$steps

계속하려면 "계속" 또는 "continue", 새로 시작하려면 "새로 시작" 또는 "new"
EOF
        fi
    fi
}

save_boulder() {
    initialize_state_dir

    if [ -n "$BOULDER_DATA" ]; then
        updated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "$BOULDER_DATA" | jq --arg ts "$updated_at" '.updated_at = $ts' > "$BOULDER_PATH"
    fi
}

clear_boulder() {
    if [ -f "$BOULDER_PATH" ]; then
        rm -f "$BOULDER_PATH"
        echo "[PLAN CLEARED] 이전 계획이 삭제되었습니다. 새로운 계획을 시작합니다."
    fi
}

case "$ACTION" in
    load) load_boulder ;;
    save) save_boulder ;;
    clear) clear_boulder ;;
    *) echo "Unknown action: $ACTION" ;;
esac
