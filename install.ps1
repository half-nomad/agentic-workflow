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
    # Replace relative "hooks/" with absolute path - use forward slashes for JSON compatibility
    $hooksPathForward = $hooksPath -replace '\\', '/'
    return $JsonContent -replace '"hooks/', "`"$hooksPathForward/"
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

# Timestamped backup root for any pre-existing file we are about to overwrite.
# Installing must never destroy a file the user already had under the same name.
$BackupRoot = Join-Path $ClaudeHome ("backups/install-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
$script:BackedUp = 0

function Backup-IfExists {
    param([string]$Target)
    if (-not (Test-Path $Target -PathType Leaf)) { return }
    $rel = $Target.Substring($ClaudeHome.Length).TrimStart('\', '/')
    $dst = Join-Path $BackupRoot $rel
    New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -Force | Out-Null
    Copy-Item -Path $Target -Destination $dst -Force
    $script:BackedUp++
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
            Backup-IfExists -Target $DestFile
            Copy-Item -Path $Item.FullName -Destination $DestFile -Force
            Write-Host "    Copied: $($Item.Name)" -ForegroundColor DarkGray
        }
        return $Items.Count
    }
    return 0
}

# --- CLAUDE.md managed block + hook merge (mirrors install.sh / update.ps1) ---
$ClaudeMdBegin = '<!-- BEGIN agentic-workflow -->'
$ClaudeMdEnd   = '<!-- END agentic-workflow -->'
$ClaudeMdNote  = '<!-- Managed by agentic-workflow. Edits INSIDE this block are overwritten on update. Put your own instructions outside it, or in ~/.claude/rules/personal.md -->'

# Identity of a registered hook is the (matcher, command) PAIR, compared at the
# handler level. Keying on matcher alone silently unregisters the user's own
# hooks that happen to share a matcher. Handlers without `command`
# (http / mcp_tool / prompt / agent) fall back to their full JSON.
function Get-HookId {
    param($Handler, [string]$Matcher)
    $id = $null
    if ($Handler -and $Handler.PSObject.Properties.Name -contains 'command' -and $Handler.command) {
        $id = [string]$Handler.command
    } else {
        $id = ($Handler | ConvertTo-Json -Compress -Depth 10)
    }
    return ($Matcher + [char]1 + $id)
}

function Merge-Hooks {
    param($OldHooks, $NewHooks)

    $events = @()
    if ($OldHooks) { $events += $OldHooks.PSObject.Properties.Name }
    if ($NewHooks) { $events += $NewHooks.PSObject.Properties.Name }
    $events = @($events | Select-Object -Unique)

    $merged = [ordered]@{}
    foreach ($e in $events) {
        $oldArr = @()
        if ($OldHooks -and ($OldHooks.PSObject.Properties.Name -contains $e)) { $oldArr = @($OldHooks.$e) }
        $newArr = @()
        if ($NewHooks -and ($NewHooks.PSObject.Properties.Name -contains $e)) { $newArr = @($NewHooks.$e) }

        $newIds = New-Object 'System.Collections.Generic.HashSet[string]'
        foreach ($entry in $newArr) {
            if (-not $entry) { continue }
            $m = [string]$entry.matcher
            foreach ($h in @($entry.hooks)) {
                if ($null -eq $h) { continue }
                [void]$newIds.Add((Get-HookId -Handler $h -Matcher $m))
            }
        }

        $kept = @()
        foreach ($entry in $oldArr) {
            if (-not $entry) { continue }
            $m = [string]$entry.matcher
            $kh = @()
            foreach ($h in @($entry.hooks)) {
                if ($null -eq $h) { continue }
                if (-not $newIds.Contains((Get-HookId -Handler $h -Matcher $m))) { $kh += $h }
            }
            if ($kh.Count -gt 0) {
                $entry.hooks = @($kh)
                $kept += $entry
            }
        }
        $merged[$e] = @($kept + $newArr)
    }
    return [PSCustomObject]$merged
}

# Exactly one BEGIN, one END, BEGIN first. Any other topology is ambiguous.
function Test-ClaudeMdMarkers {
    param([string]$Path)
    if (-not (Test-Path $Path -PathType Leaf)) { return $false }
    $lines = @(Get-Content $Path)
    $nb = @($lines | Where-Object { $_ -ceq $ClaudeMdBegin }).Count
    $ne = @($lines | Where-Object { $_ -ceq $ClaudeMdEnd }).Count
    if ($nb -ne 1 -or $ne -ne 1) { return $false }
    return ([array]::IndexOf($lines, $ClaudeMdBegin) -lt [array]::IndexOf($lines, $ClaudeMdEnd))
}

