# 🤖 SFMS 프로젝트 Gemini 작업 가이드

이 파일은 SFMS 프로젝트의 백엔드 및 프론트엔드 개발 표준과 작업 문맥을 기록합니다. Gemini CLI 세션이 시작될 때 이 내용을 반드시 숙지하십시오.

## 📋 핵심 기술 표준 (2026-03-21 최신화)

### 1. 백엔드 (FastAPI & Python 3.13)
*   **문서화 (Docstring)**: 모든 서비스 클래스 및 라우터 메서드에 **Google Style Docstring**을 필수로 적용합니다.
*   **메시지 전송 정책 (중요)**: 프론트엔드로 보내는 에러나 알림 메시지는 반드시 **영문 코드(예: `USER_NOT_FOUND`)** 형태로 전송합니다. 한글 텍스트를 응답 본문에 직접 포함하지 않습니다.
*   **서비스 레이어**: 지연 로딩(`MissingGreenlet`) 방지를 위해 관계형 데이터(Roles, Organization 등) 조회 시 반드시 **`joinedload` 또는 `selectinload`를 명시**합니다.
*   **데이터 매핑**: Pydantic 스키마의 `metadata`(alias)와 SQLAlchemy 모델의 `user_metadata` 컬럼 간의 매핑을 서비스 레이어에서 명시적으로 처리하여 데이터 누락을 방지합니다.

### 2. 프론트엔드 (React 19 & Ant Design v5)
*   **🚨 Zero Any Policy**: **더 이상 `any` 타입을 사용하지 않습니다.** 모든 타입은 인터페이스나 유니온 타입으로 구체화해야 합니다.
*   **🚨 Zero Hardcoded Strings**: **모든 UI 문자열 및 에러 메시지에 대해 하드코딩을 엄격히 금지합니다.** 모든 텍스트는 `messages.ts`에 정의하고 `t()` 함수를 통해 가져와야 합니다. (Fallback 문자열 사용 금지)
*   **i18n 메시지 처리**: 백엔드에서 받은 영문 코드를 키(Key)로 활용하여 로케일에 맞는 메시지를 출력합니다. `MESSAGES.ERRORS[code]` 형식을 따르며 UI 하드코딩을 금지합니다.
*   **UI/UX 벤또 표준 (Bento Standard v1.1)**:
    *   **Icon-centric UI**: 상단 필터나 액션 버튼 등은 텍스트 라벨 대신 **아이콘 + Tooltip** 조합을 우선적으로 사용합니다. (화면 콤팩트화)
    *   **Floating Filter**: 필터 영역은 기본적으로 숨김 상태이며, 필터 버튼 클릭 시에만 Bento 스타일의 플로팅 박스로 노출됩니다.
    *   **Active Filter Tags**: 현재 적용된 필터 조건들은 테이블 상단에 태그(Balloons) 형태로 표시하며, 개별 삭제 및 전체 초기화 기능을 제공해야 합니다.
    *   **Layout**: 모든 페이지는 `100vh` 기반의 `Fixed Layout`이며, `Splitter`를 사용한 독립적 카드 구조를 가집니다.
    *   **Splitter Persistence**: `Splitter`의 분할 비율은 `localStorage`에 저장하여 재접속 시 복구하며, 조절 범위는 `15% ~ 40%` 사이로 제한합니다.
    *   **Bento Card Style**: 패널 내부 컨테이너는 `borderRadius: 12px`와 `overflow: hidden`을 적용합니다.
    *   **Zero-Card-Scroll Policy (중요)**: 상위 카드 자체는 절대 스크롤되지 않아야 하며, 스크롤은 오직 내부의 리스트/트리 영역에만 허용합니다. (10개 행 기준)
*   **이미지 처리**: 프로필 사진 등 비공개 파일은 정확한 API 경로와 쿼리 파라미터 기반 인증 토큰(`?token=...`)을 결합하여 로드합니다.

### 3. 데이터베이스 및 보안 (PostgreSQL 16)
*   **보안 감사 로그 (Security Auditing)**:
    *   로그인 성공뿐만 아니라 **로그인 실패(`LOGIN_FAILURE`)** 및 **계정 잠금(`ACCOUNT_LOCKED`)** 이벤트도 반드시 감사 로그로 기록합니다.
    *   실패 로그에는 시도된 아이디, 클라이언트 IP, User-Agent 정보를 포함하여 보안 분석이 가능하도록 합니다.
*   **제약 조건**: 사번(`emp_code`)은 영문 대문자, 숫자, 언더바(`_`), 하이픈(`-`) 조합을 표준으로 합니다.
*   **시드 데이터**: 직위(`SENIOR`-수석), 직책(`HEAD`-부서장) 등 누락된 기초 코드를 보강하고, `props` 등 JSONB 컬럼에 `NULL` 대신 `'{}'::jsonb`를 기본값으로 사용합니다.

## 🛠️ 작업 이력 및 문맥 (최근)
*   **SYS 도메인 감사 로그 고도화 완료**: 상세 필터링, 페이징, 데이터 스냅샷 뷰어 및 아이콘 중심 UI 적용.
*   **i18n 체계 정립**: `messages.ts` 기반 전면 적용 및 모든 컴포넌트의 하드코딩/Fallback 문자열 제거.
*   **인증 보안 강화**: 로그아웃 시 리프레시 토큰 블랙리스트 즉시 등록 및 로그인 실패 추적 로직 구현.
*   **UI 일관성 확보**: 모든 조직도 트리의 루트 노드명("전체 조직도")과 아이콘(`ApartmentOutlined`) 통일.
*   **데이터베이스 이동성 확보**: `database/backup_db.sh`를 통한 전체 백업 및 복구 체계 구축.

## 💾 데이터베이스 관리 (Backup & Restore)

### 1. 백업 (Backup)
*   **방법**: 프로젝트 루트에서 백업 스크립트 실행
*   **명령어**: `./database/backup_db.sh`
*   **결과**: `database/backups/sfms_full_backup_YYYYMMDD_HHMMSS.sql` 파일 생성

### 2. 복구 (Restore)
*   **방법**: 백업된 SQL 파일을 대상 컨테이너의 `psql`로 전달
*   **명령어**: 
    ```bash
    cat <백업파일.sql> | podman exec -i <컨테이너명> psql -U <사용자명> -d <DB명>
    ```
---
