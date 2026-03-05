#!/bin/bash

# ANSI 색상 코드 정의 (Bash용)
CYAN='\033[0;36m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

# VS Code 확장 프로그램 리스트
# Bash 배열 선언 방식 사용
EXTENSIONS=(
    "ms-vscode-remote.remote-wsl"
    "pkief.material-icon-theme"
    "oderwat.indent-rainbow"
    "christian-kohler.path-intellisense"
    "exodiusStudios.comment-anchors"
    "usernamehw.errorlens"
    "eamodio.gitlens"
    "mhutchie.git-graph"
    "donjayamanne.githistory"
    "mikestead.dotenv"
    "yzhang.markdown-all-in-one"
    "davidAnson.vscode-markdownlint"
    "redhat.vscode-yaml"
    "tamasfe.even-better-toml"
    "davidWang.ini-for-vscode"
    "ms-python.python"
    "charliermarsh.ruff"
    "artinmajdi.code-dependency-visualizer"
    "biomejs.biome"
    "juanallo.vscode-dependency-cruiser"
    "ms-ossdata.vscode-pgsql"
    "bradymholt.pgformatter"
    "Redis.redis-for-vscode"
    "humao.rest-client"
    "ahmadalli.vscode-nginx-conf"  # Nginx 설정 지원
    "seriousbenentertainment.minio"  # MinIO 관리 도구
    "ms-azuretools.vscode-docker"  # 컨테이너 시각화
    "dreamcatcher45.podmanager"
    "ms-vscode-remote.remote-containers"
    "ms-azuretools.vscode-containers"
    "timonwong.shellcheck"
    "foxundermoon.shell-format"
    "mads-hartmann.bash-ide-vscode"
    "firefox-devtools.vscode-firefox-debug"   # Debugger for Firefox
    "Google.geminicodeassist"
)

echo -e "${CYAN}🚀 VS Code 확장 프로그램 일괄 설치를 시작합니다...${RESET}"
echo -e "${BLUE}----------------------------------------${RESET}"

# 확장 프로그램 설치 루프
# Bash에서 배열 전체를 순회할 때는 "${EXTENSIONS[@]}" 형식을 사용해야 합니다.
for EXT in "${EXTENSIONS[@]}"; do
    echo -e "${YELLOW}📦 설치 중:${RESET} ${GREEN}$EXT${RESET}"
    code --install-extension "$EXT" --force
done

echo -e "${BLUE}----------------------------------------${RESET}"
echo -e "${GREEN}✅ 모든 확장 프로그램 설치가 완료되었습니다!${RESET}"
echo -e "${RESET}💡 설정 적용을 위해 VS Code를 재시작(Reload)해 주세요."