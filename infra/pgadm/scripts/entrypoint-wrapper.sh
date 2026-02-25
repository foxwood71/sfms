#!/bin/bash
# -e: (에러 발생 시 종료)
# -u: (미정의 변수 사용 시 에러)
# -o pipefail: (파이프라인 에러 감지)

set -euo pipefail

echo "<pgadm Wrapper Script 시작...>"

# 1. 필수 폴더 생성 및 소유권 변경 (pgAdmin UID 5050 사용) 
# /certs 폴더가 없으면 생성하고 pgadmin 유저에게 권한을 줍니다.
CERT_DIR="/var/lib/pgadmin/certs"
mkdir -p "$CERT_DIR"
# chown 5050:5050 /certs

# 2. SSL 인증서 처리 (스마트 체크) 
# 비밀(Secrets) 폴더에 인증서가 존재할 때만 안전하게 복사합니다.
if [ -f "/run/secrets/pgadm-key" ] && [ -f "/run/secrets/pgadm-cert" ]; then
    echo "✅ [Security] pgAdmin SSL 인증서 발견! 보안 설정을 진행합니다."

    # SSL Key 복사 및 권한 설정 (0600: 소유자만 읽기 가능) 
    cp /run/secrets/pgadm-key "$CERT_DIR/server.key"
    # chown 5050:5050 "$CERT_DIR/server.key"
    chmod 0600 "$CERT_DIR/server.key"

    # SSL Cert 복사 및 권한 설정 (0644: 일반적인 읽기 권한) 
    cp /run/secrets/pgadm-cert "$CERT_DIR/server.crt"
    # chown 5050:5050 "$CERT_DIR/server.cert"
    chmod 0644 "$CERT_DIR/server.key"
else
    echo "⚠️ [Info] SSL 인증서가 발견되지 않았습니다. 일반 모드로 준비합니다."
fi

# 3. 추가 환경 변수 확인 (선택 사항)
# 만약 비밀번호 파일이 존재한다면 로그로 알려줍니다. 
if [ -f "/run/secrets/sfms-pgadmin-password" ]; then
    echo "🔐 [Auth] 관리자 비밀번호 시크릿이 로드되었습니다."
fi

# 4. Gunicorn 서버에 HTTPS 강제 적용 (가장 확실한 방법)
export GUNICORN_CMD_ARGS="--certfile=$CERT_DIR/server.crt --keyfile=$CERT_DIR/server.key"

# # root 권한을 버리고 pgadmin(5050) 유저로 전환하여 원래의 엔트리포인트를 실행합니다. 
# # exec를 사용하여 프로세스 ID(PID 1)를 그대로 승계합니다.
# exec su -s /bin/sh pgadmin -c "/entrypoint.sh"

# 5. 원래의 엔트리포인트 실행
echo "<pgadm entrypoint.sh 실행...>"
exec /entrypoint.sh "$@"