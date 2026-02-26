#!/bin/bash
# -e: (에러 발생 시 종료)
# -u: (미정의 변수 사용 시 에러)
# -o pipefail: (파이프라인 에러 감지)

set -euo pipefail

echo "<gitea Wrapper Script 스크립트 시작...>"

# ====================================================================
# [만능] Docker Secrets -> 환경변수 자동 변환 래퍼 스크립트
# ====================================================================
echo "🔍 [SFMS Security] 시크릿 파일 로드를 시작합니다..."

# if [ -f "/run/secrets/pgsql-key" ] && [ -f "/run/secrets/pgsql-cert" ]; then
#     echo "✅ SSL 인증서 발견! 복사 및 권한 설정을 진행합니다."
#     mkdir -p "$CERT_DIR"
#     chmod 700 "$CERT_DIR"

#     cp /run/secrets/pgsql-key "$CERT_DIR/server.key"
#     chown postgres:postgres "$CERT_DIR/server.key"
#     chmod 0600 "$CERT_DIR/server.key"

#     cp /run/secrets/pgsql-cert "$CERT_DIR/server.cert"
#     chown postgres:postgres "$CERT_DIR/server.cert"
#     chmod 0644 "$CERT_DIR/server.cert"

#     # [추가됨] postgresql.conf 수정: SSL 기능 활성화
#     if [ -f "$PG_CONF" ]; then
#         # echo "🔒 postgresql.conf: SSL 옵션을 활성화합니다."
#         # echo "ssl = on" >> "$PG_CONF"
#         # echo "ssl_cert_file = '$CERT_DIR/server.cert'" >> "$PG_CONF"
#         # echo "ssl_key_file = '$CERT_DIR/server.key'" >> "$PG_CONF"
#         echo "🔒 postgresql.conf: SSL 옵션을 활성화합니다."
#         {
#             echo "ssl = on"
#             echo "ssl_cert_file = '$CERT_DIR/server.cert'"
#             echo "ssl_key_file = '$CERT_DIR/server.key'"
#         } >> "$PG_CONF"
#     fi

#     # [수정됨] pg_hba.conf 수정: 모든 외부 접속을 SSL(hostssl)로 강제
#     if [ -f "$PG_HBA" ]; then
#         echo "🔒 pg_hba.conf: 모든 외부 접속을 SSL(hostssl)로 강제합니다."
#         sed -i "s|^host |hostssl |g" "$PG_HBA"
#     fi
# fi

# # 1. /run/secrets 폴더가 존재하는지 확인
# if [ -d "/run/secrets" ]; then
#     # 2. 폴더 안의 모든 시크릿 파일을 하나씩 순회
#     for secret_file in /run/secrets/*; do
#         # 실제 파일인 경우에만 처리 (폴더나 심볼릭 링크 등 제외)
#         if [ -f "$secret_file" ]; then
#             # 3. 파일명 추출 및 변수명 포맷팅 (소문자->대문자, 하이픈->언더바)
#             # 예: "redis-password" -> "REDIS_PASSWORD"
#             raw_name=$(basename "$secret_file")
#             var_name=$(echo "$raw_name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
            
#             # 4. 파일 내용을 읽어서 실제 환경변수로 Export!
#             export "$var_name"="$(cat "$secret_file")"
#             echo "✅ 시크릿 로드 완료: $var_name 환경변수가 설정되었습니다."
#         fi
#     done
# else
#     echo "⚠️ /run/secrets 폴더가 없습니다. (개발 모드 또는 시크릿 미적용 상태)"
# fi

echo "🚀 메인 애플리케이션을 실행합니다..."

# 5. 원래 컨테이너가 실행하려던 진짜 명령어(CMD)에 권한을 넘기고 실행
exec "$@"
# root에서 5050 유저로 변경하여 원래 엔트리포인트 실행
exec /usr/bin/entrypoint