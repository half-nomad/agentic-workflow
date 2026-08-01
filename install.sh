#!/bin/bash
#
# Agentic Workflow installer (Linux / macOS / WSL)
#
# Symlinks this repo into ~/.claude (and ~/.codex). Nothing is copied, so
# `git pull` is the update: the deployed config IS the repo working tree.
#
# Granularity is a safety property, not a style choice:
#   agents/ hooks/         -> per FILE  (your own files live in those dirs)
#   rules/                 -> ALLOWLIST (maestro-workflow.md only; the rest of
#                             ~/.claude/rules/ is yours and we never claim it)
#   skills/<name>/         -> per DIR   (each shipped skill dir is wholly ours)
# A directory symlink over ~/.claude/rules or ~/.claude/hooks would erase the
# files you keep there.
#
# settings.json is never touched — see the reminder printed at the end.
#
# Usage: ./install.sh
#

set -euo pipefail

# Canonical, because uninstall recognises its own links by "target starts with
# $REPO/". A non-canonical path here makes that prefix match fail silently later.
#
# Captured through a sentinel rather than a bare `$(pwd -P)`: command
# substitution strips trailing newlines, so a checkout whose path ends in one
# would collapse to a *different, real* path — and uninstall would then match
# links belonging to that other directory. Same reason `dirname` is done with
# parameter expansion instead of the external command.
_src="${BASH_SOURCE[0]}"
_dir="${_src%/*}"
if [ "$_dir" = "$_src" ]; then _dir="."; fi
REPO="$(cd -P -- "$_dir" && printf '%sX' "$PWD")"
REPO="${REPO%X}"
unset _src _dir

CLAUDE_HOME="$HOME/.claude"
CODEX_HOME="$HOME/.codex"
BACKUP_ROOT="$CLAUDE_HOME/.maestro-backup-$(date +%Y%m%d-%H%M%S)"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# --- linking -----------------------------------------------------------------
BACKED_UP_FROM=""
BACKED_UP_TO=""

# Move a real file/dir/symlink aside, keeping its path under a timestamped
# backup root. Loud on purpose: a silent backup is indistinguishable from data
# loss. `mv` on a symlink renames the link itself, so the link text survives —
# which is the whole point for aliases the user made by hand.
backup() {
    local path="$1" rel dest
    rel="${path#"$HOME"/}"
    dest="$BACKUP_ROOT/$rel"
    mkdir -p "$(dirname "$dest")"
    mv "$path" "$dest" || die "could not move $path aside; that path was left alone, but paths linked earlier in this run have already changed"
    BACKED_UP_FROM="$path"
    BACKED_UP_TO="$dest"
    printf '\n  *** BACKED UP: %s\n  ***       -> %s\n\n' "$path" "$dest"
}

link() {
    local src="$1" dest="$2"
    BACKED_UP_FROM=""
    BACKED_UP_TO=""

    # Already correct -> free and silent. This is what makes re-running install
    # after `git pull` a no-op.
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then return 0; fi

    # Anything else at this path is the user's, symlink included: an alias like
    # ~/.claude/hooks/verify-prompt.sh -> ~/personal/verify.sh is unrecoverable
    # once `rm` takes it, because its only content is the link text. Back it up
    # exactly like a real file. `-L ||` because -e is false for a broken link.
    if [ -L "$dest" ] || [ -e "$dest" ]; then
        backup "$dest"
    fi

    mkdir -p "$(dirname "$dest")"
    # `ln -s`, never `ln -sf`: -sf onto an existing symlink-to-directory creates
    # the new link INSIDE that directory instead of replacing it, and skills/
    # deploys directory links. The backup above is the replacement path.
    if ! ln -s "$src" "$dest"; then
        if [ -n "$BACKED_UP_TO" ]; then
            # Restore only into an empty slot. Blind `mv` back would clobber
            # whatever created $dest in the meantime — losing someone else's
            # file while "recovering" ours.
            if [ ! -e "$BACKED_UP_FROM" ] && [ ! -L "$BACKED_UP_FROM" ]; then
                if mv "$BACKED_UP_TO" "$BACKED_UP_FROM"; then
                    printf '  RESTORED: %s\n' "$BACKED_UP_FROM" >&2
                fi
            else
                printf '  NOT RESTORED: %s exists again; your copy stays at %s\n' \
                    "$BACKED_UP_FROM" "$BACKED_UP_TO" >&2
            fi
        fi
        die "failed to link $dest -> $src"
    fi
    printf '  linked %s\n' "${dest#"$HOME"/}"
}

# With per-file links, a file deleted or renamed upstream leaves a link pointing
# at nothing. In rules/ that means a rule silently stops loading; in hooks/ every
# matching tool call errors. `git pull` cannot fix it — re-running install can,
# which is why install is part of the documented update path.

