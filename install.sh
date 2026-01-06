#!/bin/bash
#
# Agentic Workflow 설치 스크립트 (WSL/Linux/macOS Bash)
# Claude Code용 agentic-workflow 구성 파일들을 ~/.claude/ 디렉토리에 설치합니다.
#
# Usage: ./install.sh
#

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m'

# 출력 함수
print_step() { echo -e "${CYAN}[*] $1${NC}"; }
print_success() { echo -e "${GREEN}[+] $1${NC}"; }
print_warn() { echo -e "${YELLOW}[!] $1${NC}"; }
print_error() { echo -e "${RED}[-] $1${NC}"; }
print_dim() { echo -e "${GRAY}    $1${NC}"; }

# 스크립트 위치 찾기
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_PATH="$SCRIPT_DIR"
CLAUDE_HOME="$HOME/.claude"

echo ""
echo -e "${MAGENTA}========================================${NC}"
echo -e "${MAGENTA}  Agentic Workflow Installer (Bash)${NC}"
echo -e "${MAGENTA}========================================${NC}"
echo ""

# 1. 프로젝트 소스 경로 저장
print_step "프로젝트 소스 경로 저장..."
mkdir -p "$CLAUDE_HOME"
SOURCE_FILE_PATH="$CLAUDE_HOME/.agentic-workflow-source"
echo -n "$SOURCE_PATH" > "$SOURCE_FILE_PATH"
print_success "소스 경로 저장됨: $SOURCE_FILE_PATH"

# 2. 디렉토리 생성
print_step "디렉토리 생성..."
DIRECTORIES=("$CLAUDE_HOME" "$CLAUDE_HOME/agents" "$CLAUDE_HOME/rules" "$CLAUDE_HOME/hooks" "$CLAUDE_HOME/commands" "$CLAUDE_HOME/skills")
for dir in "${DIRECTORIES[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_success "생성됨: $dir"
    else
        print_dim "이미 존재: $dir"
    fi
done

