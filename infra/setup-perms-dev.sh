#!/bin/bash

# SFMS 프로젝트 secrets, cert 권한 설정 스크립트 (Rootless Podman용)

echo "🚀 Rootless Podman 권한 설정을 시작합니다..."

# --- 1. PostgreSQL (UID: 999, GID: 999, postgres:postgres) ---
echo "📦 설정 중: pgsql"
# 실제 데이터를 '쓰는(Write)' 폴더만 UID 999로 설정 
# --> ./pgsql/secrets ./pgsql/sql은 read only이기에 수정이나 git을 위해 644로 설정
podman unshare chown -R 999:999 ./data/pgsql ./data/logs/pgsql ./pgsql/certs 
podman unshare chmod 400 ./pgsql/certs/*.key 2>/dev/null
podman unshare chmod 444 ./pgsql/certs/*.crt 2>/dev/null

# --- 2. Redis (UID: 999, GID: 1000) ---
echo "📦 설정 중: redis"
podman unshare chown -R 999:999 ./data/redis ./redis/secrets ./redis/certs
podman unshare chmod 400 ./redis/secrets/password.txt
podman unshare chmod 400 ./redis/certs/*.key 2>/dev/null
podman unshare chmod 444 ./redis/certs/*.crt 2>/dev/null

# --- 3. MinIO (UID: 0, GID: 0) ---
echo "📦 설정 중: minio"
podman unshare chown -R 0:0 ./data/minio ./minio/secrets ./minio/certs
podman unshare chmod 400 ./minio/secrets/password.txt
podman unshare chmod 400 ./minio/certs/*.key 2>/dev/null
podman unshare chmod 444 ./minio/certs/*.crt 2>/dev/null

# --- 4. PgAdmin (UID: 5050, GID: 5050) ---
echo "📦 설정 중: pgadm"
podman unshare chown -R 5050:5050 ./data/pgadm ./pgadm/secrets ./pgadm/certs
podman unshare chmod 400 ./pgadm/secrets/password.txt
podman unshare chmod 400 ./pgadm/certs/*.key 2>/dev/null
podman unshare chmod 444 ./pgadm/certs/*.crt 2>/dev/null

# --- 5. Gitea (UID: 1000, GID: 1000) ---
echo "📦 설정 중: gitea"
podman unshare chown -R 1000:1000 ./data/gitea ./gitea/secrets ./gitea/certs
podman unshare chmod 400 ./gitea/secrets/password.txt
podman unshare chmod 400 ./gitea/certs/*.key 2>/dev/null
podman unshare chmod 444 ./gitea/certs/*.crt 2>/dev/null

# --- 6. portainer (UID: 0, GID: 0) ---
echo "📦 설정 중: portainer"
podman unshare chown -R 0:0 ./data/portainer ./portainer/secrets ./portainer/certs
podman unshare chmod 400 ./portainer/secrets/password.txt
podman unshare chmod 400 ./portainer/certs/*.key 2>/dev/null
podman unshare chmod 444 ./portainer/certs/*.crt 2>/dev/null

# --- 6. Nginx, Backend 로그 및 Portainer 데이터 (컨테이너 내부 root 사용)
# 0:0 은 컨테이너 내부의 root를 의미하며, Rootless 환경에서는 곧 호스트의 사용자 계정 으로 매핑.
podman unshare chown -R 0:0 ./data/logs/nginx
podman unshare chown -R 0:0 ./data/logs/backend
podman unshare chown -R 0:0 ./data/portainer
podman unshare chown -R 0:0 ./data/backups

echo "✅ 모든 권한 설정이 완료되었습니다!"