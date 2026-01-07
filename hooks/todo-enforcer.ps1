# TODO Enforcer Hook
# Checks for incomplete TODOs and prompts continuation
# Integrates with Ralph Loop state for coordinated behavior

# Check Ralph Loop state first
$stateDir = ".agentic"
$ralphStateFile = Join-Path $stateDir "ralph-loop.state.md"
$modeFile = Join-Path $stateDir "mode.txt"

# Determine current mode
$currentMode = "manual"
if (Test-Path $modeFile) {
    $currentMode = (Get-Content $modeFile -Raw).Trim()
}

# Check if Ralph Loop is active
$ralphActive = $false
if (Test-Path $ralphStateFile) {
    $stateContent = Get-Content $ralphStateFile -Raw
    if ($stateContent -match "active:\s*true") {
        $ralphActive = $true
    }
}

# In manual mode with no Ralph Loop, be advisory only
if ($currentMode -eq "manual" -and -not $ralphActive) {
    $sessionDir = if ($env:CLAUDE_SESSION_DIR) { $env:CLAUDE_SESSION_DIR } else { ".agentic" }
    $todoFile = "$sessionDir\todos.json"
    if (Test-Path $todoFile) {
        $todos = Get-Content $todoFile | ConvertFrom-Json
        $pending = ($todos | Where-Object { $_.status -eq "pending" -or $_.status -eq "in_progress" }).Count

        if ($pending -gt 0) {
            Write-Output @"
[SESSION CHECK - Manual Mode]

Note: $pending task(s) still in progress.
Review pending tasks before ending session.
"@
        }
    }
    exit 0
}

# For semi-auto and ultrawork modes, enforce TODO completion
$sessionDir = if ($env:CLAUDE_SESSION_DIR) { $env:CLAUDE_SESSION_DIR } else { ".agentic" }
$todoFile = "$sessionDir\todos.json"

if (Test-Path $todoFile) {
    $todos = Get-Content $todoFile | ConvertFrom-Json
    $pending = @($todos | Where-Object { $_.status -eq "pending" })
    $inProgress = @($todos | Where-Object { $_.status -eq "in_progress" })
    $completed = @($todos | Where-Object { $_.status -eq "completed" })

    $pendingCount = $pending.Count
    $inProgressCount = $inProgress.Count
    $completedCount = $completed.Count
    $totalCount = $todos.Count

    if (($pendingCount + $inProgressCount) -gt 0) {
        # Build task summary
        $taskSummary = ""
        if ($inProgressCount -gt 0) {
            $taskSummary += "`nIN PROGRESS:`n"
            foreach ($task in $inProgress) {
                $taskSummary += "  - $($task.content)`n"
            }
        }
        if ($pendingCount -gt 0) {
            $taskSummary += "`nPENDING:`n"
            foreach ($task in $pending | Select-Object -First 5) {
                $taskSummary += "  - $($task.content)`n"
            }
            if ($pendingCount -gt 5) {
                $taskSummary += "  ... and $($pendingCount - 5) more`n"
            }
        }

        Write-Output @"
[TODO CONTINUATION REQUIRED]

Progress: $completedCount/$totalCount completed
Remaining: $($pendingCount + $inProgressCount) task(s)
$taskSummary
INSTRUCTIONS:
- Complete all in-progress tasks first
- Then work through pending tasks
- Mark each task as completed when done
- If blocked, document the issue and consult @architect

Mode: $currentMode
$(if ($ralphActive) { "Ralph Loop: ACTIVE - Will auto-continue" } else { "Ralph Loop: INACTIVE" })
"@
    }
    else {
        # All tasks complete
        Write-Output @"
[ALL TASKS COMPLETE]

Total completed: $completedCount tasks

$(if ($ralphActive) { "Ready to output: <promise>DONE</promise>" })
"@
    }
}
else {
    # No todo file exists
    if ($currentMode -ne "manual") {
        Write-Output @"
[SESSION CHECK]

No TODO list found. If work is incomplete:
1. Create a TODO list to track remaining tasks
2. Or confirm all requested work is complete

$(if ($ralphActive) { "Ralph Loop active - ensure <promise>DONE</promise> is output when complete" })
"@
    }
}
