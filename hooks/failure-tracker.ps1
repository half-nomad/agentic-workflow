# Failure Tracker Hook
# Detects repeated failures and triggers recovery strategies
# Integrates with Ralph Loop for automated recovery

param(
    [string]$ToolName = $(if ($env:TOOL_NAME) { $env:TOOL_NAME } else { "" }),
    [string]$ToolOutput = $(if ($env:TOOL_OUTPUT) { $env:TOOL_OUTPUT } else { "" }),
    [string]$ToolInput = $(if ($env:TOOL_INPUT) { $env:TOOL_INPUT } else { "" })
)

# State directory
$stateDir = ".agentic"
$failureFile = Join-Path $stateDir "failure-log.json"

# Ensure state directory exists
if (-not (Test-Path $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}

# Initialize or load failure log
$failureLog = @{
    failures = @()
    consecutive_failures = 0
    last_failure_time = $null
    recovery_attempts = 0
}

if (Test-Path $failureFile) {
    try {
        $failureLog = Get-Content $failureFile -Raw | ConvertFrom-Json -AsHashtable
    }
    catch {
        # Reset on parse error
    }
}

# Detect failure patterns
$isFailure = $false
$failureType = ""
$failureDetails = ""

# Check for common failure patterns
if ($ToolOutput -match "(error|Error|ERROR|failed|Failed|FAILED)") {
    $isFailure = $true
    $failureType = "error"
    $failureDetails = $ToolOutput | Select-String -Pattern "(?i)(error|exception|failed)[^\n]*" -AllMatches |
        ForEach-Object { $_.Matches.Value } | Select-Object -First 3 | Join-String -Separator "; "
}
elseif ($ToolOutput -match "(not found|NotFound|cannot find|doesn't exist|does not exist)") {
    $isFailure = $true
    $failureType = "not_found"
    $failureDetails = "Resource not found"
}
elseif ($ToolOutput -match "(permission denied|access denied|unauthorized)") {
    $isFailure = $true
    $failureType = "permission"
    $failureDetails = "Permission or access issue"
}
elseif ($ToolOutput -match "(timeout|timed out|connection refused)") {
    $isFailure = $true
    $failureType = "timeout"
    $failureDetails = "Connection or timeout issue"
}

# Check for Edit tool specific failures
if ($ToolName -eq "Edit" -and $ToolOutput -match "(old_string not found|no match|string not unique)") {
    $isFailure = $true
    $failureType = "edit_mismatch"
    $failureDetails = "Edit target string not found or not unique"
}

# Check for Bash exit code failures
if ($ToolName -eq "Bash" -and $ToolOutput -match "exit code [1-9]") {
    $isFailure = $true
    $failureType = "command_failure"
    $failureDetails = "Command exited with non-zero status"
}

if ($isFailure) {
    # Record failure
    $failureEntry = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        tool = $ToolName
        type = $failureType
        details = $failureDetails
        input_summary = if ($ToolInput.Length -gt 200) { $ToolInput.Substring(0, 200) + "..." } else { $ToolInput }
    }

    $failureLog.failures += $failureEntry
    $failureLog.consecutive_failures++
    $failureLog.last_failure_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

    # Keep only last 20 failures
    if ($failureLog.failures.Count -gt 20) {
        $failureLog.failures = $failureLog.failures | Select-Object -Last 20
    }

    # Save failure log
    $failureLog | ConvertTo-Json -Depth 10 | Set-Content $failureFile -Encoding UTF8

    # Determine recovery strategy based on consecutive failures
    $recoveryMessage = ""

    if ($failureLog.consecutive_failures -ge 3) {
        $failureLog.recovery_attempts++

        $recoveryMessage = @"

[FAILURE PATTERN DETECTED - Recovery Strategy Required]

Consecutive Failures: $($failureLog.consecutive_failures)
Failure Type: $failureType
Recovery Attempt: $($failureLog.recovery_attempts)

RECOMMENDED ACTIONS:
"@

        switch ($failureType) {
            "edit_mismatch" {
                $recoveryMessage += @"

1. Re-read the target file to get current content
2. Verify the exact string to match (check whitespace, indentation)
3. Use a longer, more unique old_string
4. Consider using Write tool if edit keeps failing
"@
            }
            "not_found" {
                $recoveryMessage += @"

1. Use Glob to find the correct file path
2. Verify the project structure
3. Check for typos in file/directory names
4. Consider if the resource needs to be created first
"@
            }
            "command_failure" {
                $recoveryMessage += @"

1. Check command syntax and arguments
2. Verify required tools are installed
3. Check working directory context
4. Try alternative commands
"@
            }
            "permission" {
                $recoveryMessage += @"

1. Check file/directory permissions
2. Verify you have write access
3. Consider if elevated permissions are needed
"@
            }
            default {
                $recoveryMessage += @"

1. Review the error message carefully
2. Try a different approach
3. Consult @architect for alternative strategies
4. Break down the task into smaller steps
"@
            }
        }

        if ($failureLog.consecutive_failures -ge 5) {
            $recoveryMessage += @"


[CRITICAL] 5+ consecutive failures detected.
Consider: /ralph-cancel to stop automation and review manually.
Or: Consult @architect for a completely different approach.
"@
        }

        Write-Output $recoveryMessage

        # Save updated recovery attempts
        $failureLog | ConvertTo-Json -Depth 10 | Set-Content $failureFile -Encoding UTF8
    }
}
else {
    # Success - reset consecutive failure count
    if ($failureLog.consecutive_failures -gt 0) {
        $failureLog.consecutive_failures = 0
        $failureLog | ConvertTo-Json -Depth 10 | Set-Content $failureFile -Encoding UTF8
    }
}
