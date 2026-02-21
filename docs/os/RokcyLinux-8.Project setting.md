# Mise + UV 관리 FastAPI + React/Vite 프로젝트 셋업 가이드

git clone 후 mise/uv가 관리하는 FastAPI 백엔드와 React/Vite 프론트엔드 프로젝트를 완벽하게 셋업하는 순서입니다. [perplexity](https://www.perplexity.ai/search/0ec474c8-cfd7-4540-a296-54b07075c854)

mise가 Node/Python 버전을 자동 전환하고, uv가 Python 의존성을 초고속 설치합니다. [perplexity](https://www.perplexity.ai/search/c1ee5dbc-d006-45f4-8aa7-be645595d229)

## 사전 요구사항
- mise 설치 확인: `mise --version` (없으면 `curl https://mise.jdx.dev/install.sh | sh` 후 `mise activate bash` 추가). [perplexity](https://www.perplexity.ai/search/41930b37-0f31-4bfc-b199-c4f0c633430c)
- WSL/Ubuntu 환경 가정 (사용자 환경).
- VSCode + Remote-WSL 확장 설치.

## 1. 클론 & Mise 초기화
```
git clone <repo-url>
cd <project-root>  # .mise.toml 있는 루트
mise trust         # .mise.toml 신뢰 (필수!)
mise install       # Node/Python/pnpm 자동 설치/전환
```
- `.mise.toml` 예: `node = "22"`, `python = "3.12"`, `pnpm = "9"`. [perplexity](https://www.perplexity.ai/search/06a0e234-5cb8-4d74-acce-0c188a4a4cdc)
- 새 터미널에서도 자동 버전 전환. [perplexity](https://www.perplexity.ai/search/0ec474c8-cfd7-4540-a296-54b07075c854)

## 2. 백엔드 (FastAPI) 셋업
```
cd backend
mise trust          # 서브디렉토리 mise.toml 신뢰 (필요시)
uv sync             # pyproject.toml 기반 venv + deps 설치 (pip 100배 빠름)
uv run uvicorn app.main:app --reload  # 테스트 실행
```
- `.env` 자동 로드: `python-dotenv` deps 확인, `load_dotenv()` in main.py. [perplexity](https://www.perplexity.ai/search/c1ee5dbc-d006-45f4-8aa7-be645595d229)
- DB: PostgreSQL 로컬 실행 후 `DATABASE_URL` 설정. [perplexity](https://www.perplexity.ai/search/90c1acf8-4db3-4cea-b1e8-ce82eb71ef05)

## 3. 프론트엔드 (React/Vite) 셋업
```
cd ../frontend
mise trust          # 서브디렉토리 mise.toml 신뢰 (필요시)
pnpm install        # package.json deps 설치 (pnpm 빠름)
pnpm dev            # http://localhost:5173 실행
```
- Tailwind/Vite/TS 최적화 가정.

## 4. VSCode 통합 설정
프로젝트 루트 `.vscode/settings.json` 생성/편집:
```json
{
  "terminal.integrated.profiles.linux": {
    "Backend (uv)": { "path": "mise", "args": ["exec", "--", "uv", "run", "bash"], "cwd": "${workspaceFolder:backend}" },
    "Frontend (pnpm)": { "path": "pnpm", "args": ["exec", "bash"], "cwd": "${workspaceFolder:frontend}" }
  },
  "terminal.integrated.defaultProfile.linux": "Backend (uv)"
}
```
- 새 터미널(Ctrl+Shift+`) → 드롭다운 선택 → 자동 cwd/venv.[cite:44]

## 5. 추가 도구 & 테스트
```
# 린팅/포맷 (Ruff 권장)
uv add --dev ruff  # 백엔드
pnpm add -D @biomejs/biome  # 프론트

# DB/서버 테스트
uv run python -c "print('✅ Backend ready')"
pnpm dev  # 프론트 확인
```
- Ruff: `uv run ruff check .`. [perplexity](https://www.perplexity.ai/search/0ec474c8-cfd7-4540-a296-54b07075c854)

## 문제 해결
| 증상 | 해결 |
|------|------|
| `mise: command not found` | `mise activate bash` → `source ~/.bashrc` [perplexity](https://www.perplexity.ai/search/41930b37-0f31-4bfc-b199-c4f0c633430c) |
| 버전 안 바뀜 | `mise trust --force` 재실행 [perplexity](https://www.perplexity.ai/search/06a0e234-5cb8-4d74-acce-0c188a4a4cdc) |
| uv sync 느림 | `uv cache clean` 후 재시도 |
| .env 안 로드 | `uv add python-dotenv` + `load_dotenv()` [perplexity](https://www.perplexity.ai/search/c1ee5dbc-d006-45f4-8aa7-be645595d229) |

셋업 완료! `mise doctor`로 환경 진단 후 개발 시작하세요. [perplexity](https://www.perplexity.ai/search/41930b37-0f31-4bfc-b199-c4f0c633430c)