-- database/deploy.sql
-- 각 도메인 폴더의 파일들을 순서대로 호출

-- 공통 프롬프트
-- 이 코드에서 주요부분에 주석을 달아주고 각 field 마다 꼼꼼 하게 생략하지 말고 comment를 이용해서 주석을 달아줘 그리고 인덱스는 각 테이블 생성 코드 아래에 넣어줘 [Pro]
-- Phase 1 - 
-- 1. USR (사용자/조직)
\i '01_user/schema.pgsql'
-- 2. IAM (인증/권한)
\i '02_iam/schema.pgsql'
-- 3. CMM (공통 코드)
\i '03_cmm/schema.pgsql'
\i '03_cmm/seed.pgsql'
-- 4. FAC (시설)
\i '04_fac/schema.sql'


SELECT 'SFMS Database Deployment Completed!' AS status;