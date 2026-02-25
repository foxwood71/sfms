# 로컬CA와 자체서명(Self-signed) TLS 인증서 생성방법 (SAN 포함)의 순서

로컬 개발 환경(`localhost`)에서 HTTPS를 완벽하게 지원하려면, 단순히 자체 서명된 인증서를 만드는 것을 넘어 **로컬 CA(최상위 인증기관)를 만들고 이를 통해 SAN(주체 대체 이름, Subject Alternative Name)이 포함된 서버 인증서를 발급**해야 합니다. 최신 브라우저(Chrome, Edge 등)는 SAN이 없는 인증서를 신뢰하지 않기 때문입니다.

이 작업은 `OpenSSL`을 사용하여 진행할 수 있습니다. 운영체제에 OpenSSL이 설치되어 있는지 먼저 확인해 주세요.

* 인증서/보안 확장자 의미
  
| 확장자 | 의미 | 용도 |
| --- | --- | --- |
| .crt | Certificate | 인증서 (PEM) |
| .key | Private Key | 개인키 |
| .pem | PEM Encoded | Base64 인증서/키 |
| .pfx | PKCS#12 | 인증서+키 번들 |
| .csr | Certificate Signing Request | 인증서 요청 |

---

## 1단계: 로컬 CA(Root CA) 생성하기

먼저, 우리가 발급할 서버 인증서를 보증해 줄 '나만의 로컬 인증기관(CA)'을 만듭니다.

### 1. Root CA 개인키 생성

```bash
openssl genrsa -out rootCA.key 2048

```

*이 명령어는 `rootCA.key`라는 이름의 2048비트 RSA 개인키를 생성합니다.*

### 2. Root CA 인증서 생성 (10년 유효)

```bash
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.pem

```

*실행 후 국가(C), 조직명(O) 등을 묻는 프롬프트가 나옵니다. 적당히 입력하거나 엔터를 쳐서 넘어가셔도 됩니다. Common Name(CN) 부분에는 `My Local Root CA`와 같이 알아보기 쉬운 이름을 적어주세요.*

---

---

## 2단계: localhost 서버 인증서 준비 (개인키 및 CSR 생성)

이제 웹 서버(localhost)에서 사용할 인증서의 뼈대를 만듭니다.

### 1. 서버용 개인키 생성

```bash
openssl genrsa -out localhost.key 2048

```

### 2. 인증서 서명 요청서(CSR) 생성

```bash
openssl req -new -key localhost.key -out localhost.csr

```

*프롬프트가 나타나면 Common Name(CN)에 반드시 `localhost`를 입력해 주세요. 나머지는 비워두셔도 됩니다.*

---

## 3단계: SAN (Subject Alternative Name) 설정 파일 작성

최신 브라우저가 인증서를 정상적으로 인식하도록 확장 설정 파일(`localhost.ext`)을 만듭니다. 메모장이나 에디터를 열고 아래 내용을 복사하여 `localhost.ext`라는 이름으로 저장하세요.

```ini
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1

```

---

## 4단계: 로컬 CA로 서명하여 최종 인증서 발급

앞서 만든 Root CA의 권한으로 서버의 CSR을 승인하고, SAN 설정을 포함시켜 최종 서버 인증서(`localhost.crt`)를 만들어냅니다. (유효기간 825일 기준, macOS의 최대 허용 기간)

```bash
openssl x509 -req -in localhost.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out localhost.crt -days 825 -sha256 -extfile localhost.ext

```

🎉 **완료되었습니다!** 이제 폴더에 생성된 파일 중 웹 서버에 실제로 필요한 파일은 다음 두 가지입니다.

* **`localhost.key`** (서버 개인키)
* **`localhost.crt`** (서버 인증서)

---

## 5단계: Root CA를 OS/브라우저에 신뢰할 수 있는 기관으로 등록 (필수)

인증서를 서버에 적용해도 브라우저에는 여전히 "주의 요함" 경고가 뜹니다. 내 컴퓨터가 방금 만든 `rootCA.pem`을 '믿을 수 있는 인증기관'으로 인식하도록 등록해야 합니다.

