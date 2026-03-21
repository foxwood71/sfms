# 📘 SFMS Phase 1 DB - 02 시스템 관리 (SYS) 설계서

* **문서 버전:** v1.3 (Security Audit Policy Update)
* **최종 수정일:** 2026-03-21
* **도메인:** `SYS` (System)
* **관련 스키마:** `sys`

---

## 1. 🏗️ 도메인 개요
시스템 전반의 인프라 성격의 데이터(감사 로그, 자동 채번 규칙, 도메인 메타데이터)를 관리합니다.

---

## 2. 📊 테이블 명세

### 2.1 감사 로그 (`sys.audit_logs`)
시스템 내에서 발생하는 모든 데이터 변경 및 보안 이벤트를 기록합니다.

| 컬럼명 | 타입 | 제약 조건 | 설명 |
| :--- | :--- | :---: | :--- |
| `id` | BIGSERIAL | PK | 로그 고유 ID |
| `actor_user_id` | BIGINT | FK (usr.users) | 행위 수행자 (시스템 시 NULL) |
| `action_type` | VARCHAR(20) | NOT NULL | CREATE, UPDATE, DELETE, LOGIN, LOGIN_FAILURE, ACCOUNT_LOCKED |
| `target_domain` | VARCHAR(3) | NOT NULL | 대상 업무 도메인 (USR, FAC 등) |
| `target_table` | VARCHAR(50) | NOT NULL | 변경이 발생한 테이블명 |
| `target_id` | VARCHAR(50) | NOT NULL | 대상 데이터의 식별자(PK) |
| `snapshot` | JSONB | NOT NULL | 변경 데이터의 JSON 스냅샷 (기본값: '{}') |
| `client_ip` | VARCHAR(50) | | 요청자 IP 주소 |
| `user_agent` | TEXT | | 접속 브라우저/기기 정보 |
| `description` | TEXT | | 행위에 대한 비즈니스적 설명 |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | 발생 일시 |

#### [인덱스 전략]
*   `idx_audit_logs_created_at`: 로그 발생 일시 역순 조회 최적화 (DESC)
*   `idx_audit_logs_actor_id`: 특정 사용자별 행위 추적 최적화
*   `idx_audit_logs_description_pg`: `PGroonga`를 통한 상세 설명 전문 검색(Full-text Search) 지원

---

## 🛡️ 3. 보안 감사 정책 (Security Policy)

1.  **로그인 실패 기록**: 단순 오류 메시지 외에도 `LOGIN_FAILURE` 이벤트를 기록하여 브루트 포스 공격을 감시합니다.
2.  **계정 잠금**: 연속 실패로 인한 계정 잠금 시 `ACCOUNT_LOCKED`를 기록하여 관리자 알림의 근거로 활용합니다.
3.  **데이터 무결성**: `snapshot` 컬럼은 절대 `NULL`을 허용하지 않으며, 데이터가 없는 경우 반드시 빈 JSON 객체(`{}`)를 삽입합니다.
