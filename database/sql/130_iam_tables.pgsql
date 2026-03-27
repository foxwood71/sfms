-----------------------------------------------------------
-- [Phase 1] IAM Domain Tables
-----------------------------------------------------------

-- 1. 역할 (roles)
CREATE TABLE iam.roles (
    id                  BIGSERIAL PRIMARY KEY,
    code                VARCHAR(50) NOT NULL UNIQUE,    -- role_code에서 code로 변경
    name                VARCHAR(100) NOT NULL,          -- role_name에서 name으로 변경 (백엔드 로그 기준)
    description         TEXT,
    permissions         JSONB DEFAULT '{}'::jsonb,    -- []에서 {}로 변경
    is_active           BOOLEAN DEFAULT true,
    is_system           BOOLEAN DEFAULT false,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT
);

COMMENT ON TABLE iam.roles IS '사용자 권한 그룹(역할) 정의 테이블';
COMMENT ON COLUMN iam.roles.id IS '역할 고유 ID (PK)';
COMMENT ON COLUMN iam.roles.code IS '역할 식별 코드 (예: SYS_ADMIN, FAC_MANAGER)';
COMMENT ON COLUMN iam.roles.name IS '역할 명칭 (예: 시스템 관리자)';
COMMENT ON COLUMN iam.roles.description IS '역할 상세 설명';
COMMENT ON COLUMN iam.roles.permissions IS '역할에 부여된 권한 셋 (JSONB, 예: {"ALL": ["*"]})';
COMMENT ON COLUMN iam.roles.is_active IS '사용 여부';
COMMENT ON COLUMN iam.roles.is_system IS '시스템 필수 역할 여부 (True: 삭제/수정 제한)';
COMMENT ON COLUMN iam.roles.created_at IS '생성 일시';
COMMENT ON COLUMN iam.roles.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN iam.roles.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN iam.roles.updated_by IS '최종 수정자 사용자 ID';

-- 2. 사용자-역할 매핑 (user_roles)
CREATE TABLE iam.user_roles (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT NOT NULL,
    role_id             BIGINT NOT NULL,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    CONSTRAINT uq_user_role UNIQUE (user_id, role_id)
);

COMMENT ON TABLE iam.user_roles IS '사용자별 역할 할당 매핑 테이블';
COMMENT ON COLUMN iam.user_roles.id IS '매핑 고유 ID (PK)';
COMMENT ON COLUMN iam.user_roles.user_id IS '대상 사용자 ID (usr.users.id)';
COMMENT ON COLUMN iam.user_roles.role_id IS '할당된 역할 ID (iam.roles.id)';

-- 3. 권한 항목 (permissions) - 세부 기능별 권한
CREATE TABLE iam.permissions (
    id                  BIGSERIAL PRIMARY KEY,
    domain_code         VARCHAR(3),
    resource            VARCHAR(100) NOT NULL,
    action              VARCHAR(50) NOT NULL,
    perm_code           VARCHAR(150) GENERATED ALWAYS AS (domain_code || ':' || resource || ':' || action) STORED UNIQUE,
    description         TEXT,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE iam.permissions IS '시스템 세부 기능별 권한 정의 테이블';
COMMENT ON COLUMN iam.permissions.id IS '권한 고유 ID (PK)';
COMMENT ON COLUMN iam.permissions.domain_code IS '소속 업무 도메인';
COMMENT ON COLUMN iam.permissions.resource IS '보호 자원 명칭 (테이블명 또는 기능명)';
COMMENT ON COLUMN iam.permissions.action IS '수행 가능 작업 (READ, WRITE, DELETE 등)';
COMMENT ON COLUMN iam.permissions.perm_code IS '권한 식별 코드 (자동 생성, 예: FAC:FACILITIES:READ)';
COMMENT ON COLUMN iam.permissions.description IS '권한 상세 설명';

-- 4. 역할-권한 매핑 (role_permissions)
CREATE TABLE iam.role_permissions (
    id                  BIGSERIAL PRIMARY KEY,
    role_id             BIGINT NOT NULL,
    permission_id       BIGINT NOT NULL,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    CONSTRAINT uq_role_permission UNIQUE (role_id, permission_id)
);

COMMENT ON TABLE iam.role_permissions IS '역할별 세부 권한 할당 매핑 테이블';
COMMENT ON COLUMN iam.role_permissions.id IS '매핑 고유 ID (PK)';
COMMENT ON COLUMN iam.role_permissions.role_id IS '대상 역할 ID (iam.roles.id)';
COMMENT ON COLUMN iam.role_permissions.permission_id IS '할당된 세부 권한 ID (iam.permissions.id)';

-- Triggers
CREATE TRIGGER trg_updated_at_roles BEFORE UPDATE ON iam.roles FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();