* **Windows:**
1. `rootCA.pem`의 확장자를 `rootCA.crt`로 변경 후 더블클릭합니다.
2. [인증서 설치] -> [로컬 컴퓨터] 선택.
3. **'모든 인증서를 다음 저장소에 저장'**을 선택하고 찾아보기를 눌러 **[신뢰할 수 있는 루트 인증 기관]**을 선택한 뒤 완료합니다.

* **macOS:**
1. `rootCA.pem`을 더블클릭하여 '키체인 접근' 앱을 엽니다.
2. '시스템' 키체인에 등록된 `My Local Root CA`를 더블클릭합니다.
3. [신뢰] 항목을 열고 **'항상 신뢰(Always Trust)'**로 변경합니다.

도커(Docker) 환경에서 여러 서버를 동시에 운영하시는군요!

먼저 팁을 하나 드리자면, **각각의 서비스마다 별도의 인증서를 새로 발급받으실 필요는 없습니다.** 모든 서비스가 결국 `localhost` (또는 로컬 IP) 환경에서 포트만 다르게 동작한다면, **앞서 만든 하나의 `localhost.crt`와 `localhost.key` 쌍을 모든 컨테이너에 공통으로 마운트하여 재사용**하는 것이 관리상 훨씬 편리합니다.

(만약 `gitea.local`, `minio.local` 등 별도의 로컬 도메인을 쓰신다면 앞서 설명한 `localhost.ext` 파일의 `[alt_names]` 아래에 `DNS.2 = gitea.local`, `DNS.3 = minio.local` 식으로 SAN을 추가해서 하나의 인증서로 통일하는 것을 추천합니다.)

도커 컴포즈(`docker-compose.yml`)를 기준으로 호스트 컴퓨터의 인증서 폴더(`./certs/`)에 `localhost.crt`와 `localhost.key`가 있다고 가정하고, **각 서비스별 TLS(HTTPS/SSL) 적용 설정 방법**을 정리해 드립니다.

## 6단계 인증서 검증

생성한 인증서가 올바르게 만들어졌는지, 그리고 도커에 띄운 서비스들이 실제로 TLS를 통해 안전하게 통신하고 있는지 확인하는 과정은 매우 중요합니다.

단계별로 **파일 자체 검증**, **웹 브라우저 검증**, 그리고 **CLI 도구 검증** 방법을 정리해 드립니다.

---

### 1. 인증서 파일 자체 검증 (배포 전)

도커에 적용하기 전, `OpenSSL` 명령어로 인증서의 내용과 신뢰 체계를 확인합니다.

* **SAN(주체 대체 이름) 확인:** 브라우저 거부의 가장 큰 원인입니다. 아래 명령어로 `DNS:localhost`가 포함되었는지 확인하세요.

```bash
openssl x509 -in localhost.crt -text -noout | grep -A 1 "Subject Alternative Name"
```

* **발급자(Issuer) 확인:** 내가 만든 Root CA에 의해 서명되었는지 확인합니다.

```bash
openssl x509 -in localhost.crt -noout -issuer
```

* **신뢰 체인 검증:** `rootCA.pem(rootCA.crt)` 파일로 `localhost.crt`를 검증할 수 있는지 확인합니다.

```bash
openssl verify -CAfile rootCA.pem localhost.crt
# 출력 결과가 'localhost.crt: OK'여야 합니다.
```

### 2. 웹 서비스 검증 (Gitea, MinIO, Portainer, pgAdmin 등)

서비스를 띄운 후 브라우저와 `curl`을 통해 확인합니다.

* **브라우저 주소창 확인:** `https://localhost:포트`로 접속했을 때 주소창의 **자물쇠 아이콘**이 정상적으로 표시되어야 합니다. "주의 요함"이 뜬다면 인증서 경로가 잘못되었거나 Root CA가 시스템에 등록되지 않은 것입니다.
* **curl 명령어로 상세 확인:**
상세 로그(`-v`)를 통해 TLS 핸드쉐이크 과정을 볼 수 있습니다.

```bash
curl -vI https://localhost:9443  # Portainer 예시

```

* 출력 내용 중 `SSL certificate verify ok` 문구가 보이면 성공입니다.

