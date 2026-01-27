# Keyword Detector Hook
# Detects ultrawork/ulw/swarm keywords and injects orchestration prompts
# Also creates state files for automatic continuation

param(
    [string]$Keyword = "ultrawork"
)

$prompt = if ($env:USER_PROMPT) { $env:USER_PROMPT } else { "" }
$stateDir = ".agentic"

function Initialize-StateDir {
    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }
}

# Check for swarm activation keywords
if ($Keyword -eq "swarm" -or $prompt -match "(swarm:|parallel:|병렬:)") {
    Initialize-StateDir

    # Set mode file
    $modeFile = Join-Path $stateDir "mode.txt"
    "swarm" | Set-Content $modeFile -Encoding UTF8

    Write-Output @"
[SWARM MODE ACTIVATED] 병렬 에이전트 실행 모드

EXECUTION RULES:
1. IDENTIFY - 독립적인 작업들을 식별하라
2. SPLIT - 각 작업을 별도 Task로 분리하라
3. DISPATCH - 단일 메시지에서 여러 Task를 병렬 호출하라
4. COLLECT - 모든 결과를 수집하라
5. SYNTHESIZE - 결과를 통합하여 보고하라

PARALLEL EXECUTION PATTERN:
┌→ Agent A (Task 1) ─┐
│→ Agent B (Task 2) ─┤→ Collect → Synthesize
└→ Agent C (Task 3) ─┘

AVAILABLE AGENTS:
- @librarian (sonnet): 문서 리서치, 병렬 검색에 최적
- @architect (opus): 아키텍처 분석
- Explore (haiku): 코드베이스 탐색
- general-purpose: 범용 작업

RULES:
- 각 Task는 독립적이어야 함 (상호 의존성 없음)
- 단일 메시지에서 여러 Task 호출 필수
- background 모드 활용 권장
"@
    exit 0
}

# Check for ultrawork activation keywords
if ($prompt -match "(ultrawork|ulw|finish everything|complete all)") {
    Initialize-StateDir

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
