-- =========================================================
-- Schema: loc (Location Management)
-- UI 요구사항(types.ts)과 100% 동기화된 전체 스키마 소스
-- =========================================================

DROP SCHEMA IF EXISTS loc CASCADE;
CREATE SCHEMA loc;

-- 권한 설정 (필요시)
-- GRANT ALL ON SCHEMA loc TO wims;

-- ---------------------------------------------------------
-- 1. 기초 코드 테이블 (Code Tables)
-- ---------------------------------------------------------

-- 1-1. 시설 카테고리 (UI: FacilityCategoryDialog 대응)
CREATE TABLE loc.facility_categories (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE, -- 예: STP, WTP, PS
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 1-2. 공간 유형 (UI: TypeManagerDialog 대응)
CREATE TABLE loc.space_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE, -- 예: BLD, FLR, ROOM
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 1-3. 공간 기능 (UI: FunctionManagerDialog 대응)
CREATE TABLE loc.space_functions (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE, -- 예: ELEC, MECH, CHEM
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),             -- 대분류 (UI 필터링용)
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- ---------------------------------------------------------
-- 2. 핵심 엔티티 테이블 (Main Tables)
-- ---------------------------------------------------------

-- 2-1. 시설 (Facilities) - 최상위 위치 단위
CREATE TABLE loc.facilities (
    id SERIAL PRIMARY KEY,
    category_id INT REFERENCES loc.facility_categories(id), -- 카테고리 FK
    
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    
    address VARCHAR(255),
    
    is_active BOOLEAN DEFAULT true,
    
    description TEXT,
    sort_order INT DEFAULT 0,


    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2-2. 공간 (Spaces) - 시설 하위의 계층적 공간
CREATE TABLE loc.spaces (
    id SERIAL PRIMARY KEY,
    facility_id INT NOT NULL REFERENCES loc.facilities(id) ON DELETE CASCADE, -- 소속 시설
    parent_id INT REFERENCES loc.spaces(id) ON DELETE CASCADE,                -- 상위 공간 (계층 구조)
    
    space_type_id INT REFERENCES loc.space_types(id),         -- 공간 유형 FK
    space_function_id INT REFERENCES loc.space_functions(id), -- 공간 기능 FK
    
    code VARCHAR(50) NOT NULL, -- 시설 내에서 유니크해야 하므로 복합 Unique 추천
    name VARCHAR(100) NOT NULL,
    
    area_size NUMERIC(10, 2),        -- 면적 (m²)
    is_restricted BOOLEAN DEFAULT false, -- 통제 구역 여부
    is_active BOOLEAN DEFAULT true,

    description TEXT,
    sort_order INT DEFAULT 0,

    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- [제약조건] 같은 시설 내에서 코드는 중복될 수 없음 (선택 사항)
    CONSTRAINT uq_space_code_per_facility UNIQUE (facility_id, code)
);


-- ---------------------------------------------------------
-- 3. 인덱스 및 트리거 (Optional)
-- ---------------------------------------------------------

-- 검색 성능 향상을 위한 인덱스
CREATE INDEX idx_spaces_facility_id ON loc.spaces(facility_id);
CREATE INDEX idx_spaces_parent_id ON loc.spaces(parent_id);

-- updated_at 자동 갱신 트리거 함수 (공통 사용)
CREATE OR REPLACE FUNCTION loc.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 적용
CREATE TRIGGER trg_facility_categories_updated BEFORE UPDATE ON loc.facility_categories FOR EACH ROW EXECUTE FUNCTION loc.update_timestamp();
CREATE TRIGGER trg_space_types_updated BEFORE UPDATE ON loc.space_types FOR EACH ROW EXECUTE FUNCTION loc.update_timestamp();
CREATE TRIGGER trg_space_functions_updated BEFORE UPDATE ON loc.space_functions FOR EACH ROW EXECUTE FUNCTION loc.update_timestamp();
CREATE TRIGGER trg_facilities_updated BEFORE UPDATE ON loc.facilities FOR EACH ROW EXECUTE FUNCTION loc.update_timestamp();
CREATE TRIGGER trg_spaces_updated BEFORE UPDATE ON loc.spaces FOR EACH ROW EXECUTE FUNCTION loc.update_timestamp();


-- ---------------------------------------------------------
-- 4. 기초 데이터 (Optional - 초기 세팅용)
-- ---------------------------------------------------------

-- 필수 공간 유형
INSERT INTO loc.space_types (code, name, description) VALUES
('BLD', '건물', 'Building'),
('FLR', '층', 'Floor'),
('ROOM', '실', 'Room'),
('ZONE', '구역', 'Zone');

-- 필수 시설 카테고리
INSERT INTO loc.facility_categories (code, name, description) VALUES
('STP', '하수처리장', 'Sewage Treatment Plant'),
('WTP', '정수장', 'Water Treatment Plant'),
('PS', '펌프장', 'Pumping Station');