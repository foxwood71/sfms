# 📘 SFMS Phase 1 DATABASE 설계서 - 공통 관리 (CMM)

* **문서 버전:** v1.2 (Implementation Sync)
* **최종 수정일:** 2026-03-07
* **대상 스키마:** `cmm`
* **기준 규격:** `SFMS Standard v1.2`

---

## 1. 🗺️ 설계 개요

시스템 전반에서 공통으로 사용되는 기준정보와 인프라 데이터를 관리합니다.

* **공통 코드**: 시스템의 각종 구분값과 상태값을 그룹/상세 단위로 관리.
* **통합 첨부파일**: 파일 메타데이터를 통합 관리하고 MinIO 스토리지와 연동.
* **사용자 알림**: 시스템 및 사용자 간 메시지 전달 기능.

---

## 2. 🗄️ 상세 스키마 정의 (DDL)

```sql
-----------------------------------------------------------
-- 🟨 cmm 도메인 (공통 관리)
-----------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS cmm;

-- 1. [Table] 공통 코드 그룹
CREATE TABLE cmm.code_groups (
    id                  BIGSERIAL PRIMARY KEY,
    group_code          VARCHAR(30) NOT NULL UNIQUE,
    group_name          VARCHAR(100) NOT NULL,
    domain_code         VARCHAR(3),
    is_system           BOOLEAN DEFAULT false,
    is_active           BOOLEAN DEFAULT true,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. [Table] 공통 코드 상세
CREATE TABLE cmm.code_details (
    id                  BIGSERIAL PRIMARY KEY,
    group_code          VARCHAR(30) REFERENCES cmm.code_groups(group_code) ON DELETE CASCADE,
    detail_code         VARCHAR(30) NOT NULL,
    detail_name         VARCHAR(100) NOT NULL,
    props               JSONB NOT NULL DEFAULT '{}'::jsonb,
    sort_order          INT DEFAULT 0,
    is_active           BOOLEAN DEFAULT true,
    CONSTRAINT uq_cmm_code_detail UNIQUE (group_code, detail_code)
);

-- 3. [Table] 통합 첨부파일 (Attachments)
CREATE TABLE cmm.attachments (
    id                  UUID PRIMARY KEY,
    domain_code         VARCHAR(3) NOT NULL,
    resource_type       VARCHAR(50) NOT NULL,
    ref_id              BIGINT NOT NULL,
    org_id              BIGINT,                         -- [Added] 업로드 당시 부서
    file_name           VARCHAR(255) NOT NULL,
    file_path           VARCHAR(500) NOT NULL UNIQUE,
    file_size           BIGINT DEFAULT 0,
    is_deleted          BOOLEAN DEFAULT false,          -- 소프트 삭제 플래그
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT
);
```

---

## ⚡ 3. 인덱스 및 트리거 명세

* **파일 조회 최적화**: `idx_cmm_attach_lookup (domain_code, resource_type, ref_id)`
* **부서 기반 권한**: `idx_cmm_attach_org (org_id)`
* **자동 갱신 트리거**: 모든 테이블에 `sys.trg_set_updated_at()` 적용.

---

## 🚀 4. 운영 정책

* **소프트 삭제 전략**: 파일 삭제 시 `is_deleted = true` 처리 후, 배치 스크립트(`purge_attachments.py`)를 통해 일정 기간 후 물리 삭제함.
* **부서 공유 권한**: 파일 관리는 업로더 개인뿐 아니라 동일 부서원(`org_id`)도 수행 가능함.
