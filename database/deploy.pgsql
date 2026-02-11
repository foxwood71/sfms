-- database/deploy.sql
-- 각 도메인 폴더의 파일들을 순서대로 호출

-- 1. CMM (공통)
\i '01_cmm/tables.sql'
\i '01_cmm/functions.sql'
\i '01_cmm/seed.sql'

-- -- 2. IAM (인증/권한)
-- \i '02_iam/tables.sql'
-- \i '02_iam/seed.sql'

-- -- 3. USR (사용자/조직)
-- \i '03_usr/tables.sql'
-- \i '03_usr/seed.sql'

-- -- 4. FAC / EQP (시설/설비)
-- \i '04_fac/tables.sql'
-- \i '05_eqp/tables.sql'

SELECT 'SFMS Database Deployment Completed!' AS status;