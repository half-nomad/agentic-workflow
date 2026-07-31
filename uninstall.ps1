<#
.SYNOPSIS
    agentic-workflow Uninstall Script (Windows PowerShell)
.DESCRIPTION
    Removes agentic-workflow related files installed in ~/.claude/.
#>

param([switch]$Force)

$ErrorActionPreference = "Stop"

function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }

$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$SourceFile = Join-Path $ClaudeDir ".agentic-workflow-source"

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  agentic-workflow Uninstaller" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

Write-Info "Checking installation status..."

if (-not (Test-Path $SourceFile)) {
    Write-Warn "agentic-workflow is not installed."
    exit 0
}

$SourcePath = (Get-Content $SourceFile -Raw).Trim()
Write-Info "Installed source path: $SourcePath"

if (-not $Force) {
    $confirm = Read-Host "Remove agentic-workflow? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Info "Removal cancelled."
        exit 0
    }
}

# File removal function
function Remove-InstalledFiles {
    param([string]$FolderName, [string]$SourceSubDir)

    $targetDir = Join-Path $ClaudeDir $FolderName
    $sourceDir = Join-Path $SourcePath $SourceSubDir

    if (-not (Test-Path $targetDir) -or -not (Test-Path $sourceDir)) { return }

    $removedCount = 0
    Get-ChildItem -Path $sourceDir -File -Recurse | ForEach-Object {
        $relativePath = $_.FullName.Substring($sourceDir.Length).TrimStart('\', '/')
        $targetFile = Join-Path $targetDir $relativePath
        if (Test-Path $targetFile) {
            Remove-Item $targetFile -Force
            $removedCount++
        }
    }

    if ($removedCount -gt 0) { Write-Success "$removedCount files removed from $FolderName" }
}

Write-Info "Removing installed files..."
Remove-InstalledFiles -FolderName "agents" -SourceSubDir "agents"
Remove-InstalledFiles -FolderName "rules" -SourceSubDir "rules"
Remove-InstalledFiles -FolderName "hooks" -SourceSubDir "hooks"
Remove-InstalledFiles -FolderName "commands" -SourceSubDir "commands"
Remove-InstalledFiles -FolderName "skills" -SourceSubDir "skills"

# CLAUDE.md - remove only our managed block, never the user's own content.
$ClaudeMd = Join-Path $ClaudeDir "CLAUDE.md"
$MdBegin = '<!-- BEGIN agentic-workflow -->'
$MdEnd   = '<!-- END agentic-workflow -->'

$HasPair = $false
if (Test-Path $ClaudeMd -PathType Leaf) {
    $lines = @(Get-Content $ClaudeMd)
    $nb = @($lines | Where-Object { $_ -ceq $MdBegin }).Count
    $ne = @($lines | Where-Object { $_ -ceq $MdEnd }).Count
    $HasPair = ($nb -eq 1 -and $ne -eq 1 -and
                ([array]::IndexOf($lines, $MdBegin) -lt [array]::IndexOf($lines, $MdEnd)))
}

if ($HasPair) {
    $lines = @(Get-Content $ClaudeMd)
    $bi = [array]::IndexOf($lines, $MdBegin)
    $ei = [array]::IndexOf($lines, $MdEnd)
    $kept = @()
    if ($bi -gt 0) { $kept += $lines[0..($bi - 1)] }
    if ($ei -lt ($lines.Count - 1)) { $kept += $lines[($ei + 1)..($lines.Count - 1)] }

    if (@($kept | Where-Object { $_ -match '\S' }).Count -gt 0) {
        Set-Content -Path $ClaudeMd -Value $kept -Encoding UTF8
        Write-Success "CLAUDE.md: managed block removed (your own content kept)."
    } else {
        Remove-Item $ClaudeMd -Force
        Write-Success "CLAUDE.md removed (contained only the managed block)."
    }
} else {
    # Pre-marker installs overwrote the whole file and left a timestamped backup.
    $ClaudeMdBackups = Get-ChildItem -Path $ClaudeDir -Filter "CLAUDE.md.backup.*" -ErrorAction SilentlyContinue |
                       Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($ClaudeMdBackups) {
        Copy-Item $ClaudeMdBackups.FullName $ClaudeMd -Force
        Remove-Item $ClaudeMdBackups.FullName -Force
        Write-Success "CLAUDE.md restored from backup (pre-marker install)."
    } elseif (Test-Path $ClaudeMd) {
        Write-Warn "CLAUDE.md has no agentic-workflow markers - left untouched."
    }
}

# Remove source path file
if (Test-Path $SourceFile) {
    Remove-Item $SourceFile -Force
    Write-Success ".agentic-workflow-source file removed."
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Uninstall Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "To reinstall, run install.ps1." -ForegroundColor Gray
Write-Host ""
