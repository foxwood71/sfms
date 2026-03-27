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

COMMENT ON TABLE fac.facilities IS '시스템 전체 시설 마스터 테이블 (최상위)';
COMMENT ON COLUMN fac.facilities.id IS '시설 고유 ID (PK)';
COMMENT ON COLUMN fac.facilities.category_group_code IS '시설 분류 그룹 코드 (cmm.code_groups)';
COMMENT ON COLUMN fac.facilities.category_code IS '시설 상세 분류 코드 (cmm.code_details)';
COMMENT ON COLUMN fac.facilities.representative_image_id IS '시설 대표 이미지 ID (cmm.attachments)';
COMMENT ON COLUMN fac.facilities.code IS '시설 식별 코드 (영문 대문자)';
COMMENT ON COLUMN fac.facilities.name IS '시설 명칭';
COMMENT ON COLUMN fac.facilities.address IS '시설 주소/위치';
COMMENT ON COLUMN fac.facilities.is_active IS '사용 여부';
COMMENT ON COLUMN fac.facilities.sort_order IS '정렬 순서';
COMMENT ON COLUMN fac.facilities.metadata IS '시설 추가 속성 정보 (JSONB)';
COMMENT ON COLUMN fac.facilities.legacy_id IS '레거시 매핑 ID';

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

COMMENT ON TABLE fac.spaces IS '시설 내 세부 공간(빌딩, 층, 실 등) 계층 관리 테이블';
COMMENT ON COLUMN fac.spaces.id IS '공간 고유 ID (PK)';
COMMENT ON COLUMN fac.spaces.facility_id IS '소속 시설 ID (fac.facilities.id)';
COMMENT ON COLUMN fac.spaces.parent_id IS '상위 공간 ID (Self-referencing)';
COMMENT ON COLUMN fac.spaces.representative_image_id IS '공간 대표 이미지 ID (cmm.attachments)';
COMMENT ON COLUMN fac.spaces.space_type_group_code IS '공간 유형 그룹 코드 (cmm.code_groups)';
COMMENT ON COLUMN fac.spaces.space_type_code IS '공간 유형 상세 코드 (cmm.code_details)';
COMMENT ON COLUMN fac.spaces.space_func_group_code IS '공간 기능 그룹 코드 (cmm.code_groups)';
COMMENT ON COLUMN fac.spaces.space_func_code IS '공간 기능 상세 코드 (cmm.code_details)';
COMMENT ON COLUMN fac.spaces.code IS '공간 식별 코드';
COMMENT ON COLUMN fac.spaces.name IS '공간 명칭';
COMMENT ON COLUMN fac.spaces.area_size IS '면적 (단위: m2)';
COMMENT ON COLUMN fac.spaces.is_active IS '사용 여부';
COMMENT ON COLUMN fac.spaces.sort_order IS '정렬 순서';
COMMENT ON COLUMN fac.spaces.is_restricted IS '출입/사용 제한 여부';
COMMENT ON COLUMN fac.spaces.org_id IS '관리 부서 ID (usr.organizations.id)';
COMMENT ON COLUMN fac.spaces.metadata IS '공간 추가 정보 (JSONB)';
COMMENT ON COLUMN fac.spaces.legacy_id IS '레거시 매핑 ID';
COMMENT ON COLUMN fac.spaces.legacy_source_tbl IS '레거시 데이터 출처 테이블';

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
