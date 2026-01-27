# Boulder Manager Hook
# Manages session state persistence via .agentic/boulder.json

param(
    [string]$Action = "load"
)

$stateDir = ".agentic"
$boulderPath = Join-Path $stateDir "boulder.json"

function Initialize-StateDir {
    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }
}

function Load-Boulder {
    if (Test-Path $boulderPath) {
        try {
            $boulder = Get-Content $boulderPath -Raw | ConvertFrom-Json

            if ($boulder.plan.status -eq "in_progress") {
                $steps = $boulder.plan.steps | ForEach-Object {
                    $status = switch ($_.status) {
                        "completed" { "[OK]" }
                        "in_progress" { "[>>]" }
                        default { "[  ]" }
                    }
                    "  $status Step $($_.id): $($_.desc)"
                }
                $stepsText = $steps -join "`n"

                Write-Output @"
[PLAN RECOVERY] 이전 세션의 계획이 발견되었습니다.

계획: $($boulder.plan.name)
패턴: $($boulder.plan.pattern)
상태: $($boulder.plan.status)
현재 단계: Step $($boulder.plan.current_step)
마지막 업데이트: $($boulder.updated_at)

진행 상황:
$stepsText

계속하려면 "계속" 또는 "continue", 새로 시작하려면 "새로 시작" 또는 "new"
"@
            }
        }
        catch {
            # Invalid JSON, ignore
        }
    }
}

function Save-Boulder {
    Initialize-StateDir

    $boulderData = $env:BOULDER_DATA
    if ($boulderData) {
        try {
            $boulder = $boulderData | ConvertFrom-Json
            $boulder.updated_at = (Get-Date).ToString("o")
            $boulder | ConvertTo-Json -Depth 10 | Set-Content $boulderPath -Encoding UTF8
        }
        catch {
            # Invalid data, ignore
        }
    }
}

function Clear-Boulder {
    if (Test-Path $boulderPath) {
        Remove-Item $boulderPath -Force
        Write-Output "[PLAN CLEARED] 이전 계획이 삭제되었습니다. 새로운 계획을 시작합니다."
    }
}

switch ($Action.ToLower()) {
    "load" { Load-Boulder }
    "save" { Save-Boulder }
    "clear" { Clear-Boulder }
    default { Write-Output "Unknown action: $Action" }
}