# The one target this installer would have written at $1 — empty if $1 is not a
# path it deploys to at all. "Points into the repo" is too loose a test: a link
# the user made by hand, say ~/.claude/rules/scratch.md -> $REPO/docs/notes.md,
# also points into the repo and is not ours to delete.
expected_target() {
    local l="$1" rel
    case "$l" in
        "$CODEX_HOME"/AGENTS.md) printf '%s\n' "$REPO/AGENTS.md"; return 0 ;;
        "$CLAUDE_HOME"/*)        rel="${l#"$CLAUDE_HOME"/}" ;;
        *)                       return 0 ;;
    esac
    case "$rel" in
        */*/*)                              return 0 ;;  # deeper than we deploy
        CLAUDE.md)                          printf '%s\n' "$REPO/CLAUDE.md" ;;
        agents/*|rules/*|hooks/*|skills/*)  printf '%s\n' "$REPO/$rel" ;;
    esac
}

sweep_dangling() {
    local root="$1" depth="$2" l want
    [ -d "$root" ] || return 0
    # -mindepth 1: without it, find reports $root itself when ~/.claude is a
    # symlink, and the rm below would take out the user's whole config dir.
    while IFS= read -r l; do
        want="$(expected_target "$l")"
        [ -n "$want" ] || continue
        if [ "$(readlink "$l")" = "$want" ] && [ ! -e "$l" ]; then
            rm "$l"
            printf '  removed dangling %s (upstream file is gone)\n' "${l#"$HOME"/}"
        fi
    done < <(find "$root" -mindepth 1 -maxdepth "$depth" -type l)
}

# --- run ---------------------------------------------------------------------
echo ""
echo "agentic-workflow installer"
echo "  repo: $REPO"
echo "  into: $CLAUDE_HOME"
echo ""

mkdir -p "$CLAUDE_HOME/agents" "$CLAUDE_HOME/rules" "$CLAUDE_HOME/hooks" "$CLAUDE_HOME/skills"

if [ -f "$REPO/CLAUDE.md" ]; then
    # Displaced like any other path — but this is the one whose disappearance
    # sends people looking, so name its replacement instead of leaving them to
    # infer it from a backup path. Only when real content actually moved: -f is
    # false for an absent file and for a dangling link, and an idempotent
    # re-install backs nothing up.
    claude_md_had_file=""
    [ -f "$CLAUDE_HOME/CLAUDE.md" ] && claude_md_had_file=1
    link "$REPO/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
    if [ -n "$claude_md_had_file" ] && [ -n "$BACKED_UP_TO" ]; then
        cat <<'EOF'
  NOTE: ~/.claude/CLAUDE.md is now a link into this repo. Put your own global
        instructions in any file under ~/.claude/rules/ — this installer places
        exactly one rule file (maestro-workflow.md) and never touches the rest.
        Files there load exactly like CLAUDE.md does.

EOF
    fi
fi

for d in agents hooks; do
    [ -d "$REPO/$d" ] || continue
    for f in "$REPO/$d"/*; do
        [ -f "$f" ] || continue
        link "$f" "$CLAUDE_HOME/$d/$(basename "$f")"
    done
done

# rules/ is an ALLOWLIST, not a glob — deliberately asymmetric with the loops
# above and below. The contract is that install places exactly one rule file and
# that every other file in ~/.claude/rules/ belongs to you: your own global.md,
# secure-coding.md, personal.md and so on live there and this repo must never
# claim them. A glob would mean that adding a same-named rule upstream displaces
# your file on the next reinstall (loudly backed up, but displaced all the same).
# Adding a rule here is a deliberate act; make it one.
for f in maestro-workflow.md; do
    [ -f "$REPO/rules/$f" ] || continue
    link "$REPO/rules/$f" "$CLAUDE_HOME/rules/$f"
done

# skills/ stays a glob: unlike rules/, whatever sits in this repo's skills/ is
# wholly ours by definition, and a name collision with one of your own skills is
# reported loudly by link() before anything moves.
if [ -d "$REPO/skills" ]; then
    for s in "$REPO"/skills/*/; do
        s="${s%/}"
        [ -d "$s" ] || continue
        link "$s" "$CLAUDE_HOME/skills/$(basename "$s")"
    done
fi

# Codex reads the same config through AGENTS.md. Only if it is already set up —
# creating ~/.codex for someone who does not use Codex is not our business.
if [ -f "$REPO/AGENTS.md" ]; then
    if [ -d "$CODEX_HOME" ]; then
        link "$REPO/AGENTS.md" "$CODEX_HOME/AGENTS.md"
    else
        echo "  skipped ~/.codex/AGENTS.md (no ~/.codex — Codex not installed)"
    fi
fi

sweep_dangling "$CLAUDE_HOME" 2
sweep_dangling "$CODEX_HOME" 1

if [ -d "$BACKUP_ROOT" ]; then
    echo ""
    echo "  displaced files were moved to: $BACKUP_ROOT"
fi

cat <<'EOF'

Done. Restart Claude Code to pick up the changes.

ONE-TIME STEP — hooks are not registered automatically.
  settings.json is yours: it holds personal keys and interleaves your own
  security hooks with this repo's, so no script writes to it. Copy the
  "hooks" block from the project README into ~/.claude/settings.json once.
  Nothing else about it ever needs to change.

To update:
  git -C REPO_PATH pull && REPO_PATH/install.sh
  (pull alone is not enough: new files have no link yet, and files removed
   upstream leave dangling links. Re-running install fixes both, and is a
   silent no-op for everything already correct.)

To remove:
  REPO_PATH/uninstall.sh
EOF
echo ""
echo "  (REPO_PATH = $REPO)"
echo ""
