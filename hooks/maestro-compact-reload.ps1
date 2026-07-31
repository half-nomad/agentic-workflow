# maestro-compact-reload.ps1
# PostCompact hook (Windows): maestro 모드에서 compact 발생 시 WORKFLOW.md 재읽기 지시를 재주입
# 근거·동작은 maestro-compact-reload.sh 주석 참조.
# Non-blocking: always exit 0

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }

$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { "." }
$stateFile = Join-Path $projectDir ".agentic\maestro-mode.state"
if (-not (Test-Path $stateFile)) { exit 0 }   # maestro 모드 아님

$workflow = Join-Path $env:USERPROFILE ".claude\skills\maestro\WORKFLOW.md"
if (-not (Test-Path $workflow)) { exit 0 }

$msg = '[maestro] 컨텍스트가 요약됐다. 진행 중인 오케스트레이션의 절차·템플릿(~/.claude/skills/maestro/WORKFLOW.md)이 요약 과정에서 소실됐을 수 있다. 다음 행동 전에 그 파일을 Read 로 다시 읽어라 — 요약본에 관련 내용이 남아 있어 보여도 원문이 아니므로 재읽기를 건너뛰지 말 것. 구속 룰(가드·Hard rule·출력 계약)은 rules/maestro-workflow.md 에 그대로 살아 있다.'

$out = @{
  hookSpecificOutput = @{
    hookEventName    = 'PostCompact'
    additionalContext = $msg
  }
}
$out | ConvertTo-Json -Depth 5 -Compress
exit 0
