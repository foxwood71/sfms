#!/bin/sh
set -eu

echo "<nginx Wrapper Script 시작...>"

# 로그 폴더 권한 확인 (nginx 기본 유저가 쓸 수 있도록)
mkdir -p /var/log/nginx
chown -R nginx:nginx /var/log/nginx

# SSL 인증서가 저장될 경로 생성
mkdir -p /etc/nginx/ssl

# Secrets에 인증서가 있다면 복사
if [ -f "/run/secrets/nginx-key" ]; then
    echo "<nginx SSL Key 복사 중...>"
    cp /run/secrets/nginx-key /etc/nginx/ssl/server.key
    chmod 600 /etc/nginx/ssl/server.key
fi

if [ -f "/run/secrets/nginx-cert" ]; then
    echo "<nginx SSL Cert 복사 중...>"
    cp /run/secrets/nginx-cert /etc/nginx/ssl/server.cert
    chmod 0644 /etc/nginx/ssl/server.cert
fi

echo "<nginx 설정 검사 및 실행...>"
# Nginx 실행
exec nginx -g "daemon off;"