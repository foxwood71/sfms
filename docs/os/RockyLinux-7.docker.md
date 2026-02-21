# Rocky Linux 9 Docker 설치 가이드

Rocky Linux 9에서 Docker CE를 공식 리포지토리를 통해 설치합니다. Podman과 함께 사용 가능합니다

## 1. 사전 준비

```bash
sudo dnf update -y
sudo dnf install -y dnf-utils yum-utils
```

## 2. Docker 공식 리포지토리 추가

```bash
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

## 3. Docker 패키지 설치

```bash
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## 4. Docker 서비스 시작 및 활성화

```bash
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker  # active (running) 확인
```

## 5. 비루트 사용자 설정 (권장)

```bash
sudo usermod -aG docker $USER
newgrp docker  # 또는 로그아웃/재로그인
```

## 6. 설치 확인

```bash
docker --version
docker run hello-world
```

## 7. Docker Compose 확인

```bash
docker compose version
```

## 8. Docker Swarm 모드 활성화

**단일 노드** 또는 **멀티 노드 클러스터**에서 Docker Swarm을 초기화합니다. 매니저 노드에서 실행하세요

### 8.1. 전제 조건 확인

```bash
# Docker 실행 확인
docker --version
docker info | grep Swarm  # inactive

# firewall 설정 (Swarm 포트 - wsl 환경에서 는 불필요)
sudo firewall-cmd --add-port=2377/tcp --permanent  # 클러스터 관리에 사용되는 포트
sudo firewall-cmd --add-port=7946/tcp --permanent  # 노드 간 통신
sudo firewall-cmd --add-port=7946/udp --permanent  # 노드 간 통신
sudo firewall-cmd --add-port=4789/udp --permanent  # 클러스터에서 사용되는 Ingress 오버레이 네트워크 트래픽에 사용
sudo firewall-cmd --reload
```

### 8.2. Swarm 모드 초기화 (매니저 노드)

**단일 노드 (개발 환경):**

```bash
docker swarm init

# wsl 환경에서는 lo, eth0 두개가 존재해서 eth0 주소를 지정
docker swarm init --advertise-addr 172.20.218.67
```

**멀티 노드 (IP 지정, 운영 환경):**

```bash
docker swarm init \
  --advertise-addr 192.168.1.100 \
  --default-addr-pool 10.10.0.0/16
```

**출력 예시:**

```text
Swarm initialized: current node (abcd...) is now a manager.

To add a worker to this swarm, run the following command:
docker swarm join --token SWMTKN-1-xxx 192.168.1.100:2377

To add a manager to this swarm, run 'docker swarm join-token manager'
```

### 8.3. 워커 노드 추가

**워커 노드에서 (매니저 출력 토큰 사용):**

```bash
docker swarm join --token SWMTKN-1-xxxxx 192.168.1.100:2377
```

### 8.4. 상태 확인

```bash
# 클러스터 상태
docker node ls

# Swarm 정보
docker info | grep -i swarm

# 서비스 확인
docker service ls
```

### 8.5. 테스트 서비스 배포

```bash
# 간단한 서비스 생성
docker service create \
  --name webapp \
  --publish 8080:80 \
  --replicas 3 \
  nginx

# 확인
docker service ls
docker service ps webapp
```

### 8.6. Swarm 종료 (선택)

```bash
# 매니저에서
docker swarm leave --force
```

**완료!** `curl localhost:8080`으로 Swarm 서비스 확인하세요

## 9. Docker Secret 사용

Docker Secret은 Swarm 모드에서 민감한 데이터(패스워드, API 키 등)를 암호화해 안전하게 관리하는 기능입니다

### 9.0. 사전 프로그램 설치 (Rocky Linux)

Rocky Linux에서 Docker와 Swarm을 위한 필수 패키지를 설치하세요. Podman이 설치된 경우 충돌 방지 위해 제거

```bash
# 1. 업데이트 및 도구 설치
sudo dnf update -y
sudo dnf install -y dnf-plugins-core yum-utils

# 3. Podman 등 충돌 패키지 제거 (필요 시)
sudo dnf remove -y podman buildah skopeo containers-common
```

