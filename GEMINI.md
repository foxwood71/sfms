# 🤖 SFMS 프로젝트 Gemini 작업 가이드

이 파일은 SFMS 프로젝트의 백엔드 및 프론트엔드 개발 표준과 작업 문맥을 기록합니다. Gemini CLI 세션이 시작될 때 이 내용을 반드시 숙지하십시오.

## 📋 핵심 기술 표준 (2026-03-09 최신화)

### 1. 백엔드 (FastAPI & Python 3.13)
*   **문서화 (Docstring)**: 모든 서비스 클래스 및 라우터 메서드에 **Google Style Docstring**을 필수로 적용합니다. (Args, Returns, Raises 포함)
*   **의존성 주입**: 반드시 `Annotated[Type, Component()] = default` 문법을 사용합니다.
*   **보안**: `passlib` 대신 **`bcrypt` 라이브러리를 직접 사용**합니다. JWT는 RTR(Rotation) 및 Redis 블랙리스트 정책을 따릅니다.
*   **서비스 레이어**: 지연 로딩(`MissingGreenlet`) 방지를 위해 항상 **SQLAlchemy 모델 대신 Pydantic Read 스키마를 반환**합니다.
*   **데이터 무결성**: 조직 비활성화 시 활성 상태인 하위 조직이 존재하면 `BadRequestException`을 발생시켜 논리적 모순을 방지합니다.

### 2. 프론트엔드 (React 19 & Ant Design v5)
*   **문서화 (TSDoc)**: 모든 컴포넌트, Props 인터페이스, 커스텀 훅에 **TSDoc** 규범을 적용합니다.
*   **UI/UX 레이아웃 표준**:
    *   **Split Layout**: 좌측 트리/필터와 우측 상세 정보/목록을 `Splitter` 컴포넌트로 분리하여 리사이즈 가능하게 구현합니다.
    *   **Bento Style Filter**: 목록 제어용 스위치와 검색창은 카드 내부에서 별도의 둥근 박스(Bento Box)로 그룹화합니다.
    *   **High Density**: 폼 필드는 `Row`/`Col`을 사용한 2단 그리드로 배치하여 세로 길이를 최소화하고 한 화면에 모든 정보를 노출합니다.
    * **스크롤 관리**: 브라우저 전체 스크롤을 금지하며, 각 섹션별 독립 스크롤(Internal Scroll)을 정밀하게 구현합니다.
    * **타입 안전성 (TypeScript & Biome)**:
    * **`any` 사용 금지**: 모든 변수, 매개변수, 반환값에 명시적 타입을 지정합니다. 불가피한 경우 `unknown`을 사용합니다.
    * **에러 처리**: `catch (error: unknown)`를 사용하며, `AxiosError<APIErrorResponse>`로 타입 단언(Type Assertion)하여 처리합니다.
    * **Ant Design 타입 활용**: 트리 데이터나 폼 값에는 `TreeDataNode`, `DefaultOptionType` 등 라이브러리 제공 타입을 우선적으로 사용합니다.
    * **상태 관리**: 전역 인증 및 세션 상태는 `Zustand`를 사용하며, API 통신은 `TanStack Query`를 통해 최신 상태를 유지합니다.

### 3. 데이터베이스 (PostgreSQL 16)
*   **코드 대문자 강제**: 모든 식별용 `code` 컬럼에는 `CHECK (code = UPPER(code))` 제약 조건을 적용하며, 프론트엔드에서도 전송 전 `toUpperCase()` 처리를 수행합니다.
*   **공통 컬럼**: 모든 테이블은 `created_at`, `updated_at`, `created_by`, `updated_by` 필드를 포함합니다.

### 4. UI/UX 디자인 표준
*   **상태 표시 용어**: 활성/비활성 상태는 **"활성 / 비활성"**으로 용어를 통일합니다. (퇴사자는 "재직 / 퇴사")
*   **상태 색상**: 활성(`green`), 비활성(`red` 또는 `default` 취소선).
*   **동적 레이블**: 필터 스위치 상태에 따라 "활성 조직만" / "비활성 조직 포함"과 같이 명확한 상태 기반 레이블을 사용합니다.

## 🛠️ 작업 이력 및 문맥 (최근)
*   `USR` 도메인의 조직도 관리 및 사용자 관리 기능이 완성되었습니다. (Deep Search, Splitter, 벤토 필터 등 적용 완료)
*   모든 도메인 서비스 및 라우터에 대한 독스트링 적용과 통합 시나리오 테스트가 완료되었습니다.
*   다음 작업 예정: `SYS` 도메인의 감사 로그(Audit Log) 조회 페이지 및 시설 관리(FAC) 도메인 고도화.
---
