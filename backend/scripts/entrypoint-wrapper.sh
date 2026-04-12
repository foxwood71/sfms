#!/bin/bash
set -euo pipefail

echo "<backend Wrapper Script 시작...>"

# SSL 옵션 초기화 (배열 사용)
SSL_ARGS=()

# 인증서 파일 존재 확인
if [ -f "/run/secrets/sfms-backend-key" ] && [ -f "/run/secrets/sfms-backend-cert" ]; then
    echo "✅ [Security] 백엔드 SSL 인증서 발견! HTTPS 모드로 전환합니다."
    SSL_ARGS=(
        "--ssl-keyfile" "/run/secrets/sfms-backend-key"
        "--ssl-certfile" "/run/secrets/sfms-backend-cert"
    )
else
    echo "⚠️ [Info] SSL 인증서 없음. 일반 HTTP 모드로 실행합니다."
fi

echo "<FastAPI 서버 실행...>"
# 배열을 사용하여 인자가 비어있을 때 빈 문자열이 전달되지 않도록 합니다.
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 "${SSL_ARGS[@]}"
