#!/bin/bash
# -e: 에러 발생 시 종료, -u: 미정의 변수 에러
set -eu

echo "<minio Wrapper Script 시작...>"

# 인증서가 저장될 내부 경로 생성
mkdir -p /certs/CAs

# Secrets에 인증서가 있다면 복사 (나중에 SSL 사용 시)
if [ -f "/run/secrets/minio-key" ]; then
    echo "<minio SSL Key 복사 중...>"
    cp /run/secrets/minio-key /certs/private.key
    chmod 0600 /certs/private.key
fi

if [ -f "/run/secrets/minio-cert" ]; then
    echo "<minio SSL Cert 복사 중...>"
    cp /run/secrets/minio-cert /certs/public.crt
    chmod 0644 /certs/public.crt
fi

echo "<minio 서버 실행...>"
# 기본 엔트리포인트 실행 (certs-dir 옵션 추가)
exec minio server /data --console-address ":9001" --certs-dir /certs