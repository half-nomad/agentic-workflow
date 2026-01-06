#Requires -Version 5.1
<#
.SYNOPSIS
    Agentic Workflow 설치 스크립트 (Windows PowerShell)
.DESCRIPTION
    Claude Code용 agentic-workflow 구성 파일들을 ~/.claude/ 디렉토리에 설치합니다.
.EXAMPLE
    .\install.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# 색상 출력 함수
function Write-Step { param($Message) Write-Host "[*] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[+] $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[!] $Message" -ForegroundColor Yellow }
function Write-Err { param($Message) Write-Host "[-] $Message" -ForegroundColor Red }

# 경로 설정
$SourcePath = $PSScriptRoot
$ClaudeHome = Join-Path $env:USERPROFILE ".claude"

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  Agentic Workflow Installer (Windows)" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

# 1. 프로젝트 소스 경로 저장
Write-Step "프로젝트 소스 경로 저장..."

if (-not (Test-Path $ClaudeHome)) {
    New-Item -ItemType Directory -Path $ClaudeHome -Force | Out-Null
}

$SourceFilePath = Join-Path $ClaudeHome ".agentic-workflow-source"
$SourcePath | Out-File -FilePath $SourceFilePath -Encoding UTF8 -NoNewline
Write-Success "소스 경로 저장됨: $SourceFilePath"

# 2. 디렉토리 생성
Write-Step "디렉토리 생성..."

$Directories = @(
    $ClaudeHome,
    (Join-Path $ClaudeHome "agents"),
    (Join-Path $ClaudeHome "rules"),
    (Join-Path $ClaudeHome "hooks"),
    (Join-Path $ClaudeHome "commands"),
    (Join-Path $ClaudeHome "skills")
)

foreach ($Dir in $Directories) {
    if (-not (Test-Path $Dir)) {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
        Write-Success "생성됨: $Dir"
    } else {
        Write-Host "    이미 존재: $Dir" -ForegroundColor DarkGray
    }
}

# 3. 파일 복사 함수
function Copy-DirectoryContents {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (Test-Path $Source) {
        $Items = Get-ChildItem -Path $Source -File
        foreach ($Item in $Items) {
            $DestFile = Join-Path $Destination $Item.Name
            Copy-Item -Path $Item.FullName -Destination $DestFile -Force
            Write-Host "    복사됨: $($Item.Name)" -ForegroundColor DarkGray
        }
        return $Items.Count
    }
    return 0
}

# 파일 복사
Write-Step "파일 복사..."

# agents/
Write-Host "  agents/ 복사 중..."
$count = Copy-DirectoryContents -Source (Join-Path $SourcePath "agents") -Destination (Join-Path $ClaudeHome "agents")
Write-Success "agents: $count 파일 복사됨"

# rules/
Write-Host "  rules/ 복사 중..."
$count = Copy-DirectoryContents -Source (Join-Path $SourcePath "rules") -Destination (Join-Path $ClaudeHome "rules")
Write-Success "rules: $count 파일 복사됨"

# hooks/
Write-Host "  hooks/ 복사 중..."
$count = Copy-DirectoryContents -Source (Join-Path $SourcePath "hooks") -Destination (Join-Path $ClaudeHome "hooks")
Write-Success "hooks: $count 파일 복사됨"

# commands/
Write-Host "  commands/ 복사 중..."
$count = Copy-DirectoryContents -Source (Join-Path $SourcePath "commands") -Destination (Join-Path $ClaudeHome "commands")
Write-Success "commands: $count 파일 복사됨"

# skills/ (재귀 복사)
Write-Host "  skills/ 복사 중..."
$SkillsSource = Join-Path $SourcePath "skills"
$SkillsDest = Join-Path $ClaudeHome "skills"
if (Test-Path $SkillsSource) {
    Copy-Item -Path "$SkillsSource\*" -Destination $SkillsDest -Recurse -Force
    Write-Success "skills: 복사 완료"
}

# CLAUDE.global.md -> CLAUDE.md
Write-Host "  CLAUDE.md 설정 중..."
$GlobalMdSource = Join-Path $SourcePath "CLAUDE.global.md"
$ClaudeMdDest = Join-Path $ClaudeHome "CLAUDE.md"

if (Test-Path $GlobalMdSource) {
    if (Test-Path $ClaudeMdDest) {
        $BackupPath = "$ClaudeMdDest.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item -Path $ClaudeMdDest -Destination $BackupPath -Force
        Write-Warn "기존 CLAUDE.md 백업됨: $BackupPath"
    }
    Copy-Item -Path $GlobalMdSource -Destination $ClaudeMdDest -Force
    Write-Success "CLAUDE.md 복사됨"
} else {
    Write-Host "    CLAUDE.global.md 파일 없음 (건너뜀)" -ForegroundColor DarkGray
}

