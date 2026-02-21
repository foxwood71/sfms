# Rocky Linux 9 uv 설치 가이드

uv는 Rust로 작성된 초고속 Python 패키지 및 프로젝트 매니저입니다. Rocky Linux 9에서 공식 설치 스크립트를 사용해 간단히 설치할 수 있습니다. [docs.astral](https://docs.astral.sh/uv/getting-started/installation/)

## 1. 사전 요구사항

```bash
# 시스템 업데이트 및 curl 설치 확인
sudo dnf update -y
which curl || sudo dnf install curl -y
```

## 2. uv 설치 (공식 스크립트 - 권장)

```bash
# 설치 스크립트 실행 (현재 사용자 홈에 ~/.cargo/bin/uv 설치)
curl -LsSf https://astral.sh/uv/install.sh | sh

# wget 대안
wget -qO- https://astral.sh/uv/install.sh | sh
```

## 3. PATH 설정 및 확인

```bash
# 쉘 프로파일에 PATH 추가 (~/.bashrc 또는 ~/.zshrc)
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 설치 확인
uv --version
```

## 4. Snap을 통한 설치 (대안)

```bash
# EPEL 및 snapd 설치
sudo dnf install epel-release -y
sudo dnf install snapd -y
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap

# snap으로 uv 설치
sudo snap install astral-uv --classic
```

## 5. uv로 Python 설치 관리 및 프로젝트 초기화 예시

### 5.1. Python 설치

```bash
# 최신 Python 설치 (자동 다운로드)
uv python install

# 특정 버전 설치
uv python install 3.12
uv python install 3.11.9
uv python install 3.12.3  # 패치 버전 지정

# 기본 python/python3 별칭 설치 (실험적)
uv python install --default 3.12
```

### 5.2. 설치된 Python 목록 확인

```bash
# 전체 목록 (설치됨 + 다운로드 가능)
uv python list

# 설치된 버전만 (일부 버전에서 지원)
uv python list --only-installed

# 설치 경로 확인
uv python dir
```

### 5.3. Python 사용 예시

```bash
# 특정 버전으로 스크립트 실행
uv run --python 3.12 python -c "print('Hello uv!')"

# 프로젝트에 고정 (pyproject.toml)
uv python pin 3.12
```

### 5.4. 삭제 및 관리

```bash
# Python 삭제
uv python uninstall 3.11

# 특정 버전 찾기
uv python find 3.12
```

### 5.5. 프로젝트 초기화 예시

```bash
# 새 프로젝트 생성
uv init myproject
cd myproject

# 의존성 추가
uv add requests

# 가상환경 생성 및 활성화
uv sync
```

## 6. 패키지 관리 가이드

### 6.1. 패키지 추가/제거

```bash
# 패키지 추가 (의존성/개발 의존성)
uv add requests flask
uv add --dev pytest black ruff  # 개발용

# 특정 버전 고정
uv add "requests==2.31.0"

# Git 저장소
uv add "git+https://github.com/user/repo.git"

# 로컬 디렉토리
uv add "./local-package"
```

### 6.2. 의존성 동기화/설치

```bash
# pyproject.toml 기준으로 설치
uv sync

# requirements.txt에서 설치
uv pip install -r requirements.txt

# 개발 의존성 포함
uv sync --dev
```

### 6.3. 패키지 목록 확인

```bash
# 설치된 패키지 목록
uv pip list

# 트리 구조 보기
uv pip tree

# 아웃데이트된 패키지
uv pip check
```

### 6.4. 패키지 업그레이드/제거

```bash
# 모든 패키지 최신화
uv sync --upgrade-package requests
uv sync --upgrade  # 전체 업그레이드

# 패키지 제거
uv remove requests
uv remove --dev pytest
```

### 6.5. 스크립트/도구 실행

```bash
# .venv 자동 사용
uv run python main.py
uv run pytest

# 전역 도구 설치
uv tool install ruff black
uvx ruff check .  # 임시 실행
```

## 7. Python 가상환경 설정

### 7.1. 가상환경 생성 (.venv - 기본)

```bash
# 프로젝트 디렉토리에서 실행
mkdir myproject && cd myproject
uv venv
```

### 7.2. 특정 Python 버전 지정

```bash
# 설치된 Python 버전으로 생성
uv venv --python 3.12
uv venv --python python3.11

# uv가 자동 다운로드 (python.python-download 권한 필요)
uv venv --python 3.12.0
```

### 7.3. 가상환경 활성화/비활성화

```bash
# 활성화 (zsh/bash)
source .venv/bin/activate
# 프롬프트에 (.venv) 표시

# 비활성화
deactivate
```

### 7.4. 프로젝트 전체 관리 (권장)

```bash
# 프로젝트 초기화 (pyproject.toml + .venv 자동 생성)
uv init myproject
cd myproject
uv add requests flask  # 의존성 추가 + .venv 생성/동기화

# 의존성 동기화
uv sync
uv run python main.py  # .venv 자동 사용
```

### 7.6. 확인 및 관리

```bash
# 패키지 목록
uv pip list

# 환경 위치 확인
uv venv list

# 환경 삭제
rm -rf .venv
```

## 8. uv 치트시트 (Python 패키지 관리자)

**Rust 기반 초고속 pip/venv 대체재** - 10-100배 빠름! [docs.astral](https://docs.astral.sh/uv/getting-started/installation/)

### 8.1. 🚀 프로젝트 초기화

```bash
uv init myproject           # pyproject.toml + .venv 생성
cd myproject
uv init --app               # CLI 앱용
```

### 8.2. 🗃️ 가상환경 관리

```bash
uv venv                    # .venv 생성 (시스템 Python)
uv venv --python 3.12      # Python 3.12 사용
uv venv --python 3.12.3    # 정확한 버전
source .venv/bin/activate  # 활성화
```

### 8.3. 📦 패키지 설치/관리

```bash
uv add requests flask           # 의존성 추가 (pyproject.toml)
uv add --dev pytest ruff        # 개발 의존성
uv add "requests==2.31.0"       # 버전 고정
uv sync                         # pyproject.toml 기준 설치
uv sync --dev                   # 개발 의존성 포함
uv remove requests              # 제거
```

### 8.4. 🐍 Python 버전 관리

```bash
uv python install           # 최신 Python
uv python install 3.12      # 3.12 설치
uv python list              # 설치 목록
uv python uninstall 3.11    # 삭제
uv run --python 3.12 python main.py  # 특정 버전 실행
```

### 8.5. ⚡ 실행/스크립트

```bash
uv run python main.py       # .venv 자동 사용
uv run pytest               # 테스트 실행
uv run --with flask python  # 임시 패키지 추가
uvx ruff check .            # 전역 도구 임시 실행
```

### 8.6. 🔍 상태 확인

```bash
uv pip list                 # 설치된 패키지
uv pip tree                 # 의존성 트리
uv pip check                # 호환성 검사
uv lock                     # lockfile 생성
```

### 8.7. 🧹 정리/업그레이드

```bash
uv sync --upgrade           # 모든 패키지 최신화
uv sync --upgrade-package requests  # 특정 패키지만
uv cache clean              # 캐시 정리
```

### 8.8. 📝 pyproject.toml 예시

```toml
[project]
name = "myproject"
dependencies = [
    "fastapi>=0.100",
    "uvicorn[standard]"
]

[tool.uv]
dev-dependencies = [
    "pytest",
    "ruff",
    "black"
]
```

### 8.9. ⚙️ mise + uv 조합 (권장)

```toml
# .mise.toml
[tools]
python = "3.12"

[env]
# 자동 .venv 생성
_.python.venv = { path = ".venv" }
PATH = [".venv/bin"]
```

### 8.10. 🔄 워크플로우

```text
1. git clone sfms
2. mise trust      # 자동 Python 버전
3. uv sync         # 3초 패키지 설치
4. uv run uvicorn main:app --reload
```

### 8.11. 🚀 vs pip 비교

| 작업 | pip | uv |
| ------ | ----- | ---- |
| 프로젝트 생성 | `venv; pip install` | `uv init` |
| 패키지 추가 | `pip install pkg` | `uv add pkg` |
| 동기화 | 30초 | **3초** |
| lockfile | 수동 | `uv lock` 자동 |

**핵심:** `uv init` → `uv add` → `uv sync` → `uv run` 4단계로 완성! ⚡

## 문제 해결

| 문제 | 해결방법 |
| ------ | ----------- |
| `command not found: uv` | `source ~/.zshrc` 또는 로그아웃/재로그인 |
| curl 오류 | `sudo dnf install ca-certificates` |
| PATH 안 먹힘 | `export PATH="$HOME/.cargo/bin:$PATH"` 임시 추가 |
| No Python version found | sudo dnf install python3.11 python3.12 |
| 권한 오류 | --python $(which python3.12) |
| PATH 문제 | source ~/.zshrc 후 재시도 |

**완료!** `uv python install`로 Python 버전도 자동 관리 가능합니다. [newkimjiwon.tistory](https://newkimjiwon.tistory.com/544)
