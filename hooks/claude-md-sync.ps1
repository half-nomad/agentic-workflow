# claude-md-sync.ps1
# PostToolUse hook (Edit|Write|MultiEdit): CLAUDE.md 저장 시 AGENTS.md 자동 싱크 (Windows)
#  - 같은 디렉토리에 AGENTS.md 가 이미 존재할 때만 갱신 (프로젝트별 opt-in)
# Non-blocking: always exit 0

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $data = $raw | ConvertFrom-Json } catch { exit 0 }

$file = $data.tool_input.file_path
if (-not $file) { exit 0 }
if ((Split-Path $file -Leaf) -ne 'CLAUDE.md') { exit 0 }
if (-not (Test-Path $file)) { exit 0 }

# Is $p a reparse point (symlink / junction)? $false for absent paths.
function Test-IsLink([string]$p) {
    try {
        $item = Get-Item -LiteralPath $p -Force -ErrorAction Stop
        return (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
    } catch { return $false }
}

# Full path with links followed; $null when it cannot be determined. PowerShell
# has no `-ef`, so file identity is compared through this.
#
# PS 5.1 has no ResolveLinkTarget, and Resolve-Path does NOT dereference a final
# symlink — it would hand back the link's own path and every identity test below
# would silently compare the wrong thing. Rather than reimplement reparse-point
# resolution against DeviceIoControl for a case that only arises under Developer
# Mode on Windows, record that resolution was unavailable and let the caller
# skip the branch that depends on it.
$script:LinkResolutionUnavailable = $false
function Resolve-FullPath([string]$p) {
    try {
        $item = Get-Item -LiteralPath $p -Force -ErrorAction Stop
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            $target = $null
            try { $target = $item.ResolveLinkTarget($true) } catch { $target = $null }
            if ($target) { return $target.FullName }
            $script:LinkResolutionUnavailable = $true
        }
        return (Resolve-Path -LiteralPath $p -ErrorAction Stop).ProviderPath
    } catch { return $null }
}

# A deployed CLAUDE.md may be a link into the source repo (Developer Mode / WSL);
# an edit through it reports the LINK path, and the sibling lookup below would
# then aim at a nonexistent ~\.claude\AGENTS.md. Assign only on success, so a
# failure degrades to the previous behaviour rather than emptying $file (which
# would make the parent path '.' and clobber the current project's AGENTS.md).
$resolvedFile = Resolve-FullPath $file
if ($resolvedFile) { $file = $resolvedFile }
$editedThroughUnresolvableLink = $script:LinkResolutionUnavailable

$marker = '<!-- maestro-codex: sync-from-claude -->'
$header = '<!-- AUTO-SYNCED from CLAUDE.md by Maestro Codex hook; keep the marker above to opt in. -->'
$body = Get-Content $file -Raw

# 1) 같은 디렉토리 AGENTS.md — 파일이 있고 **마커도 있을 때만** (opt-in)
#
# 파일 존재만 조건으로 두면 헤더가 약속한 "keep the marker above to opt in" 이 거짓이 된다.
# 마커를 지워 미러를 끊어 둔 프로젝트도 CLAUDE.md 편집 한 번에 통째로 덮인다.
$sibling = Join-Path (Split-Path $file -Parent) 'AGENTS.md'
if ((Test-Path $sibling) -and ((Get-Content $sibling -Raw -ErrorAction SilentlyContinue) -like "*$marker*")) {
    $content = $marker + "`n" + $header + "`n`n" + $body
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($sibling, $content, $utf8NoBom)
}

exit 0
