-- database/deploy.pgsql
-- 각 도메인 폴더의 파일들을 순서대로 호출

-- ==========================================
-- 0. 사전 준비 (순환 참조 방지용 공통 객체)
-- ==========================================
CREATE SCHEMA IF NOT EXISTS sys;
COMMENT ON SCHEMA sys IS '시스템 관리';

CREATE EXTENSION IF NOT EXISTS pgroonga;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 모든 도메인에서 공통으로 사용하는 시간 갱신 트리거 함수를 최우선으로 생성
CREATE OR REPLACE FUNCTION sys.trg_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION sys.trg_set_updated_at IS '레코드 수정 시 updated_at 필드를 자동으로 갱신하는 트리거 함수';

-- ==========================================
-- 1. 테이블 생성 (의존성 순서에 맞게 배치)
-- ==========================================
-- 1) USR (사용자/조직)
\i '01_usr_schema.pgsql'

-- 2) SYS (시스템 관리)
\i '02_sys_schema.pgsql'

-- 2) CMM (공통 관리)
\i '03_cmm_schema.pgsql'

-- 3) IAM (인증/권한)
\i '04_iam_schema.pgsql'

-- 4) FAC (시설)
\i '05_fac_schema.pgsql'

-- ==========================================
-- 2. 지연된 외래키 제약조건 (Cross-Domain)
-- ==========================================
\i '90_constraints.pgsql'

-- ==========================================
-- 3. 기초 데이터 (Seed)
-- ==========================================
\i '93_cmm_seed.pgsql'

SELECT 'SFMS Database Deployment Completed!' AS status;
