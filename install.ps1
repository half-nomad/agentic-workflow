#Requires -Version 5.1
# install.ps1 - Agentic Workflow installer (native Windows PowerShell)
#
# Windows symlinks need Developer Mode or an elevated shell, so this copies
# instead of linking. Consequence: the update path is `git pull` followed by
# re-running this script - copies do not track upstream the way links do.
#
# Granularity mirrors install.sh and is a safety property:
#   CLAUDE.md, agents\*, rules\*, hooks\*  -> per FILE (your own files live there)
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

$beginMark = '<!-- BEGIN agentic-workflow -->'
$endMark = '<!-- END agentic-workflow -->'

function Get-RelPath([string]$path) {
    $full = [System.IO.Path]::GetFullPath($path)
    $root = [System.IO.Path]::GetFullPath($userHome).TrimEnd('\', '/')
    if ($full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $full.Substring($root.Length).TrimStart('\', '/')
    }
    return $full
}

# --- CLAUDE.md ownership guard ----------------------------------------------
# Same rule as install.sh: this script overwrites ~\.claude\CLAUDE.md wholesale,
# and older installs promised that anything outside the marker block survives.
# Refuse rather than quietly discard it into a backup nobody reads.
function Assert-ClaudeMdOwnership {
    $dest = Join-Path $claudeHome 'CLAUDE.md'
    if (-not (Test-Path -LiteralPath $dest -PathType Leaf)) { return }

    $lines = @(Get-Content -LiteralPath $dest)
    $leftover = ''

    if (($lines -contains $beginMark) -and ($lines -contains $endMark)) {
        $inBlock = $false
        $kept = foreach ($line in $lines) {
            if ($line -eq $beginMark) { $inBlock = $true; continue }
            if ($line -eq $endMark) { $inBlock = $false; continue }
            if (-not $inBlock) { $line }
        }
        $leftover = ($kept -join "`n")
    }
    else {
        # No marker pair: unmanaged, unless identical to what we ship.
        $src = Join-Path $repo 'CLAUDE.md'
        $current = ((Get-Content -LiteralPath $dest -Raw) -replace "`r`n", "`n").TrimEnd()
        $shipped = ''
        if (Test-Path -LiteralPath $src -PathType Leaf) {
            $shipped = ((Get-Content -LiteralPath $src -Raw) -replace "`r`n", "`n").TrimEnd()
        }
        if ($current -eq $shipped) { return }
        $leftover = $current
    }

    if ($leftover -match '\S') {
        Write-Host ''
        Write-Host 'ERROR: ~\.claude\CLAUDE.md holds instructions this installer would overwrite.' -ForegroundColor Red
        Write-Host ''
        Write-Host '  install.ps1 replaces ~\.claude\CLAUDE.md with the copy shipped in'
        Write-Host ('      ' + (Join-Path $repo 'CLAUDE.md'))
        Write-Host '  so anything you wrote in that file would be lost - and a backup you never'
        Write-Host '  open is the same as losing it.'
        Write-Host ''
        Write-Host '  Move your own instructions to'
        Write-Host '      ~\.claude\rules\personal.md'
        Write-Host '  which is user-owned: this repo never ships, overwrites or removes it, and'
        Write-Host '  it loads in every project just like CLAUDE.md. Then re-run install.ps1.'
        Write-Host ''
        Write-Host '  Nothing has been changed.'
        Write-Host ''
        exit 1
    }
}

# --- deployment --------------------------------------------------------------
$deployed = New-Object System.Collections.Generic.List[string]

# Paths this install already owns from a previous run: safe to overwrite.
# Anything else sitting at a destination is the user's, and gets moved aside
# loudly instead of being clobbered.
$previous = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    foreach ($line in (Get-Content -LiteralPath $manifestPath)) {
        if ($line.Trim()) { [void]$previous.Add($line.Trim()) }
    }
}

function Move-Aside([string]$dest, [string]$rel) {
    if (-not (Test-Path -LiteralPath $dest)) { return }
    if ($previous.Contains($rel)) { return }
    $target = Join-Path $backupRoot $rel
    $targetDir = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    Move-Item -LiteralPath $dest -Destination $target -Force
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
    [void]$deployed.Add($rel)
    Write-Host ('  copied ' + $rel)
}

function Deploy-Dir([string]$src, [string]$dest) {
    $rel = Get-RelPath $dest
    Move-Aside $dest $rel
    if (Test-Path -LiteralPath $dest) {
        Remove-Item -LiteralPath $dest -Recurse -Force
    }
    Copy-Item -LiteralPath $src -Destination $dest -Recurse -Force
    [void]$deployed.Add($rel)
    Write-Host ('  copied ' + $rel + '\')
}

# --- run ---------------------------------------------------------------------
Write-Host ''
Write-Host 'agentic-workflow installer (Windows, copy mode)'
Write-Host ('  repo: ' + $repo)
Write-Host ('  into: ' + $claudeHome)
Write-Host ''

Assert-ClaudeMdOwnership

foreach ($sub in @('agents', 'rules', 'hooks', 'skills')) {
    $d = Join-Path $claudeHome $sub
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$claudeMd = Join-Path $repo 'CLAUDE.md'
if (Test-Path -LiteralPath $claudeMd -PathType Leaf) {
    Deploy-File $claudeMd (Join-Path $claudeHome 'CLAUDE.md')
}

foreach ($sub in @('agents', 'rules', 'hooks')) {
    $srcDir = Join-Path $repo $sub
    if (-not (Test-Path -LiteralPath $srcDir)) { continue }
    foreach ($f in (Get-ChildItem -LiteralPath $srcDir -File)) {
        Deploy-File $f.FullName (Join-Path (Join-Path $claudeHome $sub) $f.Name)
    }
}

$skillsDir = Join-Path $repo 'skills'
if (Test-Path -LiteralPath $skillsDir) {
    foreach ($s in (Get-ChildItem -LiteralPath $skillsDir -Directory)) {
        Deploy-Dir $s.FullName (Join-Path (Join-Path $claudeHome 'skills') $s.Name)
    }
}

# Codex reads the same config through AGENTS.md - only if it is already set up.
$agentsMd = Join-Path $repo 'AGENTS.md'
if (Test-Path -LiteralPath $agentsMd -PathType Leaf) {
    if (Test-Path -LiteralPath $codexHome -PathType Container) {
        Deploy-File $agentsMd (Join-Path $codexHome 'AGENTS.md')
    }
    else {
        Write-Host '  skipped ~\.codex\AGENTS.md (no ~\.codex - Codex not installed)'
    }
}

Set-Content -LiteralPath $manifestPath -Value $deployed -Encoding utf8
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