**SELinux 호환:** 볼륨 마운트 시 `:z` 플래그 사용 (`-v /host:/container:z`). [oneuptime](https://oneuptime.com/blog/post/2026-02-08-how-to-install-docker-on-rocky-linux-9/view)

### 전제 조건

- Docker Swarm 모드 활성화: `docker swarm init` 또는 `docker swarm join`
- 매니저 노드에서 실행 (worker에서는 secret 생성 불가). [yongho1037.tistory]

### 9.1. Secret 생성

Secret은 문자열 또는 파일로 생성합니다.

**문자열 입력:**

```bash
echo "my_password123" | docker secret create db_password -
```

**파일 입력:**

```bash
docker secret create db_password ./secret.txt
```

**확인:**

```bash
docker secret ls
```

### 9.2. 서비스에 Secret 적용

컨테이너 내 `/run/secrets/<target_name>`에 평문 파일로 마운트됩니다.

**Docker CLI 예시 (MySQL):**

```bash
docker service create \
  --name mysql-app \
  --replicas 1 \
  --secret source=db_password,target=mysql_root_password \
  --env MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql_root_password \
  --mount type=volume,source=mysql-data,destination=/var/lib/mysql \
  mysql:8.0
```

### 9.3. Docker Compose (stack.yml)

```yaml
version: '3.8'
services:
  web:
    image: nginx:latest
    secrets:
      - app_key
    environment:
      - APP_KEY_FILE=/run/secrets/app_key
  
  db:
    image: mysql:8.0
    secrets:
      - mysql_password
    environment:
      - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql_password
    volumes:
      - db-data:/var/lib/mysql

secrets:
  app_key:
    external: true
  mysql_password:
    external: true

volumes:
  db-data:
```

**배포:**

```bash
docker stack deploy -c stack.yml myapp
```

### 9.4. 관리 명령어

```bash
# Secret 상세
docker secret inspect db_password

# 업데이트
echo "new_password" | docker secret create db_password_new -
docker service update --secret-rm db_password --secret-add source=db_password_new,target=mysql_root_password mysql-app

# 삭제
docker secret rm db_password
```

### 9.5 주의사항

- Swarm 전용: Standalone 불가.
- 최대 500KB
- firewalld 충돌 시 Docker 중지 후 재시작

## 10. Docker 치트시트

Docker 명령어와 워크플로우를 한눈에 정리했습니다. 개발/운영 모두 커버! [idchowto](https://idchowto.com/rocky-linux-9%EC%97%90-docker/)

### 10.1 🐳 기본 명령어

```bash
# 이미지
docker pull nginx:alpine
docker images
docker rmi nginx:alpine

# 컨테이너
docker run -d --name web -p 80:80 nginx
docker ps -a
docker stop web
docker rm web

# 볼륨
docker volume create data
docker run -v data:/app nginx
```

### 10.2 🔧 개발 워크플로우

```text
1. 개발 컨테이너
docker run -it -v $(pwd):/app -p 3000:3000 node:20 bash

2. Docker Compose (권장)
docker compose up -d
docker compose logs -f
docker compose down

3. 빌드/재빌드
docker build -t myapp .
docker build -t myapp:v1.0 .
```

### 10.3 🏗️ Docker Swarm

```bash
# 초기화
docker swarm init

# 서비스 배포
docker service create --name web --replicas 3 -p 80:80 nginx

# 스케일링
docker service scale web=5

# 스택 배포 (docker-compose.yml)
docker stack deploy -c docker-compose.yml mystack
```

### 10.4 📁 Dockerfile 템플릿

```dockerfile
# Node.js 예시
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

### 10.5  🔍 자주 쓰는 옵션

| 명령어 | 옵션 | 의미 |
| -------- | ------ | ------ |
| `docker run` | `-d` | 백그라운드 실행 |
| | `-p 8080:80` | 포트 매핑 |
| | `-v /host:/container` | 볼륨 마운트 |
| | `--name myapp` | 이름 지정 |
| `docker logs` | `-f` | 실시간 로그 |
| | `--tail 50` | 최근 50줄 |

### 10.6 🧹 정리 명령어

```bash
# 모든 컨테이너 중지/삭제
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

# 사용하지 않는 이미지 정리
docker image prune -a

# 전체 정리 (주의!)
docker system prune -a --volumes
```

### 10.7  📊 상태 모니터링

```bash
docker stats           # 리소스 사용량
docker logs -f web     # 컨테이너 로그
docker inspect web     # 상세 정보
docker network ls      # 네트워크
docker volume ls       # 볼륨
```

### 10.8  🚀 실전 워크플로우

```text
1. 개발: docker compose up
2. 테스트: docker run --rm myapp:test
3. 배포: 
   docker build -t registry/myapp:v1 .
   docker push registry/myapp:v1
   docker service update --image registry/myapp:v1 web
```

### 10.9 ⚙️ Rocky Linux 설정

```bash
# sudo 없이
sudo usermod -aG docker $USER

# Swarm 방화벽
sudo firewall-cmd --add-port=2377/tcp --permanent
sudo firewall-cmd --reload
```

**핵심:** `docker run`, `docker compose up`, `docker service create` 3가지만 익히면 90% 커버! 🚀

## 11. Docker Hub 접속 준비 및 사용 가이드

Docker Hub는 공식 Docker 이미지 저장소로, 공개/비공개 이미지를 push/pull합니다. Rocky Linux 환경 기준입니다. [docs.docker](https://docs.docker.com/reference/cli/docker/login/)

### 11.0. Docker Credential Pass 설정 (로컬 암호화 저장)

Docker 로그인 시 비밀번호를 `~/.docker/config.json`에 평문으로 저장하는 문제를 `pass` 도구로 해결합니다. GPG 기반 암호화 저장소입니다

#### 설치 및 설정 순서

1. **pass 설치:**

   ```bash
   sudo dnf install -y pass gnupg2
   ```

2. **GPG 키 생성:**

   ```bash
   gpg --generate-key
   ```

   - Real name: (당신 이름)
   - Email: (당신 이메일)
   - 암호 설정 (생략 가능)

3. **GPG 키 ID 확인:**

   ```bash
   gpg --list-secret-keys --keyid-format=long
   # sec   rsa4096/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 2026-02-21
   # 키 ID: 마지막 16자리 (e.g., 1234567890ABCDEF)
   ```

4. **pass 초기화:**

   ```bash
   pass init YOUR_GPG_EMAIL@example.com  # 또는 키 ID
   ```

5. **docker-credential-pass 다운로드 (최신 버전 확인):**

   ```bash
   curl -fsSL https://github.com/docker/docker-credential-helpers/releases/download/v0.8.2/docker-credential-pass-v0.8.2.linux-amd64 -o docker-credential-pass
   chmod +x docker-credential-pass
   sudo mv docker-credential-pass /usr/local/bin/
   ```

6. **Docker config 설정:**

   ```bash
   mkdir -p ~/.docker
   cat > ~/.docker/config.json << EOF
   {
     "auths": {},
     "credsStore": "pass"
   }
   EOF
   docker-credential-pass list  # {} 출력 확인
   ```

**테스트:** `docker login` 후 `docker-credential-pass list`로 확인 (Docker Hub 키 저장됨)

### 11.1. Docker Hub 계정 생성

1. <https://hub.docker.com/signup> 접속
2. Username, Password, Email 입력 후 무료 플랜 선택
3. 이메일 확인 링크 클릭
4. 로그인 후 Organizations/Repositories 생성 (private 필요 시)
**2FA (권장):** Account Settings > Security > Enable Two-Factor Authentication

### 11.2. Access Token 생성 (비밀번호 대신 사용)

1. <https://hub.docker.com/settings/security> 로그인
2. "New Access Token" 클릭.
3. Description, Expiration, Permissions (Read, Write, Delete) 설정.
4. 토큰 복사
5. 
### 11.3. Docker CLI 로그인

```bash
docker login -u YOUR_USERNAME
# Pass 설정 시 패스워드 암호화 저장됨
```

**비대화형:**

```bash
echo $DOCKER_TOKEN | docker login -u YOUR_USERNAME --password-stdin
```

**로그아웃:**

```bash
docker logout
```

### 11.4. 이미지 Push/Pull 테스트

**공개 Pull:**

```bash
docker pull nginx:latest
```

**Private Push:**

```bash
docker build -t yourusername/myapp:latest .
docker push yourusername/myapp:latest
```

### 11.5. 주의사항

- 무료 Private Repo: 제한 있음. [blog.naver](https://blog.naver.com/ilikebigmac/222035946425)
- Token 노출 방지. [docs.docker](https://docs.docker.com/reference/cli/docker/login/)
- firewalld: 443 포트 허용. [docs.rockylinux](https://docs.rockylinux.org/10/guides/security/firewalld-beginners/)

## 문제 해결

| 오류 | 해결방법 |
| --- | --- |
| `docker-ce-stable` 없음 | `sudo dnf makecache` |
| 권한 오류 | `sudo usermod -aG docker $USER` |
| repo 추가 실패 | `--add-repo` 하이픈 확인 (`--`) |
| 서비스 시작 실패 | `sudo systemctl daemon-reload` |
| `This node is already part of a swarm` | `docker swarm leave --force` |
| 포트 충돌 | `sudo firewall-cmd --list-ports` 확인 |
| 토큰 만료 | 매니저에서 `docker swarm join-token worker` 재생성 |
| pull denied | Token 권한/재로그인  [forums.docker](https://forums.docker.com/t/how-to-use-token-to-push-pull-image-to-private-repository/81026) |
| Rate Limit | 로그인 또는 플랜 업그레이드  [docs.docker](https://docs.docker.com/reference/cli/docker/login/) |
| Pass 오류 | `pass init` 재실행, GPG 키 확인  [nomad-programmer.tistory](https://nomad-programmer.tistory.com/542) |

## 추가 설정 (선택)

```bash
# 컨테이너 재시작 정책
sudo systemctl edit docker

# 저장소 설정 (/etc/docker/daemon.json)
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

**완료!** `docker run -it rockylinux:9 /bin/bash`로 테스트하세요. [sysdocu.tistory](https://sysdocu.tistory.com/1913)
