#!/bin/bash
# -e: (에러 발생 시 종료)
# -u: (미정의 변수 사용 시 에러)
# -o pipefail: (파이프라인 에러 감지)

set -euo pipefail

echo "<pgadm Wrapper Script 시작...>"

# 1. 필수 폴더 생성 및 소유권 변경 (pgAdmin UID 5050 사용) 
# /certs 폴더가 없으면 생성하고 pgadmin 유저에게 권한을 줍니다.
# CERT_DIR="/var/lib/pgadmin/certs"
# mkdir -p "$CERT_DIR"
# chown 5050:5050 /certs

# 2. SSL 인증서 처리 (스마트 체크) 
# 비밀(Secrets) 폴더에 인증서가 존재할 때만 안전하게 복사합니다.
if [ -f "/certs/server.key" ] && [ -f "/certs/server.cert" ]; then
    echo "✅ [Security] SSL 인증서 발견! 보안 설정을 진행합니다."
    if [ -f "/certs/ca.cert" ]; then
        echo "🔐 [Security] CA 인증서 발견! SSL 인증서가 추가로 로딩됩니다."
    fi
else
    echo "⚠️ [Info] SSL 인증서가 발견되지 않았습니다. 일반 모드로 준비합니다."
fi

# 3. 추가 환경 변수 확인 (선택 사항)
# # 만약 비밀번호 파일이 존재한다면 로그로 알려줍니다. 
# if [ -f "/run/secrets/sfms-pgadmin-password" ]; then
#     echo "🔐 [Auth] 관리자 비밀번호 시크릿이 로드되었습니다."
# fi

# 4. Gunicorn 서버에 HTTPS 강제 적용 (가장 확실한 방법)
# environment: 에 설정
    # - PGADMIN_CONFIG_SSL_KEY_FILE="'/var/lib/pgadmin/certs/server.key'"
    # - PGADMIN_LISTEN_PORT=443
    # - PGADMIN_ENABLE_TLS=True
# export GUNICORN_CMD_ARGS="--certfile=$CERT_DIR/server.crt --keyfile=$CERT_DIR/server.key"

# # root 권한을 버리고 pgadmin(5050) 유저로 전환하여 원래의 엔트리포인트를 실행합니다. 
# # exec를 사용하여 프로세스 ID(PID 1)를 그대로 승계합니다.
# exec su -s /bin/sh pgadmin -c "/entrypoint.sh"

# 5. 원래의 엔트리포인트 실행
echo "📜 <pgadm entrypoint.sh 실행...>"
exec /entrypoint.sh "$@"