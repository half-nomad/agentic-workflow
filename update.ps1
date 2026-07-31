<#
.SYNOPSIS
    Agentic Workflow Update Script (Windows PowerShell)
.DESCRIPTION
    Syncs changed files from source path to ~/.claude/.
#>

param([switch]$Verbose)

$ErrorActionPreference = "Stop"

function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }

$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$SourceFile = Join-Path $ClaudeDir ".agentic-workflow-source"

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  Agentic Workflow Updater" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

if (-not (Test-Path $SourceFile)) {
    Write-Host "[-] Installation info not found." -ForegroundColor Red
    Write-Host "Run install.ps1 script first." -ForegroundColor Yellow
    exit 1
}

$SourcePath = (Get-Content $SourceFile -Raw).Trim()
Write-Info "Source path: $SourcePath"

if (-not (Test-Path $SourcePath)) {
    Write-Host "[-] Source path does not exist: $SourcePath" -ForegroundColor Red
    exit 1
}

Write-Success "Source path verified"

$SyncCount = 0
$Directories = @("agents", "rules", "hooks", "commands", "skills")

Write-Host ""
Write-Info "Syncing directories..."

foreach ($Dir in $Directories) {
    $SrcDir = Join-Path $SourcePath $Dir
    $DestDir = Join-Path $ClaudeDir $Dir

    if (Test-Path $SrcDir) {
        if (-not (Test-Path $DestDir)) { New-Item -ItemType Directory -Path $DestDir -Force | Out-Null }

        $Files = Get-ChildItem -Path $SrcDir -Recurse -File
        foreach ($File in $Files) {
            $RelativePath = $File.FullName.Substring($SrcDir.Length + 1)
            $DestFile = Join-Path $DestDir $RelativePath
            $DestFileDir = Split-Path $DestFile -Parent

            if (-not (Test-Path $DestFileDir)) { New-Item -ItemType Directory -Path $DestFileDir -Force | Out-Null }
            Copy-Item -Path $File.FullName -Destination $DestFile -Force
            $SyncCount++

            if ($Verbose) { Write-Host "  -> $Dir/$RelativePath" -ForegroundColor DarkGray }
        }

        Write-Success "$Dir/ ($($Files.Count) files)"
    } else {
        Write-Warn "$Dir/ directory not found - skipping"
    }
}

# CLAUDE.global.md -> CLAUDE.md
$GlobalMd = Join-Path $SourcePath "CLAUDE.global.md"
$DestMd = Join-Path $ClaudeDir "CLAUDE.md"

if (Test-Path $GlobalMd) {
    Copy-Item -Path $GlobalMd -Destination $DestMd -Force
    $SyncCount++
    Write-Success "CLAUDE.md updated"
}

Write-Host ""
Write-Info "Merging config files..."

# settings.json
$SrcSettings = Join-Path $SourcePath "settings.json"
$DestSettings = Join-Path $ClaudeDir "settings.json"
if (Test-Path $SrcSettings) {
    $SrcJson = Get-Content $SrcSettings -Raw | ConvertFrom-Json
    if (Test-Path $DestSettings) {
        $DestJson = Get-Content $DestSettings -Raw | ConvertFrom-Json
        if ($SrcJson.hooks) { $DestJson | Add-Member -NotePropertyName "hooks" -NotePropertyValue $SrcJson.hooks -Force }
        $DestJson | ConvertTo-Json -Depth 10 | Set-Content $DestSettings -Encoding UTF8
    } else {
        Copy-Item -Path $SrcSettings -Destination $DestSettings -Force
    }
    $SyncCount++
    Write-Success "settings.json merged"
}

# .mcp.json
$SrcMcp = Join-Path $SourcePath ".mcp.json"
$DestMcp = Join-Path $env:USERPROFILE ".mcp.json"
if (Test-Path $SrcMcp) {
    $SrcMcpJson = Get-Content $SrcMcp -Raw | ConvertFrom-Json
    if (Test-Path $DestMcp) {
        $DestMcpJson = Get-Content $DestMcp -Raw | ConvertFrom-Json
        if ($SrcMcpJson.mcpServers) {
            if (-not $DestMcpJson.mcpServers) { $DestMcpJson | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue @{} -Force }
            $SrcMcpJson.mcpServers.PSObject.Properties | ForEach-Object { $DestMcpJson.mcpServers | Add-Member -NotePropertyName $_.Name -NotePropertyValue $_.Value -Force }
        }
        $DestMcpJson | ConvertTo-Json -Depth 10 | Set-Content $DestMcp -Encoding UTF8
    } else {
        Copy-Item -Path $SrcMcp -Destination $DestMcp -Force
    }
    $SyncCount++
    Write-Success ".mcp.json merged"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Update Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Items synced: $SyncCount" -ForegroundColor Cyan
Write-Host "Target path: $ClaudeDir" -ForegroundColor DarkGray
Write-Host ""
