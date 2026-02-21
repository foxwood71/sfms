#!/bin/bash
set -euo pipefail

echo "<redis Wrapper Script 시작...>"

# /certs 폴더 생성 및 권한 변경 (redis 유저 ID: 999)
mkdir -p /certs
chown 999:999 /certs

# Secrets에 인증서가 있다면 복사 (나중에 SSL 사용 시)
if [ -f "/run/secrets/redis-key" ]; then
    cp /run/secrets/redis-key /certs/server.key
    chown 999:999 /certs/server.key
    chmod 0600 /certs/server.key
fi

if [ -f "/run/secrets/redis-cert" ]; then
    cp /run/secrets/redis-cert /certs/server.cert
    chown 999:999 /certs/server.cert
    chmod 0644 /certs/server.cert
fi

echo "<redis 설정 적용 및 서버 실행...>"
# redis-server 실행 (설정 파일 경로 지정)
exec redis-server /usr/local/etc/redis/redis.conf --requirepass "${REDIS_PASSWORD}"