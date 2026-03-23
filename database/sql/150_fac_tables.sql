-----------------------------------------------------------
-- [Phase 1] FAC Domain Tables
-- 표준 가이드: 기초 코드는 공통 코드(cmm.code_details)의 3자 코드를 참조합니다.
-----------------------------------------------------------

-- 1. 최상위 시설 (facilities)
CREATE TABLE fac.facilities (
    id                  BIGSERIAL PRIMARY KEY,
    
    -- [SFMS Standard] 복합 외래 키 참조를 위한 그룹 코드 고정 (Phase 2에서 FK 설정)
    category_group_code VARCHAR(30) DEFAULT 'FAC_CATEGORY' NOT NULL,
    category_code       VARCHAR(3) NOT NULL, 

    representative_image_id UUID,

    code                VARCHAR(50) NOT NULL UNIQUE,    -- 예: STP001
    name                VARCHAR(100) NOT NULL,
    address             VARCHAR(255),
    is_active           BOOLEAN DEFAULT true,
    sort_order          INT DEFAULT 0,
    metadata            JSONB NOT NULL DEFAULT '{}'::jsonb,
    legacy_id           INTEGER,
    
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT,

    CONSTRAINT chk_fac_category_group CHECK (category_group_code = 'FAC_CATEGORY'),
    CONSTRAINT chk_facility_code_upper CHECK (code = UPPER(code))
);

-- 2. 공간 계층 (Spaces)
CREATE TABLE fac.spaces (
    id                  BIGSERIAL PRIMARY KEY,
    facility_id         BIGINT NOT NULL,
    parent_id           BIGINT,
    representative_image_id UUID,

    -- [SFMS Standard] 공간 유형 및 기능 코드 참조
    space_type_group_code VARCHAR(30) DEFAULT 'SPACE_TYPE' NOT NULL,
    space_type_code       VARCHAR(3) NOT NULL,
    
    space_func_group_code VARCHAR(30) DEFAULT 'SPACE_FUNC' NOT NULL,
    space_func_code       VARCHAR(3) NOT NULL,
    
    code                VARCHAR(50) NOT NULL,           -- 예: BLD001
    name                VARCHAR(100) NOT NULL,
    area_size           NUMERIC(10, 2),
    is_active           BOOLEAN DEFAULT true,
    sort_order          INT DEFAULT 0,
    is_restricted       BOOLEAN DEFAULT false,
    org_id              BIGINT,
    metadata            JSONB NOT NULL DEFAULT '{}'::jsonb,
    legacy_id           INTEGER,
    legacy_source_tbl   VARCHAR(50),

    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT,

    CONSTRAINT chk_spc_type_group CHECK (space_type_group_code = 'SPACE_TYPE'),
    CONSTRAINT chk_spc_func_group CHECK (space_func_group_code = 'SPACE_FUNC'),
    CONSTRAINT uq_fac_spaces_code UNIQUE (facility_id, code),
    CONSTRAINT chk_spaces_code_upper CHECK (code = UPPER(code))
);

-- 3. 조회용 뷰 (Views)
CREATE OR REPLACE VIEW fac.v_facility_categories AS
SELECT detail_code AS code, detail_name AS name, props, sort_order
FROM cmm.code_details WHERE group_code = 'FAC_CATEGORY' AND is_active = true;

CREATE OR REPLACE VIEW fac.v_space_types AS
SELECT detail_code AS code, detail_name AS name, sort_order
FROM cmm.code_details WHERE group_code = 'SPACE_TYPE' AND is_active = true;

CREATE OR REPLACE VIEW fac.v_space_functions AS
SELECT detail_code AS code, detail_name AS name, sort_order
FROM cmm.code_details WHERE group_code = 'SPACE_FUNC' AND is_active = true;

-- Triggers
CREATE TRIGGER trg_updated_at_facilities BEFORE UPDATE ON fac.facilities FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();
CREATE TRIGGER trg_updated_at_spaces BEFORE UPDATE ON fac.spaces FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();
