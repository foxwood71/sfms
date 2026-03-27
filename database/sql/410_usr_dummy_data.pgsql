-----------------------------------------------------------
-- [Phase 4] USR Dummy Data (Phase 1 Test Data)
-- 표준 가이드: 직위/직책은 metadata 내에 3자 코드로 저장합니다.
-----------------------------------------------------------

-- 1. 조직(부서) 데이터 생성
INSERT INTO usr.organizations (name, code, parent_id, sort_order, description, is_active, created_by, updated_by)
VALUES
('경영지원본부', 'MGMT_HQ', 0, 10, '회사 경영 전반 지원', true, 0, 0), -- ID 1
('IT본부', 'IT_HQ', 0, 20, '정보 기술 및 시스템 관리', true, 0, 0), -- ID 2
('영업본부', 'SALES_HQ', 0, 30, '국내외 영업 및 마케팅', true, 0, 0), -- ID 3
('인사팀', 'HR_TEAM', 1, 10, '인사 및 노무 관리', true, 0, 0), -- ID 4
('재무팀', 'FIN_TEAM', 1, 20, '회계 및 자금 관리', true, 0, 0), -- ID 5
('법무팀', 'LEGAL_TEAM', 1, 30, '법률 검토 및 계약 관리', true, 0, 0), -- ID 6
('개발1팀', 'DEV_TEAM_1', 2, 10, '플랫폼 개발', true, 0, 0), -- ID 7
('개발2팀', 'DEV_TEAM_2', 2, 20, '모바일 및 서비스 개발', true, 0, 0), -- ID 8
('디자인팀', 'DESIGN_TEAM', 2, 30, 'UI/UX 디자인', true, 0, 0), -- ID 9
('QA팀', 'QA_TEAM', 2, 40, '품질 관리 및 테스트', true, 0, 0), -- ID 10
('국내영업팀', 'DOM_SALES', 3, 10, '국내 시장 영업', true, 0, 0), -- ID 11
('해외영업팀', 'INT_SALES', 3, 20, '글로벌 시장 개척', true, 0, 0); -- ID 12

-- 2. 사용자 데이터 생성
-- 비밀번호: user1234 ($2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W)
-- metadata 가이드: pos(직위코드), dut(직책코드)
INSERT INTO usr.users (org_id, login_id, password_hash, emp_code, name, email, phone, is_active, account_status, metadata, created_by, updated_by)
VALUES
-- 경영진 (본부장급)
(1, 'manager.kim', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'MGT001', '김경영', 'manager.kim@sfms.local', '010-1111-0001', true, 'ACTIVE', '{"pos": "DIR", "dut": "GLD"}', 0, 0),
(2, 'cto.park',    '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'IT001',  '박기술', 'cto.park@sfms.local',    '010-2222-0001', true, 'ACTIVE', '{"pos": "DIR", "dut": "GLD"}', 0, 0),
(3, 'sales.head', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'SLS001', '오영업', 'sales.head@sfms.local',   '010-3333-0001', true, 'ACTIVE', '{"pos": "DIR", "dut": "GLD"}', 0, 0),

-- 팀장급
(4, 'hr.lee',     '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'HR001',  '이인사', 'hr.lee@sfms.local',      '010-1111-0002', true, 'ACTIVE', '{"pos": "SNR", "dut": "TLD"}', 0, 0),
(7, 'dev1.lee',   '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'DEV101', '이개발', 'dev1.lee@sfms.local',    '010-2222-0002', true, 'ACTIVE', '{"pos": "MGR", "dut": "TLD"}', 0, 0),

-- 팀원급
(7, 'dev1.kim',   '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'DEV102', '김코딩', 'dev1.kim@sfms.local',    '010-2222-0003', true, 'ACTIVE', '{"pos": "STF", "dut": "MBR"}', 0, 0),
(10, 'qa.kang',   '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'QA001',  '강품질', 'qa.kang@sfms.local',     '010-2222-0007', true, 'ACTIVE', '{"pos": "AST", "dut": "MBR"}', 0, 0);

-- 3. 사용자 역할(Role) 부여
-- Role ID가 동적으로 할당될 수 있으므로 role_code로 찾아서 연결하는 것이 안전하지만, 
-- 초기 배포 시나리오(admin:1, user:2)를 가정하여 처리합니다.
INSERT INTO iam.user_roles (user_id, role_id)
SELECT id, 2 FROM usr.users WHERE login_id != 'admin'
ON CONFLICT DO NOTHING;
