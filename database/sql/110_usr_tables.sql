-----------------------------------------------------------
-- [Phase 1] USR Domain Tables
-----------------------------------------------------------

-- 1. 조직 (Organizations)
CREATE TABLE usr.organizations (
    id                  BIGSERIAL PRIMARY KEY,
    name                VARCHAR(100) NOT NULL,
    code                VARCHAR(50) NOT NULL UNIQUE,
    parent_id           BIGINT,
    sort_order          INT DEFAULT 0,
    description         TEXT,
    is_active           BOOLEAN DEFAULT true,
    legacy_id           INTEGER,
    legacy_source       VARCHAR(20),
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT,
    CONSTRAINT chk_organizations_code_upper CHECK (code = UPPER(code))
);

-- 2. 사용자 (Users)
CREATE TABLE usr.users (
    id                  BIGSERIAL PRIMARY KEY,
    org_id              BIGINT,
    profile_image_id    UUID,
    login_id            VARCHAR(50) NOT NULL UNIQUE,
    password_hash       VARCHAR(255) NOT NULL,
    emp_code            VARCHAR(16) NOT NULL UNIQUE,
    name                VARCHAR(100) NOT NULL,
    email               VARCHAR(100) NOT NULL UNIQUE,
    phone               VARCHAR(50),
    is_active           BOOLEAN DEFAULT TRUE,
    account_status      VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL,
    last_login_at       TIMESTAMPTZ,
    login_fail_count    INTEGER DEFAULT 0 NOT NULL,
    legacy_id           INTEGER,
    legacy_source       VARCHAR(20),
    metadata            JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT,
    CONSTRAINT chk_users_login_id_lower CHECK (login_id = LOWER(login_id)),
    CONSTRAINT chk_users_email_lower CHECK (email = LOWER(email))
);

-- Indices
CREATE INDEX idx_usr_org_parent ON usr.organizations (parent_id);
CREATE INDEX idx_usr_users_org_id ON usr.users (org_id);

-- Triggers
CREATE TRIGGER trg_updated_at_organizations BEFORE UPDATE ON usr.organizations FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();
CREATE TRIGGER trg_updated_at_users BEFORE UPDATE ON usr.users FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();