---

### 3. DB 및 Redis 검증 (CLI 도구)

데이터베이스와 레디스는 웹 브라우저로 확인할 수 없으므로 전용 클라이언트를 사용해야 합니다.

* **PostgreSQL (psql):**
연결 후 `ssl_is_used`를 쿼리하여 암호화 여부를 확인합니다.

```bash
psql "host=localhost port=5432 user=postgres sslmode=require"
# 접속 후 실행:
SELECT datname, usename, ssl, cipher FROM pg_stat_ssl JOIN pg_stat_activity ON pg_stat_ssl.pid = pg_stat_activity.pid;
```

* **Redis (redis-cli):**
`--tls` 옵션을 붙여 접속합니다. (Root CA가 등록되어 있지 않다면 `--cacert rootCA.pem` 경로를 명시해야 합니다.)

```bash
redis-cli --tls --host localhost --port 6379 ping
# 결과로 'PONG'이 오면 성공입니다.
```

---

### 4.트러블슈팅 - "인증서가 유효하지 않음"이 뜰 때

만약 설정을 다 마쳤는데도 오류가 난다면 다음 두 가지를 체크해 보세요.

1. **인증서 파일 권한 (PostgreSQL 전용):** PostgreSQL 컨테이너 내부에서 `localhost.key` 파일의 소유자가 `postgres`가 아니거나 권한이 `600`이 아니면 서버가 실행되지 않을 수 있습니다.
    > **해결:** `chmod 600 localhost.key`를 실행하거나, Dockerfile/EntryPoint에서 소유권을 조정해야 합니다.

2. **브라우저 캐시:** Root CA를 시스템에 등록한 후에도 브라우저가 예전 인증서를 기억하고 있을 수 있습니다. 브라우저를 완전히 껐다 켜거나 시크릿 모드에서 테스트해 보세요

---

혹시 검증 과정에서 특정 서비스(예: Redis나 Postgres)에서 **'Unknown CA'** 같은 구체적인 에러 메시지가 발생하나요? 그렇다면 해당 서비스의 로그(`docker logs 컨테이너명`)와 함께 알려주시면 바로 해결책을 찾아드리겠습니다!

---

## [참고] 서버별 tls certs 적용방법

### 📁 디렉토리 구조 가정

```text
프로젝트폴더/
 ├── docker-compose.yml
 └── certs/
      ├── localhost.crt
      └── localhost.key

```

---

### 1. Nginx (웹 서버 / 리버스 프록시)

Nginx는 자체 설정 파일(`nginx.conf` 또는 `default.conf`) 안에서 SSL 경로를 지정해야 합니다.

```yaml
  nginx:
    image: nginx:latest
    ports:
      - "443:443"
    volumes:
      - ./certs:/etc/nginx/certs:ro
      - ./nginx.conf:/etc/nginx/nginx.conf:ro # 별도의 설정 파일 필요

```

**nginx.conf 주요 내용:**

```nginx
server {
    listen 443 ssl;
    server_name localhost;
    ssl_certificate /etc/nginx/certs/localhost.crt;
    ssl_certificate_key /etc/nginx/certs/localhost.key;
    # ... 프록시 설정 등 ...
}

```

### 2. Portainer (도커 관리 도구)

Portainer는 실행 명령어(`command`)로 인증서 경로를 직접 전달하면 아주 쉽게 HTTPS가 적용됩니다.

```yaml
  portainer:
    image: portainer/portainer-ce:latest
    ports:
      - "9443:9443"
    command: --sslcert /certs/localhost.crt --sslkey /certs/localhost.key
    volumes:
      - ./certs:/certs:ro
      - /var/run/docker.sock:/var/run/docker.sock

```

### 3. Gitea (버전 관리)

Gitea는 환경 변수(`environment`)를 통해 프로토콜을 HTTPS로 바꾸고 인증서 경로를 지정할 수 있습니다.

```yaml
  gitea:
    image: gitea/gitea:latest
    ports:
      - "3000:3000"
    environment:
      - GITEA__server__PROTOCOL=https
      - GITEA__server__CERT_FILE=/certs/localhost.crt
      - GITEA__server__KEY_FILE=/certs/localhost.key
      - GITEA__server__ROOT_URL=https://localhost:3000/
    volumes:
      - ./certs:/certs:ro

```

