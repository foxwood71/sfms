# 📘 SFMS Phase 1 DATABASE 설계서 - 시설 및 공간 관리 (FAC)

* **문서 버전:** v1.3 (Org Integration Updated)
* **최종 수정일:** 2026-03-08
* **대상 스키마:** `fac`
* **기준 규격:** `SFMS Standard v1.2`

---

## 1. 🗺️ 설계 개요

시스템의 물리적 근간이 되는 최상위 시설(Site)과 그 내부의 계층적 공간(Space)을 관리합니다.

* **최상위 시설**: 사업소, 처리장, 본사 등 독립적인 물리적 단위.
* **공간 계층**: 건물 > 층 > 구역 > 실 등으로 이어지는 트리 구조.
* **권한 위임**: 공간별로 '관리 책임 부서'를 지정하여 실무진의 편집 권한을 보장합니다.

---

## 2. 🗄️ 상세 스키마 정의 (DDL)

```sql
-----------------------------------------------------------
-- 🟩 fac 도메인 (시설 및 공간 관리)
-----------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS fac;

-- 1. [Table] 시설 카테고리
CREATE TABLE fac.facility_categories (
    id                  BIGSERIAL PRIMARY KEY,
    code                VARCHAR(50) NOT NULL UNIQUE,    -- 예: WTP, PS
    name                VARCHAR(100) NOT NULL,          -- 예: 하수처리장, 펌프장
    is_active           BOOLEAN DEFAULT true,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. [Table] 최상위 시설물 (Facilities)
CREATE TABLE fac.facilities (
    id                  BIGSERIAL PRIMARY KEY,
    category_id         BIGINT REFERENCES fac.facility_categories(id),
    representative_image_id UUID REFERENCES cmm.attachments(id) ON DELETE SET NULL,
    code                VARCHAR(50) NOT NULL UNIQUE,    -- 시설 관리 코드
    name                VARCHAR(100) NOT NULL,
    address             VARCHAR(255),
    is_active           BOOLEAN DEFAULT true,
    sort_order          INT DEFAULT 0,
    metadata            JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT REFERENCES usr.users(id),
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT REFERENCES usr.users(id)
);

-- 3. [Table] 공간 계층 (Spaces)
CREATE TABLE fac.spaces (
    id                  BIGSERIAL PRIMARY KEY,
    facility_id         BIGINT NOT NULL REFERENCES fac.facilities(id) ON DELETE CASCADE,
    parent_id           BIGINT REFERENCES fac.spaces(id) ON DELETE CASCADE,
    space_type_id       BIGINT REFERENCES fac.space_types(id),
    org_id              BIGINT REFERENCES usr.organizations(id) ON DELETE SET NULL, -- [중요] 관리 책임 부서
    code                VARCHAR(50) NOT NULL,           -- 시설 내 유일 코드
    name                VARCHAR(100) NOT NULL,
    area_size           NUMERIC(10, 2),
    is_active           BOOLEAN DEFAULT true,
    sort_order          INT DEFAULT 0,
    is_restricted       BOOLEAN DEFAULT false,
    metadata            JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT REFERENCES usr.users(id),
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT REFERENCES usr.users(id),
    
    CONSTRAINT uq_fac_spaces_code UNIQUE (facility_id, code),
    CONSTRAINT chk_spaces_code_upper CHECK (code = UPPER(code)),
    CONSTRAINT chk_spaces_parent_recursive CHECK (id <> parent_id)
);
```

---

## ⚡ 3. 인덱스 및 트리거 명세

* **PGroonga 전문 검색**: `fac.facilities.name`, `fac.spaces.name`에 토크나이저 인덱스 설정.
* **계층 조회 최적화**: `idx_fac_spaces_hierarchy (facility_id, parent_id)`
* **부서 기반 조회**: `idx_fac_spaces_org (org_id)`
* **자동 갱신 트리거**: 모든 테이블에 `sys.trg_set_updated_at()` 트리거 적용.

---

## 🚀 4. 운영 정책

* **공간 편집 권한**: 해당 공간의 `org_id` 소속 부서장에게 수정 권한을 위임함.
* **이미지 연동**: `representative_image_id`를 통해 `cmm.attachments`와 연동하며, 삭제 시 `SET NULL` 처리함.
