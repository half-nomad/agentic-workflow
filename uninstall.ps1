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

# CLAUDE.md handling
$ClaudeMd = Join-Path $ClaudeDir "CLAUDE.md"
$ClaudeMdBackups = Get-ChildItem -Path $ClaudeDir -Filter "CLAUDE.md.backup.*" 2>$null | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($ClaudeMdBackups) {
    Copy-Item $ClaudeMdBackups.FullName $ClaudeMd -Force
    Remove-Item $ClaudeMdBackups.FullName -Force
    Write-Success "CLAUDE.md restored from backup."
} elseif (Test-Path $ClaudeMd) {
    Remove-Item $ClaudeMd -Force
    Write-Success "CLAUDE.md removed."
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
