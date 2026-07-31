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
        # Run git diff stat
        $diffStat = git -C $projectDir diff --stat 2>$null
        if ($diffStat) {
            Write-Output "[VERIFY] Agent completed. Changed files:"
            Write-Output $diffStat
            Write-Output ""
        }

        # Check for test runner
        $hasTests = $false
        if (Test-Path (Join-Path $projectDir "package.json")) { $hasTests = $true }
        if (Test-Path (Join-Path $projectDir "pytest.ini")) { $hasTests = $true }
        if (Test-Path (Join-Path $projectDir "pyproject.toml")) { $hasTests = $true }

        if ($hasTests) {
            Write-Output "[VERIFY] Test suite detected. Run tests before marking complete."
        }

        Write-Output "[VERIFY] Review changes against success criteria before proceeding."
    }
}

exit 0
