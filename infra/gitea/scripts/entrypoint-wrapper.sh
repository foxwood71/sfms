#!/bin/bash
# -e: (에러 발생 시 종료)
# -u: (미정의 변수 사용 시 에러)
# -o pipefail: (파이프라인 에러 감지)

set -euo pipefail

echo "<gitea Wrapper Script 스크립트 시작...>"

# ====================================================================
#  SSL 인증서 처리 (스마트 체크)
# ====================================================================
# 비밀(Secrets) 폴더에 인증서가 존재할 때만 안전하게 복사합니다.
if [ -f "/certs/server.key" ] && [ -f "/certs/server.crt" ]; then
    echo "✅ [Security] SSL 인증서 발견! 보안 설정을 진행합니다."
    if [ -f "/certs/ca.crt" ]; then
        echo "🔐 [Security] CA 인증서 발견! SSL 인증서가 추가로 로딩됩니다."
    fi
else
    echo "⚠️ [Info] SSL 인증서가 발견되지 않았습니다. 일반 모드로 준비합니다."
fi

echo "🚀 메인 애플리케이션을 실행합니다..."

# 5. 원래 컨테이너가 실행하려던 진짜 명령어(CMD)에 권한을 넘기고 실행
exec /usr/bin/entrypoint "$@"