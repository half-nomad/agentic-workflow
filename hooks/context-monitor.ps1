# Context Window Monitor Hook
# Monitors context usage and warns when approaching limits

param(
    [int]$CurrentTokens = 0,
    [int]$MaxTokens = 200000
)

$usagePercent = [math]::Round(($CurrentTokens / $MaxTokens) * 100, 1)

if ($usagePercent -ge 85) {
    Write-Output @"
[CONTEXT WARNING] Usage at ${usagePercent}%

CRITICAL: Context window nearly full!
- Consider summarizing completed work
- Remove unnecessary context
- Focus on essential information only
"@
} elseif ($usagePercent -ge 70) {
    Write-Output @"
[CONTEXT NOTICE] Usage at ${usagePercent}%

Context window at 70%+. You still have room to work.
- Don't rush or cut corners
- Complete current tasks properly
- Monitor for 85% threshold
"@
}
