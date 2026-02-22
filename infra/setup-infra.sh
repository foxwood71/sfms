#!/bin/bash

echo "🚀 SFMS 인프라 디렉토리 구조 생성 및 권한 설정을 시작합니다... (개발/운영 환경 포함)"

# ====================================================================
# 1. 인프라 디렉토리 및 필수 파일 생성
# ====================================================================
echo "📁 폴더 및 파일을 생성 중입니다..."

# 운영 환경에 필요한 backend, frontend를 포함하여 모든 서비스 폴더 일괄 생성
for service in backend frontend gitea minio nginx pgadm pgsql portainer redis; do
    mkdir -p ${service}/{certs,scripts,secrets}
    # 각 서비스의 secrets 폴더 안에 빈 password.txt 파일 미리 생성
    # 기존에 파일이 있으면 touch 명령어를 아예 실행하지 않고 건너뜁니다.
    if [ ! -f ${service}/secrets/password.txt ]; then
        touch ${service}/secrets/password.txt
    fi
done

# 서비스별 특수 폴더 추가 생성
mkdir -p minio/conf
mkdir -p nginx/conf.d
mkdir -p pgsql/sql
mkdir -p redis/conf

# Data 및 하위 로그 폴더 생성 (운영 환경 전용인 nginx, portainer 포함)
mkdir -p data/{minio,pgadm,pgsql,portainer,redis,backups}
mkdir -p data/gitea/{conf,data}
mkdir -p data/logs/{backend,nginx,pgsql}

echo "✅ 디렉토리 생성이 완료되었습니다."

# ====================================================================
# 2. Podman Rootless 권한(Ownership) 설정
# ====================================================================
echo "🔐 Rootless Podman을 위한 Data 폴더 권한 설정을 진행합니다..."

# PostgreSQL (컨테이너 내부 UID 999 사용)
podman unshare chown -R 999:999 ./data/pgsql
podman unshare chown -R 999:999 ./data/logs/pgsql

# Gitea (컨테이너 내부 UID 1000 사용)
podman unshare chown -R 1000:1000 ./data/gitea

# [운영 환경 전용] Nginx, Backend 로그 및 Portainer 데이터 (컨테이너 내부 root 사용)
podman unshare chown -R 0:0 ./data/logs/nginx
podman unshare chown -R 0:0 ./data/logs/backend
podman unshare chown -R 0:0 ./data/portainer

# [공통 환경] 나머지 서비스 데이터 (컨테이너 내부 root 사용)
podman unshare chown -R 0:0 ./data/redis
podman unshare chown -R 0:0 ./data/minio
podman unshare chown -R 0:0 ./data/pgadm
podman unshare chown -R 0:0 ./data/backups

# 디렉토리 기본 권한 부여
chmod -R 755 ./data

echo "🎉 개발 및 운영 환경을 위한 모든 초기 세팅이 완벽하게 끝났습니다! 👍"