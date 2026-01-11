# Keyword Detector Hook
# Detects ultrawork/ulw keywords and injects Maestro orchestration prompt
# Also creates Ralph Loop state file for automatic continuation

param(
    [string]$Keyword = "ultrawork"
)

$prompt = if ($env:USER_PROMPT) { $env:USER_PROMPT } else { "" }

# Check for ultrawork activation keywords
if ($prompt -match "(ultrawork|ulw|finish everything|complete all)") {

    # Create state directory if needed
    $stateDir = ".agentic"
    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }

    # Set mode file
    $modeFile = Join-Path $stateDir "mode.txt"
    "ultrawork" | Set-Content $modeFile -Encoding UTF8

    # Create Ralph Loop state file
    $stateFile = Join-Path $stateDir "ralph-loop.state.md"
    $timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

    # Extract the user's request (removing the trigger keyword for cleaner storage)
    $cleanRequest = $prompt -replace "(ultrawork|ulw|finish everything|complete all)", "" | ForEach-Object { $_.Trim() }
    if ([string]::IsNullOrWhiteSpace($cleanRequest)) {
        $cleanRequest = $prompt
    }

    $stateContent = @"
---
active: true
iteration: 1
max_iterations: 50
completion_promise: "DONE"
started_at: "$timestamp"
mode: "ultrawork"
---
$cleanRequest
"@

    $stateContent | Set-Content $stateFile -Encoding UTF8

    Write-Output @"
[ULTRAWORK MODE ACTIVATED - Ralph Loop Enabled]

MAESTRO ORCHESTRATION RULES:
1. ANALYZE task complexity (simple vs complex)
2. SELECT PATTERN: Chaining / Parallelization / Routing / Orchestrator-Workers
3. IDENTIFY agents and tools needed:
   - Built-in: Explore, Plan, general-purpose
   - Specialists: @architect, @frontend-engineer, @librarian, @document-writer
4. EXECUTE with full autonomy (no approval checkpoint in ultrawork)
5. Track progress with TodoWrite
6. If stuck 2+ times -> consult @architect

RALPH LOOP STATUS:
- Active: YES
- Max Iterations: 50
- Completion Signal: <promise>DONE</promise>

COMPLETION:
When ALL work is truly complete, output: <promise>DONE</promise>
This will terminate the Ralph Loop successfully.
"@
}
