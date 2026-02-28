-- ====================================================================
-- 30_app_db_init_sfms.sql
-- sfms 서비스용 유저/DB 생성 및 확장 설치
-- ====================================================================

-- 0. 관리용 DB인 postgres로 접속을 전환합니다.
\c postgres
-- 1. 서비스용 유저 생성 (sfms_admin)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'sfms_admin') THEN
        CREATE USER sfms_admin WITH ENCRYPTED PASSWORD 'sfms_admin';

END IF;

END $$;

-- 2. 권한 부여
ALTER USER sfms_admin WITH SUPERUSER;

-- 3. 데이터베이스 생성
-- (이미 존재하지 않을 경우에만 생성하는 안전한 스크립트)
SELECT 'CREATE DATABASE sfms_db' 
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'sfms_db')\gexec

GRANT ALL PRIVILEGES ON DATABASE sfms_db TO sfms_admin;

-- 4. sfms 데이터베이스로 컨텍스트 전환 및 확장 설치
-- 중요: \c 명령은 psql에서만 동작하며, 아래 명령어들은 sfms DB에서 실행됩니다.
\c sfms_db

CREATE EXTENSION IF NOT EXISTS pgroonga;

COMMENT ON EXTENSION pgroonga IS 'sfms_db 검색용 PGroonga 확장';