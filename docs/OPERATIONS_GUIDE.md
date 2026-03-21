# 🛠️ SFMS 시스템 운영 및 관리 가이드

본 문서는 SFMS(시설 유지보수 관리 시스템)의 설치, 설정, 데이터베이스 관리 및 보안 정책에 대한 통합 가이드를 제공합니다.

---

## 1. ⚙️ 환경 설정 (Environment Setup)

### 1.1 필수 도구
*   **Runtime**: Python 3.13 (uv 권장), Node.js 24+ (pnpm 권장)
*   **Infrastructure**: Podman 5.x 또는 Docker (Compose 지원 필요)
*   **Database**: PostgreSQL 16+, Redis 7+

### 1.2 환경 변수 (`.env`) 관리
백엔드 루트(`backend/.env`)에서 다음 핵심 변수를 관리합니다.
*   `DATABASE_URL`: DB 접속 주소 (asyncpg 드라이버 사용)
*   `SECRET_KEY`: JWT 서명용 비밀키 (운영 환경 변경 필수)
*   `SFMS_ENV`: 실행 환경 구분 (`dev`, `prod`)

---

## 💾 2. 데이터베이스 관리 (DBA)

### 2.1 통합 배포 (`Bootstrapping`)
신규 환경 구축 시 다음 순서로 SQL을 실행합니다.
1. `database/sql/00_deploy.pgsql`: 전체 스키마 및 권한 일괄 배포
2. `database/sql/93_cmm_seed.pgsql`: 기초 공통 코드 및 도메인 정보 등록

### 2.2 백업 및 복구 (Backup & Restore)
프로젝트 루트에서 제공되는 자동화 스크립트를 사용합니다.

*   **백업 (Backup)**:
    ```bash
    ./database/backup_db.sh
    ```
    *   결과물: `database/backups/sfms_full_backup_YYYYMMDD_HHMMSS.sql`
*   **복구 (Restore)**:
    ```bash
    cat <백업파일.sql> | podman exec -i pgsql psql -U sfms_usr -d sfms_db
    ```

---

## 🛡️ 3. 보안 및 감사 정책

### 3.1 인증 시스템 (Authentication)
*   **RTR (Refresh Token Rotation)** 적용: 리프레시 토큰 사용 시마다 기존 토큰은 블랙리스트 처리되고 새 토큰이 발급됩니다.
*   **강력한 로그아웃**: 로그아웃 호출 시 현재 세션의 Access/Refresh 토큰을 모두 즉시 무효화합니다.

### 3.2 보안 감사 (Security Auditing)
시스템의 모든 중요 행위는 `sys.audit_logs` 테이블에 기록됩니다.
*   **기록 대상**: 로그인 성공/실패, 계정 잠금, 데이터 생성/수정/삭제, 권한 변경.
*   **실패 추적**: 존재하지 않는 ID로의 접속 시도 및 IP 주소 정보를 영구 보관합니다.

---

## 🌐 4. 다국어 및 메시지 관리 (i18n)

### 4.1 메시지 정의 (`messages.ts`)
프론트엔드의 모든 텍스트는 `frontend/src/shared/locales/ko/messages.ts`에서 중앙 관리합니다.
*   **규칙**: 하드코딩된 한글 사용 금지. 영문 키 기반 추출.
*   **에러 처리**: 백엔드 응답의 영문 에러 코드를 `getErrorMessage()` 유틸리티가 한국어로 자동 변환합니다.

### 4.2 UI 표준 (Bento Standard v1.1)
*   **아이콘 중심**: 텍스트 라벨 최소화, 아이콘 + Tooltip 조합 사용.
*   **10-Row Rule**: 데이터 테이블은 10개 행 단위로 내부 스크롤 처리.

---

## 📝 5. 장애 조치 (Troubleshooting)

### 5.1 pgAdmin 권한 문제
컨테이너 실행 시 `/var/lib/pgadmin/sessions` 권한 에러 발생 시:
```bash
# 호스트에서 데이터 디렉토리 권한 조정 (UID 5050은 pgadmin 표준)
sudo chown -R 5050:5050 ./infra/data/pgadm
```

### 5.2 JWT 인증 실패
클라이언트와 서버의 시간이 맞지 않거나 `SECRET_KEY`가 불일치할 경우 발생합니다. `.env` 파일과 시스템 시간을 점검하십시오.
