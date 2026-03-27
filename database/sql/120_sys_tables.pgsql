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

COMMENT ON TABLE sys.system_domains IS '시스템 업무 도메인 정의 테이블';
COMMENT ON COLUMN sys.system_domains.domain_code IS '도메인 식별 코드 (예: SYS, USR, FAC)';
COMMENT ON COLUMN sys.system_domains.domain_name IS '도메인 명칭 (예: 시스템 관리)';
COMMENT ON COLUMN sys.system_domains.description IS '도메인 상세 설명';
COMMENT ON COLUMN sys.system_domains.is_active IS '사용 여부';
COMMENT ON COLUMN sys.system_domains.sort_order IS '표시 순서';

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

COMMENT ON TABLE sys.menus IS '시스템 메뉴 마스터 테이블';
COMMENT ON COLUMN sys.menus.id IS '메뉴 고유 ID (PK)';
COMMENT ON COLUMN sys.menus.parent_id IS '상위 메뉴 ID (Self-referencing)';
COMMENT ON COLUMN sys.menus.domain_code IS '소속 시스템 도메인 코드';
COMMENT ON COLUMN sys.menus.menu_code IS '메뉴 식별 코드';
COMMENT ON COLUMN sys.menus.menu_name IS '메뉴 명칭';
COMMENT ON COLUMN sys.menus.menu_type IS '메뉴 유형 (DIR: 폴더, PAG: 페이지, BTN: 버튼)';
COMMENT ON COLUMN sys.menus.icon IS '메뉴 표시 아이콘 (Lucide 또는 AntD 아이콘 명칭)';
COMMENT ON COLUMN sys.menus.path IS '프론트엔드 라우팅 경로';
COMMENT ON COLUMN sys.menus.component IS '연결될 프론트엔드 컴포넌트 경로';
COMMENT ON COLUMN sys.menus.sort_order IS '메뉴 정렬 순서';
COMMENT ON COLUMN sys.menus.is_visible IS '메뉴 노출 여부';
COMMENT ON COLUMN sys.menus.is_active IS '메뉴 활성화 여부';
COMMENT ON COLUMN sys.menus.props IS '메뉴별 부가 설정 정보 (JSONB)';

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

COMMENT ON TABLE sys.audit_logs IS '시스템 작업 감사 로그 테이블';
COMMENT ON COLUMN sys.audit_logs.id IS '로그 고유 ID (PK)';
COMMENT ON COLUMN sys.audit_logs.actor_user_id IS '작업을 수행한 사용자 ID';
COMMENT ON COLUMN sys.audit_logs.action_type IS '작업 유형 (CREATE, UPDATE, DELETE, LOGIN 등)';
COMMENT ON COLUMN sys.audit_logs.target_domain IS '영향을 받은 업무 도메인';
COMMENT ON COLUMN sys.audit_logs.target_table IS '변경된 데이터 테이블명';
COMMENT ON COLUMN sys.audit_logs.target_id IS '변경된 데이터의 PK값';
COMMENT ON COLUMN sys.audit_logs.snapshot IS '작업 시점의 데이터 스냅샷';
COMMENT ON COLUMN sys.audit_logs.description IS '작업 상세 설명';
COMMENT ON COLUMN sys.audit_logs.client_ip IS '접속자 IP 주소';
COMMENT ON COLUMN sys.audit_logs.user_agent IS '접속자 브라우저/기기 정보';
COMMENT ON COLUMN sys.audit_logs.request_url IS '요청된 API 경로';
COMMENT ON COLUMN sys.audit_logs.old_data IS '변경 전 데이터 (JSON)';
COMMENT ON COLUMN sys.audit_logs.new_data IS '변경 후 데이터 (JSON)';

-- Triggers
CREATE TRIGGER trg_updated_at_system_domains BEFORE UPDATE ON sys.system_domains FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();
CREATE TRIGGER trg_updated_at_menus BEFORE UPDATE ON sys.menus FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();
