#!/bin/bash
#
# Agentic Workflow installer (Linux / macOS / WSL)
#
# Symlinks this repo into ~/.claude (and ~/.codex). Nothing is copied, so
# `git pull` is the update: the deployed config IS the repo working tree.
#
# Granularity is a safety property, not a style choice:
#   agents/ rules/ hooks/  -> per FILE  (your own files live in those dirs)
#   skills/<name>/         -> per DIR   (each shipped skill dir is wholly ours)
# A directory symlink over ~/.claude/rules would erase rules/personal.md.
#
# settings.json is never touched — see the reminder printed at the end.
#
# Usage: ./install.sh
#

set -euo pipefail

# Canonical, because uninstall recognises its own links by "target starts with
# $REPO/". A non-canonical path here makes that prefix match fail silently later.
REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

CLAUDE_HOME="$HOME/.claude"
CODEX_HOME="$HOME/.codex"
BACKUP_ROOT="$CLAUDE_HOME/.maestro-backup-$(date +%Y%m%d-%H%M%S)"

BEGIN_MARK='<!-- BEGIN agentic-workflow -->'
END_MARK='<!-- END agentic-workflow -->'

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# --- CLAUDE.md ownership guard ----------------------------------------------
# Older installs merged only the text between the markers and told users their
# own instructions could live outside the block. A whole-file symlink silently
# breaks that promise, and a backup nobody reads is a silent loss — so refuse.
guard_claude_md() {
    local dest="$CLAUDE_HOME/CLAUDE.md" src="$REPO/CLAUDE.md" leftover

    # A symlink is already ours (or the user's own choice); nothing to protect.
    if [ -L "$dest" ] || [ ! -f "$dest" ]; then return 0; fi

    if grep -qxF "$BEGIN_MARK" "$dest" && grep -qxF "$END_MARK" "$dest"; then
        leftover="$(awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
            $0 == b { inb = 1; next }
            $0 == e { inb = 0; next }
            inb     { next }
                    { print }' "$dest")"
    else
        # No marker pair. The file is unmanaged unless it is byte-identical to
        # what we ship (i.e. an old whole-file install nobody edited).
        if [ -f "$src" ] && cmp -s "$dest" "$src"; then return 0; fi
        leftover="$(cat "$dest")"
    fi

    if printf '%s' "$leftover" | grep -q '[^[:space:]]'; then
        cat >&2 <<EOF
ERROR: ~/.claude/CLAUDE.md holds instructions this installer would hide.

  install.sh replaces ~/.claude/CLAUDE.md with a symlink to
      $src
  so anything you wrote in that file would stop being read — and a backup you
  never open is the same as losing it.

  Move your own instructions to
      ~/.claude/rules/personal.md
  which is user-owned: this repo never ships, overwrites or removes it, and it
  is loaded in every project just like CLAUDE.md. Then re-run ./install.sh.

  Nothing has been changed.
EOF
        exit 1
    fi
}

# --- linking -----------------------------------------------------------------
BACKED_UP_FROM=""
BACKED_UP_TO=""

# Move a real file/dir aside, keeping its path under a timestamped backup root.
# Loud on purpose: a silent backup is indistinguishable from data loss.
backup() {
    local path="$1" rel dest
    rel="${path#"$HOME"/}"
    dest="$BACKUP_ROOT/$rel"
    mkdir -p "$(dirname "$dest")"
    mv "$path" "$dest" || die "could not move $path aside; nothing else was changed"
    BACKED_UP_FROM="$path"
    BACKED_UP_TO="$dest"
    printf '\n  *** BACKED UP: %s\n  ***       -> %s\n\n' "$path" "$dest"
}

link() {
    local src="$1" dest="$2"
    BACKED_UP_FROM=""
    BACKED_UP_TO=""

    if [ -L "$dest" ]; then
        # Already correct -> free and silent. This is what makes re-running
        # install after `git pull` a no-op.
        if [ "$(readlink "$dest")" = "$src" ]; then return 0; fi
        rm "$dest"
    elif [ -e "$dest" ]; then
        backup "$dest"
    fi

    mkdir -p "$(dirname "$dest")"
    # `ln -s`, never `ln -sf`: -sf onto an existing symlink-to-directory creates
    # the new link INSIDE that directory instead of replacing it, and skills/
    # deploys directory links. The explicit rm above is the replacement path.
    if ! ln -s "$src" "$dest"; then
        if [ -n "$BACKED_UP_TO" ] && mv "$BACKED_UP_TO" "$BACKED_UP_FROM"; then
            printf '  RESTORED: %s\n' "$BACKED_UP_FROM" >&2
        fi
        die "failed to link $dest -> $src"
    fi
    printf '  linked %s\n' "${dest#"$HOME"/}"
}

# With per-file links, a file deleted or renamed upstream leaves a link pointing
# at nothing. In rules/ that means a rule silently stops loading; in hooks/ every
# matching tool call errors. `git pull` cannot fix it — re-running install can,
# which is why install is part of the documented update path.
sweep_dangling() {
    local root="$1" depth="$2" l
    [ -d "$root" ] || return 0
    while IFS= read -r l; do
        case "$(readlink "$l")" in
            "$REPO"/*)
                if [ ! -e "$l" ]; then
                    rm "$l"
                    printf '  removed dangling %s (upstream file is gone)\n' "${l#"$HOME"/}"
                fi
                ;;
        esac
    done < <(find "$root" -maxdepth "$depth" -type l)
}

# --- run ---------------------------------------------------------------------
echo ""
echo "agentic-workflow installer"
echo "  repo: $REPO"
echo "  into: $CLAUDE_HOME"
echo ""

guard_claude_md

mkdir -p "$CLAUDE_HOME/agents" "$CLAUDE_HOME/rules" "$CLAUDE_HOME/hooks" "$CLAUDE_HOME/skills"

if [ -f "$REPO/CLAUDE.md" ]; then
    link "$REPO/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
fi

for d in agents rules hooks; do
    [ -d "$REPO/$d" ] || continue
    for f in "$REPO/$d"/*; do
        [ -f "$f" ] || continue
        link "$f" "$CLAUDE_HOME/$d/$(basename "$f")"
    done
done

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
