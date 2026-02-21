# Rocky Linux mise 설치 순서 (단계별 가이드)

mise는 Rust 기반 다중 언어 버전 관리 도구로, nvm/fnm/uv와 함께 사용하면 개발 환경이 완벽해집니다. [perplexity](https://www.perplexity.ai/search/0ec474c8-cfd7-4540-a296-54b07075c854)

## 1. 사전 요구사항 확인

```bash
# 시스템 업데이트
sudo dnf update -y

# 필수 패키지
sudo dnf install curl git -y
```

## 2. mise 설치 스크립트 실행

```bash
curl https://mise.jdx.dev/install.sh | sh
# 또는
wget -qO- https://mise.jdx.dev/install.sh | sh
```

## 3. uv 먼저 설치 (mise와 독립, 상세는 RokyLinux-python-uv참조)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## 4. 쉘 프로파일 설정 (중요!)

```bash
# zsh 사용자
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
source ~/.zshrc

# bash 사용자
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
source ~/.bashrc
```

## 5. 설치 확인

```bash
mise --version
mise doctor  # 환경 진단
```

## 6. 첫 사용 설정

```bash
# 글로벌 도구 설치 (선택)
mise install node@latest python@3.12 pnpm

# 새 쉘에서 자동 활성화 확인
mise ls  # 설치된 도구 목록
```

## 7. 프로젝트 설정 (.mise.toml)

프로젝트 루트에 생성:

```toml
[tools]
node = "22"
python = "3.12"
pnpm = "9"

[env]
DATABASE_URL = "postgresql://localhost/sfms"
```

## 8. 프로젝트 사용

```bash
cd myproject
mise trust    # .mise.toml 신뢰
mise install  # 자동 설치
uv sync       # Python 패키지
pnpm install  # Node 패키지
```

## 9. mise 주요 명령어 치트시트

mise의 핵심 명령어를 단계별로 정리했습니다. 프로젝트 전환 시 자동 버전 관리에 유용합니다. [itsmo](https://www.itsmo.dev/introduce-mise/)

### 9.1. 기본 정보 확인

```bash
mise --version     # mise 버전
mise doctor        # 환경 진단
mise ls            # 설치된 도구/버전 목록
```

### 9.2. 도구 설치 및 관리

```bash
mise install        # .mise.toml 기준 자동 설치
mise install node@22 python@3.12  # 특정 도구
mise i node@latest  # 별칭 사용
```

### 9.3. 버전 설정

```bash
# 전역 설정
mise use -g node@22    # ~/.config/mise/config.toml
mise use --global python@3.12

# 프로젝트 로컬 설정
mise use node@18       # .mise.toml 생성
mise pin node@22.1.0   # 정확한 버전 고정
```

### 9.4. 프로젝트 작업

```bash
cd myproject
mise trust           # .mise.toml 신뢰 (필수!)
mise install         # 자동 설치
mise ls              # 프로젝트 도구 확인
```

### 9.5. 업데이트 및 정리

```bash
mise upgrade         # 모든 도구 최신화
mise upgrade node    # 특정 도구만
mise uninstall node@18  # 버전 삭제
mise cleanup         # 사용 안하는 버전 정리
```

### 9.6. 쉘 통합 (새 터미널용)

```bash
# ~/.zshrc에 추가 (이미 했으면 생략)
mise activate zsh     # 설정 출력 복사
# 또는
eval "$(mise activate zsh)"
```

### 9.7. 유용한 별칭

```bash
mise i    # install
mise u    # upgrade  
mise ls-r # ls-remote (설치 가능 버전)
```

### 워크플로우 예시

```text
1. git clone sfms
2. cd sfms/backend
3. mise trust
4. mise install    # node/python 자동
5. uv sync        # Python 패키지
6. cd ../frontend
7. pnpm install   # Node 자동 전환
```

**핵심:** `mise trust` → `mise install` 두 단계로 완성! [haril](https://haril.dev/blog/2024/06/27/Easy-devtools-version-management-mise)

## 검증 체크리스트

- [x] `mise --version` 동작
- [x] 새 터미널에서 `node --version` 자동 전환
- [x] `uv python list` 동작
- [x] 프로젝트 이동 시 버전 자동 변경

## 문제 해결

| 단계 | 오류 | 해결 |
| --- | --- | --- |
| 2 | curl 실패 | `sudo dnf install ca-certificates` |
| 3 | 쉘 재시작 후 동작 안함 | 로그아웃/재로그인 |
| 6 | .mise.toml 무시 | `mise trust` 필수 |

**완료!** 이제 mise + uv + pnpm으로 초고속 개발 환경 구축! 🚀 [perplexity](https://www.perplexity.ai/search/c1ee5dbc-d006-45f4-8aa7-be645595d229)
