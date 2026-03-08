# 🚩 SFMS Phase 1 작업 진행 보고서 (2026-03-08)

## 1. 🏗️ 백엔드 (Backend) 작업 현황

### ✅ 도메인별 검증 및 보완 완료
- **CMM (공통)**: 
    - `NotificationService.mark_as_read` 필드명 버그 수정 (`recipient_user_id` -> `receiver_user_id`).
    - 첨부파일 영구 삭제(`permanent=true`) 로직 검증 및 테스트 보강.
- **SYS (시스템)**: 
    - 채번(Sequence) 발급 시 비관적 락(`with_for_update`) 동작 확인 및 연도별 리셋 로직 검증.
- **IAM (인증/권한)**: 
    - 리프레시 토큰 로테이션(RTR) 및 블랙리스트 보안 로직 검증.
    - `AuthService` 내 Rate Limiting 및 계정 잠금 정책 명문화.
- **USR (사용자/조직)**: 
    - **[중요]** `OrgService` 지연 로딩(`MissingGreenlet`) 에러 해결 (Pydantic 스키마 선변환 방식 도입).
    - 조직도 순환 참조(`Circular Reference`) 방지 로직 보강 및 테스트 통과.
- **FAC (시설/공간)**: 
    - `FacilityService` 인자 중복 전달 오류(`TypeError`) 수정.
    - 계층형 공간 트리 조회 로직 최적화.

### ✅ 코드 표준화 (Documentation)
- 모든 도메인 서비스(`services.py`) 및 라우터(`router.py`)에 **Google Style Docstring** 전수 적용.
- `core` 레이어(security, database, responses) 문서화 완료.

---

## 2. 🗄️ 데이터베이스 (Database) 작업 현황

### ✅ 스키마 최신화 및 무결성 보강
- **스키마 패치**: `fac.spaces` 테이블에 누락된 `org_id` (관리 책임 부서) 컬럼 추가 완료.
- **제약 조건**: 모든 식별 코드에 대문자 강제 제약(`CHECK code = UPPER(code)`) 적용 확인.
- **문서화**: `database/sql/` 내 모든 `.pgsql` 파일에 상세 `COMMENT ON` 주석 보강 완료.

---

## 💻 3. 프론트엔드 (Frontend) 작업 현황

### ✅ 환경 구성 및 기초 구현
- **기술 스택 최적화**: React 19 호환을 위한 `v5-patch-for-react-19` 적용 및 `antd v5` 안정화.
- **인증 시스템**: `Zustand` 기반 `useAuthStore` 구현 및 로컬 스토리지 연동.
- **로그인 페이지**: Ant Design v5 기반의 고밀도(High Density) 로그인 UI 구현 및 API 연동 완료.
- **메인 레이아웃**: 로그인 사용자 이름 표시, 로그아웃 드롭다운 메뉴 및 `ProLayout` 메뉴 구조 동기화 완료.

---

## 🛠️ 4. 시스템 환경 및 이슈 해결

- **빌드 에러 해결**: 불필요하고 컴파일 오류를 유발하던 `pyroonga` 의존성 제거.
- **실행 환경**: `uv sync`를 통한 가상환경 정상화 및 백엔드(8000), 프론트엔드(5173) 서버 가동 중.

---

## 🚀 향후 계획 (Next Steps)

1. **공통 코드 관리 화면 완성**: `CMM` 도메인 API를 활용한 실제 CRUD 연동.
2. **조직도 관리 화면**: 계층형 트리를 시각적으로 관리하는 UI 구현.
3. **시설물 관리 화면**: `FAC` 데이터 연동 및 상세 정보 페이지 개발.
4. **통합 시나리오 테스트 확대**: 더 복잡한 업무 흐름에 대한 전수 검사.
