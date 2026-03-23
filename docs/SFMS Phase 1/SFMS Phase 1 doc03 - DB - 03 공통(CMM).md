# 📘 SFMS Phase 1 DATABASE 설계서 - 공통 관리 (CMM)

* **문서 버전:** v2.0 (Standard Architecture 적용)
* **최종 수정일:** 2026-03-23
* **대상 스키마:** `cmm`
* **기준 규격:** `SFMS Standard v3.0`

---

## 1. 🗺️ 설계 개요

시스템 전반에서 공통으로 사용되는 기준정보와 인프라 데이터를 통합 관리합니다.

* **공통 코드**: 도메인별 분류, 유형, 상태값을 중앙 집중 관리하며 자동 코드 생성 규칙을 보유함.
* **통합 첨부파일**: 모든 도메인의 파일 메타데이터를 통합 관리하고 MinIO 스토리지와 연동.
* **사용자 알림**: 시스템 이벤트 및 사용자 간 메시지 전달 기능.

---

## 2. 🗄️ 상세 스키마 정의 (DDL)

```sql
-----------------------------------------------------------
-- 🟨 cmm 도메인 (공통 관리)
-----------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS cmm;

-- 1. [Table] 공통 코드 그룹 (code_groups)
CREATE TABLE cmm.code_groups (
    id                  BIGSERIAL PRIMARY KEY,
    group_code          VARCHAR(30) NOT NULL UNIQUE,    -- 그룹 식별 코드
    domain_code         VARCHAR(3),                     -- 소속 도메인
    group_name          VARCHAR(100) NOT NULL,          -- 그룹 명칭
    description         TEXT,                           -- 상세 설명
    
    -- [SFMS Standard] 코드 규격 관리 필드
    code_length         INT DEFAULT 0,                  -- 권장 코드 길이 (예: 3자)
    is_seq_used         BOOLEAN DEFAULT false,          -- 순번 생성 엔진 사용 여부

    is_system           BOOLEAN DEFAULT false,
    is_active           BOOLEAN DEFAULT true,
    props               JSONB DEFAULT '{}'::jsonb NOT NULL,
    
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT
);

-- 2. [Table] 공통 코드 상세 (code_details)
CREATE TABLE cmm.code_details (
    id                  BIGSERIAL PRIMARY KEY,
    group_code          VARCHAR(30) NOT NULL,           -- 소속 그룹 (FK)
    detail_code         VARCHAR(30) NOT NULL,           -- 상세 코드 (예: STP)
    detail_name         VARCHAR(100) NOT NULL,          -- 상세 명칭
    props               JSONB DEFAULT '{}'::jsonb NOT NULL,
    sort_order          INT DEFAULT 0,
    is_active           BOOLEAN DEFAULT true,
    
    CONSTRAINT uq_code_details_group_detail UNIQUE (group_code, detail_code)
);

-- 3. [Table] 통합 첨부파일 (attachments)
CREATE TABLE cmm.attachments (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_code         VARCHAR(3) NOT NULL,
    resource_type       VARCHAR(50) NOT NULL,           -- 테이블명
    ref_id              BIGINT NOT NULL,                -- 대상 ID
    category_code       VARCHAR(20) NOT NULL,           -- 분류 (DOC, IMG 등)
    file_name           VARCHAR(255) NOT NULL,
    file_path           VARCHAR(500) NOT NULL,
    file_size           BIGINT DEFAULT 0,
    content_type        VARCHAR(100),
    is_deleted          BOOLEAN DEFAULT false,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
```

---

## ⚡ 3. 주요 운영 정책

### 3.1 지능형 코드 생성 (Prefix + Sequence)
* `code_groups.is_seq_used`가 `true`인 경우, 해당 그룹의 `detail_code`를 접두어로 사용하여 자산 코드를 자동 생성합니다.
* 예: `FAC_CATEGORY` 그룹의 `STP`(하수처리장) 선택 시 → `STP001` 생성.

### 3.2 데이터 무결성 보장
* 도메인 테이블(FAC, USR 등)에서 공통 코드를 참조할 때는 반드시 **복합 외래 키(group_code, detail_code)**를 사용하여 데이터 정합성을 DB 레벨에서 강제합니다.

### 3.3 첨부파일 관리
* 모든 파일은 물리적으로 MinIO 스토리지에 저장되며, DB에는 접근 경로와 메타데이터만 보관합니다.
* 삭제 시 즉시 물리 삭제하지 않고 `is_deleted` 플래그를 통해 관리합니다.
