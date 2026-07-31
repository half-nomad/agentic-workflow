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
$manifestPath = Join-Path $claudeHome '.maestro-manifest.txt'

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
foreach ($line in (Get-Content -LiteralPath $manifestPath)) {
    $rel = $line.Trim()
    if (-not $rel) { continue }
    $target = Join-Path $userHome $rel
    if (Test-Path -LiteralPath $target) {
        Remove-Item -LiteralPath $target -Recurse -Force
        Write-Host ('  removed ' + $rel)
        $removed++
    }
    else {
        $missing++
    }
}

Remove-Item -LiteralPath $manifestPath -Force
Write-Host ''
Write-Host ($removed.ToString() + ' path(s) removed. Your own files were untouched.')
if ($missing -gt 0) {
    Write-Host ($missing.ToString() + ' manifest entr(y/ies) were already gone.')
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
