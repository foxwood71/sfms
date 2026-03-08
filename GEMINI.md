# 🤖 SFMS 프로젝트 Gemini 작업 가이드

이 파일은 SFMS 프로젝트의 백엔드 및 프론트엔드 개발 표준과 작업 문맥을 기록합니다. Gemini CLI 세션이 시작될 때 이 내용을 반드시 숙지하십시오.

## 📋 핵심 기술 표준 (2026-03-08 최신화)

### 1. 백엔드 (FastAPI & Python 3.13)
*   **문서화 (Docstring)**: 모든 서비스 클래스 및 라우터 메서드에 **Google Style Docstring**을 필수로 적용합니다. (Args, Returns, Raises 포함)
*   **의존성 주입**: 반드시 `Annotated[Type, Component()] = default` 문법을 사용하며, 기본값이 있는 인자는 매개변수 목록의 **맨 뒤**에 배치합니다.
*   **보안**: `passlib` 대신 **`bcrypt` 라이브러리를 직접 사용**합니다. JWT는 RTR(Rotation) 및 Redis 블랙리스트 정책을 따릅니다.
*   **서비스 레이어 (중요)**: 지연 로딩(`MissingGreenlet`) 방지를 위해 항상 **SQLAlchemy 모델 대신 Pydantic Read 스키마를 반환**합니다. (트리 구조 조립 시 모델 데이터를 딕셔너리로 선변환 권장)
*   **의존성 관리**: `pyroonga` 라이브러리는 빌드 오류 및 미사용으로 인해 제거되었습니다. DB 연동은 SQLAlchemy/asyncpg로 수행합니다.

### 2. 프론트엔드 (React 19 & Ant Design v5)
*   **문서화 (TSDoc)**: 모든 컴포넌트, Props 인터페이스, 커스텀 훅에 **TSDoc** 규범을 적용합니다. 인라인 주석(`/** ... */`)을 통해 IDE 가독성을 높입니다.
*   **호환성 패치**: React 19 네이티브 호환을 위해 `main.tsx` 최상단에 `@ant-design/v5-patch-for-react-19` 임포트가 필수입니다.
*   **상태 관리**: 전역 인증 및 세션 상태는 `Zustand`를 사용하며, 로컬 스토리지(`persist`)와 연동합니다.
*   **메시지 호출**: 반드시 `App.useApp()` 훅에서 추출한 `message`, `modal`, `notification` 객체를 사용합니다.

### 3. 데이터베이스 (PostgreSQL 16)
*   **코드 대문자 강제**: 모든 식별용 `code` 컬럼에는 `CHECK (code = UPPER(code))` 제약 조건을 필수로 적용합니다.
*   **계층 구조 무결성**: `parent_id`를 사용하는 테이블은 자기 참조 방지(`CHECK id <> parent_id`) 및 서비스 레이어 내 순환 참조 방지 로직을 구현해야 합니다.
*   **공통 컬럼**: 모든 테이블은 `created_at`, `updated_at`, `created_by`, `updated_by` 필드를 포함하며, `sys.trg_set_updated_at()` 트리거를 부착합니다.

### 4. 테스트 환경
*   **테스트 백엔드**: `pytest-asyncio` 대신 **`AnyIO`**를 사용하며, 실행 시 `pytest -p no:asyncio` 옵션을 사용합니다.
*   **독립성 보장**: 토큰 블랙리스트 작동으로 인해 로그아웃 테스트는 항상 시나리오의 가장 마지막에 배치하거나 별도 토큰을 사용합니다.

## 🛠️ 작업 이력 및 문맥
*   `cmm.attachments` 및 **`fac.spaces`** 테이블에 `org_id` 컬럼이 추가되었습니다. (DB 동기화 완료)
*   모든 도메인 서비스 및 라우터에 대한 독스트링 적용과 통합 시나리오 테스트가 통과된 상태입니다.
*   `TASK_PROGRESS.md` 파일에 상세 진행 내역이 기록되어 있습니다.
