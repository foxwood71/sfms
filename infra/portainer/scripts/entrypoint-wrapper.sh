#!/bin/sh
# -e: 에러 시 즉시 종료, -u: 미정의 변수 사용 시 에러
set -eu

echo "<portainer Wrapper Script 시작...>"

# 1. 기동 모드 점검
# sh에서는 배열 대신 위치 매개변수(positional parameters)를 활용합니다.
if [ -f "/certs/portainer.crt" ] && [ -f "/certs/portainer.key" ]; then
    echo "✅ [Security] SSL 인증서 발견! SSL 모드로 실행합니다."
    if [ -f "/certs/ca.crt" ]; then
        echo "🔐 [Security] CA 인증서 발견! SSL 인증서가 추가로 로딩됩니다."
    fi
    # 기본 sh를 사용하여 위치 매개변수에 SSL 옵션들을 설정합니다.
    set -- "--ssl" 
else
    echo "⚠️ [Info] SSL 인증서가 발견되지 않았습니다. 일반 모드로 준비합니다."
    set --
fi

# 2. Portainer 실행
# "$@"는 위에서 set으로 설정한 인자들을 개별적으로 안전하게 따옴표 처리하여 확장합니다.
echo "<portainer 서버 실행...>"
exec /entrypoint "$@"