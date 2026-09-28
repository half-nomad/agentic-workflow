#!/bin/bash
# maestro-guard.sh
# PreToolUse hook: Block Write/Edit in maestro mode
# Input: JSON on stdin from Claude Code
# Block: exit 2 + stderr message | Allow: exit 0

INPUT=$(cat)
if [ -z "$INPUT" ]; then exit 0; fi

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

# Lexically resolve `.` and `..` segments without touching the filesystem.
normalize_path() {
    local p="$1" abs=0 part result
    local -a stack=()
    [[ "$p" == /* ]] && abs=1
    local oldIFS="$IFS"
    IFS='/'
    for part in $p; do
        case "$part" in
            ''|.) ;;
            # Pop with unset, not a slice: macOS /bin/bash 3.2 joins the elements of
            # "${stack[@]:0:n}" with spaces while IFS='/', so `/a/b/.agentic/../x` came
            # out as `/a b/x`, read as outside the project, and was waved through.
            ..) [ ${#stack[@]} -gt 0 ] && unset "stack[$((${#stack[@]}-1))]" ;;
            *) stack+=("$part") ;;
        esac
    done
    IFS="$oldIFS"
    if [ ${#stack[@]} -eq 0 ]; then
        result=""
    else
        result=$(printf '%s/' "${stack[@]}")
        result="${result%/}"
    fi
    [ "$abs" -eq 1 ] && result="/$result"
    printf '%s' "$result"
}

# Maestro state is per session: `.agentic/maestro/<session id>.state`.
# A single project-wide file leaked the guard into every session of the project
# when a run died without cleanup (2026-09-09: usage limit hit mid-run), and
# concurrent runs overwrote and deleted each other's file.
# Same block in maestro-compact-reload.sh / verify-prompt.sh — keep them in sync.
maestro_active() {
    local dir="${CLAUDE_PROJECT_DIR:-.}/.agentic/maestro" sid="${CLAUDE_CODE_SESSION_ID:-}"
    [ -z "$sid" ] && sid=$(json_get "$INPUT" ".session_id")
    # Only a plain id may become a path segment; anything else counts as unknown.
    [[ "$sid" =~ ^[A-Za-z0-9_-]+$ ]] || sid=""
    # A run that could not learn its id writes unknown.state — it guards every session.
    [ -f "$dir/unknown.state" ] && return 0
    if [ -n "$sid" ]; then
        [ -f "$dir/$sid.state" ]
    else
        # Id unknown here: fall back to the old project-wide behavior (fail closed).
        compgen -G "$dir/*.state" >/dev/null
    fi
}

if maestro_active; then
    TOOL_NAME=$(json_get "$INPUT" ".tool_name")

    if [[ "$TOOL_NAME" =~ ^(Write|Edit|MultiEdit)$ ]]; then
        # Subagent bypass: Task-delegated calls include `agent_id` in stdin JSON;
        # the main orchestrator does not. Maestro blocks the orchestrator's
        # direct writes but lets delegated sub-agents execute.
        AGENT_ID=$(json_get "$INPUT" ".agent_id")
        [ -n "$AGENT_ID" ] && exit 0

        FILE_PATH=$(json_get "$INPUT" ".tool_input.file_path")
        # Collapse `.` / `..` BEFORE whitelist matching. The patterns below are
        # substring matches, so an un-normalized path like
        # `<repo>/.agentic/../rules/maestro-workflow.md` would satisfy the
        # `.agentic/` rule while actually resolving outside the whitelist.
        # Lexical (not realpath) so it also works for files that don't exist yet.
        FILE_PATH=$(normalize_path "$FILE_PATH")

        # Scope by target. This guard exists to stop the orchestrator from
        # writing code in THIS project. A target outside the project dir belongs
        # to another repo or to global config, and that is not what maestro mode
        # enforces — one session's mode must not gate another repo's work
        # (2026-08-13: a session editing agentic-workflow was blocked by an
        # unrelated maestro run in the current project).
        #
        # Fail closed: if the project root can't be established, no exemption.
        # `${CLAUDE_PROJECT_DIR:-.}` would be wrong here — normalize_path folds
        # "." to the empty string, every absolute path would read as "outside",
        # and the guard would switch itself off. Relative targets skip the
        # exemption too: they can't be compared against an absolute root.
        PROJECT_ROOT=$(normalize_path "${CLAUDE_PROJECT_DIR:-$PWD}")
        if [ -n "$PROJECT_ROOT" ] && [ "${FILE_PATH#/}" != "$FILE_PATH" ]; then
            case "$FILE_PATH" in
                "$PROJECT_ROOT"/*) ;;
                *) exit 0 ;;
            esac
        fi

        # Allow MEMORY.md edits
        [[ "$FILE_PATH" =~ (^|/)MEMORY\.md$ ]] && exit 0
        # Allow memory/*.md siblings (project/feedback/user/reference)
        [[ "$FILE_PATH" =~ /memory/.+\.md$ ]] && exit 0
        # Allow .agentic/ edits
        [[ "$FILE_PATH" =~ \.agentic[/] ]] && exit 0
        # Allow plan files
        # Allow Plan Mode system plan files (~/.claude/plans/*.md)
        [[ "$FILE_PATH" =~ \.claude/plans/.+\.md$ ]] && exit 0
        [[ "$FILE_PATH" =~ \.plan\.md$ ]] && exit 0
        # Allow workflow meta files (TODO/CHANGELOG/VERSION) — orchestrator manages these directly
        [[ "$FILE_PATH" =~ (^|/)TODO\.md$ ]] && exit 0
        [[ "$FILE_PATH" =~ (^|/)CHANGELOG(\.archive)?\.md$ ]] && exit 0
        [[ "$FILE_PATH" =~ (^|/)VERSION$ ]] && exit 0

        echo "[MAESTRO GUARD] Orchestrator mode active for this session (.agentic/maestro/). Delegate file modifications to agents via Agent tool. If this session is not running /maestro, the state file is a leftover — tell the user." >&2
        exit 2
    fi
fi

exit 0
