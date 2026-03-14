-- =========================================================
-- Domain: CMM (Common) - Seed Data (Schema v1.0 Compliant)
-- Description: 시스템 도메인 등록 및 기초 코드 설정
-- =========================================================

-- 1. 시스템 도메인 등록
INSERT INTO sys.system_domains (domain_code, domain_name, schema_name, description, sort_order)
VALUES
('SYS', 'System', 'sys', '시스템 관리 도메인', 1),
('CMM', 'Common', 'cmm', '공통 관리 도메인', 1),
('IAM', 'Identity', 'iam', '인증 및 권한 관리', 2),
('USR', 'User', 'usr', '사용자 및 조직 관리', 3),
('FAC', 'Facility', 'fac', '시설 및 공간 관리', 4),
('EQP', 'Equipment', 'eqp', '설비 관리', 5),
('WQT', 'Water Quality', 'wqt', '수질 관리', 6);

-- 2. 자동 채번 규칙 초기화
INSERT INTO sys.sequence_rules (domain_code, prefix, current_year, current_seq)
VALUES
('FAC', 'FAC', '2026', 0),
('EQP', 'EQP', '2026', 0),
('WQT', 'WQT', '2026', 0);

-- 3. 공통 코드 그룹 설정
INSERT INTO cmm.code_groups (group_code, group_name, description, is_system)
VALUES
('SYS_USE_YN', '사용 여부', '시스템 전반 활성화 상태 구분', true),
('FILE_CATEGORY', '파일 분류', '문서, 도면, 사진 등 파일 유형', true),
('EQP_STATUS', '설비 상태', '설비의 현재 가동 상태', false),
('POS_TYPE', '직위/직급', '사용자의 직위 및 직급 정보', true),
('DUTY_TYPE', '직책', '사용자의 보직 및 직책 정보', true),
('ROLE', '권한 역할', '시스템 접근 권한 그룹', true),
('USR_STATUS', '계정 상태', '사용자 계정의 활성/차단 상태', true);

-- 4. 공통 코드 상세 및 가변 속성(JSONB) 설정
INSERT INTO cmm.code_details (group_code, detail_code, detail_name, props, sort_order)
VALUES
-- 사용 여부
('SYS_USE_YN', 'Y', '사용', '{"color": "green"}', 1),
('SYS_USE_YN', 'N', '미사용', '{"color": "red"}', 2),

-- 권한 역할 (ROLE)
('ROLE', 'SUPER_USER', '슈퍼 관리자', '{"color": "gold"}', 10),
('ROLE', 'USER', '일반 사용자', '{"color": "blue"}', 20),

-- 계정 상태
('USR_STATUS', 'ACTIVE', '정상', '{"color": "blue"}', 10),
('USR_STATUS', 'BLOCKED', '차단', '{"color": "red"}', 20),

-- 직급 (POS_TYPE)
('POS_TYPE', 'STAFF', '사원', '{}'::jsonb, 10),
('POS_TYPE', 'ASSISTANT', '대리', '{}'::jsonb, 20),
('POS_TYPE', 'MANAGER', '과장', '{}'::jsonb, 30),
('POS_TYPE', 'DEPUTY', '차장', '{}'::jsonb, 40),
('POS_TYPE', 'HEAD', '부장', '{}'::jsonb, 50),
('POS_TYPE', 'SENIOR', '수석', '{}'::jsonb, 55), -- 추가됨
('POS_TYPE', 'DIRECTOR', '이사', '{}'::jsonb, 60),
('POS_TYPE', 'MD', '상무', '{}'::jsonb, 70),
('POS_TYPE', 'SMD', '전무', '{}'::jsonb, 80),
('POS_TYPE', 'EVP', '부사장', '{}'::jsonb, 90),
('POS_TYPE', 'CEO', '사장', '{}'::jsonb, 100),

-- 직책 (DUTY_TYPE)
('DUTY_TYPE', 'MEMBER', '팀원', '{}'::jsonb, 10),
('DUTY_TYPE', 'LEADER', '팀장', '{}'::jsonb, 20),
('DUTY_TYPE', 'HEAD', '부서장', '{}'::jsonb, 25), -- 추가됨
('DUTY_TYPE', 'CHIEF', '실장', '{}'::jsonb, 30),
('DUTY_TYPE', 'DIVISION_HEAD', '본부장', '{}'::jsonb, 40),
('DUTY_TYPE', 'DIRECTOR_HEAD', '부문장', '{}'::jsonb, 50),
('DUTY_TYPE', 'PRESIDENT', '대표이사', '{}'::jsonb, 60),

-- 파일 분류
('FILE_CATEGORY', 'DWG', 'CAD 도면', '{"icon": "FileDoneOutlined", "ext": "dwg"}', 1),
('FILE_CATEGORY', 'DOC', '일반 문서', '{"icon": "FileTextOutlined", "ext": "pdf,docx"}', 2),
('FILE_CATEGORY', 'IMG', '현장 사진', '{"icon": "PictureOutlined", "ext": "jpg,png"}', 3),

-- 설비 상태
('EQP_STATUS', 'RUN', '가동 중', '{"status": "processing", "color": "#52c41a"}', 1),
('EQP_STATUS', 'STP', '정지', '{"status": "default", "color": "#bfbfbf"}', 2),
('EQP_STATUS', 'ERR', '장애', '{"status": "error", "color": "#f5222d"}', 3);
