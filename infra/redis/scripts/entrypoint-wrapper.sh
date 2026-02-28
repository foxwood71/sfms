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

if [ -f "/certs/server.key" ] && [ -f "/certs/server.cert" ]; then
    echo "✅ SSL 인증서 발견!, TLS 활성화를 진행합니다."

    # # redis.conf 파일에 TLS(SSL) 설정 자동 추가
    # REDIS_CONF="/usr/local/etc/redis/redis.conf"
    # if [ -f "$REDIS_CONF" ]; then
    #     echo "🔒 redis.conf: TLS(SSL) 옵션을 활성화합니다."
    #     {
    #         echo "tls-port 6379"
    #         echo "port 0"  # 평문 접속(기본 포트) 차단을 원할 경우 활성화
    #         echo "tls-cert-file /certs/server.cert"
    #         echo "tls-key-file /certs/server.key"
    #         echo "tls-ca-cert-file /certs/ca.cert"
    #         echo "tls-auth-clients yes"
    #     } >> "$REDIS_CONF"
    # fi
    # # 핵심: redis.conf를 수정하지 않고 실행 인자로 TLS 설정을 덮어씌웁니다.
    # # port 0 은 기존 6379 일반 포트를 닫아버리는 역할을 합니다.
    set -- \
        "--port" "0" \
        "--tls-port" "6379" \
        "--tls-cert-file" "/certs/server.cert" \
        "--tls-key-file" "/certs/server.key" \
        "--tls-ca-cert-file" "/certs/ca.cert" \
        "--tls-auth-clients" "yes"
else
    echo "⚠️ SSL 인증서 없음! 개발 모드로 판단하여 인증서 복사 및 TLS 설정을 스킵합니다."
    # 인증서가 없으면 인자를 텅 비워버립니다.
    set --
fi

echo "🚀 <redis 설정 적용 및 서버 실행...>"

# 3. 비밀번호와 (존재한다면) TLS 옵션을 모두 합쳐서 서버 최종 실행!
# "$@" 를 사용하여 위에서 세팅한 인자들 호출
exec redis-server /usr/local/etc/redis/redis.conf --requirepass "${REDIS_PASSWORD}" "$@"