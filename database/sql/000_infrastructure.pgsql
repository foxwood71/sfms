-----------------------------------------------------------
-- [Phase 0] Infrastructure & Schema Setup
-----------------------------------------------------------

-- 1. Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgroonga";

-- 2. Schemas
CREATE SCHEMA IF NOT EXISTS sys;
CREATE SCHEMA IF NOT EXISTS cmm;
CREATE SCHEMA IF NOT EXISTS usr;
CREATE SCHEMA IF NOT EXISTS iam;
CREATE SCHEMA IF NOT EXISTS fac;

COMMENT ON SCHEMA sys IS '시스템 관리 도메인';
COMMENT ON SCHEMA cmm IS '공통 관리 도메인';
COMMENT ON SCHEMA usr IS '사용자 및 조직 도메인';
COMMENT ON SCHEMA iam IS '인증 및 권한 도메인';
COMMENT ON SCHEMA fac IS '시설 및 공간 관리 도메인';

-- 3. Utility Functions
CREATE OR REPLACE FUNCTION sys.trg_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
