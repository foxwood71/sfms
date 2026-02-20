# SFMS 프로젝트 VSCode 최적 설정 가이드 (PostgreSQL 포함)

SFMS의 **mise + uv + Ruff + Biome + Docker + PostgreSQL** 풀스택에 최적화된 설정입니다! [learn.microsoft](https://learn.microsoft.com/ko-kr/azure/postgresql/developer/vs-code-extension/vs-code-connect)

## 🎯 필수 확장 목록 (25개 이내)

| 확장명 | ID | 역할 |
| -------- | ---- | ------ |
| **Python** | `ms-python.python` | Pylance + 디버깅 |
| **Ruff** | `charliermarsh.ruff` | Python 린트/포맷 |
| **Biome** | `biomejs.biome` | JS/TS 린트/포맷 |
| **Docker** | `ms-azuretools.vscode-docker` | Docker 관리 |
| **PostgreSQL** | `ms-ossdata.vscode-pgsql` | **DB 연결/쿼리** |
| **Dev Containers** | `ms-vscode-remote.remote-containers` | 컨테이너 개발 |

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
  "python.defaultInterpreterPath": "./backend/.venv/bin/python",
  "python.languageServer": "Pylance",
  "python.analysis.typeCheckingMode": "basic",

  // ========== JAVASCRIPT/TS (Frontend) ==========
  "[javascript][typescript][javascriptreact][typescriptreact][json][jsonc][yaml]": {
    "editor.defaultFormatter": "biomejs.biome",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll": "explicit",
      "source.organizeImports": "explicit"
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
