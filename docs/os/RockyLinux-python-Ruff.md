# Ruff 설치 및 VSCode 설정 가이드 (uv + mise 환경)

**Ruff**는 Rust로 작성된 **초고속 Python 린터/포맷터**입니다. flake8 + black + isort를 100배 빠르게 대체! [velog](https://velog.io/@qlgks1/python-uv-ruff-%EC%84%A4%EC%B9%98%EB%B6%80%ED%84%B0-project-initializing-%EC%99%9C-%EC%A3%BC%EB%AA%A9-%EB%B0%9B%EB%8A%94%EA%B0%80)

## 1. Ruff 설치 (uv 사용)

```bash
# 프로젝트 개발 의존성으로 추가
uv add --dev ruff

# 또는 전역 도구
uv tool install ruff

# mise 프로젝트 (.mise.toml)
[tools]
ruff = "latest"
```

## 2. 기본 사용법

```bash
# 린트 (오류 검사)
ruff check .

# 자동 수정
ruff check --fix .

# 포맷팅
ruff format .

# 전체 실행
ruff check --fix && ruff format .
```

## 3. VSCode 확장 설치

1. **Ruff 확장 설치** (`charliermarsh.ruff`)
2. **Python 확장** (`ms-python.python`)

## 4. VSCode 설정 (.vscode/settings.json)

```json
{
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
  "ruff.enableExperimentalCodeActions": true
}
```

## 5. pyproject.toml 설정

```toml
[tool.ruff]
line-length = 120
indent-width = 4

[tool.ruff.lint]
select = ["E", "F", "I", "B", "Q"]
ignore = ["E501"]  # 라인 길이 무시

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
```

## 6. pre-commit 훅 설정 (.pre-commit-config.yaml)

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.9
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

## 7. 워크플로우 (mise + uv + ruff)

```bash
# 프로젝트 셋업
mise trust      # 자동 Python 버전
uv sync --dev   # ruff 포함 설치
pre-commit install

# 개발
uv run python main.py  # 자동 린트
# 저장 시 VSCode 자동 포맷/린트
git commit       # pre-commit 자동 실행
```

## 8. 확인 및 테스트

```bash
# 린트 결과 확인
ruff check . --output-format full

# 포맷 확인
ruff format . --diff

# VSCode 실시간 확인
# 빨간선 = 오류, 노란선 = 경고
```

## 🚀 Ruff vs 기존 도구

| 도구 | 속도 | 기능 | Ruff |
| ------ | ------ | ------ | ------ |
| **flake8** | 느림 | 린트 | ✅ 150+ 린터 |
| **black** | 보통 | 포맷 | ✅ Black 호환 |
| **isort** | 느림 | 정렬 | ✅ 내장 |
| **mypy** | 느림 | 타입체크 | ❌ 별도 (pyright 추천) |

**완료!** 저장할 때마다 자동 린트/포맷 = 깨끗한 코드 보장! 🎉
