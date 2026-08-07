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

$msg = '[maestro] 컨텍스트가 요약됐다. 진행 중인 오케스트레이션의 판정 기준·절차·출력 계약·검증 규약(~/.claude/skills/maestro/WORKFLOW.md)이 요약 과정에서 소실됐을 수 있다. 시스템 프롬프트에 남아 있는 것은 활성화 조건과 절대 규칙 4개뿐인 상주 스텁이므로, 그것만으로 진행하지 말 것. 다음 행동 전에 WORKFLOW.md 를 Read 로 다시 읽어라 — 요약본에 관련 내용이 남아 있어 보여도 원문이 아니고 로드 증거도 아니다.'

$out = @{
  hookSpecificOutput = @{
    hookEventName    = 'PostCompact'
    additionalContext = $msg
  }
}
$out | ConvertTo-Json -Depth 5 -Compress
exit 0
