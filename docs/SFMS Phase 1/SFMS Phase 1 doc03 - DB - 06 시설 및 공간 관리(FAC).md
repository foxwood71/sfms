# 📘 SFMS Phase 1 DATABASE 설계서 - 시설 및 공간 관리 (FAC)

* **문서 버전:** v2.0 (Standard Architecture 적용)
* **최종 수정일:** 2026-03-23
* **대상 스키마:** `fac`
* **기준 규격:** `SFMS Standard v3.0`

---

## 1. 🗺️ 설계 개요

시스템의 물리적 근간이 되는 최상위 시설(Site)과 그 내부의 계층적 공간(Space)을 관리합니다.

* **최상위 시설**: 사업소, 처리장 등 독립적인 물리적 단위. 공통 코드의 `FAC_CATEGORY`를 참조합니다.
* **공간 계층**: 건물 > 층 > 구역 > 실 등으로 이어지는 트리 구조. `SPACE_TYPE`과 `SPACE_FUNC`를 참조합니다.
* **참조 표준**: 모든 기초 정보는 ID가 아닌 **3자리 영문 코드**를 사용하여 참조하며, DB 레벨에서 복합 FK로 무결성을 보장합니다.

---

## 2. 🗄️ 상세 스키마 정의 (DDL)

```sql
-----------------------------------------------------------
-- 🟩 fac 도메인 (시설 및 공간 관리)
-----------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS fac;

-- 1. [Table] 최상위 시설물 (facilities)
CREATE TABLE fac.facilities (
    id                  BIGSERIAL PRIMARY KEY,
    
    -- 공통코드 참조 (FAC_CATEGORY)
    category_group_code VARCHAR(30) DEFAULT 'FAC_CATEGORY' NOT NULL,
    category_code       VARCHAR(3) NOT NULL, 

    representative_image_id UUID,
    code                VARCHAR(50) NOT NULL UNIQUE,    -- 관리 코드 (Prefix+Seq)
    name                VARCHAR(100) NOT NULL,
    address             VARCHAR(255),
    is_active           BOOLEAN DEFAULT true,
    sort_order          INT DEFAULT 0,
    metadata            JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT,

    CONSTRAINT chk_fac_category_group CHECK (category_group_code = 'FAC_CATEGORY')
);

-- 2. [Table] 공간 계층 (Spaces)
CREATE TABLE fac.spaces (
    id                  BIGSERIAL PRIMARY KEY,
    facility_id         BIGINT NOT NULL,
    parent_id           BIGINT,
    representative_image_id UUID,

    -- 공간 유형 및 기능 코드 참조
    space_type_group_code VARCHAR(30) DEFAULT 'SPACE_TYPE' NOT NULL,
    space_type_code       VARCHAR(3) NOT NULL,
    space_func_group_code VARCHAR(30) DEFAULT 'SPACE_FUNC' NOT NULL,
    space_func_code       VARCHAR(3) NOT NULL,
    
    code                VARCHAR(50) NOT NULL,
    name                VARCHAR(100) NOT NULL,
    area_size           NUMERIC(10, 2),
    is_active           BOOLEAN DEFAULT true,
    sort_order          INT DEFAULT 0,
    is_restricted       BOOLEAN DEFAULT false,
    org_id              BIGINT,
    metadata            JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT
);

-- 3. [View] 조회용 인터페이스
CREATE VIEW fac.v_facility_categories AS
SELECT detail_code AS code, detail_name AS name, props, sort_order
FROM cmm.code_details WHERE group_code = 'FAC_CATEGORY' AND is_active = true;

CREATE VIEW fac.v_space_types AS
SELECT detail_code AS code, detail_name AS name, sort_order
FROM cmm.code_details WHERE group_code = 'SPACE_TYPE' AND is_active = true;
```

---

## ⚡ 3. 주요 아키텍처 포인트

### 3.1 복합 외래 키 (Composite FK)
* 실제 제약조건 연결 시 `(group_code, detail_code)` 조합을 `cmm.code_details`와 연결하여, 엉뚱한 그룹의 코드가 입력되는 것을 원천 차단합니다.

### 3.2 코드 기반 식별 체계
* 사용자가 시설 분류로 `STP`를 선택하면, 시스템은 자동으로 `STP001`, `STP002`와 같은 코드를 생성하여 `code` 컬럼에 저장합니다.

### 3.3 뷰(View) 중심의 조회
* 백엔드 개발자는 복잡한 공통 코드 조인 대신 `fac.v_facility_categories`와 같은 전용 뷰를 통해 데이터를 조회함으로써 생산성을 높입니다.
