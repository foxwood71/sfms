#!/bin/bash
# ====================================================================
# PostgreSQL 초기 설정 및 확장 프로그램 설치
# 관리용 DB: postgres (pg_cron 관리용)
# ====================================================================
# -e: (에러 발생 시 종료)
# -u: (미정의 변수 사용 시 에러)
# -o pipefail: (파이프라인 에러 감지)

set -euo pipefail

PG_DATA="/var/lib/postgresql/data"
PG_CONF="$PG_DATA/postgresql.conf"
PG_HBA="$PG_DATA/pg_hba.conf"
CERT_DIR="$PG_DATA/certs"

echo "<pgsql 초기 설정 스크립트 시작...>"

# 1. SSL 키 복사 및 접속/서버 보안 강화 (스마트 모드)
echo "<pgsql SSL 인증서 점검 중...>"

if [ -f "/run/secrets/server.key" ] && [ -f "/run/secrets/server.crt" ]; then
    echo "✅ SSL 인증서 발견! 복사 및 권한 설정을 진행합니다."
    mkdir -p "$CERT_DIR"
    chmod 700 "$CERT_DIR"

    cp /run/secrets/server.key "$CERT_DIR/server.key"
    chown postgres:postgres "$CERT_DIR/server.key"
    chmod 0600 "$CERT_DIR/server.key"

    cp /run/secrets/server.crt "$CERT_DIR/server.crt"
    chown postgres:postgres "$CERT_DIR/server.crt"
    chmod 0644 "$CERT_DIR/server.crt"

    # CA 인증서도 있으면 복사 (verify-full 등을 위해)
    [ -f "/run/secrets/ca.crt" ] && cp /run/secrets/ca.crt "$CERT_DIR/ca.crt"

    # [추가됨] postgresql.conf 수정: SSL 기능 활성화
    if [ -f "$PG_CONF" ]; then
        echo "🔒 postgresql.conf: SSL 옵션을 활성화합니다."
        {
            echo "" # 👈 안전하게 한 줄 띄워주기 (중요!)
            echo "ssl = on"
            echo "ssl_cert_file = '$CERT_DIR/server.crt'"
            echo "ssl_key_file = '$CERT_DIR/server.key'"
            echo "ssl_ca_file = '$CERT_DIR/ca.crt'"
        } >> "$PG_CONF"
    fi

    # [수정됨] pg_hba.conf 수정: 모든 외부 접속을 SSL(hostssl)로 강제
    if [ -f "$PG_HBA" ]; then
        echo "🔒 pg_hba.conf: 모든 외부 접속을 SSL(hostssl)로 강제합니다."
        sed -i "s|^host |hostssl |g" "$PG_HBA"
    fi
else
    echo "⚠️ SSL 인증서 없음! 개발 모드로 판단하여 인증서 복사 및 SSL 설정을 스킵합니다."
fi

# 2. shared_preload_libraries 설정 (기존 로직) - Containerfile CMD와 중복 삭제 
# echo "shared_preload_libraries 설정..."

# if [ -f "$PG_CONF" ]; then
#     if ! grep -q "shared_preload_libraries = '.*pg_cron.*'" "$PG_CONF"; then
#         if grep -q "^shared_preload_libraries =" "$PG_CONF"; then
#             sed -i "s|^shared_preload_libraries = '\(.*\)'|shared_preload_libraries = '\1,pg_cron,pgroonga'|" "$PG_CONF"
#         else
#             echo "shared_preload_libraries = 'pg_cron,pgroonga'" >> "$PG_CONF"
#         fi
#         echo "shared_preload_libraries 설정이 업데이트되었습니다."
#     fi
# else
#     echo "경고: $PG_CONF 파일을 찾을 수 없습니다. 초기화 단계에서 설정이 적용됩니다."
# fi

# 1. postgresql.conf 파일에 필수 확장 모듈 주입
echo ">>> postgresql.conf에 pgroonga, pg_cron 설정 주입 중..."
if [ -f "$PG_CONF" ]; then
    echo "🔒 postgresql.conf: Extension을 활성화합니다."
    {
        echo "" # 👈 안전하게 한 줄 띄워주기 (중요!)
        echo "shared_preload_libraries = 'pgroonga'"
    } >> "$PG_CONF"
fi

# 2. [핵심] 10_global_init.sql이 실행되기 전에 임시 서버를 재시작하여 라이브러리 적재!
echo ">>> 확장 모듈 로드를 위해 임시 DB 서버를 재시작합니다..."
pg_ctl restart -D "$PG_DATA" -m fast -w

echo ">>> [00_configure_system.sh] 설정 완료!"

echo "<pgsql 초기 설정 스크립트 종료...>"