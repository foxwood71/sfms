#!/bin/bash
set -e

PG_DATA="/var/lib/postgresql/data"
PG_CONF="$PG_DATA/postgresql.conf"

echo ">>> 모든 초기화 완료! 마지막으로 pg_cron을 설정에 추가합니다..."

if [ -f "$PG_CONF" ]; then
    # 기존 pgroonga 옆에 pg_cron을 살짝 추가
    sed -i "s/shared_preload_libraries = 'pgroonga'/shared_preload_libraries = 'pgroonga,pg_cron'/g" "$PG_CONF"
    
    # cron 상세 설정 추가
    {
        echo "cron.database_name = 'postgres'"
        echo "cron.timezone = 'Asia/Seoul'"
    } >> "$PG_CONF"
fi

# 2. [핵심] 10_global_init.sql이 실행되기 전에 임시 서버를 재시작하여 라이브러리 적재!
echo ">>> 확장 모듈 로드를 위해 임시 DB 서버를 재시작합니다..."
pg_ctl restart -D "$PG_DATA" -m fast -w

echo ">>> [99_finalize_config.sh] 설정 완료!"

echo ">>> pg_cron 추가 완료! 이제 정식 서버가 기동됩니다."