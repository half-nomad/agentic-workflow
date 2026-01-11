#Requires -Version 5.1
<#
.SYNOPSIS
    Agentic Workflow Installation Script (Windows PowerShell)
.DESCRIPTION
    Installs agentic-workflow configuration files to ~/.claude/ directory for Claude Code.
.EXAMPLE
    .\install.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Step { param($Message) Write-Host "[*] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[+] $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[!] $Message" -ForegroundColor Yellow }
function Write-Err { param($Message) Write-Host "[-] $Message" -ForegroundColor Red }

# Convert hooks path: Convert relative path "hooks/" to absolute path
function Convert-HooksPath {
    param([string]$JsonContent)
    $hooksPath = Join-Path $env:USERPROFILE ".claude\hooks"
    # Convert to escaped backslashes for JSON
    $escaped = $hooksPath -replace '\\', '\\\\'
    return $JsonContent -replace '"hooks/', "`"$escaped\\"
}

# Path setup
$SourcePath = $PSScriptRoot
$ClaudeHome = Join-Path $env:USERPROFILE ".claude"

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  Agentic Workflow Installer (Windows)" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

# 1. Save project source path
Write-Step "Saving project source path..."

if (-not (Test-Path $ClaudeHome)) {
    New-Item -ItemType Directory -Path $ClaudeHome -Force | Out-Null
}

$SourceFilePath = Join-Path $ClaudeHome ".agentic-workflow-source"
$SourcePath | Out-File -FilePath $SourceFilePath -Encoding UTF8 -NoNewline
Write-Success "Source path saved: $SourceFilePath"

# 2. Create directories
Write-Step "Creating directories..."

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
        Write-Success "Created: $Dir"
    } else {
        Write-Host "    Already exists: $Dir" -ForegroundColor DarkGray
    }
}

# 3. File copy function
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
            Write-Host "    Copied: $($Item.Name)" -ForegroundColor DarkGray
        }
        return $Items.Count
    }
    return 0
}

# Copy files
Write-Step "Copying files..."

# agents/
Write-Host "  Copying agents/..."
$count = Copy-DirectoryContents -Source (Join-Path $SourcePath "agents") -Destination (Join-Path $ClaudeHome "agents")
Write-Success "agents: $count files copied"

# rules/
Write-Host "  Copying rules/..."
$count = Copy-DirectoryContents -Source (Join-Path $SourcePath "rules") -Destination (Join-Path $ClaudeHome "rules")
Write-Success "rules: $count files copied"

# hooks/
Write-Host "  Copying hooks/..."
$count = Copy-DirectoryContents -Source (Join-Path $SourcePath "hooks") -Destination (Join-Path $ClaudeHome "hooks")
Write-Success "hooks: $count files copied"

# commands/
Write-Host "  Copying commands/..."
$count = Copy-DirectoryContents -Source (Join-Path $SourcePath "commands") -Destination (Join-Path $ClaudeHome "commands")
Write-Success "commands: $count files copied"

# skills/ (recursive copy)
Write-Host "  Copying skills/..."
$SkillsSource = Join-Path $SourcePath "skills"
$SkillsDest = Join-Path $ClaudeHome "skills"
if (Test-Path $SkillsSource) {
    Copy-Item -Path "$SkillsSource\*" -Destination $SkillsDest -Recurse -Force
    Write-Success "skills: copy complete"
}

# CLAUDE.md
Write-Host "  Setting up CLAUDE.md..."
$ClaudeMdSource = Join-Path $SourcePath "CLAUDE.md"
$ClaudeMdDest = Join-Path $ClaudeHome "CLAUDE.md"

if (Test-Path $ClaudeMdSource) {
    if (Test-Path $ClaudeMdDest) {
        $BackupPath = "$ClaudeMdDest.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item -Path $ClaudeMdDest -Destination $BackupPath -Force
        Write-Warn "Existing CLAUDE.md backed up: $BackupPath"
    }
    Copy-Item -Path $ClaudeMdSource -Destination $ClaudeMdDest -Force
    Write-Success "CLAUDE.md copied (Maestro workflow)"
} else {
    Write-Host "    CLAUDE.md not found (skipping)" -ForegroundColor DarkGray
}

# 4. Merge configuration files
Write-Step "Merging configuration files..."

# Merge settings.json
$SettingsSource = Join-Path $SourcePath "settings.json"
$SettingsDest = Join-Path $ClaudeHome "settings.json"

if (Test-Path $SettingsSource) {
    # Read source file and convert hooks path
    $SourceContent = Get-Content -Path $SettingsSource -Raw
    $SourceContent = Convert-HooksPath -JsonContent $SourceContent
    $NewSettings = $SourceContent | ConvertFrom-Json

    if (Test-Path $SettingsDest) {
        $ExistingSettings = Get-Content -Path $SettingsDest -Raw | ConvertFrom-Json

        # Merge permissions
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

        # Merge hooks: merge arrays per event type
        if ($NewSettings.hooks) {
            if (-not $ExistingSettings.hooks) {
                $ExistingSettings | Add-Member -NotePropertyName "hooks" -NotePropertyValue @{} -Force
            }

            # Iterate through each event type (UserPromptSubmit, PostToolUse, Stop, etc.)
            foreach ($EventType in $NewSettings.hooks.PSObject.Properties) {
                $EventName = $EventType.Name
                $NewHooksArray = @($EventType.Value)

                if ($ExistingSettings.hooks.PSObject.Properties[$EventName]) {
                    # If event exists, merge arrays (no deduplication)
                    $ExistingHooksArray = @($ExistingSettings.hooks.$EventName)
                    $MergedArray = $ExistingHooksArray + $NewHooksArray
                    $ExistingSettings.hooks.$EventName = $MergedArray
                } else {
                    # If event doesn't exist, add new
                    $ExistingSettings.hooks | Add-Member -NotePropertyName $EventName -NotePropertyValue $NewHooksArray -Force
                }
            }
        }

        $ExistingSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $SettingsDest -Encoding UTF8
        Write-Success "settings.json merged"
    } else {
        # New file: save with path conversion applied
        $NewSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $SettingsDest -Encoding UTF8
        Write-Success "settings.json copied (new file)"
    }
}

# Merge .mcp.json
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
        Write-Success ".mcp.json merged: $McpDest"
    } else {
        Copy-Item -Path $McpSource -Destination $McpDest -Force
        Write-Success ".mcp.json copied (new file): $McpDest"
    }
}

# 5. MCP installation guide
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  MCP Tools Installation Guide" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "grep_app_mcp installation required. Run the following command:" -ForegroundColor White
Write-Host ""
Write-Host "  uvx --from git+https://github.com/ai-tools-all/grep_app_mcp grep-app-mcp" -ForegroundColor Cyan
Write-Host ""
Write-Host "If uv is not installed:" -ForegroundColor DarkGray
Write-Host "  pip install uv" -ForegroundColor DarkGray
Write-Host ""

# 6. Completion message
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installation location: $ClaudeHome" -ForegroundColor White
Write-Host ""
Write-Host "Installed components:" -ForegroundColor White
Write-Host "  - agents/     : AI agent prompts"
Write-Host "  - rules/      : Coding rules"
Write-Host "  - hooks/      : Claude Code hook scripts"
Write-Host "  - commands/   : Slash commands"
Write-Host "  - skills/     : Skill definitions"
Write-Host "  - settings.json : Claude Code settings"
Write-Host "  - ~/.mcp.json   : MCP server settings"
Write-Host ""
Write-Host "Restart Claude Code to apply changes." -ForegroundColor Yellow
Write-Host ""
