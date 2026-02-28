#!/bin/bash
# MinIO는 bash를 지원하므로 pipefail을 안전하게 사용할 수 있습니다.
# -e: (에러 발생 시 종료)
# -u: (미정의 변수 사용 시 에러)
# -o pipefail: (파이프라인 에러 감지)
set -euo pipefail

echo "<minio Wrapper Script 시작...>"

# MinIO는 도커 환경변수(MINIO_ROOT_USER_FILE 등)와 
echo "🔍 [Security] Redis SSL 인증서 점검 중..."
if [ -f "/root/.minio/certs/public.key" ]&& \
    [ -f "/root/.minio/certs/public.crt" ]&& \
    [ -f "/root/.minio/certs/ca.crt" ]; then
    echo "✅ SSL 인증서 발견!, HTTPS 모드 활성화를 진행합니다."
    echo "🚀 <minio 서버 최종 실행 (HTTPS 모드 실행)>"
    
    # MinIO에게 인증서 폴더 위치를 환경변수로 명확하게 짚어줍니다
    export MINIO_CERTS_DIR="/root/.minio/certs"
else
    echo "⚠️ [Warning] SSL 인증서가 감지되지 않았습니다. 일반(HTTP) 모드로 시작합니다."
    echo "🚀 <minio 서버 최종 실행 (HTTP 모드 실행)>"   
fi

echo "🚀 <minio 서버 최종 실행>"

# MinIO 원본 엔트리포인트로 모든 권한과 실행 인자를 넘겨줍니다.
exec /usr/bin/docker-entrypoint.sh "$@"