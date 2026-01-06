# Keyword Detector Hook
# Detects ultrawork/ulw keywords and injects orchestration prompt
# Also creates Ralph Loop state file for automatic continuation

param(
    [string]$Keyword = "ultrawork"
)

$prompt = if ($env:USER_PROMPT) { $env:USER_PROMPT } else { "" }

# Check for ultrawork activation keywords
if ($prompt -match "(ultrawork|ulw|끝까지|완료해|finish everything|complete all)") {

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
    $cleanRequest = $prompt -replace "(ultrawork|ulw|끝까지|완료해|finish everything|complete all)", "" | ForEach-Object { $_.Trim() }
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

ORCHESTRATION RULES:
1. Create comprehensive TODO list IMMEDIATELY using TodoWrite
2. Use Task tool for parallel exploration with @explorer/@librarian agents
3. Delegate specialized work to appropriate agents:
   - UI/UX changes -> @frontend-engineer
   - Architecture questions -> @architect
   - Documentation -> @document-writer
   - Planning -> @planner
4. NEVER stop until ALL TODOs are marked as completed
5. VERIFY each step with evidence before marking complete
6. If stuck 2+ times -> consult @architect for alternative approaches

RALPH LOOP STATUS:
- Active: YES
- Max Iterations: 50
- Completion Signal: <promise>DONE</promise>

EXECUTION FLOW (Sisyphus Phases):
Phase 1: EXPLORE - Parallel discovery with @explorer, @librarian
Phase 2: PLAN - Create detailed TODO list with success criteria
Phase 3: EXECUTE - Work through tasks, delegate to specialists
Phase 4: VERIFY - Validate results, run tests

COMPLETION:
When ALL work is truly complete, output: <promise>DONE</promise>
This will terminate the Ralph Loop successfully.
"@
}
