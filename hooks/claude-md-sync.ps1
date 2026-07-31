# claude-md-sync.ps1
# PostToolUse hook (Edit|Write|MultiEdit): CLAUDE.md 저장 시 AGENTS.md 자동 싱크 (Windows)
#  - 같은 디렉토리에 AGENTS.md 가 이미 존재할 때만 갱신 (프로젝트별 opt-in)
#  - 전역 ~/.claude/CLAUDE.md 저장 시 ~/.codex/AGENTS.md (Codex 전역 지침) 로도 싱크
# Non-blocking: always exit 0

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $data = $raw | ConvertFrom-Json } catch { exit 0 }

$file = $data.tool_input.file_path
if (-not $file) { exit 0 }
if ((Split-Path $file -Leaf) -ne 'CLAUDE.md') { exit 0 }
if (-not (Test-Path $file)) { exit 0 }

$header = '<!-- AUTO-SYNCED from CLAUDE.md - edit CLAUDE.md, not this file. (hooks/claude-md-sync) -->'
$rulesNote = '<!-- Also read ~/.claude/rules/*.md (secure-coding, global, ...) and apply those rules identically when working here. -->'
$body = Get-Content $file -Raw

# 1) 같은 디렉토리 AGENTS.md — 이미 존재할 때만 (opt-in)
$sibling = Join-Path (Split-Path $file -Parent) 'AGENTS.md'
if (Test-Path $sibling) {
    Set-Content -Path $sibling -Value ($header + "`n" + $rulesNote + "`n`n" + $body) -Encoding utf8
}

# 2) 전역 CLAUDE.md → Codex 전역 지침
$globalMd = Join-Path $env:USERPROFILE '.claude\CLAUDE.md'
$codexDir = Join-Path $env:USERPROFILE '.codex'
$isGlobal = $false
try {
    $isGlobal = ((Resolve-Path $file -ErrorAction Stop).Path -eq (Resolve-Path $globalMd -ErrorAction Stop).Path)
} catch { $isGlobal = $false }
if ($isGlobal -and (Test-Path $codexDir)) {
    $note = '<!-- source: ~/.claude/CLAUDE.md - relative paths (rules/, skills/) resolve under ~/.claude/ -->'
    Set-Content -Path (Join-Path $codexDir 'AGENTS.md') -Value ($header + "`n" + $rulesNote + "`n" + $note + "`n`n" + $body) -Encoding utf8
}
exit 0
