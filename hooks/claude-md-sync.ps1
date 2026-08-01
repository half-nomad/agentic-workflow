# claude-md-sync.ps1
# PostToolUse hook (Edit|Write|MultiEdit): CLAUDE.md 저장 시 AGENTS.md 자동 싱크 (Windows)
#  - 같은 디렉토리에 AGENTS.md 가 이미 존재할 때만 갱신 (프로젝트별 opt-in)
#  - 전역 ~/.claude/CLAUDE.md 저장 시 ~/.codex/AGENTS.md (Codex 전역 지침) 로도 싱크
# Non-blocking: always exit 0

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $data = $raw | ConvertFrom-Json } catch { exit 0 }

$file = $data.tool_input.file_path
if (-not $file) { exit 0 }
if ((Split-Path $file -Leaf) -ne 'CLAUDE.md') { exit 0 }
if (-not (Test-Path $file)) { exit 0 }

# Is $p a reparse point (symlink / junction)? $false for absent paths.
function Test-IsLink([string]$p) {
    try {
        $item = Get-Item -LiteralPath $p -Force -ErrorAction Stop
        return (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
    } catch { return $false }
}

# Full path with links followed; $null when it cannot be determined. PowerShell
# has no `-ef`, so file identity is compared through this.
#
# PS 5.1 has no ResolveLinkTarget, and Resolve-Path does NOT dereference a final
# symlink — it would hand back the link's own path and every identity test below
# would silently compare the wrong thing. Rather than reimplement reparse-point
# resolution against DeviceIoControl for a case that only arises under Developer
# Mode on Windows, record that resolution was unavailable and let the caller
# skip the branch that depends on it.
$script:LinkResolutionUnavailable = $false
function Resolve-FullPath([string]$p) {
    try {
        $item = Get-Item -LiteralPath $p -Force -ErrorAction Stop
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            $target = $null
            try { $target = $item.ResolveLinkTarget($true) } catch { $target = $null }
            if ($target) { return $target.FullName }
            $script:LinkResolutionUnavailable = $true
        }
        return (Resolve-Path -LiteralPath $p -ErrorAction Stop).ProviderPath
    } catch { return $null }
}

# A deployed CLAUDE.md may be a link into the source repo (Developer Mode / WSL);
# an edit through it reports the LINK path, and the sibling lookup below would
# then aim at a nonexistent ~\.claude\AGENTS.md. Assign only on success, so a
# failure degrades to the previous behaviour rather than emptying $file (which
# would make the parent path '.' and clobber the current project's AGENTS.md).
$resolvedFile = Resolve-FullPath $file
if ($resolvedFile) { $file = $resolvedFile }
$editedThroughUnresolvableLink = $script:LinkResolutionUnavailable

$header = '<!-- AUTO-SYNCED from CLAUDE.md - edit CLAUDE.md, not this file. (hooks/claude-md-sync) -->'
$rulesNote = '<!-- Also read ~/.claude/rules/*.md (maestro-workflow.md ships with this repo; the rest are the user''s) and apply those rules identically when working here. -->'
$body = Get-Content $file -Raw

# 1) 같은 디렉토리 AGENTS.md — 이미 존재할 때만 (opt-in)
$sibling = Join-Path (Split-Path $file -Parent) 'AGENTS.md'
if (Test-Path $sibling) {
    Set-Content -Path $sibling -Value ($header + "`n" + $rulesNote + "`n`n" + $body) -Encoding utf8
}

# 2) 전역 CLAUDE.md → Codex 전역 지침
$globalMd = Join-Path $env:USERPROFILE '.claude\CLAUDE.md'
$codexDir = Join-Path $env:USERPROFILE '.codex'
$isGlobal = $false
try {
    $isGlobal = ((Resolve-Path $file -ErrorAction Stop).Path -eq (Resolve-Path $globalMd -ErrorAction Stop).Path)
} catch { $isGlobal = $false }
# Set-Content writes THROUGH a symlink, so this branch decides by what the
# destination IS, never by what it merely is not:
#   not a link -> ours to write (the Windows copy install, which is why this
#                 branch exists at all; there branch 1 no-ops)
#   link -> $sibling -> branch 1 already wrote that exact file. This branch emits
#                 one extra header line, so the two would fight on every edit and
#                 churn a git-tracked file.
#   any other link, broken included -> NOT ours. Never write through a link whose
#                 destination we did not create.
$codexAgents = Join-Path $codexDir 'AGENTS.md'

if ($isGlobal -and (Test-Path $codexDir)) {
    if ($editedThroughUnresolvableLink) {
        # PS 5.1 could not dereference the edited CLAUDE.md, so $sibling is a
        # guess and the identity test below is meaningless. Skip rather than
        # write through a link we cannot account for.
        [Console]::Error.WriteLine('claude-md-sync: cannot resolve the edited CLAUDE.md link on this PowerShell; skipped ~\.codex\AGENTS.md sync')
    }
    elseif (-not (Test-IsLink $codexAgents)) {
        $note = '<!-- source: ~/.claude/CLAUDE.md - relative paths (rules/, skills/) resolve under ~/.claude/ -->'
        Set-Content -Path $codexAgents -Value ($header + "`n" + $rulesNote + "`n" + $note + "`n`n" + $body) -Encoding utf8
    }
    else {
        $codexResolved = Resolve-FullPath $codexAgents
        $siblingResolved = Resolve-FullPath $sibling
        if (-not ($codexResolved -and $siblingResolved -and ($codexResolved -eq $siblingResolved))) {
            [Console]::Error.WriteLine('claude-md-sync: ~\.codex\AGENTS.md is a link to something this repo did not create; skipped (writing would overwrite its target)')
        }
        # else: branch 1 already wrote it
    }
}
exit 0
