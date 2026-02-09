# Prompt Filter Hook
# Reads pipeline input from Claude Code, checks prompt against pattern, outputs message if matched
# Usage: prompt-filter.ps1 -Pattern "regex" -Message "output text"

param(
    [string]$Pattern,
    [string]$Message
)

# Read prompt from pipeline ($input) - Claude Code pipes JSON via stdin
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

if ($prompt -match $Pattern) {
    Write-Output $Message
}
