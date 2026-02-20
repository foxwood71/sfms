# Rocky Linux 9 Docker 설치 가이드

Rocky Linux 9에서 Docker CE를 공식 리포지토리를 통해 설치합니다. Podman과 함께 사용 가능합니다. [idchowto](https://idchowto.com/rocky-linux-9%EC%97%90-docker/)

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

**단일 노드** 또는 **멀티 노드 클러스터**에서 Docker Swarm을 초기화합니다. 매니저 노드에서 실행하세요. [howtoforge](https://www.howtoforge.com/how-to-install-docker-swarm-on-rocky-linux/)

### 8.1. 전제 조건 확인

```bash
# Docker 실행 확인
docker --version
docker info | grep Swarm  # inactive

# firewall 설정 (Swarm 포트)
sudo firewall-cmd --add-port=2377/tcp --permanent
sudo firewall-cmd --add-port=7946/tcp --permanent
sudo firewall-cmd --add-port=7946/udp --permanent
sudo firewall-cmd --add-port=4789/udp --permanent
sudo firewall-cmd --reload
```

### 8.2. Swarm 모드 초기화 (매니저 노드)

**단일 노드 (개발 환경):**

```bash
docker swarm init
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

**완료!** `curl localhost:8080`으로 Swarm 서비스 확인하세요! [korsa.tistory](https://korsa.tistory.com/560)

## 9. Docker 치트시트

Docker 명령어와 워크플로우를 한눈에 정리했습니다. 개발/운영 모두 커버! [idchowto](https://idchowto.com/rocky-linux-9%EC%97%90-docker/)

### 9.1 🐳 기본 명령어

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

### 9.2 🔧 개발 워크플로우

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

### 9.3 🏗️ Docker Swarm

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

### 9.4 📁 Dockerfile 템플릿

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

### 9.5  🔍 자주 쓰는 옵션

| 명령어 | 옵션 | 의미 |
| -------- | ------ | ------ |
| `docker run` | `-d` | 백그라운드 실행 |
| | `-p 8080:80` | 포트 매핑 |
| | `-v /host:/container` | 볼륨 마운트 |
| | `--name myapp` | 이름 지정 |
| `docker logs` | `-f` | 실시간 로그 |
| | `--tail 50` | 최근 50줄 |

### 9.6 🧹 정리 명령어

```bash
# 모든 컨테이너 중지/삭제
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

# 사용하지 않는 이미지 정리
docker image prune -a

# 전체 정리 (주의!)
docker system prune -a --volumes
```

### 9.7  📊 상태 모니터링

```bash
docker stats           # 리소스 사용량
docker logs -f web     # 컨테이너 로그
docker inspect web     # 상세 정보
docker network ls      # 네트워크
docker volume ls       # 볼륨
```

### 9.8  🚀 실전 워크플로우

```text
1. 개발: docker compose up
2. 테스트: docker run --rm myapp:test
3. 배포: 
   docker build -t registry/myapp:v1 .
   docker push registry/myapp:v1
   docker service update --image registry/myapp:v1 web
```

### 9.10 ⚙️ Rocky Linux 설정

```bash
# sudo 없이
sudo usermod -aG docker $USER

# Swarm 방화벽
sudo firewall-cmd --add-port=2377/tcp --permanent
sudo firewall-cmd --reload
```

**핵심:** `docker run`, `docker compose up`, `docker service create` 3가지만 익히면 90% 커버! 🚀

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
