# SFMS 프로젝트 VSCode 최적 설정 가이드 (PostgreSQL 포함)

SFMS의 **mise + uv + Ruff + Biome + Docker + PostgreSQL** 풀스택에 최적화된 설정입니다! [learn.microsoft](https://learn.microsoft.com/ko-kr/azure/postgresql/developer/vs-code-extension/vs-code-connect)

## 🎯 필수 확장 목록 (20개 이내)

| 확장명 | ID | 역할 |
| -------- | ---- | ------ |
| **WSL** | `ms-vscode-remote.remote-wsl` | WSL 원격 연결(필요시) |
| **Material Icon** | `Themepkief.material-icon-theme` | 파일/폴더 아이콘 |
| **Indent-Rainbow** | `oderwat.indent-rainbow` | 들여쓰기 색상화 |
| **Path Intellisense** | `christian-kohler.path-intellisense` | 경로 자동 완성 |
| **Comment Anchors** | `remy-beone.comment-anchors` | 주석 북마크 |
| **GitLens** | `eamodio.gitlens` | Git 내역 시각화 |
| **Git Graph** | `mhutchie.git-graph` | 커밋 히스토리 시각화 |
| **Git History** | `donjayamanne.githistory` | 파일 단위 이력 추적 |
| **Error Lens** | `usernamehw.errorlens` | 인라인 에러 표시 |
| **DotENV** | `mikestead.dotenv` | .env 파일 |
| **Markdown** | `yzhang.markdown-all-in-one` | Markdown All in One |
| **markdownlint** | `davidAnson.vscode-markdownlint` | linting(스타일 검사, 자동 수정) |
| **TOML** | `tamasfe.even-better-toml` | Even Better TOML |
| **INI** | `davidWang.ini-for-vscode` | Ini for VS Code |
| **Python** | `ms-python.python` | Pylance + 디버깅 |
| **Ruff** | `charliermarsh.ruff` | Python 린트/포맷 |
| **Biome** | `biomejs.biome` | JS/TS 린트/포맷 |
| **Database Client** | `cweijan.vscode-database-client2` | PostgreSQL, Redis 등을 통합 관리하는 GUI 클라이언트 |
| **REST Clien** | `thumao.rest-client` | API 테스트 |
| **NGINX Configuration Language Support** | `ahmadalli.vscode-nginx-conf` | default.conf 등 설정 파일의 문법 강조 및 자동 완성 지원 |
| **MinIO** | `seriousbenentertainment.minio` | MinIO 버킷 생성 및 파일 업로드/관리 도구 |
| **Docker** | `ms-azuretools.vscode-docker` | Docker 관리 |
| **Pod Manager** | `dreamcatcher45.podmanager` | Podman 전용 관리 UI |
| **Dev Containers** | `ms-vscode-remote.remote-containers` | 컨테이너 안에서 개발 |
| **Container Tools** | `ms-azuretools.vscode-containers` | 컨테이너 종합 관리 |
| **ShellCheck** | `timonwong.shellcheck` | 필수 중의 필수 |
| **shell-format** | `foxundermoon.shell-format` | 포맷터 |
| **Bash IDE** | `mads-hartmann.bash-ide-vscode` | 인텔리센스 |

## 🎯 필수 확장 설치 shell script

아래 내용을 복사하여 install_extensions.sh 파일로 저장하거나, 터미널에 그대로 붙여넣으세요.

```bash
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
    "tamasfe.even-better-toml"
    "davidWang.ini-for-vscode"
    "ms-python.python"
    "charliermarsh.ruff"
    "biomejs.biome"
    "cweijan.vscode-database-client2"  # PostgreSQL/Redis 관리용
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
```

## 📁 프로젝트 루트 `.vscode/settings.json`

```json
{
  // ========== PYTHON (Backend) ==========
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll.ruff": "explicit",
      "source.organizeImports.ruff": "explicit"
    }
  },
  "[jupyter]": {
    "editor.formatOnSave": true
  },
  "python.terminal.activateEnvironment": true,
  "python.defaultInterpreterPath": "./backend/.venv/bin/python",
  "python.languageServer": "Pylance",
  "python.analysis.typeCheckingMode": "basic",
  "ruff.enableExperimentalCodeActions": true,

  // ========== JAVASCRIPT/TS (Frontend) ==========
  "[javascript][javascriptreact][typescript][typescriptreact][json][jsonc][yaml][css]": {
    "editor.tabSize": 2,
    "editor.defaultFormatter": "biomejs.biome",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll.biome": "explicit",
      "source.organizeImports": "explicit",
      "source.organizeImports.biome": "explicit",
      "source.addMissingImports": "explicit"
    }
  },

  // ========== SQL (PostgreSQL) ==========
  "[sql]": {
    "editor.formatOnSave": true
  },
  "pgsql.connectionTimeout": 30,
  "pgsql.showStartNotification": false,

  // ========== 공통 ==========
  "editor.formatOnSave": true,
  "files.associations": {
    "*.sql": "sql"
  },

  // ========== Docker ==========
  "docker.showStartNotification": false,

  // ========== Ruff/Biome 최적화 ==========
  "ruff.enableExperimentalCodeActions": true,
  "biome.enabled": true
  "biome.formatOnSave": true, 

}
```

## 🐳 `.vscode/devcontainer.json`

```json
{
  "name": "SFMS Fullstack",
  "dockerComposeFile": "../infra/docker-compose.yml",
  "service": "backend",
  "workspaceFolder": "/workspace",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker": {},
    "ghcr.io/devcontainers/features/postgres": {}
  },
  "forwardPorts": [3000, 8000, 5432, 9000],
  "postCreateCommand": "mise trust && uv sync --dev && cd ../frontend && pnpm install",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "charliermarsh.ruff",
        "biomejs.biome",
        "ms-azuretools.vscode-docker",
        "ms-ossdata.vscode-pgsql"
      ]
    }
  }
}
```

## 🗄️ PostgreSQL 연결 설정

### 1. 확장 설치 후

```text
Ctrl+Shift+P → PostgreSQL: Add Connection
```

### 2. SFMS DB 연결 정보

```text
Server: localhost (또는 docker-compose 호스트)
Port: 5432
Username: sfms_user
Password: (docker-compose.yml 참조)
Database: sfms
```

### 3. 쿼리 단축키

```text
Ctrl+Shift+P → PostgreSQL: New Query
→ DB 선택 → SQL 작성 → Ctrl+Enter 실행
```

## 🔧 터미널 프로파일 `.vscode/settings.json`

```json
"terminal.integrated.profiles.linux": {
  "SFMS Backend": {
    "path": "mise",
    "args": ["exec", "--", "uv", "run", "bash"],
    "cwd": "${workspaceFolder}/backend"
  },
  "SFMS Frontend": {
    "path": "mise",
    "args": ["exec", "--", "pnpm", "exec", "bash"],
    "cwd": "${workspaceFolder}/frontend"
  },
  "PostgreSQL": {
    "path": "psql",
    "args": ["-h", "localhost", "-U", "sfms_user", "sfms"]
  }
}
```

## 🎨 테마 및 폰트 (SFMS 맞춤)  `.vscode/settings.json`

```json
{
  "workbench.colorTheme": "GitHub Dark Dimmed",
  "editor.fontFamily": "'JetBrains Mono Nerd Font', monospace",
  "editor.fontLigatures": true,
  "editor.fontSize": 13,
  "terminal.integrated.fontSize": 12,
  "workbench.iconTheme": "material-icon-theme"
}
```

## 📋 키바인딩 (추가)

| 단축키 | 기능 | 확장 |
| -------- | ------ | ------ |
| `Ctrl+Shift+Q` | **새 SQL 쿼리** | PostgreSQL |
| `Ctrl+Enter` | **쿼리 실행** | PostgreSQL |
| `Alt+Enter` | **결과 내보내기** | PostgreSQL |

## 🧪 완벽 검증 워크플로우

```text
1. git clone sfms
2. Ctrl+Shift+P → Dev Containers: Reopen in Container
3. 자동: mise + uv sync + pnpm install
4. Backend: F5 → FastAPI 디버깅
5. Frontend: pnpm dev → http://localhost:3000
6. PostgreSQL: Ctrl+Shift+Q → DB 연결 → 쿼리 실행
7. 저장(Ctrl+S) → 모든 언어 자동 린트/포맷!
```

## 🔍 PostgreSQL 기능 활용

```text
✅ 스키마 탐색 (테이블/뷰/함수)
✅ 실시간 쿼리 실행 (Ctrl+Enter)
✅ 결과 CSV/JSON 내보내기
✅ SQL 자동완성
✅ 다중 연결 탭
✅ pgAdmin 대체
```

**SFMS 풀스택 완벽 환경 구축 완료!** **Docker → Python → TS → PostgreSQL** 모두 **저장만 하면 완벽**! 🔥
