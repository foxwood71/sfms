#!/bin/bash
# ====================================================================
# PostgreSQL 초기 설정 및 확장 프로그램 설치
# 관리용 DB: postgres (pg_cron 관리용)
# ====================================================================
# -e: (에러 발생 시 종료)
# -u: (미정의 변수 사용 시 에러)
# -o pipefail: (파이프라인 에러 감지)

set -euo pipefail

# postgresql.conf 및 pg_hba.conf 파일 경로 설정 (PostgreSQL 이미지에 따라 다를 수 있음)
PG_DATA="/var/lib/postgresql/data"
PG_CONF="$PG_DATA/postgresql.conf"
PG_HBA="$PG_DATA/pg_hba.conf"
CERT_DIR="$PG_DATA/certs"

echo "<pgsql 초기 설정 스크립트 시작...>"

# 1. SSL 키 복사 및 권한 설정 (복구됨)
# Secrets(읽기전용) -> /etc/ssl/certs/(전용공간)으로 복사
echo "<pgsql SSL 인증서 설치 중...>"

mkdir -p "$CERT_DIR"
chmod 700 "$CERT_DIR"

if [ -f "/run/secrets/pgsql-key" ]; then
    cp /run/secrets/pgsql-key "$CERT_DIR/server.key"
    chown postgres:postgres "$CERT_DIR/server.key"
    chmod 0600 "$CERT_DIR/server.key"
fi

if [ -f "/run/secrets/pgsql-cert" ]; then
    cp /run/secrets/pgsql-cert "$CERT_DIR/server.cert"
    chown postgres:postgres "$CERT_DIR/server.cert"
    chmod 0644 "$CERT_DIR/server.cert"
fi


# 2. shared_preload_libraries 설정 (기존 로직)
echo "shared_preload_libraries 설정..."

if [ -f "$PG_CONF" ]; then
    if ! grep -q "shared_preload_libraries = '.*pg_cron.*'" "$PG_CONF"; then
        if grep -q "^shared_preload_libraries =" "$PG_CONF"; then
            sed -i "s|^shared_preload_libraries = '\(.*\)'|shared_preload_libraries = '\1,pg_cron,pgroonga'|" "$PG_CONF"
        else
            echo "shared_preload_libraries = 'pg_cron,pgroonga'" >> "$PG_CONF"
        fi
        echo "shared_preload_libraries 설정이 업데이트되었습니다."
    fi
else
    echo "경고: $PG_CONF 파일을 찾을 수 없습니다. 초기화 단계에서 설정이 적용됩니다."
fi


# 3. 보안 강화: pg_hba.conf 수정 (SSL 강제) - 필요시
# echo "pg_hba.conf: SSL 접속 강제 설정 중..."
# 
# if [ -f "$PG_HBA" ]; then
#     sed -i "s|^host |hostssl |g" "$PG_HBA"
#     echo "pg_hba.conf: SSL 접속 강제 설정 완료."
# fi

echo "<pgadm 초기 설정 스크립트 종료...>"