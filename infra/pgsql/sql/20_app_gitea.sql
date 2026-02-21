-- ====================================================================
-- 20_init_gitea.sql
-- Gitea 서비스용 유저/DB 생성 및 확장 설치
-- ====================================================================

-- 1. 서비스용 유저 생성 (Gitea)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'gitea') THEN
        CREATE USER gitea WITH ENCRYPTED PASSWORD 'gitea';
    END IF;
END
$$;

-- 2. 권한 부여
ALTER USER gitea WITH SUPERUSER;

-- 3. 데이터베이스 생성
-- (이미 존재하지 않을 경우에만 생성하는 안전한 스크립트)
SELECT 'CREATE DATABASE gitea' 
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'gitea')\gexec

GRANT ALL PRIVILEGES ON DATABASE gitea TO gitea;

-- 4. Gitea 데이터베이스로 컨텍스트 전환 및 확장 설치
-- 중요: \c 명령은 psql에서만 동작하며, 아래 명령어들은 gitea DB에서 실행됩니다.
\c gitea

CREATE EXTENSION IF NOT EXISTS pgroonga;
COMMENT ON EXTENSION pgroonga IS 'Gitea 검색용 PGroonga 확장';