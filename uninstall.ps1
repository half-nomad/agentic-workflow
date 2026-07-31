#Requires -Version 5.1
# uninstall.ps1 - Agentic Workflow uninstaller (native Windows PowerShell)
#
# Removes ONLY the paths install.ps1 recorded in ~\.claude\.maestro-manifest.txt.
# If the manifest is missing this script refuses to run rather than guessing by
# filename: your own agents, rules, hooks and skills sit in the very same
# directories, and guessing is how you delete someone's skills.

$ErrorActionPreference = 'Stop'

$userHome = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
$claudeHome = Join-Path $userHome '.claude'
$codexHome = Join-Path $userHome '.codex'
$manifestPath = Join-Path $claudeHome '.maestro-manifest.txt'

# The manifest is a file on disk, so it is input, not authority. A line reading
# '..\..\Documents' joined onto the home directory resolves to a real place
# outside anything this installer ever wrote to - and Remove-Item -Recurse
# -Force does not ask. Containment is checked structurally: strictly inside
# ~\.claude or ~\.codex, separator-bounded so ~\.claudeX cannot pass.
function Test-InsideRoot([string]$path, [string]$root) {
    try {
        $p = [System.IO.Path]::GetFullPath($path)
        $r = [System.IO.Path]::GetFullPath($root).TrimEnd('\', '/')
    }
    catch { return $false }
    $sep = [System.IO.Path]::DirectorySeparatorChar
    return $p.StartsWith(($r + $sep), [System.StringComparison]::OrdinalIgnoreCase)
}

# Mirrors Get-PathFingerprint in install.ps1 - keep the two in step.
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

Write-Host ''
Write-Host 'agentic-workflow uninstaller (Windows)'
Write-Host ''

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    Write-Host 'ERROR: no install manifest found at' -ForegroundColor Red
    Write-Host ('    ' + $manifestPath)
    Write-Host ''
    Write-Host '  That file is the only record of what this installer deployed. Without it'
    Write-Host '  the script would have to guess by filename, and the same directories hold'
    Write-Host '  your own agents, rules, hooks and skills - so it refuses.'
    Write-Host ''
    Write-Host '  If you installed on this machine, re-run install.ps1 to regenerate the'
    Write-Host '  manifest, then run uninstall.ps1 again. Otherwise remove the files by hand.'
    Write-Host ''
    exit 1
}

$removed = 0
$missing = 0
$skipped = 0
foreach ($line in (Get-Content -LiteralPath $manifestPath)) {
    $entry = $line.Trim()
    if (-not $entry) { continue }
    if ($entry.StartsWith('#')) { continue }

    # <SHA256>  <relpath>; a bare path is a legacy manifest and carries no proof.
    $fingerprint = $null
    $rel = $entry
    if ($entry -match '^([0-9A-Fa-f]{64})\s+(.+)$') {
        $fingerprint = $Matches[1]
        $rel = $Matches[2]
    }

    # Reject traversal before resolution, on either separator - the manifest is
    # written on Windows but may be read anywhere.
    if (($rel -split '[\\/]+') -contains '..') {
        Write-Host ('  WARNING: refusing manifest entry with a ".." segment: ' + $rel) -ForegroundColor Yellow
        $skipped++
        continue
    }

    $target = Join-Path $userHome $rel
    if (-not ((Test-InsideRoot $target $claudeHome) -or (Test-InsideRoot $target $codexHome))) {
        Write-Host ('  WARNING: refusing manifest entry outside ~\.claude and ~\.codex: ' + $rel) -ForegroundColor Yellow
        $skipped++
        continue
    }

    if (-not (Test-Path -LiteralPath $target)) {
        $missing++
        continue
    }

    # A remembered pathname is not proof of current ownership. If what is there
    # now is not what install left there, it is the user's - leave it.
    if (-not $fingerprint) {
        Write-Host ('  SKIPPED ' + $rel + ' - legacy manifest entry has no fingerprint, so ownership cannot be verified. Re-run install.ps1 to regenerate the manifest, or delete it by hand.') -ForegroundColor Yellow
        $skipped++
        continue
    }
    if ($fingerprint -ne (Get-PathFingerprint $target)) {
        Write-Host ('  SKIPPED ' + $rel + ' - changed since install, so it is no longer ours to delete. Remove it by hand if you want it gone.') -ForegroundColor Yellow
        $skipped++
        continue
    }

    Remove-Item -LiteralPath $target -Recurse -Force
    Write-Host ('  removed ' + $rel)
    $removed++
}

Remove-Item -LiteralPath $manifestPath -Force
Write-Host ''
Write-Host ($removed.ToString() + ' path(s) removed. Your own files were untouched.')
if ($missing -gt 0) {
    Write-Host ($missing.ToString() + ' manifest entr(y/ies) were already gone.')
}
if ($skipped -gt 0) {
    Write-Host ($skipped.ToString() + ' manifest entr(y/ies) were skipped - see the warnings above.') -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Left in place, on purpose:'
Write-Host '  ~\.claude\.maestro-backup-*   files install displaced, if any. Review, then'
Write-Host '                                delete them yourself.'
Write-Host '  ~\.claude\settings.json       never written by any script here. Remove this'
Write-Host '                                repo''s hook entries by hand - see the uninstall'
Write-Host '                                snippet in the project README. Leaving them behind'
Write-Host '                                makes every matching tool call error, because the'
Write-Host '                                hook scripts are now gone.'
Write-Host '  ~\.claude\rules\personal.md   user-owned; never installed, never removed.'
Write-Host ''
