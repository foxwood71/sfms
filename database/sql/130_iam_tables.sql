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

-- 2. 사용자-역할 매핑 (user_roles)
CREATE TABLE iam.user_roles (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT NOT NULL,
    role_id             BIGINT NOT NULL,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    CONSTRAINT uq_user_role UNIQUE (user_id, role_id)
);

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

-- 4. 역할-권한 매핑 (role_permissions)
CREATE TABLE iam.role_permissions (
    id                  BIGSERIAL PRIMARY KEY,
    role_id             BIGINT NOT NULL,
    permission_id       BIGINT NOT NULL,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    CONSTRAINT uq_role_permission UNIQUE (role_id, permission_id)
);

-- Triggers
CREATE TRIGGER trg_updated_at_roles BEFORE UPDATE ON iam.roles FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();
