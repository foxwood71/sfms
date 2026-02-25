# 개발환경 설정

## 1. mise 설치 및 Zsh 설정

시스템 전체에서 '매니저' 역할을 할 mise와 uv를 먼저 설치합니다. 이들은 각 프로젝트의 버전을 관리하는 인프라입니다.

1.1. uv 설치 (초고속 패키지 매니저)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
echo -e "\n# un 환경설정" >> ~/.zshrc
echo -e "# uv에서 권장하는 경로 설정 스크립트 실행" >> ~/.zshrc
echo -e '. "$HOME/.local/bin/env"' >> ~/.zshrc
echo -e "# uv 명령어를 인식하게 하고, 탭(Tab) 키를 눌렀을 때 명령어 완성" >> ~/.zshrc
echo -e 'eval "$(uv generate-shell-completion zsh)"' >> ~/.zshrc
echo -e 'eval "$(uvx --generate-shell-completion zsh)"' >> ~/.zshrc
source ~/.zshrc
```

1.2. mise 설치 (런타임 매니저):

```bash
curl https://mise.jdx.dev/install.sh | sh
echo -e "\n# mise 환경설정" >> ~/.zshrc
echo -e "# 디렉토리 이동 시 .mise.toml을 읽어 파이썬/노드 버전을 자동 스위칭" >> ~/.zshrc
echo 'eval "$($HOME/.local/bin/mise activate zsh)"' >> ~/.zshrc
source ~/.zshrc
```

---

## 2. 프로젝트 통합 초기화

하나의 루트 폴더 안에 백엔드와 프론트엔드를 각각 구성합니다.

```bash
mkdir projects/sfms && cd projects/sfms

# mise를 이용해 프로젝트에서 사용할 버전 고정 (No Global 핵심)
# 이 명령은 폴더에 .mise.toml 파일을 생성합니다.
mise use python@3.13 node@24
```

## 3. Backend 설정 (uv + venv)

```bash
mkdir backend && cd backend

# 1. uv 프로젝트 초기화 및 파이썬 버전 고정
uv init
uv python pin 3.13

# 2. 가상환경 생성 및 패키지 추가 (FastAPI 기준)
uv venv
uv add fastapi uvicorn pydantic-settings
# 또는
uv sync

cd ..
```

## 4. Frontend 설정 (Vite + React)

```bash
# 루트 폴더에서 실행 (mise가 이미 Node 24를 활성화한 상태)
npm create vite@latest frontend -- --template react

cd frontend
mise install
mise use -g pnpm

# 선호하시는 lucide-react 아이콘 설치
pnpm add lucide-react
cd ..
```

선택사항 - pnpm설치

```bash

# pnpm 설치 및 전역(global) 사용 설정
mise use -g pnpm
# 설치 확인
pnpm -v

```

기존 프로젝트를 pnpm으로 전환하기

```bash
# 1. 기존 무거운 폴더와 잠금 파일 삭제
rm -rf node_modules package-lock.json

# 2. pnpm으로 패키지 설치 (엄청난 속도를 체감하실 수 있습니다)
pnpm install
```

## 5. VS Code 환경 최적화

프로젝트가 시스템 파이썬이 아닌 프로젝트 내부의 .venv를 정확히 인식하도록 설정합니다.

.vscode/settings.json:

```json
{
  "editor.tabSize": 4,
  "editor.insertSpaces": true,
  "python.defaultInterpreterPath": "${workspaceFolder}/backend/.venv/bin/python",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.ruff": "always"
  },
  "files.exclude": {
    "**/__pycache__": true,
    "**/.pytest_cache": true
  }
}
```

## 6. 환경 검증용 파이썬 코드

백엔드 환경이 "No Global"로 잘 설정되었는지 확인하는 코드입니다.

```python
import sys
import os


def verify_isolated_env():
    """현재 실행 환경이 프로젝트 내에 격리되었는지 검증합니다."""
    #  현재 실행 중인 인터프리터 경로
    python_exe = sys.executable
    #  프로젝트 루트 경로
    cwd = os.getcwd()

    print(f"--- Environment Verification ---")
    print(f"Python Path: {python_exe}")  #  반드시 프로젝트 폴더 내 .venv 경로여야 함
    print(f"Node Version: {os.popen('node -v').read().strip()}")  #  mise가 잡은 노드 버전

    if "backend/.venv" in python_exe:
        print("Status: Isolated (Project Level)")  #  격리 성공
    else:
        print("Status: Global (System Level - Warning)")


if __name__ == "__main__":
    verify_isolated_env()
```

## 📋 "No Global" 환경의 장점

완벽한 격리: 시스템의 파이썬이나 노드 버전을 건드리지 않습니다.

**이동성:** .mise.toml, pyproject.toml, package.json만 있으면 다른 우분투 서버에서도 mise install과 uv sync만으로 즉시 복구가 가능합니다.

**충돌 방지:** 프로젝트 A는 Python 3.10, 프로젝트 B는 3.13을 사용해도 아무런 문제가 없습니다.

## 프로젝트 터미널 실행

```bash
cd backend
uv run uvicorn app.main:app --reload
```

```bash
cd frontend
npm run dev
```
