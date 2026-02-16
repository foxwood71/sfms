-- =========================================================
-- Schema: facility (V20. Grand Master)
-- 작성일: 2026-02-12
-- 
-- [주요 반영 사항]
-- 1. 구조적 완성도: Sites, Spaces 모두 'code' 컬럼 사용 & 자동생성 트리거 적용
-- 2. 갤러리 모델: 대표 사진(Thumbnail)을 Attachment ID로 참조 (순환참조 해결 로직 포함)
-- 3. 유연한 점검(Inspection): 공간(Space)뿐만 아니라 사이트(Site) 단위 점검 지원 (Nullable & Constraint)
-- 4. 다양한 공간 유형 지원: 지하구(INF), 수직구(SHA) 등 논의된 시나리오 반영
-- 5. 문서화: 모든 테이블 및 컬럼에 상세 주석(COMMENT) 100% 작성
-- =========================================================

DROP SCHEMA IF EXISTS facility CASCADE;
CREATE SCHEMA facility;

-- =========================================================
-- 1. 기초 코드 (Codes & Types)
-- =========================================================

-- 1-1. 사이트 카테고리
CREATE TABLE facility.site_categories (
    id SERIAL PRIMARY KEY,
    code VARCHAR(4) NOT NULL UNIQUE, 
    name VARCHAR(100) NOT NULL,
    icon_name VARCHAR(50) DEFAULT 'building',
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE facility.site_categories IS '사이트 유형 (공원, 체육, 문화, 자원 등)';
COMMENT ON COLUMN facility.site_categories.id IS '고유 ID (PK)';
COMMENT ON COLUMN facility.site_categories.code IS '식별 코드 (4자리, 자동생성 접두어, 예: PARK)';
COMMENT ON COLUMN facility.site_categories.name IS '카테고리 명칭';
COMMENT ON COLUMN facility.site_categories.icon_name IS 'UI 아이콘 명칭 (Lucide/Material)';
COMMENT ON COLUMN facility.site_categories.description IS '상세 설명';
COMMENT ON COLUMN facility.site_categories.is_active IS '사용 여부';
COMMENT ON COLUMN facility.site_categories.created_at IS '생성 일시';

-- 1-2. 공간 유형 (논의된 인프라, 샤프트 등 추가됨)
CREATE TABLE facility.space_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(3) NOT NULL UNIQUE, 
    name VARCHAR(100) NOT NULL,
    icon_name VARCHAR(50) DEFAULT 'folder',
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE facility.space_types IS '공간 계층 유형 (건물, 층, 공간, 인프라 등)';
COMMENT ON COLUMN facility.space_types.id IS '고유 ID (PK)';
COMMENT ON COLUMN facility.space_types.code IS '유형 코드 (3자리, 자동생성 접두어, 예: BLD, INF)';
COMMENT ON COLUMN facility.space_types.name IS '유형 명칭';
COMMENT ON COLUMN facility.space_types.icon_name IS 'UI 아이콘 명칭';
COMMENT ON COLUMN facility.space_types.description IS '상세 설명';
COMMENT ON COLUMN facility.space_types.is_active IS '사용 여부';
COMMENT ON COLUMN facility.space_types.created_at IS '생성 일시';

-- 1-3. 공간 기능
CREATE TABLE facility.space_functions (
    id SERIAL PRIMARY KEY,
    code VARCHAR(4) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    color_code VARCHAR(20),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE facility.space_functions IS '공간의 용도 (사무실, 기계실, 공용부 등)';
COMMENT ON COLUMN facility.space_functions.id IS '고유 ID (PK)';
COMMENT ON COLUMN facility.space_functions.code IS '기능 코드 (4자리, 예: WORK)';
COMMENT ON COLUMN facility.space_functions.name IS '기능 명칭';
COMMENT ON COLUMN facility.space_functions.color_code IS 'UI 표시용 색상 코드 (Hex)';
COMMENT ON COLUMN facility.space_functions.description IS '상세 설명';
COMMENT ON COLUMN facility.space_functions.created_at IS '생성 일시';

-- 1-4. 유지보수 작업 유형
CREATE TABLE facility.maintenance_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(6) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    is_warranty_required BOOLEAN DEFAULT false,
    is_outsourcing BOOLEAN DEFAULT false,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE facility.maintenance_types IS '작업 유형 (자체수선, 외주공사, 정기점검 등)';
COMMENT ON COLUMN facility.maintenance_types.id IS '고유 ID (PK)';
COMMENT ON COLUMN facility.maintenance_types.code IS '작업 유형 코드 (6자리, 예: REPAIR)';
COMMENT ON COLUMN facility.maintenance_types.name IS '작업 유형 명칭';
COMMENT ON COLUMN facility.maintenance_types.is_warranty_required IS '하자보증 기간 입력 필수 여부';
COMMENT ON COLUMN facility.maintenance_types.is_outsourcing IS '외부 업체 정보 입력 필수 여부';
COMMENT ON COLUMN facility.maintenance_types.description IS '상세 설명';
COMMENT ON COLUMN facility.maintenance_types.is_active IS '사용 여부';
COMMENT ON COLUMN facility.maintenance_types.created_at IS '생성 일시';


-- =========================================================
-- 2. 첨부파일 (Attachments) - 선언부
-- [중요] FK 설정은 테이블 생성 후 맨 아래에서 수행 (순환 참조 방지)
-- =========================================================
CREATE TABLE facility.attachments (
    id SERIAL PRIMARY KEY,
    
    -- 역참조 ID (나중에 ALTER로 FK 연결)
    site_id INT,
    space_id INT,
    history_id INT,
    inspection_id INT,
    
    file_type VARCHAR(50) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    file_size INT,
    mime_type VARCHAR(100),
    description TEXT,
    uploader_name VARCHAR(50),
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE facility.attachments IS '도면, 매뉴얼, 사진 통합 관리 (물리적 파일은 S3/MinIO 저장)';
COMMENT ON COLUMN facility.attachments.id IS '파일 고유 ID (PK)';
COMMENT ON COLUMN facility.attachments.site_id IS '연관 사이트 ID (FK 예정)';
COMMENT ON COLUMN facility.attachments.space_id IS '연관 공간 ID (FK 예정)';
COMMENT ON COLUMN facility.attachments.history_id IS '연관 이력 ID (FK 예정)';
COMMENT ON COLUMN facility.attachments.inspection_id IS '연관 검사 ID (FK 예정)';
COMMENT ON COLUMN facility.attachments.file_type IS '파일 유형 (BLUEPRINT, PHOTO, MANUAL, REPORT)';
COMMENT ON COLUMN facility.attachments.file_name IS '원본 파일명';
COMMENT ON COLUMN facility.attachments.file_url IS '파일 저장 경로 (Storage URL)';
COMMENT ON COLUMN facility.attachments.file_size IS '파일 크기 (Byte)';
COMMENT ON COLUMN facility.attachments.mime_type IS 'MIME 타입 (image/jpeg, application/pdf 등)';
COMMENT ON COLUMN facility.attachments.description IS '파일 설명';
COMMENT ON COLUMN facility.attachments.uploader_name IS '업로더명';
COMMENT ON COLUMN facility.attachments.created_at IS '업로드 일시';


-- =========================================================
-- 3. 핵심 엔티티 (Sites & Spaces)
-- =========================================================

-- 3-1. 사이트 (Sites)
CREATE TABLE facility.sites (
    id SERIAL PRIMARY KEY,
    category_id INT REFERENCES facility.site_categories(id),
    
    code VARCHAR(20) NOT NULL UNIQUE, -- 자동생성 (PARK-2026-001)
    name VARCHAR(100) NOT NULL,
    
    -- [대표 사진] Attachments 테이블 참조 (FK)
    representative_image_id UUID REFERENCES cmm.attachments(id) ON DELETE SET NULL,
    
    address VARCHAR(255),
    manager_name VARCHAR(50),
    contact_phone VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    description TEXT,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE facility.sites IS '관리 최상위 단위 (사업장/단지)';
COMMENT ON COLUMN facility.sites.id IS '사이트 고유 ID (PK)';
COMMENT ON COLUMN facility.sites.category_id IS '사이트 유형 참조 (FK)';
COMMENT ON COLUMN facility.sites.code IS '사이트 식별 코드 (자동생성: Category-연도-순번)';
COMMENT ON COLUMN facility.sites.name IS '사업장 명칭';
COMMENT ON COLUMN facility.sites.representative_attachment_id IS '대표 사진 첨부파일 ID (FK, 썸네일용)';
COMMENT ON COLUMN facility.sites.address IS '주소';
COMMENT ON COLUMN facility.sites.manager_name IS '관리 책임자';
COMMENT ON COLUMN facility.sites.contact_phone IS '연락처';
COMMENT ON COLUMN facility.sites.is_active IS '운영 여부 (False: 폐쇄)';
COMMENT ON COLUMN facility.sites.description IS '설명';
COMMENT ON COLUMN facility.sites.sort_order IS '정렬 순서';
COMMENT ON COLUMN facility.sites.created_at IS '생성 일시';
COMMENT ON COLUMN facility.sites.updated_at IS '수정 일시';

-- 3-2. 공간 (Spaces)
CREATE TABLE facility.spaces (
    id SERIAL PRIMARY KEY,
    site_id INT NOT NULL REFERENCES facility.sites(id) ON DELETE CASCADE,
    
    -- [계층 구조] parent_id가 NULL이면 Site 직속, 있으면 계층 구조
    parent_id INT REFERENCES facility.spaces(id) ON DELETE CASCADE,
    
    space_type_id INT NOT NULL REFERENCES facility.space_types(id),
    space_function_id INT REFERENCES facility.space_functions(id),
    
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) UNIQUE, -- 자동생성 (SPC-2026-001)
    
    -- [대표 사진] Attachments 테이블 참조 (FK)
    representative_image_id UUID REFERENCES cmm.attachments(id) ON DELETE SET NULL
    
    area_size NUMERIC(10, 2),
    completion_date DATE, 
    
    -- [선형 자산 관리] 이전 구간과 이후 구간 연결
    predecessor_id INT REFERENCES facility.spaces(id),
    successor_id INT REFERENCES facility.spaces(id),
    installer_partner_id INT,
    
    is_maintainable BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    description TEXT,
    sort_order INT DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE facility.spaces IS '공간 트리 구조 (건물, 층, 호실, 설비공간 등)';
COMMENT ON COLUMN facility.spaces.id IS '공간 고유 ID (PK)';
COMMENT ON COLUMN facility.spaces.site_id IS '소속 사이트 ID (FK)';
COMMENT ON COLUMN facility.spaces.parent_id IS '상위 공간 ID (FK, Self)';
COMMENT ON COLUMN facility.spaces.space_type_id IS '공간 유형 ID (FK)';
COMMENT ON COLUMN facility.spaces.space_function_id IS '공간 기능 ID (FK)';
COMMENT ON COLUMN facility.spaces.name IS '공간 명칭';
COMMENT ON COLUMN facility.spaces.code IS '공간 관리 번호 (자동생성: Type-연도-순번)';
COMMENT ON COLUMN facility.spaces.representative_attachment_id IS '대표 사진 첨부파일 ID (FK, 썸네일용)';
COMMENT ON COLUMN facility.spaces.area_size IS '면적 (m²)';
COMMENT ON COLUMN facility.spaces.completion_date IS '준공일 또는 설치일 (선형자산 관리용)';
COMMENT ON COLUMN facility.spaces.predecessor_id IS '이전 구간 ID (선형자산 연결용)';
COMMENT ON COLUMN facility.spaces.successor_id IS '이후 구간 ID (선형자산 연결용)';
COMMENT ON COLUMN facility.spaces.installer_partner_id IS '[예약] 시공사 ID (Partner DB 연동)';
COMMENT ON COLUMN facility.spaces.is_maintainable IS '이력 관리 대상 여부';
COMMENT ON COLUMN facility.spaces.is_active IS '사용 여부';
COMMENT ON COLUMN facility.spaces.description IS '설명';
COMMENT ON COLUMN facility.spaces.sort_order IS '트리 정렬 순서';
COMMENT ON COLUMN facility.spaces.created_at IS '생성 일시';
COMMENT ON COLUMN facility.spaces.updated_at IS '수정 일시';


-- =========================================================
-- 4. 이력 및 검사 (History & Inspection)
-- =========================================================

-- 4-1. 유지보수 이력
CREATE TABLE facility.maintenance_history (
    id SERIAL PRIMARY KEY,
    space_id INT NOT NULL REFERENCES facility.spaces(id) ON DELETE CASCADE,
    maintenance_type_id INT NOT NULL REFERENCES facility.maintenance_types(id),
    
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'COMPLETED',
    
    company_name VARCHAR(100),
    company_contact VARCHAR(50),
    worker_name VARCHAR(50),
    performer_partner_id INT,
    
    cost NUMERIC(15, 0) DEFAULT 0,
    work_start_date DATE DEFAULT CURRENT_DATE,
    work_end_date DATE DEFAULT CURRENT_DATE,
    
    warranty_start_date DATE,
    warranty_end_date DATE,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE facility.maintenance_history IS '유지보수 및 공사 이력';
COMMENT ON COLUMN facility.maintenance_history.id IS '이력 고유 ID (PK)';
COMMENT ON COLUMN facility.maintenance_history.space_id IS '대상 공간 ID (FK)';
COMMENT ON COLUMN facility.maintenance_history.maintenance_type_id IS '작업 유형 ID (FK)';
COMMENT ON COLUMN facility.maintenance_history.title IS '작업 제목';
COMMENT ON COLUMN facility.maintenance_history.description IS '작업 상세 내용';
COMMENT ON COLUMN facility.maintenance_history.status IS '진행 상태 (SCHEDULED, PROGRESS, COMPLETED)';
COMMENT ON COLUMN facility.maintenance_history.company_name IS '시공/수리 업체명';
COMMENT ON COLUMN facility.maintenance_history.company_contact IS '업체 연락처';
COMMENT ON COLUMN facility.maintenance_history.worker_name IS '작업자명';
COMMENT ON COLUMN facility.maintenance_history.performer_partner_id IS '[예약] 수행 업체 ID (Partner DB 연동)';
COMMENT ON COLUMN facility.maintenance_history.cost IS '소요 비용';
COMMENT ON COLUMN facility.maintenance_history.work_start_date IS '작업 시작일';
COMMENT ON COLUMN facility.maintenance_history.work_end_date IS '작업 종료일';
COMMENT ON COLUMN facility.maintenance_history.warranty_start_date IS '하자 보증 시작일';
COMMENT ON COLUMN facility.maintenance_history.warranty_end_date IS '하자 보증 만료일';
COMMENT ON COLUMN facility.maintenance_history.created_at IS '생성 일시';
COMMENT ON COLUMN facility.maintenance_history.updated_at IS '수정 일시';

-- 4-2. 법정 검사 (V20 핵심 변경: Site/Space 겸용)
CREATE TABLE facility.inspections (
    id SERIAL PRIMARY KEY,
    
    -- [V20 수정] 사이트 전체 점검(소방훈련 등)과 공간 점검(승강기 점검)을 모두 수용
    site_id INT REFERENCES facility.sites(id) ON DELETE CASCADE,
    space_id INT REFERENCES facility.spaces(id) ON DELETE CASCADE,
    
    title VARCHAR(200) NOT NULL,
    legal_basis VARCHAR(100),
    
    inspection_date DATE NOT NULL,
    inspector_name VARCHAR(100),
    inspector_partner_id INT,
    
    result_grade VARCHAR(10),
    result_summary TEXT,
    is_passed BOOLEAN DEFAULT true,
    
    next_inspection_date DATE,
    related_history_id INT REFERENCES facility.maintenance_history(id),
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- [무결성 제약] site_id나 space_id 중 하나는 반드시 있어야 함
    CONSTRAINT chk_inspection_target CHECK (site_id IS NOT NULL OR space_id IS NOT NULL)
);
COMMENT ON TABLE facility.inspections IS '법정 의무 검사 및 안전진단 (사이트/공간 겸용)';
COMMENT ON COLUMN facility.inspections.id IS '검사 고유 ID (PK)';
COMMENT ON COLUMN facility.inspections.site_id IS '대상 사이트 ID (전체 점검 시 사용)';
COMMENT ON COLUMN facility.inspections.space_id IS '대상 공간 ID (개별 시설 점검 시 사용)';
COMMENT ON COLUMN facility.inspections.title IS '검사명';
COMMENT ON COLUMN facility.inspections.legal_basis IS '관련 법령';
COMMENT ON COLUMN facility.inspections.inspection_date IS '검사 수행일';
COMMENT ON COLUMN facility.inspections.inspector_name IS '검사 기관명';
COMMENT ON COLUMN facility.inspections.inspector_partner_id IS '[예약] 검사 기관 ID (Partner DB 연동)';
COMMENT ON COLUMN facility.inspections.result_grade IS '검사 결과 등급 (A~E)';
COMMENT ON COLUMN facility.inspections.result_summary IS '결과 요약';
COMMENT ON COLUMN facility.inspections.is_passed IS '합격 여부';
COMMENT ON COLUMN facility.inspections.next_inspection_date IS '차기 검사 예정일';
COMMENT ON COLUMN facility.inspections.related_history_id IS '조치 이력 ID (FK)';
COMMENT ON COLUMN facility.inspections.created_at IS '생성 일시';
COMMENT ON COLUMN facility.inspections.updated_at IS '수정 일시';


-- =========================================================
-- 5. [핵심] 첨부파일 FK 연결 (순환 참조 해결)
-- =========================================================
ALTER TABLE facility.attachments ADD CONSTRAINT fk_attachments_site FOREIGN KEY (site_id) REFERENCES facility.sites(id) ON DELETE CASCADE;
ALTER TABLE facility.attachments ADD CONSTRAINT fk_attachments_space FOREIGN KEY (space_id) REFERENCES facility.spaces(id) ON DELETE CASCADE;
ALTER TABLE facility.attachments ADD CONSTRAINT fk_attachments_history FOREIGN KEY (history_id) REFERENCES facility.maintenance_history(id) ON DELETE CASCADE;
ALTER TABLE facility.attachments ADD CONSTRAINT fk_attachments_inspection FOREIGN KEY (inspection_id) REFERENCES facility.inspections(id) ON DELETE CASCADE;


-- =========================================================
-- 6. 함수 및 트리거 (Business Logic)
-- =========================================================

-- 6-1. Timestamp 자동 갱신
CREATE OR REPLACE FUNCTION facility.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6-2. 사이트 코드 자동 생성 함수 (예: PARK-2026-001)
CREATE OR REPLACE FUNCTION facility.generate_site_code()
RETURNS TRIGGER AS $$
DECLARE
    v_prefix VARCHAR(10);
    v_seq INT;
    v_year VARCHAR(4);
BEGIN
    IF NEW.code IS NOT NULL THEN RETURN NEW; END IF;

    SELECT code INTO v_prefix FROM facility.site_categories WHERE id = NEW.category_id;
    v_year := TO_CHAR(CURRENT_DATE, 'YYYY');

    SELECT COUNT(*) + 1 INTO v_seq
    FROM facility.sites s
    JOIN facility.site_categories c ON s.category_id = c.id
    WHERE c.code = v_prefix AND TO_CHAR(s.created_at, 'YYYY') = v_year;

    NEW.code := v_prefix || '-' || v_year || '-' || LPAD(v_seq::TEXT, 3, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6-3. 공간 코드 자동 생성 함수 (예: INF-2026-001)
CREATE OR REPLACE FUNCTION facility.generate_space_code()
RETURNS TRIGGER AS $$
DECLARE
    v_prefix VARCHAR(10);
    v_seq INT;
    v_year VARCHAR(4);
BEGIN
    IF NEW.code IS NOT NULL THEN RETURN NEW; END IF;

    SELECT code INTO v_prefix FROM facility.space_types WHERE id = NEW.space_type_id;
    v_year := TO_CHAR(CURRENT_DATE, 'YYYY');

    SELECT COUNT(*) + 1 INTO v_seq
    FROM facility.spaces s
    JOIN facility.space_types t ON s.space_type_id = t.id
    WHERE t.code = v_prefix AND TO_CHAR(s.created_at, 'YYYY') = v_year;

    NEW.code := v_prefix || '-' || v_year || '-' || LPAD(v_seq::TEXT, 3, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 연결
CREATE TRIGGER trg_sites_update BEFORE UPDATE ON facility.sites FOR EACH ROW EXECUTE FUNCTION facility.update_timestamp();
CREATE TRIGGER trg_spaces_update BEFORE UPDATE ON facility.spaces FOR EACH ROW EXECUTE FUNCTION facility.update_timestamp();
CREATE TRIGGER trg_history_update BEFORE UPDATE ON facility.maintenance_history FOR EACH ROW EXECUTE FUNCTION facility.update_timestamp();
CREATE TRIGGER trg_inspect_update BEFORE UPDATE ON facility.inspections FOR EACH ROW EXECUTE FUNCTION facility.update_timestamp();

CREATE TRIGGER trg_sites_code BEFORE INSERT ON facility.sites FOR EACH ROW EXECUTE FUNCTION facility.generate_site_code();
CREATE TRIGGER trg_spaces_code BEFORE INSERT ON facility.spaces FOR EACH ROW EXECUTE FUNCTION facility.generate_space_code();


-- =========================================================
-- 7. 기초 데이터 (Seed Data)
-- =========================================================

-- 7-1. 사이트 카테고리
INSERT INTO facility.site_categories (code, name, icon_name, description) VALUES 
('PARK', '공원',           'trees',     '시민 휴식 및 녹지 공간'),
('GYMS', '체육시설',       'dumbbell',  '체육관, 운동장 등'),
('ARTS', '문화시설',       'landmark',  '도서관, 박물관, 공연장'),
('RCYL', '자원재활용',     'recycle',   '소각장, 선별장 등'),
('MGMT', '관리시설',       'briefcase', '관리사무소, 행정동'),
('BLDG', '일반건물',       'building',  '기타 일반 건물');

-- 7-2. 공간 유형 (V20 추가: INF, SHA 등)
INSERT INTO facility.space_types (code, name, icon_name, description) VALUES 
('BLD', '건축물',      'building',    '일반적인 건물 (동 단위)'),       
('FLR', '층',          'layers',      '건물의 층'),             
('SPC', '공간',        'hexagon',     '벽으로 구획된 일반 실/방'),          
('ZON', '구역',        'grid-2x2',    '논리적인 관리 구역 (지하주차장 등)'),
('INF', '기반시설',    'route',       '지하 공동구, 전력구 등 선형 자산'),
('SHA', '수직구',      'arrow-up-down', '엘리베이터, PS, EPS 등 수직 공간');

-- 7-3. 유지보수 유형
INSERT INTO facility.maintenance_types (code, name, is_warranty_required, is_outsourcing) VALUES 
('REPAIR', '자체 수선', false, false), 
('CONSTR', '외주 공사', true, true),
('EXTREP', '외주 수리', true, true),
('INSPCT', '정기 점검', false, false);

-- 7-4. 공간 기능
INSERT INTO facility.space_functions (code, name, color_code) VALUES
('WORK', '업무시설', '#10B981'),  
('MEET', '회의실',   '#3B82F6'),   
('REST', '화장실',   '#06B6D4'),    
('ELEC', '전기실',   '#EF4444'),
('MECH', '기계실',   '#F59E0B'),
('COMM', '공용부',   '#6B7280');