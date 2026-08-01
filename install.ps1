#Requires -Version 5.1
# install.ps1 - Agentic Workflow installer (native Windows PowerShell)
#
# Windows symlinks need Developer Mode or an elevated shell, so this copies
# instead of linking. Consequence: the update path is `git pull` followed by
# re-running this script - copies do not track upstream the way links do.
#
# Granularity mirrors install.sh and is a safety property:
#   agents\* hooks\*  -> per FILE   (your own files live there)
#   rules\             -> ALLOWLIST (maestro-workflow.md only; CLAUDE.md is NOT deployed)
#   skills\<name>\                         -> per DIR  (each is wholly ours)
#
# Every deployed path is recorded in ~\.claude\.maestro-manifest.txt, and
# uninstall.ps1 removes only what that manifest lists. settings.json is never
# written - see the reminder at the end.

$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$userHome = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
$claudeHome = Join-Path $userHome '.claude'
$codexHome = Join-Path $userHome '.codex'
$manifestPath = Join-Path $claudeHome '.maestro-manifest.txt'
$backupRoot = Join-Path $claudeHome ('.maestro-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))

function Get-RelPath([string]$path) {
    $full = [System.IO.Path]::GetFullPath($path)
    $root = [System.IO.Path]::GetFullPath($userHome).TrimEnd('\', '/')
    if ($full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $full.Substring($root.Length).TrimStart('\', '/')
    }
    return $full
}

# --- deployment --------------------------------------------------------------
$deployed = New-Object System.Collections.Generic.List[string]

# Fingerprint of what we deployed, so ownership is a property of the CONTENT and
# not merely of the pathname. `skills\maestro` appearing in an old manifest does
# not prove the directory sitting there today is still ours - the user may have
# replaced it - and deleting on the strength of a remembered path is how you
# destroy someone's work on a reinstall.
#   file: SHA256 of its bytes
#   dir : SHA256 of the "<relpath><TAB><sha256>" listing of its files, LF-joined,
#         sorted ordinally
function Get-PathFingerprint([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    }
    $root = [System.IO.Path]::GetFullPath($path).TrimEnd('\', '/')
    $records = New-Object System.Collections.Generic.List[string]
    foreach ($f in (Get-ChildItem -LiteralPath $path -Recurse -File -Force)) {
        $rel = [System.IO.Path]::GetFullPath($f.FullName).Substring($root.Length + 1) -replace '\\', '/'
        $records.Add($rel + "`t" + (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash)
    }
    $arr = $records.ToArray()
    [System.Array]::Sort($arr, [System.StringComparer]::Ordinal)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes(($arr -join "`n")))
    }
    finally { $sha.Dispose() }
    return (-join ($bytes | ForEach-Object { $_.ToString('X2') }))
}

# Paths this install already owns from a previous run AND whose content still
# matches what it left there: safe to overwrite. Anything else sitting at a
# destination is the user's, and gets moved aside loudly instead of clobbered.
# A legacy manifest line (path only, no fingerprint) is unverifiable, so it
# claims nothing - the destination is backed up as if it were the user's.
$previous = @{}
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    foreach ($line in (Get-Content -LiteralPath $manifestPath)) {
        $t = $line.Trim()
        if (-not $t) { continue }
        if ($t.StartsWith('#')) { continue }
        if ($t -match '^([0-9A-Fa-f]{64})\s+(.+)$') { $previous[$Matches[2]] = $Matches[1] }
        else { $previous[$t] = $null }
    }
}

function Move-Aside([string]$dest, [string]$rel) {
    $script:movedAside = $false
    if (-not (Test-Path -LiteralPath $dest)) { return }
    if ($previous.ContainsKey($rel)) {
        $recorded = $previous[$rel]
        if ($recorded -and ($recorded -eq (Get-PathFingerprint $dest))) { return }
        Write-Host ('  note: ' + $rel + ' no longer matches what this installer left there - backing it up rather than overwriting') -ForegroundColor Yellow
    }
    $target = Join-Path $backupRoot $rel
    $targetDir = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    Move-Item -LiteralPath $dest -Destination $target -Force
    $script:movedAside = $true
    Write-Host ''
    Write-Host ('  *** BACKED UP: ' + $dest) -ForegroundColor Yellow
    Write-Host ('  ***       -> ' + $target) -ForegroundColor Yellow
    Write-Host ''
}

function Deploy-File([string]$src, [string]$dest) {
    $rel = Get-RelPath $dest
    Move-Aside $dest $rel
    $destDir = Split-Path -Parent $dest
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    Copy-Item -LiteralPath $src -Destination $dest -Force
    [void]$deployed.Add(((Get-PathFingerprint $dest) + '  ' + $rel))
    Write-Host ('  copied ' + $rel)
}

function Deploy-Dir([string]$src, [string]$dest) {
    $rel = Get-RelPath $dest
    Move-Aside $dest $rel
    if (Test-Path -LiteralPath $dest) {
        Remove-Item -LiteralPath $dest -Recurse -Force
    }
    Copy-Item -LiteralPath $src -Destination $dest -Recurse -Force
    [void]$deployed.Add(((Get-PathFingerprint $dest) + '  ' + $rel))
    Write-Host ('  copied ' + $rel + '\')
}

# --- run ---------------------------------------------------------------------
Write-Host ''
Write-Host 'agentic-workflow installer (Windows, copy mode)'
Write-Host ('  repo: ' + $repo)
Write-Host ('  into: ' + $claudeHome)
Write-Host ''

foreach ($sub in @('agents', 'rules', 'hooks', 'skills')) {
    $d = Join-Path $claudeHome $sub
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# ~\.claude\CLAUDE.md is deliberately NOT deployed. It is yours.
#
# Shipping our instructions there meant overwriting a file the user owns, which
# forced a marker-block merge to protect their content, which was 152 lines of
# topology parsing across two languages - all of it downstream of one avoidable
# choice. rules\*.md and CLAUDE.md are loaded at the same tier (the system prompt
# labels both "user's private global instructions for all projects"), so a rule
# file behaves identically and never collides with anything of yours. There is
# nothing to merge when files simply coexist.

foreach ($sub in @('agents', 'hooks')) {
    $srcDir = Join-Path $repo $sub
    if (-not (Test-Path -LiteralPath $srcDir)) { continue }
    foreach ($f in (Get-ChildItem -LiteralPath $srcDir -File)) {
        Deploy-File $f.FullName (Join-Path (Join-Path $claudeHome $sub) $f.Name)
    }
}

# rules\ is an ALLOWLIST, not a glob - deliberately asymmetric with the loops
# above and below. This installer places exactly one rule file; every other file
# in ~\.claude\rules\ is yours (your own global.md, personal.md, ...). A glob
# would mean that adding a same-named rule upstream displaces your file on the
# next reinstall. Adding a rule here is a deliberate act; make it one.
foreach ($ruleName in @('maestro-workflow.md')) {
    $src = Join-Path (Join-Path $repo 'rules') $ruleName
    if (Test-Path -LiteralPath $src) {
        Deploy-File $src (Join-Path (Join-Path $claudeHome 'rules') $ruleName)
    }
}

# skills\ stays a glob: whatever sits in this repo's skills\ is wholly ours.
$skillsDir = Join-Path $repo 'skills'
if (Test-Path -LiteralPath $skillsDir) {
    foreach ($s in (Get-ChildItem -LiteralPath $skillsDir -Directory)) {
        Deploy-Dir $s.FullName (Join-Path (Join-Path $claudeHome 'skills') $s.Name)
    }
}

# ~\.codex\AGENTS.md is NOT deployed either, for the same reason as
# ~\.claude\CLAUDE.md: it is Codex's equivalent of that file and it belongs to
# you. This repo's AGENTS.md is generated from this repo's CLAUDE.md, and both
# are *contributor* instructions for working on this checkout.
#
# To let Codex see the same rules Claude gets, add one line to your own
# ~\.codex\AGENTS.md - see "Codex" in the project README.

# Manifest format - one record per deployed path, readable on purpose:
#
#   <SHA256>  <path relative to the user profile>
#
# The fingerprint is of what THIS run wrote (file: hash of its bytes; directory:
# hash of its sorted "<relpath><TAB><sha256>" listing). It is what makes
# ownership verifiable: on reinstall or uninstall, a path whose fingerprint no
# longer matches is not ours any more and is backed up / skipped instead of
# being deleted. Lines starting with '#' are comments. Older manifests carrying
# a bare path are still read, but claim nothing - they cannot be verified.
# Retired paths: recorded by a previous run, not deployed by this one - the file
# left this repo upstream. Without this pass they would sit in ~\.claude\ forever,
# owned by nobody: the new manifest drops them, so uninstall will never remove
# them either. If the fingerprint still matches what we left, the copy is
# provably still ours and is moved to the backup root. If it no longer matches,
# the user edited it - say so and leave it alone; it is theirs now.
$deployedRels = @{}
foreach ($line in $deployed) {
    if ($line -match '^[0-9A-Fa-f]{64}\s+(.+)$') { $deployedRels[$Matches[1]] = $true }
}
foreach ($rel in @($previous.Keys)) {
    if ($deployedRels.ContainsKey($rel)) { continue }
    $dest = Join-Path $userHome $rel
    if (-not (Test-Path -LiteralPath $dest)) { continue }
    $recorded = $previous[$rel]
    if ($recorded -and (Get-PathFingerprint $dest) -eq $recorded) {
        # NOT Move-Aside: that helper returns early on a fingerprint match,
        # because in the deploy path a match means "ours, safe to overwrite".
        # Here a match means the opposite - ours, and no longer shipped, so it
        # has to go. Move it explicitly.
        $target = Join-Path $backupRoot $rel
        $targetDir = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        Move-Item -LiteralPath $dest -Destination $target -Force
        Write-Host ''
        Write-Host ('  *** RETIRED: ' + $rel + ' is no longer shipped') -ForegroundColor Yellow
        Write-Host ('  ***       -> ' + $target) -ForegroundColor Yellow
        Write-Host ''
    } else {
        Write-Host ('  RETIRED: ' + $rel + ' is no longer shipped and differs from what we left - kept in place, it is yours now') -ForegroundColor Yellow
    }
}

$manifestHeader = @(
    '# agentic-workflow install manifest - written by install.ps1, read by uninstall.ps1.',
    '# Format:  <SHA256>  <path relative to %USERPROFILE%>',
    '#   file      -> SHA256 of the file bytes',
    '#   directory -> SHA256 of its sorted "<relpath><TAB><SHA256>" listing, LF-joined',
    '# A path whose fingerprint no longer matches is no longer ours: install backs it',
    '# up instead of overwriting, uninstall skips it instead of deleting. Do not edit.'
)
Set-Content -LiteralPath $manifestPath -Value ($manifestHeader + $deployed) -Encoding utf8
Write-Host ''
Write-Host ('  manifest: ' + $manifestPath + ' (' + $deployed.Count + ' entries)')
if (Test-Path -LiteralPath $backupRoot) {
    Write-Host ('  displaced files were moved to: ' + $backupRoot)
}

Write-Host ''
Write-Host 'Done. Restart Claude Code to pick up the changes.'
Write-Host ''
Write-Host 'ONE-TIME STEP - hooks are not registered automatically.'
Write-Host '  settings.json is yours: it holds personal keys and interleaves your own'
Write-Host '  security hooks with this repo''s, so no script writes to it. Copy the'
Write-Host '  PowerShell "hooks" block from the project README into'
Write-Host '  ~\.claude\settings.json once. Nothing else about it ever needs to change.'
Write-Host ''
Write-Host 'To update (copies do not track upstream - both steps are required):'
Write-Host ('  git -C ' + $repo + ' pull')
Write-Host ('  ' + (Join-Path $repo 'install.ps1'))
Write-Host ''
Write-Host 'To remove:'
Write-Host ('  ' + (Join-Path $repo 'uninstall.ps1'))
Write-Host ''
