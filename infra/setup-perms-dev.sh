#!/bin/bash

# SFMS 프로젝트 secrets, cert 권한 설정 스크립트 (Rootless Podman용)

echo "🚀 Rootless Podman 권한 설정을 시작합니다..."

# --- 1. PostgreSQL (UID: 999, GID: 999) ---
echo "📦 설정 중: pgsql"
podman unshare chown -R 999:999 ./pgsql/secrets ./pgsql/certs
podman unshare chmod 400 ./pgsql/secrets/password.txt
podman unshare chmod 400 ./pgsql/certs/*.key 2>/dev/null
podman unshare chmod 444 ./pgsql/certs/*.crt 2>/dev/null

# --- 2. Redis (UID: 999, GID: 1000) ---
echo "📦 설정 중: redis"
podman unshare chown -R 999:1000 ./redis/secrets ./redis/certs
podman unshare chmod 400 ./redis/secrets/password.txt
podman unshare chmod 400 ./redis/certs/*.key 2>/dev/null
podman unshare chmod 444 ./redis/certs/*.crt 2>/dev/null

# --- 3. MinIO (UID: 0, GID: 0) ---
# Rootless에서 0:0은 실행 유저 자신입니다.
echo "📦 설정 중: minio"
podman unshare chown -R 0:0 ./minio/secrets ./minio/certs
podman unshare chmod 400 ./minio/secrets/password.txt
podman unshare chmod 400 ./minio/certs/*.key 2>/dev/null
podman unshare chmod 444 ./minio/certs/*.crt 2>/dev/null

# --- 4. PgAdmin (UID: 5050, GID: 5050) ---
echo "📦 설정 중: pgadm"
podman unshare chown -R 5050:5050 ./pgadm/secrets ./pgadm/certs
podman unshare chmod 400 ./pgadm/secrets/password.txt
podman unshare chmod 400 ./pgadm/certs/*.key 2>/dev/null
podman unshare chmod 444 ./pgadm/certs/*.crt 2>/dev/null

# --- 5. Gitea (UID: 1000, GID: 1000) ---
echo "📦 설정 중: gitea"
podman unshare chown -R 1000:1000 ./gitea/secrets ./gitea/certs ./data/gitea
podman unshare chmod 400 ./gitea/secrets/password.txt
podman unshare chmod 400 ./gitea/certs/*.key 2>/dev/null
podman unshare chmod 444 ./gitea/certs/*.crt 2>/dev/null

echo "✅ 모든 권한 설정이 완료되었습니다!"