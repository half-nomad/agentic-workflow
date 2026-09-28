#!/bin/bash
# tests/hooktest.sh <hooks-dir> [sh|ps1] — maestro 훅의 세션 판정 동작 표
#   bash tests/hooktest.sh hooks            # 레포 루트에서, 두 판 모두 (ps1 은 pwsh 필요)
# 세 훅(guard · compact-reload · verify-prompt) × sh/ps1 를 임시 디렉터리의 가짜 프로젝트·가짜 홈에서 돌린다.
# 실제 $HOME·프로젝트는 건드리지 않는다. 실패가 하나라도 있으면 exit 1.
# 칸을 뺄 땐 무엇을 지키던 칸인지 먼저 본다 — 2026-09-28 변형 검사에서 env/stdin 불일치 칸과
# '/' 없는 이상한 id 칸이 없어 변형 12개가 살아남았고, 그 뒤 추가됐다.
set -u
HOOKS="$(cd "$1" && pwd)"
ONLY="${2:-}"          # sh | ps1 | (비우면 둘 다)
T=$(mktemp -d)
P="$T/proj"; FH="$T/home"; OUT="$T/other"
mkdir -p "$P" "$FH/.claude/skills/maestro" "$OUT"
echo "# wf" > "$FH/.claude/skills/maestro/WORKFLOW.md"
git -C "$P" init -q && echo a > "$P/app.rb" && git -C "$P" add app.rb \
  && git -C "$P" -c user.email=t@t -c user.name=t commit -qm init && echo b >> "$P/app.rb"
A=aaaa-1111; B=bbbb-2222
fail=0; n=0

state_reset() { rm -rf "$P/.agentic"; mkdir -p "$P/.agentic/maestro"; }
put() { echo maestro > "$P/.agentic/maestro/$1.state"; }

# run <flavor> <hook> <env-sid|-> <json>  → prints "exit=<code> out=<0|1>"
run() {
  local fl="$1" hook="$2" sid="$3" json="$4" out code
  local -a envs=(env -u CLAUDE_CODE_SESSION_ID CLAUDE_PROJECT_DIR="$P" HOME="$FH" USERPROFILE="$FH")
  [ "$sid" != "-" ] && envs+=(CLAUDE_CODE_SESSION_ID="$sid")
  if [ "$fl" = sh ]; then
    out=$(printf '%s' "$json" | "${envs[@]}" bash "$HOOKS/$hook.sh" 2>/dev/null); code=$?
  else
    out=$(printf '%s' "$json" | "${envs[@]}" pwsh -NoProfile -File "$HOOKS/$hook.ps1" 2>/dev/null); code=$?
  fi
  printf 'exit=%s out=%s' "$code" "$([ -n "$out" ] && echo 1 || echo 0)"
}

# check <label> <flavor> <hook> <env-sid|-> <json-sid|-> <expect: block|pass|emit|silent> [file_path] [extra-json]
check() {
  local label="$1" fl="$2" hook="$3" esid="$4" jsid="$5" expect="$6" fp="${7:-$P/app.rb}" extra="${8:-}"
  local sidfield=""; [ "$jsid" != "-" ] && sidfield=",\"session_id\":\"$jsid\""
  local json
  case "$hook" in
    maestro-guard) json="{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$fp\"}$sidfield$extra}" ;;
    maestro-compact-reload) json="{\"hook_event_name\":\"SessionStart\",\"source\":\"${SRC:-compact}\"$sidfield}" ;;
    verify-prompt) json="{\"tool_name\":\"Agent\",\"hook_event_name\":\"PostToolUse\"$sidfield}" ;;
  esac
  local r; r=$(run "$fl" "$hook" "$esid" "$json")
  local ok=0
  case "$expect" in
    block)  [[ "$r" == exit=2* ]] && ok=1 ;;
    pass)   [[ "$r" == exit=0* ]] && ok=1 ;;
    emit)   [[ "$r" == *out=1 ]] && ok=1 ;;
    silent) [[ "$r" == *out=0 && "$r" == exit=0* ]] && ok=1 ;;
  esac
  n=$((n+1))
  if [ $ok = 1 ]; then printf 'PASS  %-4s %-24s %-44s %s\n' "$fl" "$hook" "$label" "$r"
  else fail=$((fail+1)); printf 'FAIL  %-4s %-24s %-44s %s (want %s)\n' "$fl" "$hook" "$label" "$r" "$expect"; fi
}

