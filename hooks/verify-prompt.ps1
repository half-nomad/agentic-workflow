# verify-prompt.ps1
# PostToolUse hook: After Agent tool returns, inject verification reminder
# Input: JSON on stdin from Claude Code
# Output: stdout text injected as context to Claude

# Read stdin the way maestro-guard.ps1 does. This hook used to assign to `$input` — a
# reserved automatic variable — and emitted nothing at all (measured 2026-09-28 with pwsh 7:
# state file present + uncommitted diff -> no output).
$stdinReader = New-Object System.IO.StreamReader([Console]::OpenStandardInput())
$payload = $stdinReader.ReadToEnd() | ConvertFrom-Json -ErrorAction SilentlyContinue
if (-not $payload) { exit 0 }

# 세션별 상태 파일 — maestro-guard.ps1 의 Test-MaestroActive 와 같은 판정 (근거는 maestro-guard.sh).
function Test-MaestroActive($payload) {
    $root = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
    $dir = Join-Path $root ".agentic/maestro"
    $sid = $env:CLAUDE_CODE_SESSION_ID
    if (-not $sid -and $payload) { $sid = [string]$payload.session_id }
    if ($sid -notmatch '^[A-Za-z0-9_-]+$') { $sid = "" }
    if (Test-Path -LiteralPath (Join-Path $dir "unknown.state")) { return $true }
    if ($sid) { return (Test-Path -LiteralPath (Join-Path $dir "$sid.state")) }
    return [bool](Get-ChildItem -LiteralPath $dir -Filter *.state -File -ErrorAction SilentlyContinue)
}

$toolName = $payload.tool_name
$projectDir = $env:CLAUDE_PROJECT_DIR

if ($toolName -eq "Agent") {
    if (Test-MaestroActive $payload) {
        # Emit INFORMATION, not exhortation. What the orchestrator cannot get for
        # free is "what did that agent actually change" - a tool call it would
        # otherwise have to spend. Reminders to run tests and check success
        # criteria are already binding in rules/maestro-workflow.md (5b output
        # contract, Result Integration); repeating them after every single Agent
        # return is noise that trains the reader to skim past this block.
        $diffStat = git -C $projectDir diff --stat 2>$null
        if ($diffStat) {
            Write-Output "[VERIFY] Agent completed. Uncommitted changes in the worktree:"
            Write-Output $diffStat
            Write-Output ""
        }
    }
}

exit 0
