#!/bin/bash
# -e: (에러 발생 시 종료)
# -u: (미정의 변수 사용 시 에러)
# -o pipefail: (파이프라인 에러 감지)

set -euo pipefail

echo "<gitea Wrapper Script 스크립트 시작...>"

mkdir -p /certs

if [ -f "/run/secrets/gitea-key" ]; then
    echo "<gitea SSL Key 복사 및 권한 설정중...>"
    cp /run/secrets/gitea-key /certs/server.key
    chown git:git /certs/server.key
    chmod 0600 /certs/server.key
fi

if [ -f "/run/secrets/gitea-cert" ]; then
    echo "<gitea SSL Cert 복사 및 권한 설정중...>"
    cp /run/secrets/gitea-cert /certs/server.cert
    chown git:git /certs/server.cert
    chmod 0644 /certs/server.cert
fi

echo "<gitea Wrapper Script 종료 및 entrypoint.sh 실헹...>"
# root에서 5050 유저로 변경하여 원래 엔트리포인트 실행
exec /usr/bin/entrypoint