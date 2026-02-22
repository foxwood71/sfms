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
pnpm run dev        # http://localhost:5173 실행
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
- Ruff: `uv run ruff check .`


아래는 지금 작성하신 “6. 자체서명 / 6.2 로컬 CA” 문서에 **SAN(localhost)** 를 자연스럽게 끼워 넣어 보완한 버전입니다. 

## 6. 자체서명(Self-signed) TLS 인증서 생성방법 (SAN 포함 보완)

(요즘 TLS는 CN만으로는 부족해서 `subjectAltName`을 넣는 게 사실상 필수라서, `localhost`면 `DNS:localhost`(+ 필요 시 `IP:127.0.0.1`)를 넣는 형태로 정리했습니다.)

```bash
# key + crt 한 번에 생성 (RSA 2048, 1년) + SAN( localhost, 127.0.0.1 )
openssl req -newkey rsa:2048 -nodes \
  -keyout server.key \
  -x509 -days 365 -sha256 \
  -out server.crt \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
```
- `-addext "subjectAltName=..."`로 SAN을 추가하는 방식입니다.
- OpenSSL 버전/환경에 따라 `-addext`가 불편하면, 아래 6.1.1의 extfile 방식으로 대체할 수 있습니다.
  
#### 6.1.1 (대안) extfile로 SAN 넣기

```bash
cat > san.ext <<'EOF'
subjectAltName=DNS:localhost,IP:127.0.0.1
EOF

openssl req -newkey rsa:2048 -nodes \
  -keyout server.key \
  -new -sha256 -subj "/CN=localhost" \
  -out server.csr

openssl x509 -req -in server.csr \
  -signkey server.key \
  -out server.crt -days 365 -sha256 \
  -extfile san.ext
```
`openssl x509 ... -extfile`로 확장(SAN)을 인증서에 포함시키는 패턴입니다.


### 6.2 [추천] 로컬 CA + 서버 인증서(서명) 생성 (SAN 포함)
> CA를 만들어 두고 서버 인증서를 CA로 서명하면, 클라이언트/브라우저에 **CA만** 신뢰시켜서 경고를 줄일 수 있습니다

#### 6.2.1 CA 키/인증서 만들기

```bash
openssl genrsa -des3 -out ca.key 2048
openssl req -new -x509 -sha256 -key ca.key -out ca.crt
```

#### 6.2.2 서버 키 + CSR 만들기 (CSR에 SAN 넣기)
SAN을 CSR에 넣으려면 `-reqexts` + `-config`를 쓰는 방식이 흔합니다

```bash
openssl genrsa -out server.key 2048

openssl req -new -sha256 \
  -key server.key \
  -out server.csr \
  -subj "/CN=localhost" \
  -reqexts SAN \
  -config <(printf "[req]\ndistinguished_name=req\n[SAN]\nsubjectAltName=DNS:localhost,IP:127.0.0.1\n")
```
서버 인증서의 CN은 실제 접속하는 FQDN(또는 개발용 도메인)으로 맞추는 게 기본입니다.

#### 6.2.3 CA로 서버 인증서 서명 (인증서에 SAN “확실히” 포함)
중요: 환경에 따라 “CSR에 SAN이 들어있어도” 서명 결과(cert)에 SAN이 안 들어가는 케이스가 있어서, 서명 단계에서도 `-extfile`/`-extensions`로 SAN을 명시해주는 게 가장 안전합니다. 

```bash
cat > v3.ext <<'EOF'
subjectAltName=DNS:localhost,IP:127.0.0.1
EOF

openssl x509 -req -in server.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days 365 -sha256 \
  -extfile v3.ext
```
(필요 시 `-extensions`를 쓰는 변형도 있지만, 위처럼 단순 extfile로도 SAN을 넣을 수 있습니다.) 

***

### 6.3 SAN 포함 여부 확인

```bash
openssl x509 -in server.crt -noout -ext subjectAltName
```
인증서에 SAN이 실제로 들어갔는지 확인하는 방법입니다. 

원하시는 접근이 `https://localhost`만 쓰는지, `https://127.0.0.1`로도 접근하는지에 따라 SAN에서 `IP:127.0.0.1`는 빼도 됩니다.


## 6.4 생성 파일 저장 위치/권한 가이드

### 6.4.1 파일별 역할
- `server.key`: 서버 **개인키**(절대 외부 노출 금지).  
- `server.crt`: 서버 **인증서**(공개 가능, 배포 대상).  
- `ca.key`: 로컬 CA **개인키**(가장 민감, 오프라인 보관 권장).  
- `ca.crt`: 로컬 CA **인증서**(클라이언트/브라우저에 “신뢰”로 설치하는 파일).  

