\c sfms_db

-- ========================================================
-- 1. ADT (Audit Log) - 감사 로그
-- ========================================================
CREATE TABLE adt_audit_logs (
    id BIGSERIAL PRIMARY KEY,
    trace_id UUID,
    actor_id BIGINT,
    action VARCHAR(20) NOT NULL,
    target_domain VARCHAR(50) NOT NULL,
    target_id VARCHAR(100) NOT NULL,
    snapshot JSONB, -- 변경 전후 데이터
    ip_address INET,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- PGroonga 인덱스: 로그 스냅샷(JSON) 내부 검색 가속
CREATE INDEX idx_adt_snapshot_pgroonga ON adt_audit_logs USING pgroonga (snapshot);
CREATE INDEX idx_adt_created_at ON adt_audit_logs (created_at);

-- ========================================================
-- 2. USR (User) - 사용자
-- ========================================================
CREATE TABLE usr_users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(50) NOT NULL,
    org_id BIGINT,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- PGroonga 인덱스: 사용자 이름 검색 (오타 보정, 자동완성 지원)
CREATE INDEX idx_usr_name_pgroonga ON usr_users USING pgroonga (name);

-- ========================================================
-- 3. FAC (Facility) - 시설 관리
-- ========================================================
CREATE TABLE fac_facilities (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    type VARCHAR(20) NOT NULL, -- SITE, PROCESS, AREA, POINT
    parent_id BIGINT REFERENCES fac_facilities(id),
    metadata JSONB, -- 시설 제원 (JSON)
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- PGroonga 인덱스: 시설명 및 메타데이터(JSON) 통함 검색
CREATE INDEX idx_fac_name_pgroonga ON fac_facilities USING pgroonga (name);
CREATE INDEX idx_fac_metadata_pgroonga ON fac_facilities USING pgroonga (metadata);