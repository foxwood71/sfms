# 📘 SFMS Phase 1 DATABASE 설계서 - 사용자 및 조직 (USR)

* **문서 버전:** v1.2 (Implementation Sync)
* **최종 수정일:** 2026-03-07
* **대상 스키마:** `usr`
* **기준 규격:** `SFMS Standard v1.2`

---

## 1. 🗺️ 설계 개요

시스템의 인적 자원과 조직 구조를 관리하는 핵심 도메인입니다.

* **조직 관리**: 본부 > 팀 > 파트 등으로 이어지는 계층형(Self-Ref) 조직도 관리.
* **사용자 관리**: 임직원 계정 정보, 사번, 연락처, 프로필 관리.
* **권한 연동**: IAM 도메인의 역할(Role)과 연결되어 시스템 접근 제어의 기반을 제공합니다.

---

## 2. 🗄️ 상세 스키마 정의 (DDL)

```sql
-----------------------------------------------------------
-- 🟦 usr 도메인 (사용자 및 조직)
-----------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS usr;

-- 1. [Table] 조직 (Organizations)
CREATE TABLE usr.organizations (
    id                  BIGSERIAL PRIMARY KEY,
    name                VARCHAR(100) NOT NULL,
    code                VARCHAR(50) NOT NULL UNIQUE,
    parent_id           BIGINT REFERENCES usr.organizations(id),
    sort_order          INT DEFAULT 0,
    is_active           BOOLEAN DEFAULT true,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT
);

-- 2. [Table] 사용자 (Users)
CREATE TABLE usr.users (
    id                  BIGSERIAL PRIMARY KEY,
    org_id              BIGINT REFERENCES usr.organizations(id) ON DELETE SET NULL,
    login_id            VARCHAR(50) NOT NULL UNIQUE,
    password_hash       VARCHAR(255) NOT NULL,
    emp_code            VARCHAR(16) NOT NULL UNIQUE,
    name                VARCHAR(100) NOT NULL,
    email               VARCHAR(100) NOT NULL UNIQUE,
    phone               VARCHAR(50),
    profile_image_id    UUID,                       -- cmm.attachments 참조
    is_active           BOOLEAN DEFAULT true,
    login_fail_count    INTEGER DEFAULT 0,
    last_login_at       TIMESTAMPTZ,
    metadata            JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT
);
```

---

## ⚡ 3. 인덱스 및 트리거 명세

* **조직 계층**: `idx_usr_org_parent (parent_id)`
* **로그인 성능**: `idx_usr_login_id (login_id)` 고유 인덱스.
* **이름 전문 검색**: `idx_usr_name_pg` (PGroonga).
* **자동 갱신 트리거**: 모든 테이블에 `sys.trg_set_updated_at()` 적용.

---

## 🚀 4. 운영 정책

* **논리적 삭제**: 사용자와 조직은 데이터 보존을 위해 물리 삭제 대신 `is_active = false` 처리를 원칙으로 함.
* **비밀번호 보안**: 모든 비밀번호는 `bcrypt` 또는 `argon2` 해시로 암호화하여 저장.
