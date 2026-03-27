-----------------------------------------------------------
-- [Phase 0] System Bootstrapping
-- 핵심 목적: 순환 참조 해결을 위한 기초 데이터(Admin, Root Org, Roles) 선적재
-----------------------------------------------------------

-- 1. 최상위 시스템 조직 (ID: 0)
INSERT INTO usr.organizations (
    id, name, code, sort_order, description, is_active
) VALUES (
    0, '시스템 관리', 'SYSTEM', -1, '시스템 자동 생성 및 관리를 위한 가상 최상위 조직', true
) ON CONFLICT (id) DO NOTHING;

-- 2. 시스템 슈퍼 관리자 (ID: 0)
-- 비밀번호: admin1234
INSERT INTO usr.users (
    id, org_id, login_id, password_hash, emp_code, name,
    email, is_active, account_status, metadata
) VALUES (
    0, 0, 'admin', '$2b$12$bEs8G.YGwEAd9HVoNhBFFeBnF/mBD3y0wC9SSvg5mcwvReRuKKxVi', '0000', '시스템관리자',
    'admin@sfms.local', true, 'ACTIVE', '{"role": "SUPER_USER"}'
) ON CONFLICT (id) DO NOTHING;

-- 3. 핵심 시스템 역할 (Roles)
-- permissions 형식을 백엔드 is_superuser 프로퍼티 규격인 {"ALL": ["*"]} 로 수정
INSERT INTO iam.roles (
    id, code, name, description, is_system, permissions
) VALUES 
(1, 'SUPER_USER', '슈퍼 관리자', '시스템 전체 제어 권한', true, '{"ALL": ["*"]}'),
(2, 'USER', '일반 사용자', '표준 업무 권한', true, '{}')
ON CONFLICT (id) DO NOTHING;

-- 4. 관리자-역할 매핑
INSERT INTO iam.user_roles (user_id, role_id)
VALUES (0, 1)
ON CONFLICT DO NOTHING;

-- 시퀀스 초기화
SELECT setval('usr.organizations_id_seq', 1, false);
SELECT setval('usr.users_id_seq', 1, false);
SELECT setval('iam.roles_id_seq', 3, false);
