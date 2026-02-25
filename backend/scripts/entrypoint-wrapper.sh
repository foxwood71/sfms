#!/bin/bash
set -euo pipefail

echo "<backend Wrapper Script 시작...>"

# SSL 옵션 초기화
SSL_ARGS=""

# 인증서 파일 존재 확인
if [ -f "/run/secrets/sfms-backend-key" ] && [ -f "/run/secrets/sfms-backend-cert" ]; then
    echo "✅ [Security] 백엔드 SSL 인증서 발견! HTTPS 모드로 전환합니다."
    SSL_ARGS="--ssl-keyfile /run/secrets/sfms-backend-key --ssl-certfile /run/secrets/sfms-backend-cert"
else
    echo "⚠️ [Info] SSL 인증서 없음. 일반 HTTP 모드로 실행합니다."
fi

echo "<FastAPI 서버 실행...>"
# CMD로 넘어온 기본 인자들($@) 뒤에 SSL 옵션(있을 경우만) 추가
# 운영 환경을 위해 --reload는 빼고 실행하는 것이 좋습니다.
# "${SSL_ARGS[@]}"는 Bash에서 배열 요소를 하나씩 꺼내어 각각 큰따옴표를 붙여주는 특수한 문법입니다. 
# 이렇게 하면 SSL_ARGS 배열에 여러 개의 인자가 있을 때도 각각이 올바르게 처리됩니다.
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 "${SSL_ARGS[@]}"