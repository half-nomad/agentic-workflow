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

# Full path with links followed; $null when it cannot be determined. PowerShell
# has no `-ef`, so file identity is compared through this.
function Resolve-FullPath([string]$p) {
    try {
        $item = Get-Item -LiteralPath $p -ErrorAction Stop
        try {
            $target = $item.ResolveLinkTarget($true)   # PS 7+; throws on 5.1
            if ($target) { return $target.FullName }
        } catch { }
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

$header = '<!-- AUTO-SYNCED from CLAUDE.md - edit CLAUDE.md, not this file. (hooks/claude-md-sync) -->'
$rulesNote = '<!-- Also read ~/.claude/rules/*.md (secure-coding, global, ...) and apply those rules identically when working here. -->'
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
# Skip when ~\.codex\AGENTS.md IS the file branch 1 just wrote (it can be a link
# to the repo's tracked AGENTS.md). This branch emits one extra header line, so
# the two would fight on every edit and churn a tracked file. PowerShell has no
# `-ef`, so compare resolved full paths.
# A wrong-target or broken link must NOT count as "same" — that would skip a sync
# that is genuinely needed — so both sides must resolve to a real path first.
$codexAgents = Join-Path $codexDir 'AGENTS.md'
$sameAsSibling = $false
$codexResolved = Resolve-FullPath $codexAgents
$siblingResolved = Resolve-FullPath $sibling
if ($codexResolved -and $siblingResolved -and ($codexResolved -eq $siblingResolved)) {
    $sameAsSibling = $true
}

if ($isGlobal -and (Test-Path $codexDir) -and -not $sameAsSibling) {
    $note = '<!-- source: ~/.claude/CLAUDE.md - relative paths (rules/, skills/) resolve under ~/.claude/ -->'
    Set-Content -Path (Join-Path $codexDir 'AGENTS.md') -Value ($header + "`n" + $rulesNote + "`n" + $note + "`n`n" + $body) -Encoding utf8
}
exit 0