# 4. 설정 파일 병합
Write-Step "설정 파일 병합..."

# settings.json 병합
$SettingsSource = Join-Path $SourcePath "settings.json"
$SettingsDest = Join-Path $ClaudeHome "settings.json"

if (Test-Path $SettingsSource) {
    $NewSettings = Get-Content -Path $SettingsSource -Raw | ConvertFrom-Json

    if (Test-Path $SettingsDest) {
        $ExistingSettings = Get-Content -Path $SettingsDest -Raw | ConvertFrom-Json

        # 권한 병합
        if ($NewSettings.permissions -and $NewSettings.permissions.allow) {
            if (-not $ExistingSettings.permissions) {
                $ExistingSettings | Add-Member -NotePropertyName "permissions" -NotePropertyValue @{ allow = @() } -Force
            }
            if (-not $ExistingSettings.permissions.allow) {
                $ExistingSettings.permissions.allow = @()
            }
            $AllPermissions = @($ExistingSettings.permissions.allow) + @($NewSettings.permissions.allow) | Select-Object -Unique
            $ExistingSettings.permissions.allow = $AllPermissions
        }

        # hooks 병합
        if ($NewSettings.hooks) {
            $ExistingSettings | Add-Member -NotePropertyName "hooks" -NotePropertyValue $NewSettings.hooks -Force
        }

        $ExistingSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $SettingsDest -Encoding UTF8
        Write-Success "settings.json 병합됨"
    } else {
        Copy-Item -Path $SettingsSource -Destination $SettingsDest -Force
        Write-Success "settings.json 복사됨 (새 파일)"
    }
}

# .mcp.json 병합
$McpSource = Join-Path $SourcePath ".mcp.json"
$McpDest = Join-Path $env:USERPROFILE ".mcp.json"

if (Test-Path $McpSource) {
    $NewMcp = Get-Content -Path $McpSource -Raw | ConvertFrom-Json

    if (Test-Path $McpDest) {
        $ExistingMcp = Get-Content -Path $McpDest -Raw | ConvertFrom-Json

        if ($NewMcp.mcpServers) {
            if (-not $ExistingMcp.mcpServers) {
                $ExistingMcp | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue @{} -Force
            }
            foreach ($Server in $NewMcp.mcpServers.PSObject.Properties) {
                $ExistingMcp.mcpServers | Add-Member -NotePropertyName $Server.Name -NotePropertyValue $Server.Value -Force
            }
        }

        $ExistingMcp | ConvertTo-Json -Depth 10 | Out-File -FilePath $McpDest -Encoding UTF8
        Write-Success ".mcp.json 병합됨: $McpDest"
    } else {
        Copy-Item -Path $McpSource -Destination $McpDest -Force
        Write-Success ".mcp.json 복사됨 (새 파일): $McpDest"
    }
}

# 5. MCP 설치 안내
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  MCP 도구 설치 안내" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "grep_app_mcp 설치가 필요합니다. 다음 명령어를 실행하세요:" -ForegroundColor White
Write-Host ""
Write-Host "  uvx --from git+https://github.com/ai-tools-all/grep_app_mcp grep-app-mcp" -ForegroundColor Cyan
Write-Host ""
Write-Host "uv가 설치되어 있지 않다면:" -ForegroundColor DarkGray
Write-Host "  pip install uv" -ForegroundColor DarkGray
Write-Host ""

# 6. 완료 메시지
Write-Host "========================================" -ForegroundColor Green
Write-Host "  설치 완료!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "설치된 위치: $ClaudeHome" -ForegroundColor White
Write-Host ""
Write-Host "설치된 구성요소:" -ForegroundColor White
Write-Host "  - agents/     : AI 에이전트 프롬프트"
Write-Host "  - rules/      : 코딩 규칙"
Write-Host "  - hooks/      : Claude Code 훅 스크립트"
Write-Host "  - commands/   : 슬래시 명령어"
Write-Host "  - skills/     : 스킬 정의"
Write-Host "  - settings.json : Claude Code 설정"
Write-Host "  - ~/.mcp.json   : MCP 서버 설정"
Write-Host ""
Write-Host "Claude Code를 재시작하여 변경사항을 적용하세요." -ForegroundColor Yellow
Write-Host ""
