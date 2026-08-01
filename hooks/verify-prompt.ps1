# verify-prompt.ps1
# PostToolUse hook: After Agent tool returns, inject verification reminder
# Input: JSON on stdin from Claude Code
# Output: stdout text injected as context to Claude

$input = [Console]::In.ReadToEnd() | ConvertFrom-Json -ErrorAction SilentlyContinue
if (-not $input) { exit 0 }

$toolName = $input.tool_name
$projectDir = $env:CLAUDE_PROJECT_DIR

if ($toolName -eq "Agent") {
    $stateFile = Join-Path $projectDir ".agentic/maestro-mode.state"
    if (Test-Path $stateFile) {
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
