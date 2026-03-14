-- ====================================================================
-- 30_app_db_init_sfms.sql
-- sfms 서비스용 유저/DB 생성 및 확장 설치
-- ====================================================================

-- 0. 관리용 DB인 postgres로 접속을 전환합니다.
\c postgres
-- 1. 서비스용 유저 생성 (sfms_admin: 관리자, sfms_usr: 앱 연결용)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'sfms_admin') THEN
        CREATE USER sfms_admin WITH ENCRYPTED PASSWORD 'pgpass';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'sfms_usr') THEN
        CREATE USER sfms_usr WITH ENCRYPTED PASSWORD 'pgpass';
    END IF;
END $$;

-- 2. 권한 설정
-- sfms_admin은 스키마 관리 등을 위해 슈퍼유저 또는 고권한 부여
ALTER USER sfms_admin WITH SUPERUSER;
-- sfms_usr는 데이터 조작만 가능하도록 설정 (필요 시 최소 권한 원칙 적용)
ALTER USER sfms_usr WITH NOSUPERUSER NOCREATEDB NOCREATEROLE;

-- 3. 데이터베이스 생성 및 소유권 지정
SELECT 'CREATE DATABASE sfms_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'sfms_db')\gexec

-- 데이터베이스 접속 권한 부여
GRANT CONNECT ON DATABASE sfms_db TO sfms_usr;
GRANT ALL PRIVILEGES ON DATABASE sfms_db TO sfms_admin;

-- 4. sfms 데이터베이스 내부 권한 설정 (접속 전환 후 실행)
\c sfms_db

-- 확장 설치 (슈퍼유저 권한 필요하므로 sfms_admin 또는 postgres로 실행됨)
CREATE EXTENSION IF NOT EXISTS pgroonga;
COMMENT ON EXTENSION pgroonga IS 'sfms_db 검색용 PGroonga 확장';

-- [중요] public 스키마 또는 특정 스키마에 대한 sfms_usr 권한 부여
-- (테이블이 생성된 후 실행되어야 하므로 배포 스크립트 마지막에 넣는 것이 좋으나,
--  여기서는 기본 스키마 권한을 미리 부여합니다.)
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO sfms_usr;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO sfms_usr;
