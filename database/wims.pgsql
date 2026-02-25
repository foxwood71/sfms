--
-- PostgreSQL 데이터베이스 덤프(No Error One Pass Code)
--

-- 데이터베이스 버전 16.9 (Debian 16.9-1.pgdg120+1)에서 덤프됨
-- pg_dump 버전 16.9에 의해 덤프됨

-- 2025-05-29 19:51:24 KST 시작 (수정된 코드 시작 시간)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- 기존 스키마 및 테이블 삭제 (클린 시작을 위해. 실제 운영 환경에서는 매우 주의해야 합니다.)
-- WARNING: This will delete ALL data!
DROP SCHEMA IF EXISTS app CASCADE;
DROP SCHEMA IF EXISTS usr CASCADE;
DROP SCHEMA IF EXISTS loc CASCADE;
DROP SCHEMA IF EXISTS ven CASCADE;
DROP SCHEMA IF EXISTS fms CASCADE;
DROP SCHEMA IF EXISTS inv CASCADE;
DROP SCHEMA IF EXISTS lims CASCADE;
DROP SCHEMA IF EXISTS ops CASCADE;

-- 함수 삭제 (새 스키마 및 기능에 맞게 조정되기 전 충돌 방지)
DROP FUNCTION IF EXISTS app.update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS inv.deduct_material_fifo() CASCADE;
DROP FUNCTION IF EXISTS lims.generate_sample_code() CASCADE;
DROP FUNCTION IF EXISTS lims.generate_test_request_code() CASCADE;
DROP FUNCTION IF EXISTS lims.date_serial(date, date) CASCADE;
DROP FUNCTION IF EXISTS lims.get_container_name(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS lims.get_parameter_name(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS lims.get_parameter_list_from_json(JSON) CASCADE;
DROP FUNCTION IF EXISTS lims.get_sampling_point_name(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS lims.get_sample_type_name(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS lims.auto_dispose_aliquot_sample() CASCADE;
DROP FUNCTION IF EXISTS lims.auto_dispose_parent_sample() CASCADE;
DROP FUNCTION IF EXISTS lims.update_parent_sample_analysis_status() CASCADE;
DROP FUNCTION IF EXISTS lims.generate_aliquot_sample_code() CASCADE;
DROP FUNCTION IF EXISTS lims.mark_labels_printed() CASCADE;


--
-- 스키마 정의
--
CREATE SCHEMA app; COMMENT ON SCHEMA app IS '애플리케이션 공용 데이터 (이미지, 문서 등)';
CREATE SCHEMA usr; COMMENT ON SCHEMA usr IS '사용자 및 부서 관리';
CREATE SCHEMA loc; COMMENT ON SCHEMA loc IS '위치 정보 (시설, 설치/보관 장소 등)';
CREATE SCHEMA ven; COMMENT ON SCHEMA ven IS '업체 관리';
CREATE SCHEMA fms; COMMENT ON SCHEMA fms IS '시설 관리 시스템';
CREATE SCHEMA inv; COMMENT ON SCHEMA inv IS '자재 및 재고 관리';
CREATE SCHEMA lims; COMMENT ON SCHEMA lims IS '실험실 정보 관리 시스템 (LIMS) 및 품질 보증/품질 관리 (QA/QC)'; -- QAQC 통합 명시
CREATE SCHEMA ops; COMMENT ON SCHEMA ops IS '운영 데이터 관리 (공정 운영, 일지 등)';


--
-- 확장 기능
--
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public; -- 명시적으로 public 스키마에 설치
COMMENT ON EXTENSION pgcrypto IS '암호화 함수 (애플리케이션에서 public.gen_salt 및 public.crypt 함수를 사용하여 비밀번호 해싱 권장)';
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public; -- UUID 생성 확장 (gen_random_uuid() 사용)
COMMENT ON EXTENSION "uuid-ossp" IS 'UUID 생성 함수 (예: gen_random_uuid())';
CREATE EXTENSION IF NOT EXISTS pg_bigm WITH SCHEMA public;
COMMENT ON EXTENSION pg_bigm IS 'PostgreSQL용 bigram 기반 유사성 텍스트 검색 확장';



--
-- 공통 함수: updated_at 타임스탬프 자동 업데이트
--
CREATE OR REPLACE FUNCTION app.update_updated_at_column() RETURNS trigger
  LANGUAGE plpgsql
  AS $update_updated_at_column$

BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$update_updated_at_column$;
COMMENT ON FUNCTION app.update_updated_at_column() IS 'updated_at 타임스탬프 자동 업데이트';



--
-- app 스키마 테이블 (애플리케이션 공용 데이터)
--
CREATE TABLE app.versions (
    id SERIAL PRIMARY KEY,
    version VARCHAR(50),
    publish_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE app.versions IS '애플리케이션 버전 정보를 관리하는 테이블';
COMMENT ON COLUMN app.versions.id IS '버전 고유 ID';
COMMENT ON COLUMN app.versions.version IS '버전 번호';
COMMENT ON COLUMN app.versions.publish_date IS '배포일';
COMMENT ON COLUMN app.versions.notes IS '버전 노트/변경 사항';
COMMENT ON COLUMN app.versions.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN app.versions.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE app.image_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE app.image_types IS '이미지 유형을 관리하는 테이블';
COMMENT ON COLUMN app.image_types.id IS '이미지 유형 고유 ID';
COMMENT ON COLUMN app.image_types.name IS '이미지 유형 명칭';
COMMENT ON COLUMN app.image_types.description IS '설명';
COMMENT ON COLUMN app.image_types.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN app.image_types.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE app.images (
    id SERIAL PRIMARY KEY,
    image_type_id INTEGER REFERENCES app.image_types(id) ON UPDATE CASCADE ON DELETE SET NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(255) NOT NULL, -- 파일 저장 경로
    file_size_kb INTEGER,
    mime_type VARCHAR(50),
    description TEXT,
    uploaded_by_user_id INTEGER REFERENCES usr.users(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 사용자 삭제 시 이미지 정보는 유지하고 업로더만 NULL로
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE app.images IS '업로드된 이미지 파일 정보를 관리하는 테이블';
COMMENT ON COLUMN app.images.id IS '이미지 고유 ID';
COMMENT ON COLUMN app.images.image_type_id IS '이미지 유형 ID (FK)';
COMMENT ON COLUMN app.images.file_name IS '파일 이름';
COMMENT ON COLUMN app.images.file_path IS '파일 저장 경로';
COMMENT ON COLUMN app.images.file_size_kb IS '파일 크기 (KB)';
COMMENT ON COLUMN app.images.mime_type IS 'MIME 타입';
COMMENT ON COLUMN app.images.description IS '설명';
COMMENT ON COLUMN app.images.uploaded_by_user_id IS '업로드 사용자 ID (FK)';
COMMENT ON COLUMN app.images.uploaded_at IS '업로드 일시';
COMMENT ON COLUMN app.images.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE app.entity_images ( -- 각 테이블과 이미지 연결 (다대다 관계 또는 일대다 관계를 위한 연결 테이블)
    id SERIAL PRIMARY KEY,
    image_id INTEGER NOT NULL REFERENCES app.images(id) ON UPDATE CASCADE ON DELETE CASCADE, -- 이미지 삭제 시 연결 정보도 삭제
    entity_type VARCHAR(50) NOT NULL, -- 'EQUIPMENT', 'MATERIAL', 'LOCATION', 'VENDOR', 'SAMPLE', 'TEST_REQUEST' 등
    entity_id INTEGER NOT NULL,
    is_main_image BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE app.entity_images IS '다양한 엔티티(시설, 자재 등)와 이미지 간의 연결 정보를 관리하는 테이블';
COMMENT ON COLUMN app.entity_images.id IS '연결 고유 ID';
COMMENT ON COLUMN app.entity_images.image_id IS '이미지 ID (FK)';
COMMENT ON COLUMN app.entity_images.entity_type IS '연결된 엔티티 유형 (예: EQUIPMENT, MATERIAL)';
COMMENT ON COLUMN app.entity_images.entity_id IS '연결된 엔티티의 ID';
COMMENT ON COLUMN app.entity_images.is_main_image IS '대표 이미지 여부';
COMMENT ON COLUMN app.entity_images.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN app.entity_images.updated_at IS '레코드 마지막 업데이트 일시';


--
-- usr 스키마 테이블 (사용자 및 부서 관리)
--


-- ==========================================
-- 1. 부문 (Sector) 테이블: 최상위 조직 위계
-- ==========================================
CREATE TABLE usr.sectors (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE,
    name VARCHAR(100) NOT NULL UNIQUE,
    sort_order INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE usr.sectors IS '조직의 최상위 부문 정보를 관리하는 테이블 (예: 환경사업부문, 경영지원부문)';
COMMENT ON COLUMN usr.sectors.id IS '부문 고유 ID';
COMMENT ON COLUMN usr.sectors.name IS '부문 명칭';
COMMENT ON COLUMN usr.sectors.code IS '부문 코드 (예: SEC01)';
COMMENT ON COLUMN usr.sectors.sort_order IS 'UI 출력 시 정렬 순서';

-- ==========================================
-- 2. 센터 (Center) 테이블: 지역 거점 관리 조직
-- ==========================================
CREATE TABLE usr.centers (
    id SERIAL PRIMARY KEY,
    sector_id INTEGER REFERENCES usr.sectors(id) ON UPDATE CASCADE ON DELETE SET NULL,
    code VARCHAR(20) UNIQUE,
    name VARCHAR(100) NOT NULL UNIQUE,
    facility_ids JSONB DEFAULT '[]'::jsonb,
    description TEXT,
    sort_order INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE usr.centers IS '지역 거점 관리 조직인 센터 정보를 관리하는 테이블 (예: 광주 통합 센터)';
COMMENT ON COLUMN usr.centers.id IS '센터 고유 ID';
COMMENT ON COLUMN usr.centers.sector_id IS '소속 부문 ID (FK)';
COMMENT ON COLUMN usr.centers.name IS '센터 명칭';
COMMENT ON COLUMN usr.centers.code IS '센터 코드 (예: CTR01)';
COMMENT ON COLUMN usr.departments.facility_ids IS '센터에서 실무적으로 관할하는 시설(loc.facilities) ID 목록. JSONB 배열 형식(예: [1, 10, 12])으로 저장하여 권한 및 데이터 필터링에 활용함';
COMMENT ON COLUMN usr.centers.description IS '센터 상세 설명 및 관할 구역 정보';

-- ==========================================
-- 3. 부서 (Department) 테이블: 실무 조직 단위
-- ==========================================
CREATE TABLE usr.departments (
    id SERIAL PRIMARY KEY,
    sector_id INTEGER REFERENCES usr.sectors(id) ON UPDATE CASCADE ON DELETE SET NULL,
    center_id INTEGER REFERENCES usr.centers(id) ON UPDATE CASCADE ON DELETE SET NULL,
    code VARCHAR(4) UNIQUE,
    name VARCHAR(100) NOT NULL,
    facility_ids JSONB,
    sort_order INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- 🛡️ [제약 조건] 부서는 반드시 부문 또는 센터 중 한 곳에는 속해야 함
    CONSTRAINT chk_dept_belonging CHECK (sector_id IS NOT NULL OR center_id IS NOT NULL)
);
COMMENT ON TABLE usr.departments IS '부서 정보를 관리하며, 본사 부문 직속 또는 현장 센터 소속이 모두 가능함';
COMMENT ON COLUMN usr.departments.id IS '부서 고유 ID';
COMMENT ON COLUMN usr.departments.sector_id IS '소속 부문 ID (본사 직속 부서일 경우 필수 입력)';
COMMENT ON COLUMN usr.departments.center_id IS '소속 센터 ID (현장 센터 산하 부서일 경우 필수 입력)';
COMMENT ON COLUMN usr.departments.name IS '부서 명칭 (예: 통합 운영팀, 인사팀)';
COMMENT ON COLUMN usr.departments.facility_ids IS '부서에서 실무적으로 관할하는 시설(loc.facilities) ID 목록. JSONB 배열 형식(예: [1, 10, 12])으로 저장하여 권한 및 데이터 필터링에 활용함';

-- ==========================================
-- 4. usr.users: 시스템 사용자 정보 테이블
-- ==========================================
CREATE TABLE usr.users (
    id SERIAL PRIMARY KEY,
    department_id INTEGER REFERENCES usr.departments(id) ON UPDATE CASCADE ON DELETE SET NULL,
    profile_image_id INTEGER REFERENCES app.images(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 프로필 이미지 연결
    login_id VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    code VARCHAR(16) UNIQUE,                  -- 사번 또는 고유 코드
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(50),
 
    role INTEGER DEFAULT 100 NOT NULL,        -- 1: 최고관리자, 10: 관리자, 100: 일반사용자

    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMP WITH TIME ZONE,   -- 마지막 로그인 일시 (계정 관리용)

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE usr.users IS '시스템 사용자 정보를 관리하는 테이블';
COMMENT ON COLUMN usr.users.id IS '사용자 고유 ID';
COMMENT ON COLUMN usr.users.profile_image_id IS '사용자 프로필 이미지 ID (app.images 참조)';
COMMENT ON COLUMN usr.users.department_id IS '소속 부서 ID (FK) - 이를 통해 센터/부문 역추적 가능';
COMMENT ON COLUMN usr.users.login_id IS '로그인용 아이디 (UI: loginId)';
COMMENT ON COLUMN usr.users.password_hash IS '암호화된 비밀번호 해시';
COMMENT ON COLUMN usr.users.code IS '사용자 사번';
COMMENT ON COLUMN usr.users.name IS '사용자 이름';
COMMENT ON COLUMN usr.users.email IS '사용자 이메일 주소';
COMMENT ON COLUMN usr.users.phone IS '사용자 연락처 (센터/현장 비상 연락용)';
COMMENT ON COLUMN usr.users.role IS '권한 레벨 (1: SuperAdmin, 10: Admin, 100: User)';
COMMENT ON COLUMN usr.users.is_active IS '계정 활성 여부 (정상/중지)';
COMMENT ON COLUMN usr.users.last_login_at IS '최근 시스템 접속 일시';

-- =============================================================
-- ✨ 제한 설정 (Constraints) - 스크립트 끝 부분 배치
-- =============================================================

-- 부서는 부문 직속이거나 센터 산하여야 함 (하이브리드 구조)
ALTER TABLE usr.departments 
ADD CONSTRAINT chk_dept_belonging 
CHECK (sector_id IS NOT NULL OR center_id IS NOT NULL);



--
-- loc 스키마 테이블 (위치 정보)
--
CREATE TABLE loc.facilities ( 
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE,
    name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(20) DEFAULT 'STP',

    address VARCHAR(255),
    contact_person VARCHAR(100),
    contact_phone VARCHAR(50),

    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),

    description TEXT,
    sort_order INTEGER,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE loc.facilities IS '시설 및 현장 시설 정보를 관리하는 테이블';
COMMENT ON COLUMN loc.facilities.id IS '시설 고유 ID';
COMMENT ON COLUMN loc.facilities.code IS '시설 코드';
COMMENT ON COLUMN loc.facilities.name IS '시설 현장 호칭 명칭';
COMMENT ON COLUMN loc.facilities.category IS '시설 유형';
COMMENT ON COLUMN loc.facilities.address IS '주소';
COMMENT ON COLUMN loc.facilities.contact_person IS '담당자';
COMMENT ON COLUMN loc.facilities.contact_phone IS '연락처';
COMMENT ON COLUMN loc.facilities.latitude IS '위도';
COMMENT ON COLUMN loc.facilities.longitude IS '경도';
COMMENT ON COLUMN loc.facilities.description IS '설명';
COMMENT ON COLUMN loc.facilities.sort_order IS '정렬 순서';
COMMENT ON COLUMN loc.facilities.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN loc.facilities.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE loc.space_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL UNIQUE, -- 예: 유입동, 반응조, 탈수동, 창고, 야외 등... 표준화된 구분
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE loc.space_types IS '장소 유형을 관리하는 테이블 (예: 유입동, 반응조, 창고)';
COMMENT ON COLUMN loc.space_types.id IS '장소 유형 고유 ID';
COMMENT ON COLUMN loc.space_types.code IS '장소 유형 코드';
COMMENT ON COLUMN loc.space_types.name IS '장소 유형 명칭';
COMMENT ON COLUMN loc.space_types.description IS '설명';
COMMENT ON COLUMN loc.space_types.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN loc.space_types.updated_at IS '레코드 마지막 업데이트 일시';
-- 데이터 예시:
-- (BLDG    건물	    처리장 내 건물)
-- (FLR	    층	        건물의 층 (1F, B1))
-- (ROOM	실(Room)	구획된 방)
-- (TANK	수조(Tank)	물을 담는 구조물 (침전지 등))
-- (ZONE	구역	    야외 특정 구역)

CREATE TABLE loc.space_functions (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,  -- SED, AER, THK, PUMP, ELEC
    name VARCHAR(100) NOT NULL UNIQUE, -- 침전, 포기, 농축, 펌프, 전기
    category VARCHAR(50),              -- 대분류 (예: 수처리공정, 슬러지공정, 지원시설)
    description TEXT
);
COMMENT ON TABLE loc.space_functions IS '장소 기능을 관리하는 테이블 (예: 침전, 포기, 농축, 펌프, 전기)';
COMMENT ON COLUMN loc.space_functions.id IS '장소 기능 고유 ID';
COMMENT ON COLUMN loc.space_functions.code IS '장소 기능 코드';
COMMENT ON COLUMN loc.space_functions.name IS '장소 기능 명칭';
COMMENT ON COLUMN loc.space_functions.description IS '설명';
COMMENT ON COLUMN loc.space_functions.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN loc.space_functions.updated_at IS '레코드 마지막 업데이트 일시';
-- 데이터 예시:
-- ('GRT', '침사/유입', '수처리공정'),
-- ('SED', '침전', '수처리공정'),
-- ('BIO', '생물반응', '수처리공정'),
-- ('ELEC', '전기/동력', '지원시설'),
-- ('OFFICE', '사무/행정', '지원시설')

CREATE TABLE loc.spaces(
    id SERIAL PRIMARY KEY,
    -- 소속 시설 (필수)
    facility_id INTEGER NOT NULL REFERENCES loc.facilities(id) ON UPDATE CASCADE ON DELETE CASCADE,
    -- 공간 유형 (필수)
    space_type_id INTEGER REFERENCES loc.space_types(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    -- 공간 기능 (선택)
    space_function_id INTEGER REFERENCES loc.space_functions(id),
    -- 상위 공간 (계층 구조용, NULL이면 최상위 건물/구역)
    parent_id INTEGER REFERENCES loc.spaces(id) ON DELETE CASCADE,

    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL, -- 설치장소 또는 보관장소의 현장 호칭 명칭 (예: 반응조 A, 펌프실 1, 창고 2)

    area_size NUMERIC(10, 2),             -- 면적 (m2) - Space 관리의 핵심 속성
    is_restricted BOOLEAN DEFAULT false,  -- 출입 통제 구역 여부
    
    description TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE NULLS NOT DISTINCT (facility_id, parent_id, name) -- Ensures unique locations within a plant, considering hierarchy
);
COMMENT ON TABLE loc.spaces IS '처리장 내의 실제 장소 (설치 위치, 보관 위치 등)를 관리하는 테이블';
COMMENT ON COLUMN loc.spaces.id IS '장소 고유 ID';
COMMENT ON COLUMN loc.spaces.facility_id IS '소속 처리장 ID (FK)';
COMMENT ON COLUMN loc.spaces.space_type_id IS '장소 유형 ID (FK)';
COMMENT ON COLUMN loc.spaces.parent_id IS '상위 장소 ID (계층 구조를 위해)';
COMMENT ON COLUMN loc.spaces.code IS '장소 유형 코드';
COMMENT ON COLUMN loc.spaces.name IS '장소 현장 호칭 명칭';
COMMENT ON COLUMN loc.spaces.area_size IS '면적 (m2)';
COMMENT ON COLUMN loc.spaces.is_restricted IS '출입 통제 구역 여부';
COMMENT ON COLUMN loc.spaces.description IS '설명';
COMMENT ON COLUMN loc.spaces.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN loc.spaces.updated_at IS '레코드 마지막 업데이트 일시';

--
-- ven 스키마 테이블 (공급업체 관리)
--
CREATE TABLE ven.supplier_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE ven.supplier_categories IS '공급업체 카테고리를 관리하는 테이블';
COMMENT ON COLUMN ven.supplier_categories.id IS '공급업체 카테고리 고유 ID';
COMMENT ON COLUMN ven.supplier_categories.name IS '카테고리 명칭';
COMMENT ON COLUMN ven.supplier_categories.description IS '설명';
COMMENT ON COLUMN ven.supplier_categories.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN ven.supplier_categories.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE ven.suppliers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    business_number VARCHAR(50) UNIQUE, -- 사업자 등록 번호
    address VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(100),
    website VARCHAR(255),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE ven.suppliers IS '공급업체 정보를 관리하는 테이블';
COMMENT ON COLUMN ven.suppliers.id IS '공급업체 고유 ID';
COMMENT ON COLUMN ven.suppliers.name IS '공급업체명';
COMMENT ON COLUMN ven.suppliers.business_number IS '사업자 등록 번호';
COMMENT ON COLUMN ven.suppliers.address IS '주소';
COMMENT ON COLUMN ven.suppliers.phone IS '전화번호';
COMMENT ON COLUMN ven.suppliers.email IS '이메일';
COMMENT ON COLUMN ven.suppliers.website IS '웹사이트 주소';
COMMENT ON COLUMN ven.suppliers.description IS '설명';
COMMENT ON COLUMN ven.suppliers.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN ven.suppliers.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE ven.supplier_supplier_categories (
    supplier_id INTEGER NOT NULL REFERENCES ven.suppliers(id) ON UPDATE CASCADE ON DELETE CASCADE, -- 공급업체 삭제 시 연결 정보도 삭제
    supplier_category_id INTEGER NOT NULL REFERENCES ven.supplier_categories(id) ON UPDATE CASCADE ON DELETE CASCADE, -- 카테고리 삭제 시 연결 정보도 삭제
    PRIMARY KEY (supplier_id, supplier_category_id)
);
COMMENT ON TABLE ven.supplier_supplier_categories IS '공급업체와 카테고리 간의 다대다 관계 테이블';
COMMENT ON COLUMN ven.supplier_supplier_categories.supplier_id IS '공급업체 ID (FK)';
COMMENT ON COLUMN ven.supplier_supplier_categories.supplier_category_id IS '공급업체 카테고리 ID (FK)';

CREATE TABLE ven.supplier_contacts (
    id SERIAL PRIMARY KEY,
    supplier_id INTEGER NOT NULL REFERENCES ven.suppliers(id) ON UPDATE CASCADE ON DELETE CASCADE, -- 공급업체 삭제 시 연락처도 삭제
    name VARCHAR(100) NOT NULL,
    title VARCHAR(100),
    phone VARCHAR(50),
    email VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE ven.supplier_contacts IS '공급업체의 담당자 정보를 관리하는 테이블';
COMMENT ON COLUMN ven.supplier_contacts.id IS '연락처 고유 ID';
COMMENT ON COLUMN ven.supplier_contacts.supplier_id IS '소속 공급업체 ID (FK)';
COMMENT ON COLUMN ven.supplier_contacts.name IS '담당자 이름';
COMMENT ON COLUMN ven.supplier_contacts.title IS '담당자 직함';
COMMENT ON COLUMN ven.supplier_contacts.phone IS '담당자 전화번호';
COMMENT ON COLUMN ven.supplier_contacts.email IS '담당자 이메일';
COMMENT ON COLUMN ven.supplier_contacts.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN ven.supplier_contacts.updated_at IS '레코드 마지막 업데이트 일시';

--
-- fms 스키마 테이블 (시설 관리 시스템)
--
CREATE TABLE fms.equipment_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE, -- 예: 모터, 수질계측기, 펌프, 밸브, 소방시설 등 표준화된 구분
    description TEXT,
    korean_useful_life_years INTEGER, -- 한국 정부의 내용연수 규정 반영 (연 단위)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE fms.equipment_categories IS '시설 카테고리를 관리하는 테이블';
COMMENT ON COLUMN fms.equipment_categories.id IS '시설 카테고리 고유 ID';
COMMENT ON COLUMN fms.equipment_categories.name IS '카테고리 명칭';
COMMENT ON COLUMN fms.equipment_categories.description IS '설명';
COMMENT ON COLUMN fms.equipment_categories.korean_useful_life_years IS '한국 정부 권장 내용연수 (년)';
COMMENT ON COLUMN fms.equipment_categories.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN fms.equipment_categories.updated_at IS '레코드 마지막 업데이트 일시';

--  fms.equipment_spec_definitions
CREATE TABLE fms.equipment_spec_definitions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE, -- 예: 'power_kw', 'voltage_v', 'flow_rate_lps'
    display_name VARCHAR(100) NOT NULL, -- UI에 표시될 이름 (예: '정격 출력 (kW)', '전압 (V)')
    unit VARCHAR(50), -- 단위 (예: 'kW', 'V', 'LPS')
    data_type VARCHAR(50) NOT NULL CHECK (data_type IN ('text', 'numeric', 'boolean', 'jsonb')), -- 값의 데이터 타입 (예: 'numeric', 'text')
    description TEXT, -- 해당 규격 항목에 대한 설명
    is_required BOOLEAN DEFAULT FALSE, -- 해당 스펙 항목이 필수인지 여부
    default_value TEXT, -- 기본값 (텍스트 형태로 저장 후 사용 시 타입 변환)
    sort_order INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE fms.equipment_spec_definitions IS '시설 스펙 항목의 정의와 메타데이터를 관리하는 테이블';
COMMENT ON COLUMN fms.equipment_spec_definitions.id IS '스펙 정의 고유 ID';
COMMENT ON COLUMN fms.equipment_spec_definitions.name IS '스펙 항목의 내부 코드명 (JSONB 키로 사용)';
COMMENT ON COLUMN fms.equipment_spec_definitions.display_name IS '스펙 항목의 표시 명칭';
COMMENT ON COLUMN fms.equipment_spec_definitions.unit IS '스펙 항목의 단위';
COMMENT ON COLUMN fms.equipment_spec_definitions.data_type IS '스펙 항목의 데이터 타입 (text, numeric, boolean, jsonb)';
COMMENT ON COLUMN fms.equipment_spec_definitions.description IS '스펙 항목에 대한 설명';
COMMENT ON COLUMN fms.equipment_spec_definitions.is_required IS '해당 스펙 항목이 필수 입력인지 여부';
COMMENT ON COLUMN fms.equipment_spec_definitions.default_value IS '스펙 항목의 기본값';
COMMENT ON COLUMN fms.equipment_spec_definitions.sort_order IS '정렬 순서';
COMMENT ON COLUMN fms.equipment_spec_definitions.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN fms.equipment_spec_definitions.updated_at IS '레코드 마지막 업데이트 일시';

-- fms.equipment_category_spec_definitions
CREATE TABLE fms.equipment_category_spec_definitions (
    equipment_category_id INTEGER NOT NULL REFERENCES fms.equipment_categories(id) ON UPDATE CASCADE ON DELETE CASCADE,
    spec_definition_id INTEGER NOT NULL REFERENCES fms.equipment_spec_definitions(id) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (equipment_category_id, spec_definition_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE fms.equipment_category_spec_definitions IS '시설 카테고리에 적용되는 스펙 정의들을 연결하는 테이블';
COMMENT ON COLUMN fms.equipment_category_spec_definitions.equipment_category_id IS '시설 카테고리 ID (FK)';
COMMENT ON COLUMN fms.equipment_category_spec_definitions.spec_definition_id IS '스펙 정의 ID (FK)';
COMMENT ON COLUMN fms.equipment_category_spec_definitions.created_at IS '레코드 생성 일시';

CREATE TABLE fms.equipments (
    id SERIAL PRIMARY KEY,
    plant_id INTEGER NOT NULL REFERENCES loc.facilities(id) ON UPDATE CASCADE ON DELETE CASCADE, -- 처리장 삭제 시 시설도 삭제
    equipment_category_id INTEGER NOT NULL REFERENCES fms.equipment_categories(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 사용 중인 시설 카테고리는 삭제 불가
    current_location_id INTEGER REFERENCES loc.spaces(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 설치 위치 삭제 시 시설는 유지하고 위치만 NULL로
    name VARCHAR(100) NOT NULL, -- 시설의 현장 호칭 명칭 (예: 유입 펌프 #1, 반응조 혼합기)
    model_number VARCHAR(100),
    serial_number VARCHAR(100) UNIQUE,
    manufacturer VARCHAR(100),
    installation_date DATE,
    purchase_date DATE,
    purchase_price NUMERIC(18, 2), -- NULL 허용 (무상 또는 가격 미정)
    expected_lifespan_years INTEGER, -- 일반적인 예상 수명 (또는 카테고리에서 가져옴)
    status VARCHAR(50) DEFAULT 'OPERATIONAL' CHECK (status IN ('OPERATIONAL', 'UNDER_MAINTENANCE', 'OUT_OF_SERVICE', 'SCRAPPED')), -- 시설 상태 제약 추가
    asset_tag VARCHAR(100) UNIQUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE fms.equipments IS '시설 정보를 관리하는 테이블';
COMMENT ON COLUMN fms.equipments.id IS '시설 고유 ID';
COMMENT ON COLUMN fms.equipments.plant_id IS '소속 처리장 ID (FK)';
COMMENT ON COLUMN fms.equipments.equipment_category_id IS '시설 카테고리 ID (FK)';
COMMENT ON COLUMN fms.equipments.current_location_id IS '현재 설치 위치 ID (FK)';
COMMENT ON COLUMN fms.equipments.name IS '시설 현장 호칭 명칭';
COMMENT ON COLUMN fms.equipments.model_number IS '모델 번호';
COMMENT ON COLUMN fms.equipments.serial_number IS '일련 번호';
COMMENT ON COLUMN fms.equipments.manufacturer IS '제조사';
COMMENT ON COLUMN fms.equipments.installation_date IS '설치일';
COMMENT ON COLUMN fms.equipments.purchase_date IS '구입일';
COMMENT ON COLUMN fms.equipments.purchase_price IS '구입 가격';
COMMENT ON COLUMN fms.equipments.expected_lifespan_years IS '예상 수명 (년)';
COMMENT ON COLUMN fms.equipments.status IS '시설 상태 (OPERATIONAL, UNDER_MAINTENANCE, OUT_OF_SERVICE, SCRAPPED)';
COMMENT ON COLUMN fms.equipments.asset_tag IS '자산 태그';
COMMENT ON COLUMN fms.equipments.notes IS '비고';
COMMENT ON COLUMN fms.equipments.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN fms.equipments.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE fms.equipment_specs ( -- 시설별 표준화된 특성값 (JSONB 활용)
    id SERIAL PRIMARY KEY,
    equipment_id INTEGER NOT NULL REFERENCES fms.equipments(id) ON UPDATE CASCADE ON DELETE CASCADE, -- 시설 삭제 시 스펙도 삭제
    specs JSONB, -- 예: {"power_kw": 2.2, "voltage_v": 380, "flow_rate_lps": 100}
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE fms.equipment_specs IS '시설별 상세 스펙 정보를 관리하는 테이블';
COMMENT ON COLUMN fms.equipment_specs.id IS '스펙 고유 ID';
COMMENT ON COLUMN fms.equipment_specs.equipment_id IS '관련 시설 ID (FK)';
COMMENT ON COLUMN fms.equipment_specs.specs IS '시설 스펙 (JSONB)';
COMMENT ON COLUMN fms.equipment_specs.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN fms.equipment_specs.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE fms.equipment_history ( -- 시설 유지보수 및 이력
    id SERIAL PRIMARY KEY,
    equipment_id INTEGER NOT NULL REFERENCES fms.equipments(id) ON UPDATE CASCADE ON DELETE CASCADE, -- 시설 삭제 시 이력도 삭제
    change_type VARCHAR(50) NOT NULL, -- 예: NEW_INSTALLATION, REPAIR, REMOVAL, REPLACEMENT, MAINTENANCE, DECOMMISSIONED
    change_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    performed_by_user_id INTEGER REFERENCES usr.users(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 사용자 삭제 시 이력은 유지하고 담당자만 NULL로
    service_provider_supplier_id INTEGER REFERENCES ven.suppliers(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 공급업체 삭제 시 이력은 유지하고 업체만 NULL로
    outsourcing BOOLEAN DEFAULT FALSE NOT NULL, -- 외주 여부
    next_service_date TIMESTAMP WITH TIME ZONE, -- 다음 서비스 예정일
    cost NUMERIC(19,4) DEFAULT 0,
    replaced_by_equipment_id INTEGER REFERENCES fms.equipments(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 교체된 시설 삭제 시 이력은 유지하고 연결만 NULL로
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP -- updated_at 컬럼 추가
);
COMMENT ON TABLE fms.equipment_history IS '시설의 유지보수 및 변경 이력을 관리하는 테이블';
COMMENT ON COLUMN fms.equipment_history.id IS '이력 고유 ID';
COMMENT ON COLUMN fms.equipment_history.equipment_id IS '관련 시설 ID (FK)';
COMMENT ON COLUMN fms.equipment_history.change_type IS '변경 유형 (NEW_INSTALLATION, REPAIR 등)';
COMMENT ON COLUMN fms.equipment_history.change_date IS '변경 발생 일시';
COMMENT ON COLUMN fms.equipment_history.description IS '변경 내용 상세';
COMMENT ON COLUMN fms.equipment_history.performed_by_user_id IS '작업 수행 사용자 ID (FK)';
COMMENT ON COLUMN fms.equipment_history.service_provider_supplier_id IS '서비스 제공 공급업체 ID (FK)';
COMMENT ON COLUMN fms.equipment_history.outsourcing IS '외주 여부';
COMMENT ON COLUMN fms.equipment_history.next_service_date IS '다음 서비스 예정일';
COMMENT ON COLUMN fms.equipment_history.cost IS '발생 비용';
COMMENT ON COLUMN fms.equipment_history.replaced_by_equipment_id IS '교체된 시설 ID (FK)';
COMMENT ON COLUMN fms.equipment_history.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN fms.equipment_history.updated_at IS '레코드 마지막 업데이트 일시';

--
-- inv 스키마 테이블 (자재 및 재고 관리)
--
CREATE TABLE inv.material_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE inv.material_categories IS '자재 카테고리를 관리하는 테이블';
COMMENT ON COLUMN inv.material_categories.id IS '자재 카테고리 고유 ID';
COMMENT ON COLUMN inv.material_categories.name IS '카테고리 명칭';
COMMENT ON COLUMN inv.material_categories.description IS '설명';
COMMENT ON COLUMN inv.material_categories.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN inv.material_categories.updated_at IS '레코드 마지막 업데이트 일시';

--  inv.material_spec_definitions
CREATE TABLE inv.material_spec_definitions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE, -- 예: 'power_kw', 'voltage_v', 'flow_rate_lps'
    display_name VARCHAR(100) NOT NULL, -- UI에 표시될 이름 (예: '정격 출력 (kW)', '전압 (V)')
    unit VARCHAR(50), -- 단위 (예: 'kW', 'V', 'LPS')
    data_type VARCHAR(50) NOT NULL CHECK (data_type IN ('text', 'numeric', 'boolean', 'jsonb')), -- 값의 데이터 타입 (예: 'numeric', 'text')
    description TEXT, -- 해당 규격 항목에 대한 설명
    is_required BOOLEAN DEFAULT FALSE, -- 해당 스펙 항목이 필수인지 여부
    default_value TEXT, -- 기본값 (텍스트 형태로 저장 후 사용 시 타입 변환)
    sort_order INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE inv.material_spec_definitions IS '자재 스펙 항목의 정의와 메타데이터를 관리하는 테이블';
COMMENT ON COLUMN inv.material_spec_definitions.id IS '스펙 정의 고유 ID';
COMMENT ON COLUMN inv.material_spec_definitions.name IS '스펙 항목의 내부 코드명 (JSONB 키로 사용)';
COMMENT ON COLUMN inv.material_spec_definitions.display_name IS '스펙 항목의 표시 명칭';
COMMENT ON COLUMN inv.material_spec_definitions.unit IS '스펙 항목의 단위';
COMMENT ON COLUMN inv.material_spec_definitions.data_type IS '스펙 항목의 데이터 타입 (text, numeric, boolean, jsonb)';
COMMENT ON COLUMN inv.material_spec_definitions.description IS '스펙 항목에 대한 설명';
COMMENT ON COLUMN inv.material_spec_definitions.is_required IS '해당 스펙 항목이 필수 입력인지 여부';
COMMENT ON COLUMN inv.material_spec_definitions.default_value IS '스펙 항목의 기본값';
COMMENT ON COLUMN inv.material_spec_definitions.sort_order IS '정렬 순서';
COMMENT ON COLUMN inv.material_spec_definitions.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN inv.material_spec_definitions.updated_at IS '레코드 마지막 업데이트 일시';

-- inv.material_category_spec_definitions
CREATE TABLE inv.material_category_spec_definitions (
    material_category_id INTEGER NOT NULL REFERENCES inv.material_categories(id) ON UPDATE CASCADE ON DELETE CASCADE,
    spec_definition_id INTEGER NOT NULL REFERENCES inv.material_spec_definitions(id) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (material_category_id, spec_definition_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE inv.material_category_spec_definitions IS '시설 카테고리에 적용되는 스펙 정의들을 연결하는 테이블';
COMMENT ON COLUMN inv.material_category_spec_definitions.material_category_id IS '자재 카테고리 ID (FK)';
COMMENT ON COLUMN inv.material_category_spec_definitions.spec_definition_id IS '스펙 정의 ID (FK)';
COMMENT ON COLUMN inv.material_category_spec_definitions.created_at IS '레코드 생성 일시';

CREATE TABLE inv.materials (
    id SERIAL PRIMARY KEY,
    material_category_id INTEGER NOT NULL REFERENCES inv.material_categories(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 사용 중인 자재 카테고리는 삭제 불가
    name VARCHAR(100) NOT NULL,
    unit_of_measure VARCHAR(20) NOT NULL, -- 단위 (예: EA, L, KG)
    sku VARCHAR(50) UNIQUE,
    min_stock_level NUMERIC(18, 2) DEFAULT 0,
    max_stock_level NUMERIC(18, 2) DEFAULT 0,
    msds_link VARCHAR(255), -- MSDS 문서 링크
    msds_data JSONB, -- MSDS 주요 정보 (JSONB)
    discontinued BOOLEAN DEFAULT FALSE, -- 단종 여부
    reorder_level INTEGER, -- 재주문 레벨 (일반 재고 관리용)
    related_equipment_id INTEGER REFERENCES fms.equipments(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 관련 시설가 있다면 자재는 유지하지만 시설 삭제는 불가 (시설 폐기 시 자재 관계 해지 필요)
    replacement_cycle DOUBLE PRECISION DEFAULT 0, -- 시설의 관련 자재 교체 주기 (예: 분석 장비의 필터 교체 주기)
    replacement_cycle_unit VARCHAR(255) DEFAULT '시간'::VARCHAR, -- 교체 주기 단위 (예: 시간, 일, 월)
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE inv.materials IS '자재 품목 정보를 관리하는 테이블';
COMMENT ON COLUMN inv.materials.id IS '자재 품목 고유 ID';
COMMENT ON COLUMN inv.materials.material_category_id IS '자재 카테고리 ID (FK)';
COMMENT ON COLUMN inv.materials.name IS '자재명';
COMMENT ON COLUMN inv.materials.unit_of_measure IS '측정 단위 (예: EA, L, KG)';
COMMENT ON COLUMN inv.materials.sku IS '재고 관리 단위 (Stock Keeping Unit)';
COMMENT ON COLUMN inv.materials.min_stock_level IS '최소 재고 수량';
COMMENT ON COLUMN inv.materials.max_stock_level IS '최대 재고 수량';
COMMENT ON COLUMN inv.materials.msds_link IS 'MSDS 문서 링크';
COMMENT ON COLUMN inv.materials.msds_data IS 'MSDS 주요 정보 (JSONB)';
COMMENT ON COLUMN inv.materials.discontinued IS '단종 여부';
COMMENT ON COLUMN inv.materials.reorder_level IS '재주문 레벨';
COMMENT ON COLUMN inv.materials.related_equipment_id IS '관련 시설 ID (FK)';
COMMENT ON COLUMN inv.materials.replacement_cycle IS '교체 주기 값';
COMMENT ON COLUMN inv.materials.replacement_cycle_unit IS '교체 주기 단위';
COMMENT ON COLUMN inv.materials.notes IS '비고';
COMMENT ON COLUMN inv.materials.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN inv.materials.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE inv.materials_specs ( -- 시설별 표준화된 특성값 (JSONB 활용)
    id SERIAL PRIMARY KEY,
    materials_id INTEGER NOT NULL REFERENCES inv.materials(id) ON UPDATE CASCADE ON DELETE CASCADE, -- 시설 삭제 시 스펙도 삭제
    specs JSONB, -- 예: {"power_kw": 2.2, "voltage_v": 380, "flow_rate_lps": 100}
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE inv.materials_specs IS '시설별 상세 스펙 정보를 관리하는 테이블';
COMMENT ON COLUMN inv.materials_specs.id IS '스펙 고유 ID';
COMMENT ON COLUMN inv.materials_specs.materials_id IS '관련 자재 ID (FK)';
COMMENT ON COLUMN inv.materials_specs.specs IS '시설 스펙 (JSONB)';
COMMENT ON COLUMN inv.materials_specs.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN inv.materials_specs.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE inv.material_batches ( -- 자재 재고 배치 (FIFO 관리를 위해 필수)
    id SERIAL PRIMARY KEY,
    material_id INTEGER NOT NULL REFERENCES inv.materials(id) ON UPDATE CASCADE ON DELETE CASCADE, -- 자재 삭제 시 배치도 삭제
    plant_id INTEGER NOT NULL REFERENCES loc.facilities(id) ON UPDATE CASCADE ON DELETE CASCADE, -- 처리장 삭제 시 배치도 삭제
    storage_location_id INTEGER REFERENCES loc.spaces(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 보관 위치 삭제 시 배치는 유지하고 위치만 NULL로
    lot_number VARCHAR(100),
    quantity NUMERIC(18, 2) NOT NULL CHECK (quantity >= 0),
    unit_cost NUMERIC(18, 2), -- NULL 허용 (무상 또는 가격 미정)
    received_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expiration_date DATE,
    supplier_id INTEGER REFERENCES ven.suppliers(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 공급업체 삭제 시 배치는 유지하고 업체만 NULL로
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE inv.material_batches IS '자재의 개별 입고 배치 (Lot) 정보를 관리하는 테이블 (FIFO 재고 관리에 사용)';
COMMENT ON COLUMN inv.material_batches.id IS '배치 고유 ID';
COMMENT ON COLUMN inv.material_batches.material_id IS '관련 자재 품목 ID (FK)';
COMMENT ON COLUMN inv.material_batches.plant_id IS '보관 처리장 ID (FK)';
COMMENT ON COLUMN inv.material_batches.storage_location_id IS '보관 위치 ID (FK)';
COMMENT ON COLUMN inv.material_batches.lot_number IS '로트 번호';
COMMENT ON COLUMN inv.material_batches.quantity IS '재고 수량';
COMMENT ON COLUMN inv.material_batches.unit_cost IS '단가';
COMMENT ON COLUMN inv.material_batches.received_date IS '입고 일시';
COMMENT ON COLUMN inv.material_batches.expiration_date IS '만료일';
COMMENT ON COLUMN inv.material_batches.supplier_id IS '공급업체 ID (FK)';
COMMENT ON COLUMN inv.material_batches.notes IS '비고';
COMMENT ON COLUMN inv.material_batches.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN inv.material_batches.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE inv.material_transactions ( -- 자재 입출고 및 사용 이력
    id SERIAL PRIMARY KEY,
    material_id INTEGER NOT NULL REFERENCES inv.materials(id) ON UPDATE CASCADE ON DELETE CASCADE, -- 자재 삭제 시 트랜잭션 기록도 삭제
    plant_id INTEGER NOT NULL REFERENCES loc.facilities(id) ON UPDATE CASCADE ON DELETE CASCADE, -- 처리장 삭제 시 트랜잭션 기록도 삭제
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('PURCHASE', 'USAGE', 'RETURN', 'ADJUSTMENT')), -- 트랜잭션 유형 제약 추가
    quantity_change NUMERIC(18, 2) NOT NULL, -- 입고는 양수, 출고(사용)는 음수
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    related_equipment_id INTEGER REFERENCES fms.equipments(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 관련 시설 삭제 시 트랜잭션은 유지하고 시설만 NULL로
    related_equipment_history_id INTEGER REFERENCES fms.equipment_history(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 관련 시설 이력 삭제 시 트랜잭션은 유지하고 이력만 NULL로
    source_batch_id INTEGER REFERENCES inv.material_batches(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 배치 삭제 시 트랜잭션은 유지하고 배치만 NULL로
    performed_by_user_id INTEGER REFERENCES usr.users(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 사용자 삭제 시 트랜잭션은 유지하고 사용자만 NULL로
    supplier_id INTEGER REFERENCES ven.suppliers(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 구매 시 공급업체
    unit_price NUMERIC(19,4) DEFAULT 0, -- 구매 시 단가
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP -- updated_at 컬럼 추가
);
COMMENT ON TABLE inv.material_transactions IS '자재의 입고, 출고, 사용, 반환, 조정 등의 거래 이력을 관리하는 테이블';
COMMENT ON COLUMN inv.material_transactions.id IS '거래 이력 고유 ID';
COMMENT ON COLUMN inv.material_transactions.material_id IS '관련 자재 품목 ID (FK)';
COMMENT ON COLUMN inv.material_transactions.plant_id IS '거래 발생 처리장 ID (FK)';
COMMENT ON COLUMN inv.material_transactions.transaction_type IS '거래 유형 (PURCHASE, USAGE 등)';
COMMENT ON COLUMN inv.material_transactions.quantity_change IS '수량 변경 (양수: 입고, 음수: 출고/사용)';
COMMENT ON COLUMN inv.material_transactions.transaction_date IS '거래 발생 일시';
COMMENT ON COLUMN inv.material_transactions.related_equipment_id IS '관련 시설 ID (FK)';
COMMENT ON COLUMN inv.material_transactions.related_equipment_history_id IS '관련 시설 이력 ID (FK)';
COMMENT ON COLUMN inv.material_transactions.source_batch_id IS '사용된 배치 ID (FK)';
COMMENT ON COLUMN inv.material_transactions.performed_by_user_id IS '거래 수행 사용자 ID (FK)';
COMMENT ON COLUMN inv.material_transactions.supplier_id IS '관련 공급업체 ID (FK)';
COMMENT ON COLUMN inv.material_transactions.unit_price IS '단가 (구매 시)';
COMMENT ON COLUMN inv.material_transactions.notes IS '비고';
COMMENT ON COLUMN inv.material_transactions.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN inv.material_transactions.updated_at IS '레코드 마지막 업데이트 일시';

-- 자재 재고 자동 차감 로직(FIFO)
-- 이 함수는 자재가 'USAGE' 타입으로 기록될 때 가장 오래된 배치를 찾아 차감하도록 도와줍니다.
-- 더 정교한 FIFO 구현은 애플리케이션 레벨에서 관리하는 것이 권장됩니다.
CREATE OR REPLACE FUNCTION inv.deduct_material_fifo() RETURNS trigger
    LANGUAGE plpgsql
	AS $deduct_material_fifo$
DECLARE
    remaining_qty NUMERIC;
    batch_record RECORD;
BEGIN
    IF NEW.transaction_type = 'USAGE' THEN
        remaining_qty := ABS(NEW.quantity_change); -- 사용량은 음수로 기록되므로 절대값
        FOR batch_record IN (
            SELECT id, quantity
            FROM inv.material_batches
            WHERE material_id = NEW.material_id AND plant_id = NEW.plant_id
            ORDER BY received_date ASC, id ASC -- FIFO
            FOR UPDATE -- Lock rows to prevent race conditions
        ) LOOP
            IF remaining_qty <= 0 THEN
                EXIT;
            END IF;

            IF batch_record.quantity >= remaining_qty THEN
                UPDATE inv.material_batches
                SET quantity = quantity - remaining_qty
                WHERE id = batch_record.id;
                NEW.source_batch_id = batch_record.id; -- 어떤 배치에서 사용되었는지 기록
                remaining_qty := 0;
            ELSE
                remaining_qty := remaining_qty - batch_record.quantity;
                UPDATE inv.material_batches
                SET quantity = 0
                WHERE id = batch_record.id;
                NEW.source_batch_id = batch_record.id; -- 마지막으로 사용된 배치 기록
            END IF;
        END LOOP;

        IF remaining_qty > 0 THEN
            RAISE EXCEPTION 'Not enough % in stock at plant % for usage. Remaining: %', NEW.material_id, NEW.plant_id, remaining_qty;
        END IF;
    END IF;
    RETURN NEW;
END;
$deduct_material_fifo$;
COMMENT ON FUNCTION inv.deduct_material_fifo() IS '자재 재고 자동 차감 로직(FIFO).';



--
-- lims 스키마 테이블 (실험실 정보 관리 시스템 및 QA/QC)
--
-- LIMS 관련 함수 (plant_id, department_id, user_id 등 FK 참조 변경)
CREATE OR REPLACE FUNCTION lims.generate_sample_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $generate_sample_code$
  DECLARE
    sample_date CHAR(8) :=  to_char(NEW.sampling_date, 'YYYYMMDD');
    project_c CHAR(4);
    smp_c VARCHAR(10); -- sampling_points.code는 VARCHAR(10)까지 가능
  BEGIN
    SELECT code INTO project_c FROM lims.projects WHERE id = NEW.project_id;
    SELECT code INTO smp_c FROM lims.sampling_points WHERE id = NEW.sampling_point_id;

    NEW.sample_code := lpad(project_c::text,4,'0') ||
                       lpad(smp_c::text,10,'0') || -- sampling_points.code 길이에 맞춰 조정
                       sample_date ||
                       lpad(NEW.id::text,4,'0');
    RETURN NEW;
  END;
$generate_sample_code$;
COMMENT ON FUNCTION lims.generate_sample_code() IS 'LIMS 관련 함수 (plant_id, department_id, user_id 등 FK 참조 변경).';

CREATE OR REPLACE FUNCTION lims.generate_test_request_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $generate_test_request_code$
    DECLARE
        request_date CHAR(8) := to_char(NEW.request_date, 'YYYYMMDD');
        project_c CHAR(4);
        dept_c CHAR(4);
    BEGIN
        SELECT code INTO project_c FROM lims.projects WHERE id = NEW.project_id;
        SELECT code INTO dept_c FROM usr.departments WHERE id = NEW.department_id;

        NEW.request_code := lpad(project_c::text,4,'0') ||
                            lpad(dept_c::text,4,'0') ||
                            request_date ||
                            lpad(NEW.id::text,4,'0');
        RETURN NEW;
    END;
$generate_test_request_code$;
COMMENT ON FUNCTION lims.generate_test_request_code() IS '새 시험 의뢰의 고유 코드를 자동으로 생성합니다.';

CREATE OR REPLACE FUNCTION lims.date_serial(p_start date, p_stop date) RETURNS TABLE(dates date)
    LANGUAGE plpgsql
    AS $date_serial$
DECLARE
  t_sql text;
BEGIN
  t_sql = 'SELECT t.ts::date as dates ' ||
          'FROM generate_series(''' || p_start || ''',''' || p_stop || ''', ''1day''::interval) AS t(ts);';

  return query execute t_sql;
END $date_serial$;
COMMENT ON FUNCTION lims.date_serial(date, date) IS '지정된 시작일과 종료일 사이의 모든 날짜를 반환합니다.';

CREATE OR REPLACE FUNCTION lims.get_container_name(p_container_id INTEGER) RETURNS TEXT
    LANGUAGE plpgsql
    AS $get_container_name$
 DECLARE
   _name TEXT;
 BEGIN
     SELECT INTO _name name FROM lims.sample_containers
   WHERE id = p_container_id;
   RETURN _name;
   END;
$get_container_name$;
COMMENT ON FUNCTION lims.get_container_name(INTEGER) IS '시료 용기 ID에 해당하는 이름을 반환합니다.';

CREATE OR REPLACE FUNCTION lims.get_parameter_name(p_parameter_id INTEGER) RETURNS TEXT
    LANGUAGE plpgsql
    AS $get_parameter_list_from_json$
 DECLARE
   _name TEXT;
 BEGIN
     SELECT INTO _name name FROM lims.parameters
   WHERE id = p_parameter_id;
   RETURN _name;
   END;
$get_parameter_list_from_json$;
COMMENT ON FUNCTION lims.get_parameter_name(INTEGER) IS '분석 항목 ID에 해당하는 이름을 반환합니다.';

CREATE OR REPLACE FUNCTION lims.get_parameter_list_from_json(p_json_in JSON) RETURNS TEXT
    LANGUAGE plpgsql
    AS $get_sampling_point_name$
    DECLARE
        _item JSON;
        _name TEXT;
        _list TEXT;
    BEGIN
        _list='';
        FOR _item IN SELECT row_to_json(t.*) FROM json_each_text(p_json_in) AS t
        LOOP
            IF _item->>'value' = '1' THEN
                SELECT INTO _name name FROM lims.parameters AS t
                WHERE t.code = _item->>'key';
                _list = _list || _name || ',';
            END IF;
        END LOOP;
        RETURN regexp_replace(_list, ',$', '');
    END;
$get_sampling_point_name$;
COMMENT ON FUNCTION lims.get_parameter_list_from_json(JSON) IS 'JSON 형식의 분석 항목 목록에서 이름을 추출하여 쉼표로 구분된 문자열로 반환합니다.';

CREATE OR REPLACE FUNCTION lims.get_sampling_point_name(p_smp_id INTEGER) RETURNS TEXT
    LANGUAGE plpgsql
    AS $get_sampling_point_name$
 DECLARE
   _smp_name TEXT;
 BEGIN
   SELECT INTO _smp_name name FROM lims.sampling_points
   WHERE id = p_smp_id;
   RETURN _smp_name;
   END;
$get_sampling_point_name$;
COMMENT ON FUNCTION lims.get_sampling_point_name(INTEGER) IS '채수 지점 ID에 해당하는 이름을 반환합니다.';

CREATE OR REPLACE FUNCTION lims.get_sample_type_name(p_sample_type_id INTEGER) RETURNS TEXT
    LANGUAGE plpgsql
    AS $get_sample_type_name$
 DECLARE
   _name TEXT;
 BEGIN
     SELECT INTO _name name FROM lims.sample_types
   WHERE id = p_sample_type_id;
   RETURN _name;
   END;
$get_sample_type_name$;
COMMENT ON FUNCTION lims.get_sample_type_name(INTEGER) IS '시료 유형 ID에 해당하는 이름을 반환합니다.';

CREATE OR REPLACE FUNCTION lims.auto_dispose_aliquot_sample() RETURNS trigger
    LANGUAGE plpgsql
    AS $auto_dispose_aliquot_sample$
    BEGIN
        IF NEW.analysis_status = 'Completed' THEN
            -- pg_cron의 public.cron.schedule 함수는 비동기로 작업을 스케줄링합니다.
            -- NEW.id는 INTEGER 타입이므로 직접 삽입해도 SQL 인젝션 위험은 낮습니다.
            PERFORM public.cron.schedule('dispose_aliquot_sample_' || NEW.id, '0 0 * * *',
                'UPDATE lims.aliquot_samples SET disposal_date = CURRENT_DATE, status = ''Disposed'' WHERE id = ' || NEW.id);
        END IF;
        RETURN NEW;
    END;
$auto_dispose_aliquot_sample$;
COMMENT ON FUNCTION lims.auto_dispose_aliquot_sample() IS '분할 시료 분석 완료 시 자동으로 폐기일을 설정합니다.';

CREATE OR REPLACE FUNCTION lims.auto_dispose_parent_sample() RETURNS trigger
    LANGUAGE plpgsql
    AS $auto_dispose_parent_sample$
    DECLARE
        all_aliquots_completed BOOLEAN;
    BEGIN
        SELECT NOT EXISTS (
            SELECT 1
            FROM lims.aliquot_samples
            WHERE parent_sample_id = NEW.id AND analysis_status <> 'Completed'
        ) INTO all_aliquots_completed;

        IF all_aliquots_completed THEN
            PERFORM public.cron.schedule('dispose_parent_sample_' || NEW.id, '0 0 * * *',
                'UPDATE lims.samples SET disposal_date = CURRENT_DATE + INTERVAL ''3 days'', status = ''Disposed'' WHERE id = ' || NEW.id);
        END IF;
        RETURN NEW;
    END;
$auto_dispose_parent_sample$;
COMMENT ON FUNCTION lims.auto_dispose_parent_sample() IS '모든 분할 시료 분석 완료 시 원 시료의 폐기일을 설정합니다.';

CREATE OR REPLACE FUNCTION lims.update_parent_sample_analysis_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $update_parent_sample_analysis_status$
    DECLARE
        parent_sample_id_val INTEGER;
        total_aliquots INTEGER;
        completed_aliquots INTEGER;
    BEGIN
        IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
            parent_sample_id_val := NEW.parent_sample_id;
        ELSIF TG_OP = 'DELETE' THEN
            parent_sample_id_val := OLD.parent_sample_id;
        END IF;

        SELECT COUNT(*) INTO total_aliquots FROM lims.aliquot_samples WHERE parent_sample_id = parent_sample_id_val;
        SELECT COUNT(*) INTO completed_aliquots FROM lims.aliquot_samples WHERE parent_sample_id = parent_sample_id_val AND analysis_status = 'Completed';

        IF total_aliquots = completed_aliquots AND total_aliquots > 0 THEN
            UPDATE lims.samples SET analysis_status = 'Completed' WHERE id = parent_sample_id_val;
        ELSIF completed_aliquots = 0 THEN
             UPDATE lims.samples SET analysis_status = 'Pending' WHERE id = parent_sample_id_val;
        ELSE
            UPDATE lims.samples SET analysis_status = 'In Progress' WHERE id = parent_sample_id_val;
        END IF;

        RETURN NULL;
    END;
$update_parent_sample_analysis_status$;
COMMENT ON FUNCTION lims.update_parent_sample_analysis_status() IS '분할 시료의 상태 변경 시 원 시료의 분석 상태를 업데이트합니다.';

CREATE OR REPLACE FUNCTION lims.generate_aliquot_sample_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $generate_aliquot_sample_code$
    DECLARE
        parent_sample_code TEXT;
    BEGIN
        SELECT sample_code INTO parent_sample_code FROM lims.samples WHERE id = NEW.parent_sample_id;
        NEW.aliquot_code := parent_sample_code || '-ALIQ-' || NEW.id;
        RETURN NEW;
    END;
$generate_aliquot_sample_code$;
COMMENT ON FUNCTION lims.generate_aliquot_sample_code() IS '분할 시료의 고유 코드를 자동으로 생성합니다.';

CREATE OR REPLACE FUNCTION lims.mark_labels_printed() RETURNS trigger
    LANGUAGE plpgsql
    AS $mark_labels_printed$
    BEGIN
        UPDATE lims.test_requests SET label_printed = TRUE WHERE id = NEW.id;
        RETURN NEW;
    END;
$mark_labels_printed$;
COMMENT ON FUNCTION lims.mark_labels_printed() IS '시험 의뢰 생성 시 라벨 인쇄 여부를 표시합니다.';

CREATE TABLE lims.parameters (
    id SERIAL PRIMARY KEY,
    code VARCHAR(4) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    units VARCHAR(255) DEFAULT NULL,
    method VARCHAR(255) DEFAULT NULL,
    detection_limit_low NUMERIC(28,8) DEFAULT NULL,
    detection_limit_high NUMERIC(28,8) DEFAULT NULL,
    quantification_limit NUMERIC(28,8) DEFAULT NULL,
    default_value0 VARCHAR(255) DEFAULT NULL,
    default_value1 VARCHAR(255) DEFAULT NULL,
    default_value2 VARCHAR(255) DEFAULT NULL,
    instrument_id INTEGER REFERENCES fms.equipments(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 장비 삭제 시 분석 항목도 삭제 불가
    price MONEY,
    description TEXT,
    sort_order INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE lims.parameters IS '분석 항목 (파라미터) 정보를 관리하는 테이블';
COMMENT ON COLUMN lims.parameters.id IS '분석 항목 고유 ID';
COMMENT ON COLUMN lims.parameters.code IS '분석 항목 코드';
COMMENT ON COLUMN lims.parameters.name IS '분석 항목명';
COMMENT ON COLUMN lims.parameters.units IS '측정 단위';
COMMENT ON COLUMN lims.parameters.method IS '분석 방법';
COMMENT ON COLUMN lims.parameters.detection_limit_low IS '하한 검출 한계';
COMMENT ON COLUMN lims.parameters.detection_limit_high IS '상한 검출 한계';
COMMENT ON COLUMN lims.parameters.quantification_limit IS '정량 한계';
COMMENT ON COLUMN lims.parameters.default_value0 IS '기본값 0';
COMMENT ON COLUMN lims.parameters.default_value1 IS '기본값 1';
COMMENT ON COLUMN lims.parameters.default_value2 IS '기본값 2';
COMMENT ON COLUMN lims.parameters.instrument_id IS '관련 장비 ID (FK)';
COMMENT ON COLUMN lims.parameters.price IS '분석 비용';
COMMENT ON COLUMN lims.parameters.description IS '설명';
COMMENT ON COLUMN lims.parameters.sort_order IS '정렬 순서';
COMMENT ON COLUMN lims.parameters.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.parameters.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE lims.projects (
    id SERIAL PRIMARY KEY,
    code VARCHAR(4) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE lims.projects IS '프로젝트 정보를 관리하는 테이블';
COMMENT ON COLUMN lims.projects.id IS '프로젝트 고유 ID';
COMMENT ON COLUMN lims.projects.code IS '프로젝트 코드';
COMMENT ON COLUMN lims.projects.name IS '프로젝트명';
COMMENT ON COLUMN lims.projects.start_date IS '프로젝트 시작일';
COMMENT ON COLUMN lims.projects.end_date IS '프로젝트 종료일';
COMMENT ON COLUMN lims.projects.description IS '설명';
COMMENT ON COLUMN lims.projects.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.projects.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE lims.sample_containers (
    id SERIAL PRIMARY KEY,
    code INTEGER NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL UNIQUE,
    memo TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE lims.sample_containers IS '시료 용기 정보를 관리하는 테이블';
COMMENT ON COLUMN lims.sample_containers.id IS '용기 고유 ID';
COMMENT ON COLUMN lims.sample_containers.code IS '용기 코드';
COMMENT ON COLUMN lims.sample_containers.name IS '용기 명칭';
COMMENT ON COLUMN lims.sample_containers.memo IS '메모';
COMMENT ON COLUMN lims.sample_containers.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.sample_containers.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE lims.sample_types (
    id SERIAL PRIMARY KEY,
    code INTEGER NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL UNIQUE,
    memo TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE lims.sample_types IS '시료 유형 정보를 관리하는 테이블';
COMMENT ON COLUMN lims.sample_types.id IS '시료 유형 고유 ID';
COMMENT ON COLUMN lims.sample_types.code IS '시료 유형 코드';
COMMENT ON COLUMN lims.sample_types.name IS '시료 유형 명칭';
COMMENT ON COLUMN lims.sample_types.memo IS '메모';
COMMENT ON COLUMN lims.sample_types.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.sample_types.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE lims.sampling_points (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) UNIQUE, -- 최대 10자리 코드 허용
    name VARCHAR(255),
    plant_id INTEGER REFERENCES loc.facilities(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 처리장 삭제 시 채수 지점도 삭제 불가
    memo TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE lims.sampling_points IS '시료 채수 지점 정보를 관리하는 테이블';
COMMENT ON COLUMN lims.sampling_points.id IS '채수 지점 고유 ID';
COMMENT ON COLUMN lims.sampling_points.code IS '채수 지점 코드';
COMMENT ON COLUMN lims.sampling_points.name IS '채수 지점명';
COMMENT ON COLUMN lims.sampling_points.plant_id IS '소속 처리장 ID (FK)';
COMMENT ON COLUMN lims.sampling_points.memo IS '메모';
COMMENT ON COLUMN lims.sampling_points.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.sampling_points.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE lims.weather_conditions (
    id SERIAL PRIMARY KEY,
    code INTEGER NOT NULL UNIQUE,
    status VARCHAR(255) NOT NULL UNIQUE,
    memo TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE lims.weather_conditions IS '날씨 조건 정보를 관리하는 테이블';
COMMENT ON COLUMN lims.weather_conditions.id IS '날씨 조건 고유 ID';
COMMENT ON COLUMN lims.weather_conditions.code IS '날씨 코드';
COMMENT ON COLUMN lims.weather_conditions.status IS '날씨 상태 (예: 맑음, 비)';
COMMENT ON COLUMN lims.weather_conditions.memo IS '메모';
COMMENT ON COLUMN lims.weather_conditions.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.weather_conditions.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE lims.test_requests (
    id SERIAL PRIMARY KEY,
    request_code VARCHAR(20) UNIQUE,
    request_date DATE NOT NULL,
    project_id INTEGER NOT NULL REFERENCES lims.projects(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 프로젝트 삭제 시 시험 의뢰도 삭제 불가
    department_id INTEGER NOT NULL REFERENCES usr.departments(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 부서 삭제 시 시험 의뢰도 삭제 불가
    requester_user_id INTEGER NOT NULL REFERENCES usr.users(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 요청자 삭제 시 시험 의뢰도 삭제 불가
    title TEXT NOT NULL,
    label_printed BOOLEAN DEFAULT FALSE,
    memo TEXT,
    submitted_at TIMESTAMP WITH TIME ZONE,
    sampling_date DATE,
    sampling_time_from TIME WITHOUT TIME ZONE, -- 시간대 정보 없이 시간만 필요할 경우 적절
    sampling_time_to TIME WITHOUT TIME ZONE,    -- 시간대 정보 없이 시간만 필요할 경우 적절
    sampling_weather_id INTEGER REFERENCES lims.weather_conditions(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 날씨 조건 삭제 시 시험 의뢰도 삭제 불가
    sampler VARCHAR(32) DEFAULT NULL, -- 채수자가 명확하지 않은 경우 NULL 허용
    water_temp REAL,
    air_temp REAL,
    requested_parameters JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP -- updated_at 컬럼 추가
);
COMMENT ON TABLE lims.test_requests IS '시료 분석을 위한 시험 의뢰 정보를 관리하는 테이블';
COMMENT ON COLUMN lims.test_requests.id IS '시험 의뢰 고유 ID';
COMMENT ON COLUMN lims.test_requests.request_code IS '시험 의뢰 코드';
COMMENT ON COLUMN lims.test_requests.request_date IS '의뢰 일자';
COMMENT ON COLUMN lims.test_requests.project_id IS '관련 프로젝트 ID (FK)';
COMMENT ON COLUMN lims.test_requests.department_id IS '의뢰 부서 ID (FK)';
COMMENT ON COLUMN lims.test_requests.requester_user_id IS '의뢰 사용자 ID (FK)';
COMMENT ON COLUMN lims.test_requests.title IS '의뢰 제목';
COMMENT ON COLUMN lims.test_requests.label_printed IS '라벨 인쇄 여부';
COMMENT ON COLUMN lims.test_requests.memo IS '메모';
COMMENT ON COLUMN lims.test_requests.submitted_at IS '제출 일시';
COMMENT ON COLUMN lims.test_requests.sampling_date IS '채수일자';
COMMENT ON COLUMN lims.test_requests.sampling_time_from IS '채수시각(시) - 시간대 정보 없음';
COMMENT ON COLUMN lims.test_requests.sampling_time_to IS '채수시각(종) - 시간대 정보 없음';
COMMENT ON COLUMN lims.test_requests.sampling_weather_id IS '날씨';
COMMENT ON COLUMN lims.test_requests.sampler IS '채수자';
COMMENT ON COLUMN lims.test_requests.water_temp IS '수온';
COMMENT ON COLUMN lims.test_requests.air_temp IS '기온';
COMMENT ON COLUMN lims.test_requests.requested_parameters IS '요청된 분석 항목 (JSONB)';
COMMENT ON COLUMN lims.test_requests.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.test_requests.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE lims.samples (
    id SERIAL PRIMARY KEY,
    sample_code VARCHAR(24) UNIQUE,
    request_id INTEGER NOT NULL REFERENCES lims.test_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 시험 의뢰 삭제 시 시료도 삭제 불가
    request_sheet_index INTEGER, -- 시험 의뢰서 내 시료 순번
    sampling_point_id INTEGER NOT NULL REFERENCES lims.sampling_points(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 채수 지점 삭제 시 시료도 삭제 불가
    sampling_date DATE NOT NULL,
    sampling_time TIME WITHOUT TIME ZONE,
    sampling_weather_id INTEGER REFERENCES lims.weather_conditions(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 날씨 조건 삭제 시 시료도 삭제 불가
    sampler VARCHAR(32) DEFAULT NULL,
    sample_temp REAL,
    sample_type_id INTEGER NOT NULL REFERENCES lims.sample_types(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 시료 유형 삭제 시 시료도 삭제 불가
    container_id INTEGER NOT NULL REFERENCES lims.sample_containers(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 시료 용기 삭제 시 시료도 삭제 불가
    parameters_for_analysis JSONB NOT NULL,
    amount INTEGER DEFAULT 1 NOT NULL,
    storage_location_id INTEGER REFERENCES loc.spaces(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 보관 위치 삭제 시 시료도 삭제 불가
    analysis_status VARCHAR(20) DEFAULT 'Pending' CHECK (analysis_status IN ('Pending', 'In Progress', 'Completed', 'Canceled', 'On Hold')), -- 분석 상태 제약 추가
    request_date DATE,
    collected_date DATE,
    analyze_date DATE,
    complete_date DATE,
    disposal_date DATE,
    storage_period INTEGER,
    collector VARCHAR(255) DEFAULT NULL,
    manager VARCHAR(255) DEFAULT NULL,
    memo TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP -- updated_at 컬럼 추가
);
COMMENT ON TABLE lims.samples IS '원 시료 정보를 관리하는 테이블';
COMMENT ON COLUMN lims.samples.id IS '시료 고유 ID';
COMMENT ON COLUMN lims.samples.sample_code IS '시료 코드';
COMMENT ON COLUMN lims.samples.request_id IS '관련 시험 의뢰 ID (FK)';
COMMENT ON COLUMN lims.samples.request_sheet_index IS '시험 의뢰서 내 시료 순번';
COMMENT ON COLUMN lims.samples.sampling_point_id IS '채수 지점 ID (FK)';
COMMENT ON COLUMN lims.samples.sampling_date IS '채수일자';
COMMENT ON COLUMN lims.samples.sampling_time IS '채수시각';
COMMENT ON COLUMN lims.samples.sampling_weather_id IS '채수 시 날씨 조건 ID (FK)';
COMMENT ON COLUMN lims.samples.sampler IS '채수자';
COMMENT ON COLUMN lims.samples.sample_temp IS '시료 온도';
COMMENT ON COLUMN lims.samples.sample_type_id IS '시료 유형 ID (FK)';
COMMENT ON COLUMN lims.samples.container_id IS '시료 용기 ID (FK)';
COMMENT ON COLUMN lims.samples.parameters_for_analysis IS '분석할 항목 (JSONB)';
COMMENT ON COLUMN lims.samples.amount IS '시료 수량';
COMMENT ON COLUMN lims.samples.storage_location_id IS '보관 위치 ID (FK)';
COMMENT ON COLUMN lims.samples.analysis_status IS '분석 상태 (Pending, In Progress, Completed 등)';
COMMENT ON COLUMN lims.samples.request_date IS '의뢰 일자';
COMMENT ON COLUMN lims.samples.collected_date IS '수집 일자';
COMMENT ON COLUMN lims.samples.analyze_date IS '분석 시작 일자';
COMMENT ON COLUMN lims.samples.complete_date IS '분석 완료 일자';
COMMENT ON COLUMN lims.samples.disposal_date IS '폐기 일자';
COMMENT ON COLUMN lims.samples.storage_period IS '보관 기간';
COMMENT ON COLUMN lims.samples.collector IS '수집자';
COMMENT ON COLUMN lims.samples.manager IS '담당자';
COMMENT ON COLUMN lims.samples.memo IS '메모';
COMMENT ON COLUMN lims.samples.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.samples.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE lims.aliquot_samples (
    id SERIAL PRIMARY KEY,
    parent_sample_id INTEGER NOT NULL REFERENCES lims.samples(id) ON UPDATE CASCADE ON DELETE CASCADE, -- 부모 시료 삭제 시 분할 시료도 삭제
    aliquot_code VARCHAR(50) UNIQUE,
    parameter_id INTEGER NOT NULL REFERENCES lims.parameters(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 분석 항목 삭제 시 분할 시료도 삭제 불가
    analysis_status VARCHAR(20) DEFAULT 'Pending' CHECK (analysis_status IN ('Pending', 'In Progress', 'Completed', 'Canceled', 'On Hold')), -- 분석 상태 제약 추가
    analysis_date DATE,
    analyst_user_id INTEGER REFERENCES usr.users(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 분석자 삭제 시 분할 시료는 유지하고 분석자만 NULL로
    result REAL, -- 분할 시료의 최종 분석 결과 (워크시트 데이터와 구분)
    unit VARCHAR(50),
    qc_data JSONB,
    memo TEXT,
    disposal_date DATE,
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Disposed', 'Reserved', 'Contaminated')), -- 분할 시료 상태 제약 추가
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE lims.aliquot_samples IS '원 시료에서 분할된 개별 분석용 시료 (분할 시료) 정보를 관리하는 테이블';
COMMENT ON COLUMN lims.aliquot_samples.id IS '분할 시료 고유 ID';
COMMENT ON COLUMN lims.aliquot_samples.parent_sample_id IS '원 시료 ID (FK)';
COMMENT ON COLUMN lims.aliquot_samples.aliquot_code IS '분할 시료 코드';
COMMENT ON COLUMN lims.aliquot_samples.parameter_id IS '분석 항목 ID (FK)';
COMMENT ON COLUMN lims.aliquot_samples.analysis_status IS '분석 상태 (Pending, In Progress, Completed 등)';
COMMENT ON COLUMN lims.aliquot_samples.analysis_date IS '분석일';
COMMENT ON COLUMN lims.aliquot_samples.analyst_user_id IS '분석자 사용자 ID (FK)';
COMMENT ON COLUMN lims.aliquot_samples.result IS '최종 분석 결과';
COMMENT ON COLUMN lims.aliquot_samples.unit IS '결과 단위';
COMMENT ON COLUMN lims.aliquot_samples.qc_data IS '품질 관리 (QC) 데이터 (JSONB)';
COMMENT ON COLUMN lims.aliquot_samples.memo IS '메모';
COMMENT ON COLUMN lims.aliquot_samples.disposal_date IS '폐기일';
COMMENT ON COLUMN lims.aliquot_samples.status IS '분할 시료 상태 (Active, Disposed 등)';
COMMENT ON COLUMN lims.aliquot_samples.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.aliquot_samples.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE lims.worksheets (
    id SERIAL PRIMARY KEY,
    code VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    memo TEXT,
    sort_order INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE lims.worksheets IS '분석 워크시트 템플릿 정보를 관리하는 테이블';
COMMENT ON COLUMN lims.worksheets.id IS '워크시트 고유 ID';
COMMENT ON COLUMN lims.worksheets.code IS '워크시트 코드';
COMMENT ON COLUMN lims.worksheets.name IS '워크시트명';
COMMENT ON COLUMN lims.worksheets.memo IS '메모';
COMMENT ON COLUMN lims.worksheets.sort_order IS '정렬 순서';
COMMENT ON COLUMN lims.worksheets.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.worksheets.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE lims.worksheet_items (
    id SERIAL PRIMARY KEY,
    worksheet_id INTEGER NOT NULL REFERENCES lims.worksheets(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 워크시트 삭제 시 항목도 삭제 불가
    code VARCHAR(255) NOT NULL,
    priority_order INTEGER NOT NULL,
    xls_cell_address VARCHAR(24),
    name VARCHAR(255) NOT NULL,
    label VARCHAR(255) NOT NULL,
    type INTEGER NOT NULL,
    format VARCHAR(255),
    unit VARCHAR(8),
    memo TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE lims.worksheet_items IS '워크시트 내의 개별 항목 (데이터 입력 필드) 정보를 관리하는 테이블';
COMMENT ON COLUMN lims.worksheet_items.id IS '워크시트 항목 고유 ID';
COMMENT ON COLUMN lims.worksheet_items.worksheet_id IS '관련 워크시트 ID (FK)';
COMMENT ON COLUMN lims.worksheet_items.code IS '항목 코드';
COMMENT ON COLUMN lims.worksheet_items.priority_order IS '우선 순서/정렬 순서';
COMMENT ON COLUMN lims.worksheet_items.xls_cell_address IS '엑셀 셀 주소';
COMMENT ON COLUMN lims.worksheet_items.name IS '항목명';
COMMENT ON COLUMN lims.worksheet_items.label IS '항목 라벨';
COMMENT ON COLUMN lims.worksheet_items.type IS '데이터 타입 (숫자, 문자열 등)';
COMMENT ON COLUMN lims.worksheet_items.format IS '데이터 형식';
COMMENT ON COLUMN lims.worksheet_items.unit IS '단위';
COMMENT ON COLUMN lims.worksheet_items.memo IS '메모';
COMMENT ON COLUMN lims.worksheet_items.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.worksheet_items.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE lims.worksheet_data (
    id SERIAL PRIMARY KEY,
    worksheet_id INTEGER NOT NULL REFERENCES lims.worksheets(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 워크시트 삭제 시 데이터도 삭제 불가
    data_date DATE NOT NULL,
    analyst_user_id INTEGER REFERENCES usr.users(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 분석자 삭제 시 워크시트 데이터는 유지하고 분석자만 NULL로
    verified_by_user_id INTEGER REFERENCES usr.users(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 검증자 삭제 시 워크시트 데이터는 유지하고 검증자만 NULL로
    verified_at TIMESTAMP WITHOUT TIME ZONE,
    is_verified BOOLEAN DEFAULT FALSE,
    notes TEXT,
    raw_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE lims.worksheet_data IS '실제 워크시트 입력 데이터를 저장하는 테이블';
COMMENT ON COLUMN lims.worksheet_data.id IS '워크시트 데이터 고유 ID';
COMMENT ON COLUMN lims.worksheet_data.worksheet_id IS '관련 워크시트 ID (FK)';
COMMENT ON COLUMN lims.worksheet_data.data_date IS '데이터 입력/분석 일자';
COMMENT ON COLUMN lims.worksheet_data.analyst_user_id IS '분석자 사용자 ID (FK)';
COMMENT ON COLUMN lims.worksheet_data.verified_by_user_id IS '검증자 사용자 ID (FK)';
COMMENT ON COLUMN lims.worksheet_data.verified_at IS '검증 일시';
COMMENT ON COLUMN lims.worksheet_data.is_verified IS '검증 완료 여부';
COMMENT ON COLUMN lims.worksheet_data.notes IS '비고';
COMMENT ON COLUMN lims.worksheet_data.raw_data IS '원시 데이터 (JSONB, 워크시트 항목에 매핑)';
COMMENT ON COLUMN lims.worksheet_data.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.worksheet_data.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE lims.analysis_results (
    id SERIAL PRIMARY KEY,
    aliquot_sample_id INTEGER NOT NULL REFERENCES lims.aliquot_samples(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 분할 시료 삭제 시 분석 결과도 삭제 불가
    parameter_id INTEGER NOT NULL REFERENCES lims.parameters(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 분석 항목 삭제 시 분석 결과도 삭제 불가
    worksheet_id INTEGER NOT NULL REFERENCES lims.worksheets(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 워크시트 삭제 시 분석 결과도 삭제 불가
    worksheet_data_id INTEGER NOT NULL REFERENCES lims.worksheet_data(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 워크시트 데이터 삭제 시 분석 결과도 삭제 불가
    result_value REAL,
    unit VARCHAR(50),
    analysis_date DATE,
    analyst_user_id INTEGER REFERENCES usr.users(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 분석자 삭제 시 분석 결과는 유지하고 분석자만 NULL로
    approved_by_user_id INTEGER REFERENCES usr.users(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 승인자 삭제 시 분석 결과는 유지하고 승인자만 NULL로
    approved_at TIMESTAMP WITHOUT TIME ZONE,
    is_approved BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(aliquot_sample_id, parameter_id, worksheet_data_id) -- 동일 분할 시료/항목/워크시트 데이터에 대해 중복 결과 방지
);
COMMENT ON TABLE lims.analysis_results IS '분할 시료의 최종 분석 결과를 관리하는 테이블';
COMMENT ON COLUMN lims.analysis_results.id IS '분석 결과 고유 ID';
COMMENT ON COLUMN lims.analysis_results.aliquot_sample_id IS '관련 분할 시료 ID (FK)';
COMMENT ON COLUMN lims.analysis_results.parameter_id IS '관련 분석 항목 ID (FK)';
COMMENT ON COLUMN lims.analysis_results.worksheet_id IS '관련 워크시트 ID (FK)';
COMMENT ON COLUMN lims.analysis_results.worksheet_data_id IS '관련 워크시트 데이터 ID (FK)';
COMMENT ON COLUMN lims.analysis_results.result_value IS '분석 결과 값';
COMMENT ON COLUMN lims.analysis_results.unit IS '결과 단위';
COMMENT ON COLUMN lims.analysis_results.analysis_date IS '분석일';
COMMENT ON COLUMN lims.analysis_results.analyst_user_id IS '분석자 사용자 ID (FK)';
COMMENT ON COLUMN lims.analysis_results.approved_by_user_id IS '승인자 사용자 ID (FK)';
COMMENT ON COLUMN lims.analysis_results.approved_at IS '승인 일시';
COMMENT ON COLUMN lims.analysis_results.is_approved IS '승인 여부';
COMMENT ON COLUMN lims.analysis_results.notes IS '비고';
COMMENT ON COLUMN lims.analysis_results.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.analysis_results.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE lims.test_request_templates (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    user_id INTEGER NOT NULL REFERENCES usr.users(id) ON UPDATE CASCADE ON DELETE CASCADE, -- 사용자 삭제 시 템플릿도 삭제
    serialized_text JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE lims.test_request_templates IS '시험 의뢰 템플릿을 관리하는 테이블';
COMMENT ON COLUMN lims.test_request_templates.id IS '템플릿 고유 ID';
COMMENT ON COLUMN lims.test_request_templates.name IS '템플릿명';
COMMENT ON COLUMN lims.test_request_templates.user_id IS '생성 사용자 ID (FK)';
COMMENT ON COLUMN lims.test_request_templates.serialized_text IS '템플릿 내용 (JSONB)';
COMMENT ON COLUMN lims.test_request_templates.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.test_request_templates.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE lims.pr_views (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    user_id INTEGER NOT NULL REFERENCES usr.users(id) ON UPDATE CASCADE ON DELETE CASCADE, -- 사용자 삭제 시 사용자 정의 보기 삭제
    plant_id INTEGER NOT NULL REFERENCES loc.facilities(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 처리장 삭제 시 보기 삭제 불가
    sampling_point_ids JSONB, -- JSONB 배열 형식 권장 (예: [1, 2, 3])
    parameter_ids JSONB,       -- JSONB 배열 형식 권장 (예: [10, 20, 30])
    memo TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE lims.pr_views IS '사용자 정의 프로젝트/결과 보기 설정을 관리하는 테이블';
COMMENT ON COLUMN lims.pr_views.id IS '보기 설정 고유 ID';
COMMENT ON COLUMN lims.pr_views.name IS '보기 설정명';
COMMENT ON COLUMN lims.pr_views.user_id IS '생성 사용자 ID (FK)';
COMMENT ON COLUMN lims.pr_views.plant_id IS '관련 처리장 ID (FK)';
COMMENT ON COLUMN lims.pr_views.sampling_point_ids IS '선택된 채수 지점 ID 목록 (JSONB)';
COMMENT ON COLUMN lims.pr_views.parameter_ids IS '선택된 분석 항목 ID 목록 (JSONB)';
COMMENT ON COLUMN lims.pr_views.memo IS '메모';
COMMENT ON COLUMN lims.pr_views.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.pr_views.updated_at IS '레코드 마지막 업데이트 일시';

-- QA/QC 테이블들을 lims 스키마로 이동
CREATE TABLE lims.standard_samples ( -- 표준 시료/표준액 (구 qaqc.standard_samples)
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    parameter_id INTEGER NOT NULL REFERENCES lims.parameters(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 관련 분석 항목 삭제 시 표준 시료도 삭제 불가
    concentration REAL, -- 농도
    preparation_date DATE, -- 제조일
    expiration_date DATE, -- 유효 기간
    lot_number VARCHAR(100), -- 로트 번호
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE lims.standard_samples IS '표준 시료 또는 표준액 정보를 관리하는 테이블 (QA/QC용)';
COMMENT ON COLUMN lims.standard_samples.id IS '표준 시료 고유 ID';
COMMENT ON COLUMN lims.standard_samples.code IS '표준 시료 코드';
COMMENT ON COLUMN lims.standard_samples.name IS '표준 시료명';
COMMENT ON COLUMN lims.standard_samples.parameter_id IS '관련 분석 항목 ID (FK)';
COMMENT ON COLUMN lims.standard_samples.concentration IS '농도';
COMMENT ON COLUMN lims.standard_samples.preparation_date IS '제조일';
COMMENT ON COLUMN lims.standard_samples.expiration_date IS '유효 기간';
COMMENT ON COLUMN lims.standard_samples.lot_number IS '로트 번호';
COMMENT ON COLUMN lims.standard_samples.notes IS '비고';
COMMENT ON COLUMN lims.standard_samples.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.standard_samples.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE lims.calibration_records ( -- 교정 기록 (구 qaqc.calibration_records)
    id SERIAL PRIMARY KEY,
    equipment_id INTEGER NOT NULL REFERENCES fms.equipments(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 교정된 장비 삭제 시 교정 기록도 삭제 불가
    parameter_id INTEGER NOT NULL REFERENCES lims.parameters(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 교정된 분석 항목 삭제 시 교정 기록도 삭제 불가
    calibration_date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    next_calibration_date DATE,
    calibrated_by_user_id INTEGER REFERENCES usr.users(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 교정 수행자 삭제 시 기록은 유지하고 사용자만 NULL로
    standard_sample_id INTEGER REFERENCES lims.standard_samples(id) ON UPDATE CASCADE ON DELETE SET NULL, -- 사용된 표준 시료 삭제 시 기록은 유지하고 시료만 NULL로
    calibration_curve_data JSONB, -- 교정 곡선 데이터 (점, R-제곱 값 등)
    acceptance_criteria_met BOOLEAN, -- 허용 기준 충족 여부
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE lims.calibration_records IS '장비 및 분석 항목의 교정 기록을 관리하는 테이블';
COMMENT ON COLUMN lims.calibration_records.id IS '교정 기록 고유 ID';
COMMENT ON COLUMN lims.calibration_records.equipment_id IS '교정된 장비 ID (FK)';
COMMENT ON COLUMN lims.calibration_records.parameter_id IS '교정된 분석 항목 ID (FK)';
COMMENT ON COLUMN lims.calibration_records.calibration_date IS '교정 일시';
COMMENT ON COLUMN lims.calibration_records.next_calibration_date IS '다음 교정 예정일';
COMMENT ON COLUMN lims.calibration_records.calibrated_by_user_id IS '교정 수행자 사용자 ID (FK)';
COMMENT ON COLUMN lims.calibration_records.standard_sample_id IS '사용된 표준 시료 ID (FK)';
COMMENT ON COLUMN lims.calibration_records.calibration_curve_data IS '교정 곡선 데이터 (JSONB)';
COMMENT ON COLUMN lims.calibration_records.acceptance_criteria_met IS '허용 기준 충족 여부';
COMMENT ON COLUMN lims.calibration_records.notes IS '비고';
COMMENT ON COLUMN lims.calibration_records.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.calibration_records.updated_at IS '레코드 마지막 업데이트 일시';

CREATE TABLE lims.qc_sample_results ( -- QC 시료 결과 (구 qaqc.qc_sample_results)
    id SERIAL PRIMARY KEY,
    aliquot_sample_id INTEGER REFERENCES lims.aliquot_samples(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 관련 분할 시료 삭제 시 QC 결과도 삭제 불가 (NULL 허용은 블랭크/컨트롤 시료의 경우)
    parameter_id INTEGER NOT NULL REFERENCES lims.parameters(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 분석 항목 삭제 시 QC 결과도 삭제 불가
    qc_type VARCHAR(50) NOT NULL CHECK (qc_type IN ('Blank', 'Control', 'Spike', 'Duplicate', 'Matrix Spike', 'LCS', 'CRM')), -- QC 유형 제약 추가
    expected_value REAL, -- 예상 값
    measured_value REAL, -- 측정 값
    recovery REAL, -- 회수율 (측정값 / 예상값 * 100)
    rpd REAL, -- 상대 백분율 차이 (중복 시료용)
    acceptance_criteria JSONB, -- 허용 기준 (범위 등)
    passed_qc BOOLEAN, -- QC 통과 여부
    analysis_date DATE NOT NULL,
    analyst_user_id INTEGER REFERENCES usr.users(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 분석자 삭제 시 QC 결과도 삭제 불가
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE lims.qc_sample_results IS '품질 관리(QC) 시료 분석 결과를 관리하는 테이블';
COMMENT ON COLUMN lims.qc_sample_results.id IS 'QC 결과 고유 ID';
COMMENT ON COLUMN lims.qc_sample_results.aliquot_sample_id IS '관련 분할 시료 ID (FK)';
COMMENT ON COLUMN lims.qc_sample_results.parameter_id IS '관련 분석 항목 ID (FK)';
COMMENT ON COLUMN lims.qc_sample_results.qc_type IS 'QC 유형 (Blank, Control, Spike 등)';
COMMENT ON COLUMN lims.qc_sample_results.expected_value IS '예상 값';
COMMENT ON COLUMN lims.qc_sample_results.measured_value IS '측정 값';
COMMENT ON COLUMN lims.qc_sample_results.recovery IS '회수율';
COMMENT ON COLUMN lims.qc_sample_results.rpd IS '상대 백분율 차이';
COMMENT ON COLUMN lims.qc_sample_results.acceptance_criteria IS '허용 기준 (JSONB)';
COMMENT ON COLUMN lims.qc_sample_results.passed_qc IS 'QC 통과 여부';
COMMENT ON COLUMN lims.qc_sample_results.analysis_date IS '분석일';
COMMENT ON COLUMN lims.qc_sample_results.analyst_user_id IS '분석자 사용자 ID (FK)';
COMMENT ON COLUMN lims.qc_sample_results.notes IS '비고';
COMMENT ON COLUMN lims.qc_sample_results.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN lims.qc_sample_results.updated_at IS '레코드 마지막 업데이트 일시';

--
-- ops 스키마 테이블 (운영 데이터 관리)
--
CREATE TABLE ops.lines ( -- 처리 계열 정보
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    capacity INTEGER DEFAULT 0 NOT NULL, -- 계열 처리 용량
    plant_id INTEGER NOT NULL REFERENCES loc.facilities(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 관련 처리장 삭제 시 계열도 삭제 불가
    memo TEXT,
    sort_order INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE ops.lines IS '처리 계열 (Line) 정보를 관리하는 테이블';
COMMENT ON COLUMN ops.lines.id IS '계열 고유 ID';
COMMENT ON COLUMN ops.lines.code IS '계열 코드';
COMMENT ON COLUMN ops.lines.name IS '계열명';
COMMENT ON COLUMN ops.lines.capacity IS '계열 처리 용량';
COMMENT ON COLUMN ops.lines.plant_id IS '소속 처리시설 ID (FK)';
COMMENT ON COLUMN ops.lines.memo IS '메모';
COMMENT ON COLUMN ops.lines.sort_order IS '정렬 순서';
COMMENT ON COLUMN ops.lines.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN ops.lines.updated_at IS '레코드 마지막 업데이트 일시';

-- ops.daily_plant_operations 테이블 (파티셔닝 제거)
CREATE TABLE ops.daily_plant_operations (
    id BIGSERIAL PRIMARY KEY, -- 단일 PK로 변경
    global_id UUID NOT NULL DEFAULT public.gen_random_uuid() UNIQUE, -- 테이블 전체에서 유니크한 식별자 (FK 참조용), UNIQUE 추가
    plant_id INTEGER NOT NULL,
    op_date DATE NOT NULL,
    influent INTEGER DEFAULT 0 NOT NULL, -- 총 유입량
    effluent INTEGER DEFAULT 0 NOT NULL, -- 총 방류량
    offload INTEGER DEFAULT 0 NOT NULL, -- 부하분산-연계량
    rainfall INTEGER DEFAULT 0 NOT NULL, -- 강우량
    influent_ph REAL DEFAULT 0.0 NOT NULL, -- 유입 하수 수소이온 농도
    effluent_ph REAL DEFAULT 0.0 NOT NULL, -- 처리수 수소이온 농도
    memo TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (plant_id, op_date) -- plant_id와 op_date 조합은 여전히 유니크
);
COMMENT ON TABLE ops.daily_plant_operations IS '일일 처리장 운영 현황을 관리하는 테이블';
COMMENT ON COLUMN ops.daily_plant_operations.id IS '레코드 고유 ID';
COMMENT ON COLUMN ops.daily_plant_operations.global_id IS '테이블 전체에서 고유한 UUID 식별자 (FK 참조용)';
COMMENT ON COLUMN ops.daily_plant_operations.plant_id IS '처리시설 ID (FK)';
COMMENT ON COLUMN ops.daily_plant_operations.op_date IS '운영 일자';
COMMENT ON COLUMN ops.daily_plant_operations.influent IS '총 유입량';
COMMENT ON COLUMN ops.daily_plant_operations.effluent IS '총 방류량';
COMMENT ON COLUMN ops.daily_plant_operations.offload IS '부하 분산-연계량';
COMMENT ON COLUMN ops.daily_plant_operations.rainfall IS '강우량';
COMMENT ON COLUMN ops.daily_plant_operations.influent_ph IS '유입 하수 수소 이온 농도 (pH)';
COMMENT ON COLUMN ops.daily_plant_operations.effluent_ph IS '처리수 수소 이온 농도 (pH)';
COMMENT ON COLUMN ops.daily_plant_operations.memo IS '메모';
COMMENT ON COLUMN ops.daily_plant_operations.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN ops.daily_plant_operations.updated_at IS '레코드 마지막 업데이트 일시';

-- ops.daily_line_operations 테이블 (파티셔닝 제거)
CREATE TABLE ops.daily_line_operations (
    id BIGSERIAL PRIMARY KEY, -- 단일 PK로 변경
    global_id UUID NOT NULL DEFAULT public.gen_random_uuid() UNIQUE, -- 테이블 전체에서 유니크한 식별자 (FK 참조용), UNIQUE 추가
    daily_plant_op_id UUID NOT NULL REFERENCES ops.daily_plant_operations(global_id) ON UPDATE CASCADE ON DELETE RESTRICT, -- ops.daily_plant_operations.global_id 참조
    line_id INTEGER NOT NULL REFERENCES ops.lines(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 관련 계열 삭제 시 계열 운영 현황도 삭제 불가
    op_date DATE NOT NULL, -- 운영 일자 (daily_plant_op_id의 날짜와 일치해야 함)
    influent INTEGER DEFAULT 0 NOT NULL, -- 계열별 유입량
    reject_water INTEGER DEFAULT 0 NOT NULL, -- 반류량
    sv30 REAL, -- 30분 후 슬러지 침강률
    mlss INTEGER, -- 폭기조 내 현탁물질 농도
    svi INTEGER, -- 슬러지 용량 지수
    fm_rate REAL, -- 유기물 대 미생물 비
    return_mlss INTEGER, -- 반송 MLSS
    excess_sludge INTEGER, -- 잉여 슬러지
    srt REAL, -- 고형물 체류 시간
    return_sludge INTEGER, -- 반송량
    ml_do REAL, -- 반응조 내 용존 산소
    water_temp REAL, -- 수온
    hrt INTEGER, -- 수리학적 체류 시간
    moisture REAL, -- 함수율
    memo TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (line_id, op_date) -- line_id와 op_date 조합은 여전히 유니크
);
COMMENT ON TABLE ops.daily_line_operations IS '일일 계열별 운영 현황을 관리하는 테이블';
COMMENT ON COLUMN ops.daily_line_operations.id IS '레코드 고유 ID';
COMMENT ON COLUMN ops.daily_line_operations.global_id IS '테이블 전체에서 고유한 UUID 식별자 (FK 참조용)';
COMMENT ON COLUMN ops.daily_line_operations.daily_plant_op_id IS '관련 일일 처리장 운영 레코드 ID (FK)';
COMMENT ON COLUMN ops.daily_line_operations.line_id IS '계열 ID (FK)';
COMMENT ON COLUMN ops.daily_line_operations.op_date IS '운영 일자';
COMMENT ON COLUMN ops.daily_line_operations.influent IS '계열별 유입량';
COMMENT ON COLUMN ops.daily_line_operations.reject_water IS '반류량';
COMMENT ON COLUMN ops.daily_line_operations.sv30 IS '30분 후 슬러지 침강률';
COMMENT ON COLUMN ops.daily_line_operations.mlss IS '폭기조 내의 현탁물질 농도';
COMMENT ON COLUMN ops.daily_line_operations.svi IS '슬러지 용량 지수';
COMMENT ON COLUMN ops.daily_line_operations.fm_rate IS '유기물 대 미생물 비';
COMMENT ON COLUMN ops.daily_line_operations.return_mlss IS '반송 MLSS';
COMMENT ON COLUMN ops.daily_line_operations.excess_sludge IS '잉여 슬러지';
COMMENT ON COLUMN ops.daily_line_operations.srt IS '고형물 체류 시간';
COMMENT ON COLUMN ops.daily_line_operations.return_sludge IS '반송량';
COMMENT ON COLUMN ops.daily_line_operations.ml_do IS '반응조 내 용존 산소';
COMMENT ON COLUMN ops.daily_line_operations.water_temp IS '수온';
COMMENT ON COLUMN ops.daily_line_operations.hrt IS '수리학적 체류 시간';
COMMENT ON COLUMN ops.daily_line_operations.moisture IS '함수율';
COMMENT ON COLUMN ops.daily_line_operations.memo IS '메모';
COMMENT ON COLUMN ops.daily_line_operations.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN ops.daily_line_operations.updated_at IS '레코드 마지막 업데이트 일시';


CREATE TABLE ops.views ( -- 운영 데이터 보기 (사용자별 커스터마이징)
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    user_id INTEGER NOT NULL REFERENCES usr.users(id) ON UPDATE CASCADE ON DELETE RESTRICT, -- 사용자 삭제 시 보기 삭제 불가
    plant_ids JSONB, -- JSONB 배열 형식 권장 (예: [1, 2, 3])
    line_ids JSONB, -- JSONB 배열 형식 권장 (예: [1, 2])
    sampling_point_ids JSONB, -- JSONB 배열 형식 권장 (예: [101, 102])
    memo TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE ops.views IS '운영 데이터 보기 (사용자별 커스터마이징) 테이블';
COMMENT ON COLUMN ops.views.id IS '레코드 고유 ID';
COMMENT ON COLUMN ops.views.name IS '운영 데이터 보기 이름';
COMMENT ON COLUMN ops.views.user_id IS '운영 데이터 보기 사용자 id';
COMMENT ON COLUMN ops.views.plant_ids IS '운영 데이터 보기 처리시설 목록';
COMMENT ON COLUMN ops.views.line_ids IS '운영 데이터 보기 라인 목록';
COMMENT ON COLUMN ops.views.sampling_point_ids IS '운영 데이터 보기 샘플위치 목록';
COMMENT ON COLUMN ops.views.memo IS '메모';
COMMENT ON COLUMN ops.views.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN ops.views.updated_at IS '레코드 마지막 업데이트 일시';



--
-- 인덱스 (조회 성능 최적화)
--
-- usr 스키마
CREATE INDEX idx_usr_departments_name ON usr.departments USING btree (name);
CREATE INDEX idx_usr_departments_facility_list_gin ON usr.departments USING GIN (facility_ids);
CREATE INDEX idx_usr_users_department_id ON usr.users USING btree (department_id);
CREATE INDEX idx_usr_users_name ON usr.users USING btree (name);

-- loc 스키마
CREATE INDEX idx_loc_facility_name ON loc.facilities USING btree (name);
CREATE INDEX idx_loc_location_types_name ON loc.space_types USING btree (name);
CREATE INDEX idx_loc_locations_plant_id ON loc.spaces USING btree (plant_id);
CREATE INDEX idx_loc_locations_space_type_id ON loc.spaces USING btree (space_type_id);
CREATE INDEX idx_loc_locations_parent_id ON loc.spaces USING btree (parent_id);

-- ven 스키마
CREATE INDEX idx_ven_suppliers_name ON ven.suppliers USING btree (name);
CREATE INDEX idx_ven_supplier_categories_name ON ven.supplier_categories USING btree (name);
CREATE INDEX idx_ven_supplier_contacts_supplier_id ON ven.supplier_contacts USING btree (supplier_id);

-- fms 스키마
CREATE INDEX idx_fms_equipment_categories_name ON fms.equipment_categories USING btree (name);
CREATE INDEX idx_fms_equipments_plant_id ON fms.equipments USING btree (plant_id);
CREATE INDEX idx_fms_equipments_category_id ON fms.equipments USING btree (equipment_category_id);
CREATE INDEX idx_fms_equipments_location_id ON fms.equipments USING btree (current_location_id);
CREATE INDEX idx_fms_equipments_name ON fms.equipments USING btree (name);
CREATE INDEX idx_fms_equipment_specs_equipment_id ON fms.equipment_specs USING btree (equipment_id);
CREATE INDEX idx_fms_equipment_specs_specs_gin ON fms.equipment_specs USING GIN (specs); -- JSONB GIN 인덱스 추가
CREATE INDEX idx_fms_equipment_history_equipment_id ON fms.equipment_history USING btree (equipment_id);
CREATE INDEX idx_fms_equipment_history_change_date ON fms.equipment_history USING btree (change_date);

-- inv 스키마
CREATE INDEX idx_inv_material_categories_name ON inv.material_categories USING btree (name);
CREATE INDEX idx_inv_materials_category_id ON inv.materials USING btree (material_category_id);
CREATE INDEX idx_inv_materials_name ON inv.materials USING btree (name);
CREATE INDEX idx_inv_materials_msds_data_gin ON inv.materials USING GIN (msds_data); -- JSONB GIN 인덱스 추가


CREATE INDEX idx_inv_material_specs_material_id ON inv.materials_specs USING btree (materials_id);
CREATE INDEX idx_inv_material_specs_specs_gin ON inv.materials_specs USING GIN (specs); -- JSONB GIN 인덱스 추가

CREATE INDEX idx_inv_material_batches_material_id ON inv.material_batches USING btree (material_id);
CREATE INDEX idx_inv_material_batches_plant_id ON inv.material_batches USING btree (plant_id);
CREATE INDEX idx_inv_material_batches_location_id ON inv.material_batches USING btree (storage_location_id);
CREATE INDEX idx_inv_material_batches_received_date ON inv.material_batches USING btree (received_date);
CREATE INDEX idx_inv_material_transactions_material_id ON inv.material_transactions USING btree (material_id);
CREATE INDEX idx_inv_material_transactions_plant_id ON inv.material_transactions USING btree (plant_id);
CREATE INDEX idx_inv_material_transactions_type ON inv.material_transactions USING btree (transaction_type);
CREATE INDEX idx_inv_material_transactions_date ON inv.material_transactions USING btree (transaction_date);
CREATE INDEX idx_inv_material_transactions_equipment_id ON inv.material_transactions USING btree (related_equipment_id);
CREATE INDEX idx_inv_material_transactions_history_id ON inv.material_transactions USING btree (related_equipment_history_id);

-- app 스키마
CREATE INDEX idx_app_entity_images_entity_type_id ON app.entity_images USING btree (entity_type, entity_id); -- 복합 인덱스 추가

-- lims 스키마 (QAQC 인덱스 포함)
CREATE INDEX idx_lims_parameters_instrument_id ON lims.parameters USING btree (instrument_id);
CREATE INDEX idx_lims_projects_code ON lims.projects USING btree (code);
CREATE INDEX idx_lims_sample_containers_name ON lims.sample_containers USING btree (name);
CREATE INDEX idx_lims_sample_types_name ON lims.sample_types USING btree (name);
CREATE INDEX idx_lims_sampling_points_plant_id ON lims.sampling_points USING btree (plant_id);
CREATE INDEX idx_lims_test_requests_project_id ON lims.test_requests USING btree (project_id);
CREATE INDEX idx_lims_test_requests_department_id ON lims.test_requests USING btree (department_id);
CREATE INDEX idx_lims_test_requests_requester_user_id ON lims.test_requests USING btree (requester_user_id);
CREATE INDEX idx_lims_test_requests_requested_params_gin ON lims.test_requests USING GIN (requested_parameters); -- JSONB GIN 인덱스 추가
CREATE INDEX idx_lims_samples_request_id ON lims.samples USING btree (request_id);
CREATE INDEX idx_lims_samples_sampling_point_id ON lims.samples USING btree (sampling_point_id);
CREATE INDEX idx_lims_samples_analysis_status ON lims.samples USING btree (analysis_status);
CREATE INDEX idx_lims_samples_container_id ON lims.samples USING btree (container_id); -- 추가
CREATE INDEX idx_lims_samples_sample_type_id ON lims.samples USING btree (sample_type_id); -- 추가
CREATE INDEX idx_lims_samples_storage_location_id ON lims.samples USING btree (storage_location_id); -- 추가
CREATE INDEX idx_lims_samples_sampling_weather_id ON lims.samples USING btree (sampling_weather_id); -- 추가
CREATE INDEX idx_lims_samples_parameters_for_analysis_gin ON lims.samples USING GIN (parameters_for_analysis); -- JSONB GIN 인덱스 추가

CREATE INDEX idx_lims_aliquot_samples_parent_sample_id ON lims.aliquot_samples USING btree (parent_sample_id);
CREATE INDEX idx_lims_aliquot_samples_parameter_id ON lims.aliquot_samples USING btree (parameter_id);
CREATE INDEX idx_lims_aliquot_samples_analysis_status ON lims.aliquot_samples USING btree (analysis_status);
CREATE INDEX idx_lims_worksheets_code ON lims.worksheets USING btree (code);
CREATE INDEX idx_lims_worksheet_data_date ON lims.worksheet_data USING btree (data_date);
CREATE INDEX idx_lims_worksheet_data_raw_data_gin ON lims.worksheet_data USING GIN (raw_data); -- JSONB GIN 인덱스 추가
CREATE INDEX idx_lims_analysis_results_aliquot_sample_id ON lims.analysis_results USING btree (aliquot_sample_id);
CREATE INDEX idx_lims_analysis_results_parameter_id ON lims.analysis_results USING btree (parameter_id);
CREATE INDEX idx_lims_test_request_templates_user_id ON lims.test_request_templates USING btree (user_id);
CREATE INDEX idx_lims_test_request_templates_text_gin ON lims.test_request_templates USING GIN (serialized_text); -- JSONB GIN 인덱스 추가
CREATE INDEX idx_lims_pr_views_user_id ON lims.pr_views USING btree (user_id);
CREATE INDEX idx_lims_pr_views_plant_id ON lims.pr_views USING btree (plant_id);
CREATE INDEX idx_lims_pr_views_smp_point_ids_gin ON lims.pr_views USING GIN (sampling_point_ids); -- JSONB GIN 인덱스 추가
CREATE INDEX idx_lims_pr_views_param_ids_gin ON lims.pr_views USING GIN (parameter_ids); -- JSONB GIN 인덱스 추가

-- lims 스키마로 통합된 QAQC 관련 인덱스
CREATE INDEX idx_lims_standard_samples_parameter_id ON lims.standard_samples USING btree (parameter_id);
CREATE INDEX idx_lims_calibration_records_equipment_id ON lims.calibration_records USING btree (equipment_id);
CREATE INDEX idx_lims_calibration_records_parameter_id ON lims.calibration_records USING btree (parameter_id);
CREATE INDEX idx_lims_calibration_records_curve_data_gin ON lims.calibration_records USING GIN (calibration_curve_data); -- JSONB GIN 인덱스 추가
CREATE INDEX idx_lims_qc_sample_results_aliquot_sample_id ON lims.qc_sample_results USING btree (aliquot_sample_id);
CREATE INDEX idx_lims_qc_sample_results_parameter_id ON lims.qc_sample_results USING btree (parameter_id);
CREATE INDEX idx_lims_qc_sample_results_qc_type ON lims.qc_sample_results USING btree (qc_type);
CREATE INDEX idx_lims_qc_sample_results_acceptance_criteria_gin ON lims.qc_sample_results USING GIN (acceptance_criteria); -- JSONB GIN 인덱스 추가


-- ops 스키마
CREATE INDEX idx_ops_lines_plant_id ON ops.lines USING btree (plant_id);
CREATE INDEX idx_ops_daily_plant_operations_plant_id ON ops.daily_plant_operations USING btree (plant_id); -- 파티션 키가 아닌 다른 필드에 대한 인덱스 추가
CREATE INDEX idx_ops_daily_line_operations_line_id ON ops.daily_line_operations USING btree (line_id);
CREATE INDEX idx_ops_daily_line_operations_daily_plant_op_id ON ops.daily_line_operations USING btree (daily_plant_op_id);
CREATE INDEX idx_ops_views_user_id ON ops.views USING btree (user_id);
CREATE INDEX idx_ops_views_plant_ids_gin ON ops.views USING GIN (plant_ids); -- JSONB GIN 인덱스 추가
CREATE INDEX idx_ops_views_line_ids_gin ON ops.views USING GIN (line_ids); -- JSONB GIN 인덱스 추가
CREATE INDEX idx_ops_views_smp_point_ids_gin ON ops.views USING GIN (sampling_point_ids); -- JSONB GIN 인덱스 추가


--
-- 트리거 (자동 updated_at 및 시료 상태 관리, 코드 생성)
--
-- 자동 updated_at 타임스탬프 업데이트 트리거 적용
DO $$
DECLARE
    _table_name TEXT;
    _schema_name TEXT;
    _table_only_name TEXT;
    _trigger_sql TEXT;
    tables_to_trigger TEXT[] := ARRAY[
        'usr.departments',
        'usr.users',
        'loc.facilities',
        'loc.space_types',
        'loc.spaces',
        'ven.supplier_categories',
        'ven.suppliers',
        'ven.supplier_contacts',
        'fms.equipment_categories',
        'fms.equipments',
        'fms.equipment_specs',
        'fms.equipment_history',
        'inv.material_categories',
        'inv.materials',
        'inv.material_specs',
        'inv.material_batches',
        'inv.material_transactions',
        'app.versions',
        'app.image_types',
        'app.images',
        'app.entity_images',
        'lims.parameters',
        'lims.projects',
        'lims.sample_containers',
        'lims.sample_types',
        'lims.sampling_points',
        'lims.weather_conditions',
        'lims.test_requests',
        'lims.samples',
        'lims.aliquot_samples',
        'lims.worksheets',
        'lims.worksheet_items',
        'lims.worksheet_data',
        'lims.analysis_results',
        'lims.test_request_templates',
        'lims.pr_views',
        'lims.standard_samples',
        'lims.calibration_records',
        'lims.qc_sample_results',
        'ops.lines',
        'ops.daily_plant_operations',
        'ops.daily_line_operations',
        'ops.views'
    ];
BEGIN
    FOREACH _table_name IN ARRAY tables_to_trigger LOOP
        SELECT
            SPLIT_PART(_table_name, '.', 1),
            SPLIT_PART(_table_name, '.', 2)
        INTO _schema_name, _table_only_name;

        IF EXISTS (
            SELECT 1
            FROM pg_class c
            JOIN pg_namespace ns ON ns.oid = c.relnamespace
            WHERE ns.nspname = _schema_name
            AND c.relname = _table_only_name
            AND c.relkind IN ('r', 'p') -- 'r' for regular table, 'p' for partitioned table (PostgreSQL 10+)
            AND EXISTS (
                SELECT 1
                FROM pg_attribute a
                WHERE a.attrelid = c.oid
                AND a.attname = 'updated_at'
                AND NOT a.attisdropped
            )
        ) THEN
            _trigger_sql := FORMAT('CREATE TRIGGER set_updated_at
                                   BEFORE UPDATE ON %I.%I
                                   FOR EACH ROW
                                   EXECUTE FUNCTION app.update_updated_at_column();',
                                   _schema_name, _table_only_name);
            EXECUTE _trigger_sql;
        END IF;
    END LOOP;
END;
$$;

-- 시료 코드 생성을 위한 트리거
CREATE TRIGGER tr_bi_generate_sample_code
BEFORE INSERT ON lims.samples
FOR EACH ROW EXECUTE FUNCTION lims.generate_sample_code();

-- 분할 시료 코드 생성을 위한 트리거
CREATE TRIGGER tr_bi_generate_aliquot_sample_code
BEFORE INSERT ON lims.aliquot_samples
FOR EACH ROW EXECUTE FUNCTION lims.generate_aliquot_sample_code();

-- 원 시료 분석 상태 업데이트를 위한 트리거 (분할 시료 변경 시)
CREATE TRIGGER tr_ai_update_parent_sample_analysis_status
AFTER INSERT OR UPDATE OR DELETE ON lims.aliquot_samples
FOR EACH ROW EXECUTE FUNCTION lims.update_parent_sample_analysis_status();

-- 분할 시료 자동 폐기를 위한 트리거 (분석 완료 시 즉시)
CREATE TRIGGER tr_au_auto_dispose_aliquot_sample
AFTER UPDATE OF analysis_status ON lims.aliquot_samples
FOR EACH ROW
WHEN (NEW.analysis_status = 'Completed' AND OLD.analysis_status IS DISTINCT FROM 'Completed')
EXECUTE FUNCTION lims.auto_dispose_aliquot_sample();

-- 원 시료 자동 폐기를 위한 트리거 (모든 분할 시료 분석 완료 3일 후)
CREATE TRIGGER tr_au_auto_dispose_parent_sample
AFTER UPDATE OF analysis_status ON lims.samples
FOR EACH ROW
WHEN (NEW.analysis_status = 'Completed' AND OLD.analysis_status IS DISTINCT FROM 'Completed')
EXECUTE FUNCTION lims.auto_dispose_parent_sample();

-- 시험 의뢰 코드 생성을 위한 트리거
CREATE TRIGGER tr_bi_generate_test_request_code
BEFORE INSERT ON lims.test_requests
FOR EACH ROW EXECUTE FUNCTION lims.generate_test_request_code();

-- 라벨 인쇄 여부 표시를 위한 트리거
CREATE TRIGGER tr_ai_mark_labels_printed
AFTER INSERT ON lims.test_requests
FOR EACH ROW EXECUTE FUNCTION lims.mark_labels_printed();

-- 자재 사용 시 FIFO 방식으로 재고 차감 트리거
-- 애플리케이션 레벨에서 더 유연하게 처리할 수 있으므로, 주석 처리.
-- CREATE TRIGGER trg_deduct_material_fifo
-- BEFORE INSERT ON inv.material_transactions
-- FOR EACH ROW
-- WHEN (NEW.transaction_type = 'USAGE')
-- EXECUTE FUNCTION inv.deduct_material_fifo();


--
-- ACL (접근 제어 목록)
--
-- 중요: 아래 GRANT 문은 모든 스키마와 객체에 'postgres' 사용자에게 모든 권한을 부여합니다.
-- 실제 운영 환경에서는 보안을 위해 애플리케이션에서 사용할 별도의 데이터베이스 사용자 계정을 생성하고,
-- 해당 계정에는 비즈니스 로직에 필요한 최소한의 권한(SELECT, INSERT, UPDATE, DELETE 등)만 부여해야 합니다.
--
-- 예시:
-- CREATE ROLE app_user WITH LOGIN PASSWORD 'your_secure_password_here';
-- GRANT CONNECT ON DATABASE your_database_name TO app_user;
--
-- -- 스키마 사용 권한 부여
-- GRANT USAGE ON SCHEMA app, usr, loc, ven, fms, inv, lims, ops TO app_user;
--
-- -- 모든 테이블에 대한 기본 권한 부여 (필요에 따라 세분화)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO app_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA usr TO app_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA loc TO app_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ven TO app_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA fms TO app_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA inv TO app_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA lims TO app_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ops TO app_user;
--
-- -- 모든 시퀀스에 대한 기본 권한 부여 (NEXTVAL 사용 권한)
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA app TO app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA usr TO app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA loc TO app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ven TO app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA fms TO app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA inv TO app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA lims TO app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ops TO app_user;
--
-- -- 모든 함수에 대한 기본 권한 부여 (함수 실행 권한)
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA app TO app_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA usr TO app_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA loc TO app_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA ven TO app_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA fms TO app_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA inv TO app_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA lims TO app_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA ops TO app_user;
--
-- -- pg_cron 작업 스케줄링 권한 (cron_user 역할 필요)
-- GRANT USAGE ON SCHEMA cron TO app_user;
-- GRANT EXECUTE ON FUNCTION cron.schedule(text, text, text) TO app_user;


GRANT ALL ON SCHEMA lims TO wims;
GRANT ALL ON SCHEMA ops TO wims;
GRANT ALL ON SCHEMA usr TO wims;
GRANT ALL ON SCHEMA inv TO wims;
GRANT ALL ON SCHEMA ven TO wims;
GRANT ALL ON SCHEMA loc TO wims;
GRANT ALL ON SCHEMA fms TO wims;
GRANT ALL ON SCHEMA app TO wims;

GRANT ALL ON ALL TABLES IN SCHEMA lims TO wims;
GRANT ALL ON ALL SEQUENCES IN SCHEMA lims TO wims;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA lims TO wims;

GRANT ALL ON ALL TABLES IN SCHEMA ops TO wims;
GRANT ALL ON ALL SEQUENCES IN SCHEMA ops TO wims;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA ops TO wims;

GRANT ALL ON ALL TABLES IN SCHEMA usr TO wims;
GRANT ALL ON ALL SEQUENCES IN SCHEMA usr TO wims;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA usr TO wims;

GRANT ALL ON ALL TABLES IN SCHEMA inv TO wims;
GRANT ALL ON ALL SEQUENCES IN SCHEMA inv TO wims;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA inv TO wims;

GRANT ALL ON ALL TABLES IN SCHEMA ven TO wims;
GRANT ALL ON ALL SEQUENCES IN SCHEMA ven TO wims;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA ven TO wims;

GRANT ALL ON ALL TABLES IN SCHEMA loc TO wims;
GRANT ALL ON ALL SEQUENCES IN SCHEMA loc TO wims;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA loc TO wims;

GRANT ALL ON ALL TABLES IN SCHEMA fms TO wims;
GRANT ALL ON ALL SEQUENCES IN SCHEMA fms TO wims;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA fms TO wims;

GRANT ALL ON ALL TABLES IN SCHEMA app TO wims;
GRANT ALL ON ALL SEQUENCES IN SCHEMA app TO wims;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA app TO wims;


-- 2025-05-28 19:51:24 KST 완료 (수정된 코드 완료 시간)

--
-- PostgreSQL 데이터베이스 덤프 완료
--