### 6.4.2 (리눅스 일반/서비스 설치) 권장 경로

배포판마다 관례가 조금 다른데, RHEL/Rocky 계열은 보통 아래 경로를 많이 씁니다.
- 인증서(`*.crt`) : `/etc/pki/tls/certs/`
- 개인키(`*.key`) : `/etc/pki/tls/private/`

NGINX 같은 웹서버 설정에서도 “인증서 경로 + 키 경로”를 파일로 지정해 사용합니다.

### 6.4.3 권한(중요)

개인키(`server.key`, `ca.key`)는 최소 권한으로:

```bash
sudo chown root:root /etc/pki/tls/private/server.key
sudo chmod 600 /etc/pki/tls/private/server.key
```
`600`은 “소유자만 읽기/쓰기”라서 개인키 보호에 흔히 쓰는 설정입니다.

### 6.4.4 (로컬 개발/Podman) 추천 방식
로컬 1세트(개발용)라면 시스템 경로에 넣기보다, 프로젝트 외부의 “secrets 디렉터리”에 두고 **Podman secret로 주입**하는 게 관리가 편합니다. Podman secret는 컨테이너 안에서 `/run/secrets/<secretname>` 파일로 접근하는 방식이 기본입니다. [docs.podman](https://docs.podman.io/en/latest/markdown/podman-secret-create.1.html)

예시(호스트에 보관 → podman secret로 등록):

```bash
mkdir -p ~/secrets/tls
chmod 700 ~/secrets ~/secrets/tls

# 파일을 secrets 디렉터리에 보관
cp server.crt server.key ~/secrets/tls/
chmod 600 ~/secrets/tls/server.key

# Podman secret로 등록(컨테이너에 /run/secrets/... 로 들어감)
podman secret create tls_crt ~/secrets/tls/server.crt
podman secret create tls_key ~/secrets/tls/server.key
```
`podman secret create`는 파일 경로를 입력으로 받아 secret을 만들 수 있습니다. [docs.podman](https://docs.podman.io/en/latest/markdown/podman-secret-create.1.html)

## 6.5 리버스 프록시 컨테이너에 TLS 적용 (NGINX / Traefik)

리버스 프록시 컨테이너에서 TLS 종료를 할 때는 “컨테이너 내부에서 읽을 수 있는 경로에 인증서/키가 있어야” 하고, NGINX는 `ssl_certificate`, `ssl_certificate_key`로 파일 경로를 지정합니다. Podman을 쓰면 TLS 키/인증서를 `podman secret`으로 넣고 기본 경로(`/run/secrets/...`)로 읽게 만들 수 있습니다. [nginx](https://nginx.org/en/docs/http/configuring_https_servers.html)

### 6.5.1 공통 전제 (파일/시크릿 이름)

- 인증서: `server.crt` (또는 fullchain 성격이면 `server.crt`에 체인 포함) [nginx](https://nginx.org/en/docs/http/configuring_https_servers.html)
- 개인키: `server.key` (외부 노출 금지) [nginx](https://nginx.org/en/docs/http/configuring_https_servers.html)
- Podman secret 이름 예시: `tls_crt`, `tls_key` (컨테이너 내부 기본 경로는 `/run/secrets/tls_crt`, `/run/secrets/tls_key`) [redhat](https://www.redhat.com/en/blog/new-podman-secrets-command)

### 6.5.2 NGINX 컨테이너에 TLS 적용

NGINX 설정에서 아래처럼 지정합니다. [nginx](https://nginx.org/en/docs/http/configuring_https_servers.html)

```nginx
server {
  listen 443 ssl;
  server_name localhost;

  ssl_certificate     /run/secrets/tls_crt;
  ssl_certificate_key /run/secrets/tls_key;

  # ... location / { proxy_pass ...; } 등
}
```

NGINX는 인증서는 클라이언트에 제공되는 공개 정보지만, 개인키는 접근 권한을 제한해야 한다고 명시합니다. [nginx](https://nginx.org/en/docs/http/configuring_https_servers.html)

### 6.5.3 Traefik 컨테이너에 TLS 적용 (File provider 기준)
Traefik은 파일 provider(dynamic configuration)로 `certFile`, `keyFile` 경로를 지정해 인증서를 로드할 수 있습니다. [doc.traefik](https://doc.traefik.io/traefik/https/tls/)

예시(toml):
```toml
[[tls.certificates]]
  certFile = "/run/secrets/tls_crt"
  keyFile  = "/run/secrets/tls_key"
```
Traefik 문서에서도 이 방식은 file provider로 정의하는 형태를 예시로 들고 있습니다. [doc.traefik](https://doc.traefik.io/traefik/https/tls/)

### 6.5.4 Podman secret로 컨테이너에 주입하는 방법 (개념)
- secret 생성: `podman secret create <이름> <파일>` 형태로 만들 수 있습니다. [docs.podman](https://docs.podman.io/en/latest/markdown/podman-secret-create.1.html)
- 컨테이너 실행 시 `--secret` 옵션으로 주입하며, 기본 마운트 위치는 `/run/secrets/<secretname>`이고 `target=`으로 파일명/경로를 바꿀 수 있습니다. [docs.podman](https://docs.podman.io/en/v4.6.0/markdown/options/secret.html)

(실제 `podman run`/`podman-compose` 예시는 사용하실 compose/구성 방식에 맞춰 6.6 같은 절로 따로 적는 게 안전합니다.)


## 문제 해결
| 증상 | 해결 |
|------|------|
| `mise: command not found` | `mise activate bash` → `source ~/.bashrc` [perplexity](https://www.perplexity.ai/search/41930b37-0f31-4bfc-b199-c4f0c633430c) |
| 버전 안 바뀜 | `mise trust --force` 재실행 [perplexity](https://www.perplexity.ai/search/06a0e234-5cb8-4d74-acce-0c188a4a4cdc) |
| uv sync 느림 | `uv cache clean` 후 재시도 |
| .env 안 로드 | `uv add python-dotenv` + `load_dotenv()` [perplexity](https://www.perplexity.ai/search/c1ee5dbc-d006-45f4-8aa7-be645595d229) |

셋업 완료! `mise doctor`로 환경 진단 후 개발 시작하세요. [perplexity](https://www.perplexity.ai/search/41930b37-0f31-4bfc-b199-c4f0c633430c)

## 참고
OpenSSL 명령어는 각각의 파일(`.key`, `.csr`, `.crt`)을 생성하거나 변환하는 단계별 도구라고 보시면 됩니다. [

핵심 명령어와 파일/개념의 관계를 정리해 드릴게요.

### 1. `openssl genrsa` : 개인키(`.key`) 생성
가장 먼저 비밀번호 역할을 하는 **개인키**를 만드는 도구입니다.
- **명령어**: `openssl genrsa -out server.key 2048`
- **관계**: `server.key` 파일이 생성됩니다. 이 키는 나중에 CSR을 만들거나 인증서를 서명할 때 "주인 증명"용으로 계속 쓰입니다.

### 2. `openssl req` : 인증 요청서(`.csr`) 및 주체 정보(`CN`, `SAN`) 설정
인증서에 들어갈 **신원 정보**(누구인지)를 작성하고 공개키를 추출하는 도구입니다. 
- **명령어**: `openssl req -new -key server.key -out server.csr`
- **관계**: 
  - 실행 중 입력하는 정보가 `CN`(Common Name) 등 주체 정보가 됩니다. 
  - `-addext` 옵션을 붙이면 이때 `SAN` 정보를 포함시킬 수 있습니다. 
  - 결과물인 `server.csr`은 "나 이런 정보로 인증서 만들어줘"라는 요청서 파일입니다.

### 3. `openssl x509` : 최종 인증서(`.crt`) 발급 및 서명
요청서(`.csr`)를 바탕으로 실제 쓸 수 있는 **인증서**를 찍어내는 도구입니다.
- **명령어**: `openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key ... -out server.crt`
- **관계**: 
  - `server.csr`의 내용에 **CA의 서명**을 더해 `server.crt`를 완성합니다.
  - `-extfile` 옵션을 통해 최종 인증서에 `SAN` 정보를 "확정"해서 박아넣는 단계이기도 합니다.

### 4. `openssl req -x509` : 한 번에 생성 (Short-cut)
CSR 단계를 건너뛰고 개인키와 자체서명 인증서를 한 번에 만듭니다.
- **명령어**: `openssl req -x509 -newkey rsa:2048 ... -keyout server.key -out server.crt`
- **관계**: `server.key`와 `server.crt`가 동시에 나옵니다. 테스트용으로 가장 많이 쓰이며, 이때 `-addext`로 `SAN`을 넣으면 한 번에 끝납니다. 

### 요약 표
| OpenSSL 명령 | 결과물 | 관련 개념 | 비고 |
| :--- | :--- | :--- | :--- |
| **genrsa** | `.key` | 개인키 | 비밀번호 생성 단계 |
| **req** | `.csr` | `CN`, `SAN` | "나 누구소" 정보 입력 단계 |
| **x509** | `.crt` | **CA 서명**, `SAN` 확정 | 최종 신분증 발급 단계 |

결론적으로, **`req`는 정보를 묻는 도구**이고, **`x509`는 그 정보를 증명서로 만드는 도구**라고 이해하시면 됩니다. 

## 5. 서버 구동 필수 파일 (2개)
- **`server.key` (개인키)**: 서버가 암호화를 복호화하거나 본인임을 증명할 때 쓰는 비밀 키입니다.
- **`server.crt` (인증서)**: 클라이언트(브라우저)에게 "나는 신뢰할 수 있는 서버다"라고 보여주는 신분증입니다.
대부분의 서버 설정(NGINX 등)에서 이 두 경로만 지정하면 HTTPS가 활성화됩니다. 

## 6. 추가로 알아두면 좋은 파일 (선택 사항)
상황에 따라 파일이 하나 더 필요할 수도 있습니다.

- **`ca.crt` (또는 Chain 인증서)**: 
  - 만약 로컬 CA를 만들어 서명했다면, 클라이언트(브라우저)가 서버의 `server.crt`를 믿게 하기 위해 **클라이언트 기기에 이 `ca.crt`를 수동으로 설치(신뢰할 수 있는 루트 인증서로 등록)**해야 경고가 뜨지 않습니다.
  - 서버 설정에 따라 `server.crt`와 `ca.crt`를 하나로 합친 파일(Full-chain)을 요구하기도 합니다.


**결론**: 개발 환경에서는 생성하신 **`server.crt`와 `server.key`만 있으면 서버를 띄울 수 있습니다.**  다만, 브라우저에서 "안전하지 않음" 경고를 없애고 싶을 때만 `ca.crt`를 PC에 등록하는 작업이 추가되는 것입니다.

## 7. CA 등록 PowerShell 스크립트
로컬 CA 인증서(`ca.crt`)를 Windows의 **'신뢰할 수 있는 루트 인증 기관'** 저장소에 등록하는 PowerShell 스크립트입니다. 이 작업을 수행하면 브라우저에서 자체 서명 인증서에 대한 "안전하지 않음" 경고가 사라집니다. 

반드시 **PowerShell을 관리자 권한으로 실행**해야 합니다.

```powershell
# 1. 등록할 ca.crt 파일의 전체 경로를 지정하세요.
$certPath = "C:\Users\YourName\Documents\ca.crt" 

# 파일 존재 여부 확인
if (-Not (Test-Path $certPath)) {
    Write-Error "인증서 파일을 찾을 수 없습니다: $certPath"
    exit
}

try {
    # 'LocalMachine\Root'는 '신뢰할 수 있는 루트 인증 기관' 저장소입니다.
    # 이 명령을 통해 시스템 전체 사용자가 이 CA를 신뢰하게 됩니다.
    Import-Certificate -FilePath $certPath -CertStoreLocation "Cert:\LocalMachine\Root"
    
    Write-Host "--------------------------------------------------------"
    Write-Host "성공: CA 인증서가 '신뢰할 수 있는 루트 인증 기관'에 등록되었습니다." -ForegroundColor Green
    Write-Host "이제 브라우저를 재시작하면 해당 CA로 서명된 localhost 인증서가 신뢰됩니다."
    Write-Host "--------------------------------------------------------"
} catch {
    Write-Error "인증서 등록 중 오류가 발생했습니다: $_"
}
```

## 스크립트 실행 후 주의사항
1. **브라우저 재시작**: 크롬이나 에지 브라우저를 완전히 종료했다가 다시 켜야 변경사항이 반영됩니다.
2. **파이어폭스(Firefox)**: 파이어폭스는 윈도우 인증서 저장소를 쓰지 않고 자체 저장소를 쓰기 때문에, 설정에서 수동으로 `ca.crt`를 불러와야 할 수도 있습니다.
3. **삭제 방법**: 만약 나중에 삭제하고 싶다면 `certlm.msc`를 실행한 뒤, '신뢰할 수 있는 루트 인증 기관' 항목에서 등록한 CA 이름을 찾아 삭제하면 됩니다.

이제 이 스크립트로 `ca.crt`를 등록하면, 아까 만드신 `server.crt`(localhost용)를 사용하는 사이트에 접속할 때 경고 창이 뜨지 않을 것입니다.