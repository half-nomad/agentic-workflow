# maestro-guard.ps1
# PreToolUse hook: Block Write/Edit in maestro mode
# Input: JSON on stdin from Claude Code
# Block: exit 2 + stderr message | Allow: exit 0

# Read stdin via OpenStandardInput. `[Console]::In.ReadToEnd()` returns an EMPTY string
# when the script runs as `pwsh -File` (PowerShell consumes the pipeline first), which made
# this guard exit 0 unconditionally — i.e. it blocked nothing at all.
# Also: do not name this `$input` — that is a reserved automatic variable holding pipeline
# input, and assigning to it clobbers the very data we are trying to read.
$stdinReader = New-Object System.IO.StreamReader([Console]::OpenStandardInput())
$payload = $stdinReader.ReadToEnd() | ConvertFrom-Json -ErrorAction SilentlyContinue
if (-not $payload) { exit 0 }

$stateFile = Join-Path $env:CLAUDE_PROJECT_DIR ".agentic/maestro-mode.state"

if (Test-Path $stateFile) {
    $toolName = $payload.tool_name

    if ($toolName -match "^(Write|Edit|MultiEdit)$") {
        # Subagent bypass: Task-delegated calls include `agent_id` in stdin JSON;
        # the main orchestrator does not. Maestro blocks the orchestrator's
        # direct writes but lets delegated sub-agents execute.
        if ($payload.agent_id) { exit 0 }

        $filePath = ""
        if ($payload.tool_input -and $payload.tool_input.file_path) {
            $filePath = $payload.tool_input.file_path
        }

        # Collapse `.` / `..` BEFORE whitelist matching. The patterns below are
        # substring matches, so an un-normalized path like
        # `<repo>\.agentic\..\rules\maestro-workflow.md` would satisfy the
        # `.agentic\` rule while actually resolving outside the whitelist.
        if ($filePath) {
            try { $filePath = [System.IO.Path]::GetFullPath($filePath) }
            catch {
                [Console]::Error.WriteLine("[MAESTRO GUARD] Unresolvable path — refusing (fail closed).")
                exit 2
            }
        }

        # Allow MEMORY.md edits
        if ($filePath -match "(^|[/\\])MEMORY\.md$") { exit 0 }
        # Allow memory/*.md siblings (project/feedback/user/reference)
        if ($filePath -match "[/\\]memory[/\\].+\.md$") { exit 0 }
        # Allow .agentic/ edits
        if ($filePath -match "\.agentic[/\\]") { exit 0 }
        # Allow plan files
        # Allow Plan Mode system plan files (~/.claude/plans/*.md) — parity with maestro-guard.sh
        if ($filePath -match "\.claude[/\\]plans[/\\].+\.md$") { exit 0 }
        if ($filePath -match "\.plan\.md$") { exit 0 }
        # Allow workflow meta files (TODO/CHANGELOG/VERSION) — orchestrator manages these directly
        if ($filePath -match "[/\\]TODO\.md$") { exit 0 }
        if ($filePath -match "[/\\]CHANGELOG(\.archive)?\.md$") { exit 0 }
        if ($filePath -match "[/\\]VERSION$") { exit 0 }

        [Console]::Error.WriteLine("[MAESTRO GUARD] Orchestrator mode active. Delegate file modifications to agents via Agent tool.")
        exit 2
    }
}

exit 0