# check_msg <flavor> — compact-reload must emit valid JSON for the SessionStart event
# whose additionalContext is a string telling the model to Read both files again.
# Since v5.5.0 the absolute rules live in SKILL.md, not in a resident rule; the cells
# above only see "some output", not what it says. The event name matters: v5.4.0 and
# earlier answered as PostCompact, which cannot add context at all.
check_msg() {
  local fl="$1" out ok=0 label="SessionStart context: Read SKILL.md + WORKFLOW.md"
  local json="{\"hook_event_name\":\"SessionStart\",\"source\":\"compact\",\"session_id\":\"$A\"}"
  local -a envs=(env CLAUDE_PROJECT_DIR="$P" HOME="$FH" USERPROFILE="$FH" CLAUDE_CODE_SESSION_ID="$A")
  if [ "$fl" = sh ]; then
    out=$(printf '%s' "$json" | "${envs[@]}" bash "$HOOKS/maestro-compact-reload.sh" 2>/dev/null)
  else
    out=$(printf '%s' "$json" | "${envs[@]}" pwsh -NoProfile -File "$HOOKS/maestro-compact-reload.ps1" 2>/dev/null)
  fi
  printf '%s' "$out" | python3 -c 'import json,sys
h=json.load(sys.stdin)["hookSpecificOutput"]; c=h["additionalContext"]
sys.exit(0 if h["hookEventName"] == "SessionStart" and isinstance(c, str)
         and "SKILL.md" in c and "WORKFLOW.md" in c and "Read" in c else 1)' 2>/dev/null && ok=1
  n=$((n+1))
  if [ $ok = 1 ]; then printf 'PASS  %-4s %-24s %s\n' "$fl" maestro-compact-reload "$label"
  else fail=$((fail+1)); printf 'FAIL  %-4s %-24s %s\n' "$fl" maestro-compact-reload "$label"; fi
}

flavors="sh ps1"; [ -n "$ONLY" ] && flavors="$ONLY"
for fl in $flavors; do
  for hook in maestro-guard maestro-compact-reload verify-prompt; do
    on=emit; off=silent
    [ "$hook" = maestro-guard ] && { on=block; off=pass; }

    state_reset;                 check "no state"                          $fl $hook $A $A $off
    state_reset; put $A;         check "own state (env+stdin)"             $fl $hook $A $A $on
    state_reset; put $A;         check "own state (stdin only)"            $fl $hook - $A $on
    state_reset; put $A;         check "own state (env only)"              $fl $hook $A - $on
    state_reset; put $B;         check "other session's state only"        $fl $hook $A $A $off
    state_reset; put $B;         check "other state, sid via stdin only"   $fl $hook - $A $off
    state_reset; put $B;         check "sid unknown + some state"          $fl $hook - - $on
    state_reset;                 check "sid unknown + no state"            $fl $hook - - $off
    state_reset; put unknown;    check "unknown.state (id-less run)"       $fl $hook $A $A $on
    state_reset; echo maestro > "$P/.agentic/maestro-mode.state"
                                 check "legacy file only -> ignored"       $fl $hook $A $A $off
    state_reset; put $A;         check "sid with path chars -> unknown"    $fl $hook "../x" "../x" $on
    state_reset;                 check "sid with path chars, no state"     $fl $hook "../x" "../x" $off
    # trailing newline must not pass the id check (.NET '$' matches before a final \n)
    state_reset; put $B;         check "sid with trailing newline -> unknown" $fl $hook $'absent-1\n' - $on
    # a dot is outside the whitelist even without '/' -> unknown -> any state counts
    state_reset; put $A;         check "sid with dot -> unknown"           $fl $hook "a.b" "a.b" $on
    # env wins over stdin when they disagree
    state_reset; put $A;         check "env=A stdin=B, A.state -> on"      $fl $hook $A $B $on
    state_reset; put $A;         check "env=B stdin=A, A.state -> off"     $fl $hook $B $A $off
    # concurrency: A and B both in maestro, then A finishes
    state_reset; put $A; put $B; check "A+B running: A"                    $fl $hook $A $A $on
                                 check "A+B running: B"                    $fl $hook $B $B $on
    rm -f "$P/.agentic/maestro/$A.state"
                                 check "A finished: A"                     $fl $hook $A $A $off
                                 check "A finished: B still on"            $fl $hook $B $B $on
  done
  # guard regressions (own state present)
  state_reset; put $A
  check "subagent (agent_id) passes"     $fl maestro-guard $A $A pass "$P/app.rb" ',"agent_id":"sub1"'
  check "whitelist .agentic/ passes"     $fl maestro-guard $A $A pass "$P/.agentic/note.md"
  check "whitelist TODO.md passes"       $fl maestro-guard $A $A pass "$P/TODO.md"
  check "outside project passes"         $fl maestro-guard $A $A pass "$OUT/x.rb"
  check "dotdot escape still blocked"    $fl maestro-guard $A $A block "$P/.agentic/../app.rb"
  # compact-reload answers only a compaction, even when registered without a matcher
  SRC=startup check "SessionStart startup -> silent" $fl maestro-compact-reload $A $A silent
  check_msg $fl
done

rm -rf "$T"
echo "---- $((n-fail))/$n passed"
[ $fail = 0 ]
