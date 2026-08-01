#!/bin/bash
#
# Agentic Workflow uninstaller (Linux / macOS / WSL)
#
# Removes only symlinks whose target lives inside this repo. That is a
# structural guarantee, not carefulness: a real file fails `-type l`, and a link
# pointing anywhere else fails the prefix match — so your own rules, hooks,
# agents and skills sitting in the same directories cannot be deleted here.
#
# Usage: ./uninstall.sh
#

set -euo pipefail

# Captured through a sentinel rather than a bare `$(pwd -P)`: command
# substitution strips trailing newlines, so a checkout whose path ends in one
# would silently collapse to a *different, real* path — and this script would
# then match, and delete, links belonging to that other directory. Same reason
# `dirname` is done with parameter expansion instead of the external command.
_src="${BASH_SOURCE[0]}"
_dir="${_src%/*}"
if [ "$_dir" = "$_src" ]; then _dir="."; fi
REPO="$(cd -P -- "$_dir" && printf '%sX' "$PWD")"
REPO="${REPO%X}"
unset _src _dir
n=0

echo ""
echo "agentic-workflow uninstaller"
echo "  removing links into: $REPO"
echo ""

for root in "$HOME/.claude" "$HOME/.codex"; do
    [ -d "$root" ] || continue
    while IFS= read -r l; do
        # readlink + case, not `find -lname`: -lname is absent on older BSD and
        # busybox find, and it matches the literal link text rather than a
        # resolved path. This repo runs on machines we cannot measure.
        case "$(readlink "$l")" in
            "$REPO"/*) rm "$l"; echo "  removed ${l#"$HOME"/}"; n=$((n+1)) ;;
        esac
        # -mindepth 1: without it, a ~/.claude that is itself a symlink into
        # the repo is reported by find as its own match, and the rm above would
        # delete the user's entire config directory link.
    done < <(find "$root" -mindepth 1 -maxdepth 2 -type l)
done

echo ""
if [ "$n" -eq 0 ]; then
    cat >&2 <<EOF
WARNING: nothing was removed.

  Links are matched by the repo path recorded in them, which is
      $REPO
  If the repo was moved or renamed after install, the existing links still
  point at the old location and no longer match. Either:
    - re-run ./install.sh from this path first (which relinks everything),
      then run ./uninstall.sh again, or
    - delete the links by hand:
        find ~/.claude ~/.codex -maxdepth 2 -type l -exec ls -l {} +
EOF
else
    echo "$n link(s) removed. Your own files were untouched."
fi

cat <<'EOF'

Left in place, on purpose:
  ~/.claude/.maestro-backup-*   files install displaced, if any. Review, then
                                delete them yourself.
  ~/.claude/settings.json       never written by any script here. Remove this
                                repo's hook entries by hand — see the uninstall
                                snippet in the project README. Leaving them
                                behind makes every matching tool call error,
                                because the hook scripts are now gone.
  ~/.claude/rules/*             everything except maestro-workflow.md is yours.
                                install places that one file and nothing else,
                                so the rest was never installed and is never
                                removed.
EOF
echo ""
