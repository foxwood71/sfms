-- =========================================================
-- Domain: CMM (Common) - Seed Data (Schema v1.0 Compliant)
-- Description: 시스템 도메인 등록 및 기초 코드 설정
-- =========================================================

-- 1. 시스템 도메인 등록 [cite: 3]
INSERT INTO cmm.system_domains (domain_code, domain_name, schema_name, description, sort_order)
VALUES
('CMM', 'Common', 'cmm', '공통 관리 도메인', 1),
('IAM', 'Identity', 'iam', '인증 및 권한 관리', 2),
('USR', 'User', 'usr', '사용자 및 조직 관리', 3),
('FAC', 'Facility', 'fac', '시설 및 공간 관리', 4),
('EQP', 'Equipment', 'eqp', '설비 관리', 5),
('WQT', 'Water Quality', 'wqt', '수질 관리', 6);

-- 2. 공통 코드 그룹 설정 [cite: 4]
INSERT INTO cmm.code_groups (group_code, group_name, description, is_system)
VALUES
('SYS_USE_YN', '사용 여부', '시스템 전반 활성화 상태 구분', true),
('FILE_CATEGORY', '파일 분류', '문서, 도면, 사진 등 파일 유형', true),
('EQP_STATUS', '설비 상태', '설비의 현재 가동 상태', false);

-- 3. 공통 코드 상세 및 가변 속성(JSONB) 설정 [cite: 6, 7]
INSERT INTO cmm.code_details (group_code, detail_code, detail_name, props, sort_order)
VALUES
-- 사용 여부
('SYS_USE_YN', 'Y', '사용', '{"color": "green"}', 1),
('SYS_USE_YN', 'N', '미사용', '{"color": "red"}', 2),

-- 파일 분류
('FILE_CATEGORY', 'DWG', 'CAD 도면', '{"icon": "FileDoneOutlined", "ext": "dwg"}', 1),
('FILE_CATEGORY', 'DOC', '일반 문서', '{"icon": "FileTextOutlined", "ext": "pdf,docx"}', 2),
('FILE_CATEGORY', 'IMG', '현장 사진', '{"icon": "PictureOutlined", "ext": "jpg,png"}', 3),

-- 설비 상태 (AntD Badge 연동용 props)
('EQP_STATUS', 'RUN', '가동 중', '{"status": "processing", "color": "#52c41a"}', 1),
('EQP_STATUS', 'STP', '정지', '{"status": "default", "color": "#bfbfbf"}', 2),
('EQP_STATUS', 'ERR', '장애', '{"status": "error", "color": "#f5222d"}', 3);

-- 4. 자동 채번 규칙 초기화 [cite: 12]
INSERT INTO cmm.sequence_rules (domain_code, prefix, current_year, current_seq)
VALUES
('FAC', 'FAC', '2026', 0),
('EQP', 'EQP', '2026', 0),
('WQT', 'WQT', '2026', 0);