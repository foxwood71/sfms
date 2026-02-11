-- =========================================================
-- Schema: cmm (Common Module) - Advanced Version
-- Description: 고도화된 공통 기준정보 및 파일 관리 시스템
-- Updated At: 2026-02-12
-- Version: 1.0
-- =========================================================

CREATE SCHEMA IF NOT EXISTS cmm;
COMMENT ON SCHEMA cmm IS '공통 관리 도메인 (고도화 버전)';

-- 1. 시스템 도메인 레지스트리 (변동 없음)
CREATE TABLE cmm.system_domains (
    domain_code    VARCHAR(3) PRIMARY KEY,
    domain_name    VARCHAR(50) NOT NULL,
    schema_name    VARCHAR(50) NOT NULL,
    description    TEXT,
    sort_order     INT DEFAULT 0,
    is_active      BOOLEAN DEFAULT true,
    created_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. 공통 코드 그룹 (수정: 수정자 정보 추가)
CREATE TABLE cmm.code_groups (
    group_code     VARCHAR(30) PRIMARY KEY,
    group_name     VARCHAR(100) NOT NULL,
    description    TEXT,
    is_system      BOOLEAN DEFAULT false,
    is_active      BOOLEAN DEFAULT true,
    created_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by     INT,  -- 생성자 ID
    updated_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by     INT   -- 수정자 ID
);

-- 3. 공통 코드 상세 (고도화: JSONB 속성 및 책임 정보 추가)
CREATE TABLE cmm.code_details (
    group_code     VARCHAR(30) NOT NULL REFERENCES cmm.code_groups(group_code) ON DELETE CASCADE,
    detail_code    VARCHAR(30) NOT NULL,
    detail_name    VARCHAR(100) NOT NULL,
    
    -- [고도화] 고정 ref_val 대신 JSONB를 사용하여 코드별 다른 속성을 유연하게 저장
    -- 예: {"color": "#FF0000", "min_val": 10, "unit": "kg"}
    props          JSONB DEFAULT '{}'::jsonb, 
    
    sort_order     INT DEFAULT 0,
    is_active      BOOLEAN DEFAULT true,
    created_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by     INT,
    updated_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by     INT,
    
    PRIMARY KEY (group_code, detail_code)
);

COMMENT ON COLUMN cmm.code_details.props IS '상세 코드별 가변 속성 (JSONB)';

-- 4. [신규] 파일/첨부파일 관리 (MinIO 연동용)
-- 설명: 하수처리장 도면, 설비 사진, 수질 성적서 등을 통합 관리
CREATE TABLE cmm.attachments (
    file_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_code    VARCHAR(3) REFERENCES cmm.system_domains(domain_code),
    ref_id         VARCHAR(50),      -- 참조하는 데이터의 PK (예: 설비ID)
    
    file_name      VARCHAR(255) NOT NULL, -- 원본 파일명
    file_path      VARCHAR(500) NOT NULL, -- MinIO 내 버킷/경로
    file_size      BIGINT,                -- 파일 크기 (bytes)
    content_type   VARCHAR(100),          -- MIME 타입
    
    is_deleted     BOOLEAN DEFAULT false,
    created_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by     INT
);

COMMENT ON TABLE cmm.attachments IS '시스템 통합 첨부파일 관리';
COMMENT ON COLUMN cmm.attachments.ref_id IS '연관된 업무 데이터의 ID (FAC_001 등)';

-- 5. 자동 채번 규칙 (변동 없음)
CREATE TABLE cmm.sequence_rules (
    domain_code    VARCHAR(3) PRIMARY KEY REFERENCES cmm.system_domains(domain_code),
    prefix         VARCHAR(10) NOT NULL,
    year_format    VARCHAR(4) DEFAULT 'YYYY',
    separator      CHAR(1) DEFAULT '-',
    current_year   VARCHAR(4) NOT NULL,
    current_seq    INT DEFAULT 0,
    reset_type     VARCHAR(10) DEFAULT 'YEARLY',
    updated_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. [고도화] 코드 통합 조회 View (FE 개발 편의용)
-- 설명: React(AntD Pro)에서 Select 박스 데이터를 한 번에 가져오기 위한 뷰
CREATE OR REPLACE VIEW cmm.v_code_lookup AS
SELECT 
    g.group_code,
    g.group_name,
    d.detail_code as value,
    d.detail_name as label,
    d.props,
    d.sort_order
FROM cmm.code_groups g
JOIN cmm.code_details d ON g.group_code = d.group_code
WHERE g.is_active = true AND d.is_active = true;

-- [함수] get_next_sequence (기존 작성하신 로직 유지)
-- (생략: 기존에 제공해주신 훌륭한 함수 코드를 그대로 사용하시면 됩니다.)