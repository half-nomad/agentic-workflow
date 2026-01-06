# Ralph Loop - Stop Event Handler
# Monitors for completion promise and triggers continuation
# Based on oh-my-opencode's Sisyphus automation pattern

param(
    [string]$AssistantResponse = $(if ($env:ASSISTANT_RESPONSE) { $env:ASSISTANT_RESPONSE } else { "" }),
    [string]$StopReason = $(if ($env:STOP_REASON) { $env:STOP_REASON } else { "" })
)

# State file path
$stateDir = ".agentic"
$stateFile = Join-Path $stateDir "ralph-loop.state.md"

# Exit if state file doesn't exist (Ralph Loop not active)
if (-not (Test-Path $stateFile)) {
    exit 0
}

# Parse state file
$stateContent = Get-Content $stateFile -Raw
$yamlMatch = [regex]::Match($stateContent, "---\s*\n([\s\S]*?)\n---")

if (-not $yamlMatch.Success) {
    Write-Output "[RALPH ERROR] Invalid state file format"
    exit 1
}

$yamlContent = $yamlMatch.Groups[1].Value

# Parse YAML frontmatter
$active = $false
$iteration = 1
$maxIterations = 50
$completionPromise = "DONE"
$mode = "ultrawork"

foreach ($line in $yamlContent -split "`n") {
    if ($line -match "^active:\s*(.+)$") {
        $active = $matches[1].Trim() -eq "true"
    }
    elseif ($line -match "^iteration:\s*(\d+)$") {
        $iteration = [int]$matches[1]
    }
    elseif ($line -match "^max_iterations:\s*(\d+)$") {
        $maxIterations = [int]$matches[1]
    }
    elseif ($line -match "^completion_promise:\s*[`"']?(.+?)[`"']?$") {
        $completionPromise = $matches[1].Trim()
    }
    elseif ($line -match "^mode:\s*[`"']?(.+?)[`"']?$") {
        $mode = $matches[1].Trim()
    }
}

# Exit if not active
if (-not $active) {
    exit 0
}

# Check for completion promise in assistant response
$promisePattern = "<promise>$completionPromise</promise>"
$hasPromise = $AssistantResponse -match [regex]::Escape($promisePattern)

# Also check for Korean completion keywords
$koreanComplete = $AssistantResponse -match "(작업\s*완료|모든\s*작업.*완료|DONE|완료했습니다)"

if ($hasPromise -or $koreanComplete) {
    # Task completed - deactivate Ralph Loop
    $newContent = $stateContent -replace "active:\s*true", "active: false"
    $newContent | Set-Content $stateFile -Encoding UTF8

    Write-Output @"

[RALPH LOOP COMPLETE]
Iteration: $iteration
Promise detected: $promisePattern
Ralph Loop has been deactivated.

"@
    exit 0
}

# Check iteration limit
if ($iteration -ge $maxIterations) {
    # Max iterations reached - deactivate
    $newContent = $stateContent -replace "active:\s*true", "active: false"
    $newContent | Set-Content $stateFile -Encoding UTF8

    Write-Output @"

[RALPH LOOP LIMIT REACHED]
Maximum iterations ($maxIterations) exceeded.
Ralph Loop has been forcefully terminated.
Please review progress and restart if needed with /ralph-start

"@
    exit 0
}

# Increment iteration and update state file
$newIteration = $iteration + 1
$newContent = $stateContent -replace "iteration:\s*\d+", "iteration: $newIteration"
$newContent | Set-Content $stateFile -Encoding UTF8

# Extract original request (everything after the YAML frontmatter)
$requestMatch = [regex]::Match($stateContent, "---\s*\n[\s\S]*?\n---\s*\n([\s\S]*)")
$originalRequest = if ($requestMatch.Success) { $requestMatch.Groups[1].Value.Trim() } else { "Continue previous task" }

# Output continuation prompt
Write-Output @"

[RALPH LOOP CONTINUATION - Iteration $newIteration/$maxIterations]

The task is not yet complete. Continue working until you can output:
<promise>$completionPromise</promise>

ORIGINAL REQUEST:
$originalRequest

INSTRUCTIONS:
1. Review what has been accomplished so far
2. Check remaining TODO items
3. Continue executing pending tasks
4. ONLY output <promise>$completionPromise</promise> when ALL work is truly complete
5. If stuck, try alternative approaches or consult @architect

DO NOT STOP until the promise can be fulfilled.

"@
