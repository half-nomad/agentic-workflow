# Keyword Detector Hook
# Detects ultrawork/ulw/swarm keywords and injects orchestration prompts

# Read prompt from pipeline ($input)
$prompt = ""
try {
    $rawInput = @($input) -join ""
    if ($rawInput) {
        $data = $rawInput | ConvertFrom-Json
        $prompt = if ($data.prompt) { $data.prompt } else { "" }
    }
} catch {
    $prompt = ""
}

$stateDir = ".agentic"

function Initialize-StateDir {
    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }
}

# Check for swarm activation keywords
if ($prompt -match "(swarm:|parallel:)") {
    Initialize-StateDir

    $modeFile = Join-Path $stateDir "mode.txt"
    "swarm" | Set-Content $modeFile -Encoding UTF8

    Write-Output @"
[SWARM MODE ACTIVATED] Parallel agent execution mode

EXECUTION RULES:
1. IDENTIFY independent tasks
2. SPLIT each task into separate Task calls
3. DISPATCH multiple Tasks in a single message
4. COLLECT all results
5. SYNTHESIZE and report

AVAILABLE AGENTS:
- @librarian (sonnet): docs research, parallel search
- @architect (opus): architecture analysis
- Explore (haiku): codebase search
- general-purpose: general tasks

RULES:
- Each Task must be independent (no cross-dependencies)
- Must dispatch multiple Tasks in single message
- Prefer background mode
"@
    exit 0
}

# Check for ultrawork activation keywords
if ($prompt -match "(ultrawork|ulw|finish everything|complete all)") {
    Initialize-StateDir

    $modeFile = Join-Path $stateDir "mode.txt"
    "ultrawork" | Set-Content $modeFile -Encoding UTF8

    $stateFile = Join-Path $stateDir "ralph-loop.state.md"
    $timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

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
4. EXECUTE with full autonomy (no approval checkpoint)
5. Track progress with TodoWrite
6. If stuck 2+ times -> consult @architect

RALPH LOOP STATUS:
- Active: YES
- Max Iterations: 50
- Completion Signal: <promise>DONE</promise>

COMPLETION:
When ALL work is truly complete, output: <promise>DONE</promise>
"@
}
