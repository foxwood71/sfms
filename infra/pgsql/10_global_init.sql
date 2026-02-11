-- ====================================================================
-- 10_init_global.sql
-- 전역 설정 및 관리용 DB(postgres) 초기화
-- ====================================================================

-- 1. 관리용 확장 프로그램 설치 (postgres DB)
CREATE EXTENSION IF NOT EXISTS pg_cron;
COMMENT ON EXTENSION pg_cron IS 'PostgreSQL용 간단한 cron 기반 스케줄러';

CREATE EXTENSION IF NOT EXISTS pgroonga;
COMMENT ON EXTENSION pgroonga IS 'PostgreSQL용 고속全文검색 엔진';

-- 2. pg_cron 상세 설정
-- ALTER SYSTEM은 postgresql.auto.conf를 수정하여 영속성을 가집니다.
ALTER SYSTEM SET cron.database_name = 'postgres';
ALTER SYSTEM SET cron.timezone = 'Asia/Seoul';

-- 3. 성능 및 보안 설정 (전역 적용)
ALTER SYSTEM SET wal_level = 'replica';
ALTER SYSTEM SET synchronous_commit = 'on';
ALTER SYSTEM SET checkpoint_timeout = '5min';
ALTER SYSTEM SET max_wal_size = '1GB';

-- 4. SSL 설정 (Secrets 또는 Copy로 배치된 경로 기준)
ALTER SYSTEM SET ssl = 'on';
ALTER SYSTEM SET ssl_key_file = '/var/lib/postgresql/data/certs/server.key';
ALTER SYSTEM SET ssl_cert_file = '/var/lib/postgresql/data/certs/server.cert';

-- 5. 설정 적용 (리로드)
SELECT pg_reload_conf();