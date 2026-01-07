#!/bin/bash
# Context Window Monitor Hook
# Monitors context usage and warns when approaching limits

CURRENT_TOKENS="${CURRENT_TOKENS:-0}"
MAX_TOKENS="${MAX_TOKENS:-200000}"

# Calculate usage percentage
if [ "$MAX_TOKENS" -gt 0 ]; then
    # Bash integer arithmetic with rounding
    USAGE_PERCENT=$(( (CURRENT_TOKENS * 1000 / MAX_TOKENS + 5) / 10 ))
else
    USAGE_PERCENT=0
fi

if [ "$USAGE_PERCENT" -ge 85 ]; then
    cat << EOF
[CONTEXT WARNING] Usage at ${USAGE_PERCENT}%

CRITICAL: Context window nearly full!
- Consider summarizing completed work
- Remove unnecessary context
- Focus on essential information only
EOF
elif [ "$USAGE_PERCENT" -ge 70 ]; then
    cat << EOF
[CONTEXT NOTICE] Usage at ${USAGE_PERCENT}%

Context window at 70%+. You still have room to work.
- Don't rush or cut corners
- Complete current tasks properly
- Monitor for 85% threshold
EOF
fi

exit 0