function Merge-ClaudeMd {
    param([string]$Src, [string]$Dest)
    if (-not (Test-Path $Src -PathType Leaf)) { Write-Warn "CLAUDE.md source unreadable - skipped."; return $false }
    $srcLines = @(Get-Content $Src)

    $hasMarker = $false
    if (Test-Path $Dest -PathType Leaf) {
        $dl = @(Get-Content $Dest)
        $hasMarker = (@($dl | Where-Object { $_ -ceq $ClaudeMdBegin }).Count -gt 0) -or
                     (@($dl | Where-Object { $_ -ceq $ClaudeMdEnd }).Count -gt 0)
    }
    if ($hasMarker -and -not (Test-ClaudeMdMarkers $Dest)) {
        Write-Warn "CLAUDE.md markers are malformed (duplicated, reversed, or one-sided) - left untouched."
        return $false
    }

    $out = @()
    if (Test-ClaudeMdMarkers $Dest) {
        $lines = @(Get-Content $Dest)
        $bi = [array]::IndexOf($lines, $ClaudeMdBegin)
        $ei = [array]::IndexOf($lines, $ClaudeMdEnd)
        if ($bi -gt 0) { $out += $lines[0..($bi - 1)] }
        $out += $ClaudeMdBegin, $ClaudeMdNote
        $out += $srcLines
        $out += $ClaudeMdEnd
        if ($ei -lt ($lines.Count - 1)) { $out += $lines[($ei + 1)..($lines.Count - 1)] }
    }
    elseif ((Test-Path $Dest -PathType Leaf) -and (Select-String -Path $Dest -Pattern '^\*Maestro Workflow v' -Quiet)) {
        Write-Warn "CLAUDE.md looked like a pre-marker install - replaced with a managed block (see backup)."
        $out += $ClaudeMdBegin, $ClaudeMdNote
        $out += $srcLines
        $out += $ClaudeMdEnd
    }
    else {
        if (Test-Path $Dest -PathType Leaf) { $out += @(Get-Content $Dest); $out += "" }
        $out += $ClaudeMdBegin, $ClaudeMdNote
        $out += $srcLines
        $out += $ClaudeMdEnd
    }

    Set-Content -Path $Dest -Value $out -Encoding UTF8
    return $true
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

# skills/ (recursive copy)
Write-Host "  Copying skills/..."
$SkillsSource = Join-Path $SourcePath "skills"
$SkillsDest = Join-Path $ClaudeHome "skills"
if (Test-Path $SkillsSource) {
    foreach ($f in Get-ChildItem -Path $SkillsSource -Recurse -File) {
        $rel = $f.FullName.Substring($SkillsSource.Length).TrimStart('\', '/')
        Backup-IfExists -Target (Join-Path $SkillsDest $rel)
    }
    Copy-Item -Path "$SkillsSource\*" -Destination $SkillsDest -Recurse -Force
    Write-Success "skills: copy complete"
}

# CLAUDE.md - marker-delimited section, NOT whole-file overwrite. Anything the
# user wrote outside the markers survives install/update.
Write-Host "  Setting up CLAUDE.md..."
$ClaudeMdSource = Join-Path $SourcePath "CLAUDE.md"
$ClaudeMdDest = Join-Path $ClaudeHome "CLAUDE.md"

if (Test-Path $ClaudeMdSource) {
    Backup-IfExists -Target $ClaudeMdDest
    if (Merge-ClaudeMd -Src $ClaudeMdSource -Dest $ClaudeMdDest) {
        Write-Success "CLAUDE.md section synced (content outside markers preserved)"
    }
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
            # v4.1.1 supply-chain: revoke stale wildcard allows (superseded by run/test subset + ask)
            $RevokedPermissions = @("Bash(npm:*)", "Bash(npx:*)", "Bash(pnpm:*)", "Bash(yarn:*)")
            $ExistingSettings.permissions.allow = @($AllPermissions | Where-Object { $RevokedPermissions -notcontains $_ })
        }

        # Merge permissions.ask (union)
        if ($NewSettings.permissions -and $NewSettings.permissions.ask) {
            if (-not $ExistingSettings.permissions.ask) {
                $ExistingSettings.permissions | Add-Member -NotePropertyName "ask" -NotePropertyValue @() -Force
            }
            $ExistingSettings.permissions.ask = @(@($ExistingSettings.permissions.ask) + @($NewSettings.permissions.ask) | Select-Object -Unique)
        }

        # Merge hooks per event, keyed on the (matcher, command) pair at the
        # handler level. The previous rule removed every existing entry sharing a
        # matcher, which silently unregistered the user's own hooks.
        if ($NewSettings.hooks) {
            $MergedHooks = Merge-Hooks -OldHooks $ExistingSettings.hooks -NewHooks $NewSettings.hooks
            $ExistingSettings | Add-Member -NotePropertyName "hooks" -NotePropertyValue $MergedHooks -Force
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
Write-Host "  - skills/     : Slash commands & skills"
Write-Host "  - settings.json : Claude Code settings"
Write-Host "  - ~/.mcp.json   : MCP server settings"
Write-Host ""
Write-Host "Restart Claude Code to apply changes." -ForegroundColor Yellow
Write-Host ""