### 4. MinIO (오브젝트 스토리지)

MinIO는 **인증서 파일명이 반드시 `public.crt`와 `private.key`여야 하며, 특정 경로(`/root/.minio/certs/`)에 위치해야** 합니다. 볼륨 마운트 시 이름을 변경해서 덮어씌우면 됩니다.

```yaml
  minio:
    image: minio/minio:latest
    command: server /data --console-address ":9001"
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - ./certs/localhost.crt:/root/.minio/certs/public.crt:ro
      - ./certs/localhost.key:/root/.minio/certs/private.key:ro

```

### 5. pgAdmin4 (DB 관리 툴)

pgAdmin은 자체적으로 TLS 환경 변수를 지원합니다.

```yaml
  pgadmin:
    image: dpage/pgadmin4
    ports:
      - "8443:443" # 내부 443포트 사용
    environment:
      - PGADMIN_DEFAULT_EMAIL=admin@admin.com
      - PGADMIN_DEFAULT_PASSWORD=admin
      - PGADMIN_ENABLE_TLS=True
      - PGADMIN_CERT_FILE=/certs/localhost.crt
      - PGADMIN_KEY_FILE=/certs/localhost.key
    volumes:
      - ./certs:/certs:ro

```

### 6. PostgreSQL (데이터베이스)

PostgreSQL은 시작 명령어(`command`) 옵션으로 SSL을 켤 수 있습니다.
⚠️ **주의:** PostgreSQL은 보안상 개인키(`localhost.key`)의 파일 권한이 엄격해야 합니다(`chmod 600`). 호스트OS에서 미리 권한을 맞춰주거나 사용자 소유권 문제가 발생할 수 있습니다.

```yaml
  postgres:
    image: postgres:latest
    ports:
      - "5432:5432"
    environment:
      POSTGRES_PASSWORD: mypassword
    command: 
      - "-c"
      - "ssl=on"
      - "-c"
      - "ssl_cert_file=/certs/localhost.crt"
      - "-c"
      - "ssl_key_file=/certs/localhost.key"
    volumes:
      - ./certs:/certs:ro

```

### 7. Redis (인메모리 데이터스토어)

Redis는 시작 명령어(`command`)에 `--tls-port` 옵션과 인증서 옵션을 주어 실행합니다. 기본 6379 포트(평문)를 닫고 TLS 포트만 열려면 `--port 0` 옵션을 줍니다.

```yaml
  redis:
    image: redis:latest
    ports:
      - "6379:6379"
    command: >
      redis-server
      --port 0
      --tls-port 6379
      --tls-cert-file /certs/localhost.crt
      --tls-key-file /certs/localhost.key
      --tls-auth-clients no
    volumes:
      - ./certs:/certs:ro

```

*(참고: `--tls-auth-clients no`는 레디스에 접속하는 클라이언트(앱)가 자체 인증서를 제출하지 않아도 되게 하는 옵션입니다. 상호 인증(mTLS)이 필요하시면 이 옵션을 빼고 CA 인증서를 추가해야 합니다.)*

---

### 💡 권장 아키텍처 (Nginx 리버스 프록시 활용)

각각의 DB, 앱, 스토리지마다 모두 TLS 설정을 개별적으로 해주는 것도 좋지만, 도커 환경에서는 **Nginx(또는 Traefik, Caddy)에만 인증서를 적용하여 맨 앞에 세우고 (Reverse Proxy)**, 나머지 컨테이너(Gitea, MinIO 등)들은 내부 네트워크(Docker Network)를 통해 HTTP(평문)로 통신하게 만드는 것이 훨씬 관리하기 편하고 표준적인 방법입니다.

이 방식을 사용하시면 포트번호를 외울 필요 없이 `https://gitea.localhost`, `https://minio.localhost` 처럼 Nginx 하나가 트래픽을 분배하게 할 수 있습니다. 구조 변경에 관심 있으시다면 추가로 질문해 주세요!
