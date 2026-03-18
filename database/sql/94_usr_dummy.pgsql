-- database/sql/94_usr_dummy.pgsql
-- 부서 및 사용자 더미 데이터 (확장 버전)

-- 1. 조직(부서) 데이터 생성
-- ID 0: 시스템 관리가 이미 존재함
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
-- 모든 사용자 비밀번호는 'user1234' (해시: $2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W)
INSERT INTO usr.users (org_id, login_id, password_hash, emp_code, name, email, phone, is_active, account_status, created_by, updated_by)
VALUES
-- 경영지원본부 (ID 1)
(1, 'manager.kim', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'MGT001', '김경영', 'manager.kim@sfms.local', '010-1111-0001', true, 'ACTIVE', 0, 0),
(4, 'hr.lee', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'HR001', '이인사', 'hr.lee@sfms.local', '010-1111-0002', true, 'ACTIVE', 0, 0),
(4, 'hr.park', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'HR002', '박채용', 'hr.park@sfms.local', '010-1111-0003', true, 'ACTIVE', 0, 0),
(5, 'fin.choi', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'FIN001', '최재무', 'fin.choi@sfms.local', '010-1111-0004', true, 'ACTIVE', 0, 0),
(6, 'legal.jung', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'LEG001', '정법무', 'legal.jung@sfms.local', '010-1111-0005', true, 'ACTIVE', 0, 0),

-- IT본부 (ID 2)
(2, 'cto.park', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'IT001', '박기술', 'cto.park@sfms.local', '010-2222-0001', true, 'ACTIVE', 0, 0),
(7, 'dev1.lee', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'DEV101', '이개발', 'dev1.lee@sfms.local', '010-2222-0002', true, 'ACTIVE', 0, 0),
(7, 'dev1.kim', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'DEV102', '김코딩', 'dev1.kim@sfms.local', '010-2222-0003', true, 'ACTIVE', 0, 0),
(8, 'dev2.choi', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'DEV201', '최모바일', 'dev2.choi@sfms.local', '010-2222-0004', true, 'ACTIVE', 0, 0),
(8, 'dev2.jung', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'DEV202', '정앱', 'dev2.jung@sfms.local', '010-2222-0005', true, 'ACTIVE', 0, 0),
(9, 'design.han', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'DSN001', '한디자인', 'design.han@sfms.local', '010-2222-0006', true, 'ACTIVE', 0, 0),
(10, 'qa.kang', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'QA001', '강품질', 'qa.kang@sfms.local', '010-2222-0007', true, 'ACTIVE', 0, 0),

-- 영업본부 (ID 3)
(3, 'sales.head', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'SLS001', '오영업', 'sales.head@sfms.local', '010-3333-0001', true, 'ACTIVE', 0, 0),
(11, 'dom.kim', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'SLS101', '김국내', 'dom.kim@sfms.local', '010-3333-0002', true, 'ACTIVE', 0, 0),
(11, 'dom.lee', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'SLS102', '이시장', 'dom.lee@sfms.local', '010-3333-0003', true, 'ACTIVE', 0, 0),
(12, 'int.park', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'SLS201', '박해외', 'int.park@sfms.local', '010-3333-0004', true, 'ACTIVE', 0, 0),
(12, 'int.global', '$2b$12$mtOpkzDASNt5eeZgXXUahOeVyx5oEfLmw7ONfpok9w4kDfkrEpK3W', 'SLS202', '최글로벌', 'int.global@sfms.local', '010-3333-0005', true, 'ACTIVE', 0, 0);

-- 3. 사용자 역할(Role) 부여
-- Role 2: 일반 사용자 (USER)
-- 모든 비관리자 사용자에게 USER 역할 부여
INSERT INTO iam.user_roles (user_id, role_id, assigned_by)
SELECT id, 2, 0 FROM usr.users WHERE login_id != 'admin';
