#!/bin/sh
set -eu

echo "<portainer Wrapper Script 시작...>"

# 인증서 경로 생성
mkdir -p /certs

# Secrets에 인증서가 있다면 복사
if [ -f "/run/secrets/portainer-key" ]; then
    echo "<portainer SSL Key 복사 중...>"
    cp /run/secrets/portainer-key /certs/server.key
    chmod 600 /certs/server.key
fi

if [ -f "/run/secrets/portainer-cert" ]; then
    echo "<portainer SSL Cert 복사 중...>"
    cp /run/secrets/portainer-cert /certs/server.cert
    chmod 0644 /certs/server.cert
fi

echo "<portainer 서버 실행...>"
# SSL 인증서가 있으면 적용하여 실행, 없으면 일반 모드로 실행
if [ -f "/certs/server.key" ]; then
    exec /portainer --ssl --sslcert /certs/server.cert --sslkey /certs/server.key
else
    exec /portainer
fi