#!/bin/sh
# -e: 에러 시 즉시 종료, -u: 미정의 변수 사용 시 에러
set -eu

echo "<portainer Wrapper Script 시작...>"

# 1. 인증서 경로 생성
mkdir -p /certs

# 2. SSL 인증서 처리
# sh에서는 배열 대신 위치 매개변수(positional parameters)를 활용합니다.
if [ -f "/run/secrets/portainer-key" ] && [ -f "/run/secrets/portainer-cert" ]; then
    echo "✅ [Security] Portainer SSL 인증서 발견! 복사를 시작합니다."
    
    # Key 파일 복사 및 권한 제한 (0600)
    cp /run/secrets/portainer-key /certs/server.key
    chmod 600 /certs/server.key
    
    # Cert 파일 복사 및 권한 설정 (0644)
    cp /run/secrets/portainer-cert /certs/server.cert
    chmod 0644 /certs/server.cert

    # 위치 매개변수에 SSL 옵션들을 설정합니다.
    set -- "--ssl" "--sslcert" "/certs/server.cert" "--sslkey" "/certs/server.key"
else
    echo "⚠️ [Info] SSL 인증서가 없습니다. 일반 모드(HTTP)로 실행합니다."
    # 인증서가 없으면 매개변수를 비웁니다.
    set --
fi

echo "<portainer 서버 실행...>"

# 3. Portainer 실행
# "$@"는 위에서 set으로 설정한 인자들을 개별적으로 안전하게 따옴표 처리하여 확장합니다.
exec /portainer "$@"