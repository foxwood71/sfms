-----------------------------------------------------------
-- [Phase 1] SYS Domain Tables
-----------------------------------------------------------

-- 1. 시스템 도메인 (system_domains)
CREATE TABLE sys.system_domains (
    domain_code         VARCHAR(3) PRIMARY KEY,
    domain_name         VARCHAR(100) NOT NULL,
    description         TEXT,
    is_active           BOOLEAN DEFAULT true,
    sort_order          INT DEFAULT 0,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. 메뉴 마스터 (menus)
CREATE TABLE sys.menus (
    id                  BIGSERIAL PRIMARY KEY,
    parent_id           BIGINT,
    domain_code         VARCHAR(3),
    menu_code           VARCHAR(50) NOT NULL UNIQUE,
    menu_name           VARCHAR(100) NOT NULL,
    menu_type           VARCHAR(20) NOT NULL, -- DIR, PAG, BTN (System Constant)
    icon                VARCHAR(100),
    path                VARCHAR(255),
    component           VARCHAR(255),
    sort_order          INT DEFAULT 0,
    is_visible          BOOLEAN DEFAULT true,
    is_active           BOOLEAN DEFAULT true,
    props               JSONB DEFAULT '{}'::jsonb,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. 감사 로그 (audit_logs)
CREATE TABLE sys.audit_logs (
    id                  BIGSERIAL PRIMARY KEY,
    actor_user_id       BIGINT,               -- 백엔드 요구 규격
    action_type         VARCHAR(20) NOT NULL,
    target_domain       VARCHAR(50),          -- 백엔드 요구 규격
    target_table        VARCHAR(100),         -- 백엔드 요구 규격
    target_id           VARCHAR(100),
    snapshot            JSONB DEFAULT '{}'::jsonb, -- 백엔드 요구 규격
    description         TEXT,
    client_ip           VARCHAR(50),
    user_agent          TEXT,
    request_url         VARCHAR(255),
    old_data            JSONB,
    new_data            JSONB,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Triggers
CREATE TRIGGER trg_updated_at_system_domains BEFORE UPDATE ON sys.system_domains FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();
CREATE TRIGGER trg_updated_at_menus BEFORE UPDATE ON sys.menus FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();
