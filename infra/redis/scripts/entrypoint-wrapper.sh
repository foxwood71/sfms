#!/bin/sh
# 참고: Redis Alpine 이미지는 bash 대신 sh를 사용합니다.
# set -euo pipefail <-- bash 전용 옵션이므로 sh에서는 -e와 -u만 사용합니다.
set -eu 

echo "<redis Wrapper Script 시작...>"

# 1. 시크릿 파일에서 비밀번호 읽어오기
if [ -f "/run/secrets/redis-password" ]; then
    REDIS_PASSWORD="$(cat /run/secrets/redis-password)"
    export REDIS_PASSWORD
    echo "✅ [Security] 시크릿 파일에서 Redis 비밀번호를 성공적으로 로드했습니다."
else
    echo "⚠️ [Warning] 비밀번호 시크릿 파일이 없습니다! 실행 에러가 발생할 수 있습니다."
fi

# 2. 인증서 스마트 적용 및 SSL 자동 활성화 (조건부)
echo "🔍 [Security] Redis SSL 인증서 점검 중..."
REDIS_CONF="/usr/local/etc/redis/redis.conf"

if [ -f "/run/secrets/redis-key" ] && [ -f "/run/secrets/redis-cert" ]; then
    echo "✅ SSL 인증서 발견! 복사 및 권한 설정, TLS 활성화를 진행합니다."
    
    # 인증서 폴더 준비 (Alpine 기반 redis 이미지의 기본 유저는 uid 999, gid 1000)
    mkdir -p /certs
    chown 999:1000 /certs
    chmod 700 /certs

    # 키 파일 복사 및 권한 부여
    cp /run/secrets/redis-key /certs/server.key
    chown 999:1000 /certs/server.key
    chmod 0600 /certs/server.key

    # 인증서 파일 복사 및 권한 부여
    cp /run/secrets/redis-cert /certs/server.cert
    chown 999:1000 /certs/server.cert
    chmod 0644 /certs/server.cert

    # redis.conf 파일에 TLS(SSL) 설정 자동 추가
    if [ -f "$REDIS_CONF" ]; then
        echo "🔒 redis.conf: TLS(SSL) 옵션을 활성화합니다."
        {
            echo "tls-port 6379"
            echo "port 0"  # 평문 접속(기본 포트) 차단을 원할 경우 활성화
            echo "tls-cert-file /certs/server.cert"
            echo "tls-key-file /certs/server.key"
        } >> "$REDIS_CONF"
    fi
else
    echo "⚠️ SSL 인증서 없음! 개발 모드로 판단하여 인증서 복사 및 TLS 설정을 스킵합니다."
fi

echo "<redis 설정 적용 및 서버 실행...>"

# 3. 설정 파일과 비밀번호 환경변수를 적용하여 Redis 서버 최종 실행!
exec redis-server "$REDIS_CONF" --requirepass "${REDIS_PASSWORD}"