# 3. 파일 복사 함수
copy_directory_contents() {
    local source_dir="$1"
    local dest_dir="$2"
    local count=0
    if [ -d "$source_dir" ]; then
        for file in "$source_dir"/*; do
            if [ -f "$file" ]; then
                cp -f "$file" "$dest_dir/"
                print_dim "복사됨: $(basename "$file")"
                ((count++))
            fi
        done
    fi
    echo $count
}

# 파일 복사
print_step "파일 복사..."

echo "  agents/ 복사 중..."
count=$(copy_directory_contents "$SOURCE_PATH/agents" "$CLAUDE_HOME/agents")
print_success "agents: $count 파일 복사됨"

echo "  rules/ 복사 중..."
count=$(copy_directory_contents "$SOURCE_PATH/rules" "$CLAUDE_HOME/rules")
print_success "rules: $count 파일 복사됨"

echo "  hooks/ 복사 중..."
count=$(copy_directory_contents "$SOURCE_PATH/hooks" "$CLAUDE_HOME/hooks")
print_success "hooks: $count 파일 복사됨"

echo "  commands/ 복사 중..."
count=$(copy_directory_contents "$SOURCE_PATH/commands" "$CLAUDE_HOME/commands")
print_success "commands: $count 파일 복사됨"

echo "  skills/ 복사 중..."
if [ -d "$SOURCE_PATH/skills" ]; then
    cp -rf "$SOURCE_PATH/skills/"* "$CLAUDE_HOME/skills/" 2>/dev/null || true
    print_success "skills: 복사 완료"
fi

# CLAUDE.global.md -> CLAUDE.md
echo "  CLAUDE.md 설정 중..."
GLOBAL_MD_SOURCE="$SOURCE_PATH/CLAUDE.global.md"
CLAUDE_MD_DEST="$CLAUDE_HOME/CLAUDE.md"

if [ -f "$GLOBAL_MD_SOURCE" ]; then
    if [ -f "$CLAUDE_MD_DEST" ]; then
        BACKUP_PATH="$CLAUDE_MD_DEST.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$CLAUDE_MD_DEST" "$BACKUP_PATH"
        print_warn "기존 CLAUDE.md 백업됨: $BACKUP_PATH"
    fi
    cp "$GLOBAL_MD_SOURCE" "$CLAUDE_MD_DEST"
    print_success "CLAUDE.md 복사됨"
else
    print_dim "CLAUDE.global.md 파일 없음 (건너뜀)"
fi

# 4. 설정 파일 병합
print_step "설정 파일 병합..."

if command -v jq &> /dev/null; then
    # settings.json 병합
    SETTINGS_SOURCE="$SOURCE_PATH/settings.json"
    SETTINGS_DEST="$CLAUDE_HOME/settings.json"

    if [ -f "$SETTINGS_SOURCE" ]; then
        if [ -f "$SETTINGS_DEST" ]; then
            jq -s '.[0] * .[1] | .permissions.allow = ((.[0].permissions.allow // []) + (.[1].permissions.allow // []) | unique)' \
                "$SETTINGS_DEST" "$SETTINGS_SOURCE" > "$SETTINGS_DEST.tmp" && mv "$SETTINGS_DEST.tmp" "$SETTINGS_DEST"
            print_success "settings.json 병합됨"
        else
            cp "$SETTINGS_SOURCE" "$SETTINGS_DEST"
            print_success "settings.json 복사됨 (새 파일)"
        fi
    fi

    # .mcp.json 병합
    MCP_SOURCE="$SOURCE_PATH/.mcp.json"
    MCP_DEST="$HOME/.mcp.json"

    if [ -f "$MCP_SOURCE" ]; then
        if [ -f "$MCP_DEST" ]; then
            jq -s '.[0] * .[1] | .mcpServers = (.[0].mcpServers // {}) * (.[1].mcpServers // {})' \
                "$MCP_DEST" "$MCP_SOURCE" > "$MCP_DEST.tmp" && mv "$MCP_DEST.tmp" "$MCP_DEST"
            print_success ".mcp.json 병합됨: $MCP_DEST"
        else
            cp "$MCP_SOURCE" "$MCP_DEST"
            print_success ".mcp.json 복사됨 (새 파일): $MCP_DEST"
        fi
    fi
else
    print_warn "jq가 설치되지 않아 설정 파일을 단순 복사합니다."
    [ -f "$SOURCE_PATH/settings.json" ] && cp "$SOURCE_PATH/settings.json" "$CLAUDE_HOME/settings.json"
    [ -f "$SOURCE_PATH/.mcp.json" ] && cp "$SOURCE_PATH/.mcp.json" "$HOME/.mcp.json"
fi

# 5. MCP 설치 안내
echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  MCP 도구 설치 안내${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "grep_app_mcp 설치가 필요합니다. 다음 명령어를 실행하세요:"
echo ""
echo -e "${CYAN}  uvx --from git+https://github.com/ai-tools-all/grep_app_mcp grep-app-mcp${NC}"
echo ""
echo -e "${GRAY}uv가 설치되어 있지 않다면:${NC}"
echo -e "${GRAY}  pip install uv${NC}"
echo ""

# 6. 완료 메시지
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  설치 완료!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "설치된 위치: $CLAUDE_HOME"
echo ""
echo "설치된 구성요소:"
echo "  - agents/     : AI 에이전트 프롬프트"
echo "  - rules/      : 코딩 규칙"
echo "  - hooks/      : Claude Code 훅 스크립트"
echo "  - commands/   : 슬래시 명령어"
echo "  - skills/     : 스킬 정의"
echo "  - settings.json : Claude Code 설정"
echo "  - ~/.mcp.json   : MCP 서버 설정"
echo ""
echo -e "${YELLOW}Claude Code를 재시작하여 변경사항을 적용하세요.${NC}"
echo ""
