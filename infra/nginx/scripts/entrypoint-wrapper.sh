#!/bin/sh
# Nginx Alpine 이미지는 sh를 사용합니다.
set -eu

echo "<nginx Wrapper Script 시작...>"

# 1. 로그 및 SSL 폴더 준비
mkdir -p /var/log/nginx
mkdir -p /etc/nginx/ssl
# Nginx Alpine의 기본 유저 ID는 보통 101입니다 (chown은 이름으로 수행)
chown -R nginx:nginx /var/log/nginx /etc/nginx/ssl

# 2. 스마트 인증서 복사 및 보안 권한 부여
if [ -f "/run/secrets/nginx-key" ] && [ -f "/run/secrets/nginx-cert" ]; then
    echo "✅ [Security] Nginx SSL 인증서 발견! 복사를 진행합니다."
    
    cp /run/secrets/nginx-key /etc/nginx/ssl/server.key
    chmod 600 /etc/nginx/ssl/server.key
    chown nginx:nginx /etc/nginx/ssl/server.key

    cp /run/secrets/nginx-cert /etc/nginx/ssl/server.cert
    chmod 0644 /etc/nginx/ssl/server.cert
    chown nginx:nginx /etc/nginx/ssl/server.cert
else
    echo "⚠️ [Warning] SSL 인증서가 없습니다. 일반 HTTP 모드로만 동작할 수 있습니다."
fi

echo "<nginx 설정 검사 및 실행...>"
# 설정 파일 문법 검사 후 실행
nginx -t
exec nginx -g "daemon off;"