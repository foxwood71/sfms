-- SFMS 통합 배포 마스터 스크립트
-- 기존 스키마 삭제 (초기화)
DROP SCHEMA IF EXISTS fac CASCADE;
DROP SCHEMA IF EXISTS iam CASCADE;
DROP SCHEMA IF EXISTS usr CASCADE;
DROP SCHEMA IF EXISTS cmm CASCADE;
DROP SCHEMA IF EXISTS sys CASCADE;

-- 순차적 배포 실행
\i 000_infrastructure.pgsql
\i 100_cmm_tables.pgsql
\i 110_usr_tables.pgsql
\i 120_sys_tables.pgsql
\i 130_iam_tables.pgsql
\i 150_fac_tables.pgsql
\i 011_bootstrap.pgsql
\i 910_cmm_seed_data.pgsql
\i 930_iam_seed_data.pgsql
\i 190_phase1_constraints.pgsql
\i 410_usr_dummy_data.pgsql

-- 배포 완료 확인
SELECT 'DEPLOYMENT COMPLETED SUCCESSFULLY' as status;
