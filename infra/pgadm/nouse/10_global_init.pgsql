-- 1. SFMS 데이터베이스 생성
CREATE DATABASE sfms_db;

-- 2. 데이터베이스 설정 변경 (TimeZone)
ALTER DATABASE sfms_db SET timezone TO 'Asia/Seoul';

-- 3. sfms_db에 연결하여 확장 기능 활성화
\c sfms_db

-- PGroonga (한글/JSONB 검색용)
CREATE EXTENSION IF NOT EXISTS pgroonga;

-- PG_CRON (스케줄링용 - postgres DB에 설치되지만, 여기서 명시적으로 확인)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- UUID 생성을 위한 확장 (선택사항, 필요시 사용)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

RAISE NOTICE 'SFMS Database and Extensions initialized successfully.';