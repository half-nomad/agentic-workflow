<#
.SYNOPSIS
    agentic-workflow 제거 스크립트 (Windows PowerShell)
.DESCRIPTION
    ~/.claude/에 설치된 agentic-workflow 관련 파일들을 제거합니다.
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

Write-Info "설치 상태 확인 중..."

if (-not (Test-Path $SourceFile)) {
    Write-Warn "agentic-workflow가 설치되지 않았습니다."
    exit 0
}

$SourcePath = (Get-Content $SourceFile -Raw).Trim()
Write-Info "설치된 소스 경로: $SourcePath"

if (-not $Force) {
    $confirm = Read-Host "agentic-workflow를 제거하시겠습니까? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Info "제거가 취소되었습니다."
        exit 0
    }
}

# 파일 제거 함수
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

    if ($removedCount -gt 0) { Write-Success "$FolderName 에서 $removedCount 개 파일 제거됨" }
}

Write-Info "설치된 파일들을 제거하는 중..."
Remove-InstalledFiles -FolderName "agents" -SourceSubDir "agents"
Remove-InstalledFiles -FolderName "rules" -SourceSubDir "rules"
Remove-InstalledFiles -FolderName "hooks" -SourceSubDir "hooks"
Remove-InstalledFiles -FolderName "commands" -SourceSubDir "commands"
Remove-InstalledFiles -FolderName "skills" -SourceSubDir "skills"

# CLAUDE.md 처리
$ClaudeMd = Join-Path $ClaudeDir "CLAUDE.md"
$ClaudeMdBackups = Get-ChildItem -Path $ClaudeDir -Filter "CLAUDE.md.backup.*" 2>$null | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($ClaudeMdBackups) {
    Copy-Item $ClaudeMdBackups.FullName $ClaudeMd -Force
    Remove-Item $ClaudeMdBackups.FullName -Force
    Write-Success "CLAUDE.md가 백업에서 복원되었습니다."
} elseif (Test-Path $ClaudeMd) {
    Remove-Item $ClaudeMd -Force
    Write-Success "CLAUDE.md가 제거되었습니다."
}

# 소스 경로 파일 제거
if (Test-Path $SourceFile) {
    Remove-Item $SourceFile -Force
    Write-Success ".agentic-workflow-source 파일이 제거되었습니다."
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  제거 완료!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "재설치하려면 install.ps1을 실행하세요." -ForegroundColor Gray
Write-Host ""
