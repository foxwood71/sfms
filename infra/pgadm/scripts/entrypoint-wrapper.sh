#!/bin/bash
# -e: (에러 발생 시 종료)
# -u: (미정의 변수 사용 시 에러)
# -o pipefail: (파이프라인 에러 감지)

set -euo pipefail

echo "<pgadm Wrapper Script 스크립트 시작...>"

echo "<pgadm /certs 폴더 생성 및 권한 변경 (root -> pgadmin)"
mkdir -p /certs
chown 5050:5050 /certs

if [ -f "/run/secrets/pgadm-key" ]; then
    echo "<pgadm SSL Key 복사 및 권한 설정중...>"
    cp /run/secrets/pgadm-key /certs/server.key
    chown 5050:5050 /certs/server.key
    chmod 0600 /certs/server.key
fi

if [ -f "/run/secrets/pgadm-cert" ]; then
    echo "<pgadm SSL Cert 복사 및 권한 설정중...>"
    cp /run/secrets/pgadm-cert /certs/server.cert
    chown 5050:5050 /certs/server.cert
    chmod 0644 /certs/server.cert
fi

echo "<pgadm Wrapper Script 종료 및 entrypoint.sh 실행...>"
# root에서 5050 유저로 변경하여 원래 엔트리포인트 실행
exec su -s /bin/sh pgadmin -c "/entrypoint.sh"