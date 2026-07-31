<#
.SYNOPSIS
    Agentic Workflow Update Script (Windows PowerShell)
.DESCRIPTION
    Syncs changed files from source path to ~/.claude/.
    Mirrors update.sh: user-owned files are backed up before being overwritten,
    user hooks survive the settings merge, and the global CLAUDE.md is merged as
    a marker-delimited block instead of being replaced wholesale.
#>

param([switch]$Verbose)

$ErrorActionPreference = "Stop"

function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }

$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$SourceFile = Join-Path $ClaudeDir ".agentic-workflow-source"

# --- CLAUDE.md managed block (mirrors update.sh) -----------------------------
# The global CLAUDE.md is shared: this repo owns one section, the user owns the
# rest. Only the text between the markers is rewritten. HTML comments are
# stripped before CLAUDE.md reaches Claude's context, so markers cost no tokens.
$ClaudeMdBegin = '<!-- BEGIN agentic-workflow -->'
$ClaudeMdEnd   = '<!-- END agentic-workflow -->'
$ClaudeMdNote  = '<!-- Managed by agentic-workflow. Edits INSIDE this block are overwritten on update. Put your own instructions outside it, or in ~/.claude/rules/personal.md -->'

# Timestamped backup root. Syncing must never destroy a file the user already had
# under the same name (their own agent/rule/hook/skill, or local edits).
$BackupRoot = Join-Path $ClaudeDir ("backups/update-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
$script:BackedUp = 0

function Backup-IfDiffers {
    param([string]$Target, [string]$Source)
    if (-not (Test-Path $Target -PathType Leaf)) { return }
    if ($Source -and (Test-Path $Source -PathType Leaf)) {
        if ((Get-FileHash $Target).Hash -eq (Get-FileHash $Source).Hash) { return }  # identical - nothing to lose
    }
    $rel = $Target.Substring($ClaudeDir.Length).TrimStart('\', '/')
    $dst = Join-Path $BackupRoot $rel
    New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -Force | Out-Null
    Copy-Item -Path $Target -Destination $dst -Force
    $script:BackedUp++
}

# Identity of a registered hook is the (matcher, command) PAIR, compared at the
# handler level. Replacing the whole hooks object - or keying on matcher alone -
# silently unregisters the user's own hooks. Handlers without `command`
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

# Exactly one BEGIN, one END, BEGIN first. Any other topology (duplicate, nested,
# reversed, one-sided) is ambiguous - we must not guess which span is ours.
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
        Write-Warn "CLAUDE.md markers are malformed (duplicated, reversed, or one-sided)."
        Write-Warn "Left untouched. Fix the BEGIN/END pair by hand, then re-run."
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
        # Migration from a pre-marker install. Those installs overwrote the whole
        # file, so a file carrying our footer but no markers IS our old content.
        # Appending would ship the workflow twice; the pre-write backup holds
        # anything the user had added by hand.
        Write-Warn "CLAUDE.md looked like a pre-marker install - replaced with a managed block."
        Write-Warn "Any hand-written additions are in the backup listed at the end of this run."
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
            Backup-IfDiffers -Target $DestFile -Source $File.FullName
            Copy-Item -Path $File.FullName -Destination $DestFile -Force
            $SyncCount++

            if ($Verbose) { Write-Host "  -> $Dir/$RelativePath" -ForegroundColor DarkGray }
        }

        Write-Success "$Dir/ ($($Files.Count) files)"
    } else {
        Write-Warn "$Dir/ directory not found - skipping"
    }
}

# CLAUDE.md - managed block only (the user owns everything outside the markers).
# Replaces the old CLAUDE.global.md branch, which could never work as intended:
# a personal-content file cannot live in a public repo.
$SrcMd = Join-Path $SourcePath "CLAUDE.md"
$DestMd = Join-Path $ClaudeDir "CLAUDE.md"
if (Test-Path $SrcMd) {
    Backup-IfDiffers -Target $DestMd -Source $SrcMd
    if (Merge-ClaudeMd -Src $SrcMd -Dest $DestMd) {
        $SyncCount++
        Write-Success "CLAUDE.md section synced (content outside markers preserved)"
    }
}

Write-Host ""
Write-Info "Merging config files..."

# settings.json
$SrcSettings = Join-Path $SourcePath "settings.json"
$DestSettings = Join-Path $ClaudeDir "settings.json"
if (Test-Path $SrcSettings) {
    $SrcJson = Get-Content $SrcSettings -Raw | ConvertFrom-Json
    if (Test-Path $DestSettings) {
        Backup-IfDiffers -Target $DestSettings -Source $SrcSettings
        $DestJson = Get-Content $DestSettings -Raw | ConvertFrom-Json

        # Scalar/object settings from the repo win; hooks and permissions merge.
        foreach ($p in $SrcJson.PSObject.Properties) {
            if ($p.Name -eq 'hooks' -or $p.Name -eq 'permissions') { continue }
            $DestJson | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force
        }

        $MergedHooks = Merge-Hooks -OldHooks $DestJson.hooks -NewHooks $SrcJson.hooks
        $DestJson | Add-Member -NotePropertyName "hooks" -NotePropertyValue $MergedHooks -Force

        # permissions: union, minus the broad npm wildcards the repo must not force.
        $Broad = @("Bash(npm:*)", "Bash(npx:*)", "Bash(pnpm:*)", "Bash(yarn:*)")
        $Allow = @()
        if ($DestJson.permissions -and $DestJson.permissions.allow) { $Allow += $DestJson.permissions.allow }
        if ($SrcJson.permissions -and $SrcJson.permissions.allow) { $Allow += $SrcJson.permissions.allow }
        $Allow = @($Allow | Select-Object -Unique | Where-Object { $Broad -notcontains $_ })
        $Ask = @()
        if ($DestJson.permissions -and $DestJson.permissions.ask) { $Ask += $DestJson.permissions.ask }
        if ($SrcJson.permissions -and $SrcJson.permissions.ask) { $Ask += $SrcJson.permissions.ask }
        $Ask = @($Ask | Select-Object -Unique)

        if (-not $DestJson.permissions) { $DestJson | Add-Member -NotePropertyName "permissions" -NotePropertyValue ([PSCustomObject]@{}) -Force }
        $DestJson.permissions | Add-Member -NotePropertyName "allow" -NotePropertyValue $Allow -Force
        $DestJson.permissions | Add-Member -NotePropertyName "ask" -NotePropertyValue $Ask -Force

        $DestJson | ConvertTo-Json -Depth 10 | Set-Content $DestSettings -Encoding UTF8
    } else {
        Copy-Item -Path $SrcSettings -Destination $DestSettings -Force
    }
    $SyncCount++
    Write-Success "settings.json merged (per-hook merge; user hooks preserved)"
}

# .mcp.json
$SrcMcp = Join-Path $SourcePath ".mcp.json"
$DestMcp = Join-Path $env:USERPROFILE ".mcp.json"
if (Test-Path $SrcMcp) {
    $SrcMcpJson = Get-Content $SrcMcp -Raw | ConvertFrom-Json
    if (Test-Path $DestMcp) {
        $DestMcpJson = Get-Content $DestMcp -Raw | ConvertFrom-Json
        if ($SrcMcpJson.mcpServers) {
            if (-not $DestMcpJson.mcpServers) { $DestMcpJson | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue ([PSCustomObject]@{}) -Force }
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
if ($script:BackedUp -gt 0) {
    Write-Host "Overwritten files backed up ($script:BackedUp): $BackupRoot" -ForegroundColor Yellow
}
Write-Host "Target path: $ClaudeDir" -ForegroundColor DarkGray
Write-Host ""
