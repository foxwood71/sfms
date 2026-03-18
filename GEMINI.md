# 🤖 SFMS 프로젝트 Gemini 작업 가이드

이 파일은 SFMS 프로젝트의 백엔드 및 프론트엔드 개발 표준과 작업 문맥을 기록합니다. Gemini CLI 세션이 시작될 때 이 내용을 반드시 숙지하십시오.

## 📋 핵심 기술 표준 (2026-03-11 최신화)

### 1. 백엔드 (FastAPI & Python 3.13)
*   **문서화 (Docstring)**: 모든 서비스 클래스 및 라우터 메서드에 **Google Style Docstring**을 필수로 적용합니다.
*   **메시지 전송 정책 (중요)**: 프론트엔드로 보내는 에러나 알림 메시지는 반드시 **영문 코드(예: `USER_NOT_FOUND`)** 형태로 전송합니다. 한글 텍스트를 응답 본문에 직접 포함하지 않습니다.
*   **서비스 레이어**: 지연 로딩(`MissingGreenlet`) 방지를 위해 관계형 데이터(Roles, Organization 등) 조회 시 반드시 **`joinedload` 또는 `selectinload`를 명시**합니다.
*   **데이터 매핑**: Pydantic 스키마의 `metadata`(alias)와 SQLAlchemy 모델의 `user_metadata` 컬럼 간의 매핑을 서비스 레이어에서 명시적으로 처리하여 데이터 누락을 방지합니다.

### 2. 프론트엔드 (React 19 & Ant Design v5)
*   **🚨 Zero Any Policy**: **더 이상 `any` 타입을 사용하지 않습니다.** 모든 타입은 인터페이스나 유니온 타입으로 구체화해야 합니다.
*   **🚨 Zero Hardcoded Strings (중요)**: **모든 UI 문자열 및 에러 메시지에 대해 한글 하드코딩을 엄격히 금지합니다.** 모든 텍스트는 `messages.ts`에 정의하고 `t()` 함수나 `MESSAGES` 상수를 통해 가져와야 합니다. 
*   **i18n 메시지 처리**: 백엔드에서 받은 영문 코드를 키(Key)로 활용하여 로케일에 맞는 메시지를 출력합니다. `MESSAGES.ERRORS[code]` 형식을 따르며 UI 하드코딩을 금지합니다.
*   **UI/UX 벤또 표준 (Bento Standard v1.0)**:
    *   **Layout**: 모든 페이지는 `100vh` 기반의 `Fixed Layout`이며, `Splitter`를 사용한 독립적 카드(벤또 박스) 구조를 가집니다.
    *   **Splitter Persistence**: `Splitter`의 분할 비율은 `localStorage`에 저장하여 재접속 시 복구하며, 조절 범위는 `15% ~ 40%` 사이로 제한합니다.
    *   **Bento Card Style**:
        *   패널 내부 컨테이너는 `borderRadius: 12px`와 `overflow: hidden`을 적용하여 둥근 상자 모양을 완성합니다.
        *   카드 본체는 `bordered={false}`로 설정하여 배경에 밀착시키고, `Splitter`의 `gap: 2`를 통해 구분감을 줍니다.
        *   **Filter Box**: 트리나 테이블 상단의 필터 영역은 `borderRadius: 8px`를 적용하고, 상단 및 좌우에 적절한 `margin`을 주어 카드 내부에 떠 있는 듯한 플로팅(Floating) 느낌을 유지합니다.
        *   모든 관리 카드의 높이는 `LAYOUT_CONSTANTS.CONTENT_HEIGHT` (`calc(100vh - 180px)`)로 통일합니다.
    *   **Zero-Card-Scroll Policy (중요)**: 상위 카드 자체는 절대 스크롤되지 않아야 하며 (`overflow: hidden`), 스크롤은 오직 내부의 리스트 영역에만 허용합니다.
    *   **Tree Standard**:
        *   `showLine` 활성화, 헤더에 **전체 펼치기/접기** 버튼 배치.
        *   **Smart Scroll**: 영역 초과 시에만 슬림 스크롤바가 나타나며 공간을 차지하지 않아야 합니다.
    *   **ProTable 10-Row Rule**: 
        *   Header(필터)와 Footer(페이징)는 카드 영역 내에 고정하고 데이터 영역만 스크롤합니다.
        *   **10행 초과 시에만** 스크롤바를 활성화하고, 필터 박스가 열리면 테이블 밀도를 자동으로 `small`로 전환합니다.
*   **이미지 처리**: 프로필 사진 등 비공개 파일은 정확한 API 경로와 쿼리 파라미터 기반 인증 토큰(`?token=...`)을 결합하여 로드합니다.

### 3. 데이터베이스 (PostgreSQL 16)
*   **제약 조건**: 사번(`emp_code`)은 영문 대문자, 숫자, 언더바(`_`), 하이픈(`-`) 조합을 표준으로 합니다.
*   **시드 데이터**: 직위(`SENIOR`-수석), 직책(`HEAD`-부서장) 등 누락된 기초 코드를 상시 점검하고 보강합니다.

## 🛠️ 작업 이력 및 문맥 (최근)
*   `USR/IAM` 도메인의 사용자 관리 기능이 최종 고도화되었습니다. (실시간 사진 로딩, 인터랙티브 역할 설정, 10개 기준 내부 스크롤 복구 완료)
*   모든 프론트엔드 코드가 "Zero Any" 및 "영문 코드 기반 i18n" 구조로 리팩토링되었습니다. (`messages.json` 중심 관리)
*   **데이터베이스 이동성 확보**: `database/backup_db.sh`를 통한 전체 백업 및 복구 체계가 구축되었습니다.
*   **다음 작업 예정**: `SYS` 도메인의 감사 로그(Audit Log) 조회 페이지 및 시설 관리(FAC) 도메인 고도화.

## 💾 데이터베이스 관리 (Backup & Restore)

### 1. 백업 (Backup)
*   **방법**: 프로젝트 루트에서 백업 스크립트 실행
*   **명령어**: `./database/backup_db.sh`
*   **결과**: `database/backups/sfms_full_backup_YYYYMMDD_HHMMSS.sql` 파일 생성
*   **특징**: 컨테이너 환경(`podman`/`docker`)을 자동 감지하여 데이터베이스 스키마와 데이터를 모두 포함한 SQL 덤프를 생성합니다.

### 2. 복구 (Restore)
*   **방법**: 백업된 SQL 파일을 대상 컨테이너의 `psql`로 전달
*   **명령어**: 
    ```bash
    cat <백업파일.sql> | podman exec -i <컨테이너명> psql -U <사용자명> -d <DB명>
    ```
*   **주의**: 리스토어 시 기존 데이터가 삭제되고 백업 시점의 상태로 덮어씌워집니다 (`--clean` 옵션 적용됨).
---
