# maestro-compact-reload.ps1
# SessionStart hook (matcher "compact", Windows): maestro 모드에서 compact 발생 시 SKILL.md·WORKFLOW.md 재읽기 지시를 재주입
# PostCompact 는 컨텍스트를 넣지 못한다 - 근거는 maestro-compact-reload.sh 주석.
# 근거·동작은 maestro-compact-reload.sh 주석 참조.
# Non-blocking: always exit 0

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
$payload = $raw | ConvertFrom-Json -ErrorAction SilentlyContinue

# 세션별 상태 파일 — maestro-guard.ps1 의 Test-MaestroActive 와 같은 판정 (근거는 maestro-guard.sh).
function Test-MaestroActive($payload) {
    $root = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
    $dir = Join-Path $root ".agentic/maestro"
    $sid = $env:CLAUDE_CODE_SESSION_ID
    if (-not $sid -and $payload) { $sid = [string]$payload.session_id }
    if ($sid -notmatch '\A[A-Za-z0-9_-]+\z') { $sid = "" }
    if (Test-Path -LiteralPath (Join-Path $dir "unknown.state")) { return $true }
    if ($sid) { return (Test-Path -LiteralPath (Join-Path $dir "$sid.state")) }
    return [bool](Get-ChildItem -LiteralPath $dir -Filter *.state -File -ErrorAction SilentlyContinue)
}

if (-not $payload -or [string]$payload.source -ne 'compact') { exit 0 }   # compact 로 시작한 경우만
if (-not (Test-MaestroActive $payload)) { exit 0 }   # 이 세션이 maestro 가 아님

$workflow = Join-Path $env:USERPROFILE ".claude\skills\maestro\WORKFLOW.md"
if (-not (Test-Path $workflow)) { exit 0 }

$msg = '[maestro] 컨텍스트가 요약됐다. 진행 중인 오케스트레이션의 절대 규칙(~/.claude/skills/maestro/SKILL.md 맨 위)과 판정 기준·절차·출력 계약·검증 규약(~/.claude/skills/maestro/WORKFLOW.md)이 요약 과정에서 소실됐거나 잘렸을 수 있다 — 시스템 프롬프트에 상주하는 마에스트로 룰은 없다. 다음 행동 전에 SKILL.md 와 WORKFLOW.md 를 Read 로 다시 읽어라 — 요약본에 관련 내용이 남아 있어 보여도 원문이 아니고 로드 증거도 아니다.'

$out = @{
  hookSpecificOutput = @{
    hookEventName    = 'SessionStart'
    additionalContext = $msg
  }
}
$out | ConvertTo-Json -Depth 5 -Compress
exit 0
