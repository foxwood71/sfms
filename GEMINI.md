# 🤖 SFMS 프로젝트 Gemini 작업 가이드

이 파일은 SFMS 프로젝트의 백엔드 및 프론트엔드 개발 표준과 작업 문맥을 기록합니다. Gemini CLI 세션이 시작될 때 이 내용을 반드시 숙지하십시오.

## 📋 핵심 기술 표준 (2026-03-23 최신화)

### 1. 백엔드 (FastAPI & Python 3.13)

* **문서화 (Docstring)**: 모든 서비스 클래스 및 라우터 메서드에 **Google Style Docstring**을 필수로 적용합니다.
* **권한 데이터 구조**: 슈퍼유저 권한은 반드시 `{"ALL": ["*"]}` 형태의 JSON 객체로 관리합니다. (리스트 형태 지양)
* **코드 규격 관리**: `cmm.code_groups`의 `code_length`와 `is_seq_used` 필드를 참조하여 도메인별 자산 코드를 자동 생성합니다.

### 2. 프론트엔드 (React 19 & Ant Design v5)

* **🚨 Zero Any Policy**: 모든 타입은 인터페이스나 유니온 타입으로 구체화해야 합니다.
* **📏 코드 밀도 및 분리 표준 (Code Density & Separation)**:
  * **라인 수 제한**: 파일당 **100~200라인 내외**를 유지하며, 250라인 초과 시 반드시 컴포넌트 분리 또는 로직 추출을 수행합니다.
  * **관심사 분리**: 비즈니스 로직(상태 관리, API 호출, 데이터 가공)은 반드시 **Custom Hooks(`hooks/`)**로 추출하고, `.tsx`는 UI 렌더링에만 집중합니다.
  *   **컴포넌트화**: 반복되는 UI 패턴은 원자 단위 컴포넌트로 분리하여 재사용성을 극대화합니다. 페이지 전용 서브 컴포넌트는 해당 페이지 폴더의 `components/` 디렉토리에서 관리합니다.
  *   **🚀 성능 및 번들 최적화 (Bundle Optimization)**:
      *   **Route-based Code Splitting**: 모든 페이지 단위 컴포넌트는 `React.lazy()`와 `Suspense`를 사용하여 라우트 기반 코드 분할을 필수 적용합니다.
      *   **Vendor Chunking**: `antd`, `react`, `lucide-react` 등 대용량 외부 라이브러리는 Vite 설정을 통해 별도의 벤더 청크로 분리하여 브라우저 캐싱 효율을 높입니다.
      *   **Threshold**: 단일 JS 청크 크기가 **500kB(Gzip 전)**를 초과할 경우, 반드시 컴포넌트 세분화 또는 동적 임포트(`import()`) 적용을 검토합니다.
  *   **UI/UX 벤또 표준 (Bento Standard v1.1 - Refined)**:

  * **Single Bento Box**: 각 페이지의 메인 콘텐츠는 `borderRadius: 12px`, `overflow: hidden`, `boxShadow`가 적용된 **하나의 거대한 카드** 안에 담겨야 합니다.
  * **Solid Header Bar**: 헤더 영역은 `background: colorFillAlter`, `minHeight: 56px`, `padding: 0 20px`를 유지하여 안정감을 줍니다.
  * **Splitter Control**: 좌측 패널(트리 등)의 조절 범위는 **15% ~ 40%**로 제한하며, 우측 패널은 최소 **50%**를 보장합니다.
  * **Perfect Centering**: 데이터가 없는 `Empty` 상태는 가로/세로 기하학적 정중앙에 배치합니다.
* **Tree UX**:
  * **Recursive Search**: 트리 노드 선택 시 재귀 탐색(`findOrgInTree`)을 사용하여 말단 노드(Leaf) 선택 누락을 방지합니다.
  * **Smart Toggle**: 전체 펼치기/접기 기능을 하나의 지능형 토글 버튼으로 통합합니다.
  * **Initial State**: 페이지 로드 시 트리는 항상 **전체 펼침** 상태로 시작합니다.

### 3. 데이터베이스 설계 및 배포 표준 (PostgreSQL 16)

* **Phase 기반 배포**: `0xx`(인프라/부트스트랩) -> `1xx`(테이블) -> `9xx`(제약조건/데이터) 순으로 배포합니다.
* **ID 0 보호**: "시스템 관리(ID 0)" 노드는 엔진 전용으로 보호하며 하위 생성을 제한합니다.
* **참조 표준**: 3자리 영문 대문자 코드를 식별자로 사용하며 복합 외래키로 무결성을 보장합니다.

### 4. 인프라 및 실행 표준 (Podman Compose)

* **프론트엔드 빌드 최적화**: `nginx` 실행 시 매번 빌드되는 것을 방지하기 위해 `frontend` 서비스에 `build` 프로파일을 적용했습니다.
  * **일반 실행 (빌드 생략)**: `podman compose up -d`
  * **프론트엔드 빌드 포함 실행**: `podman compose --profile build up -d`
  * **빌드만 수행**: `podman compose --profile build up frontend`

## 🛠️ 작업 이력 및 문맥 (최근)

* **프론트엔드 빌드 옵션화**: `profiles: ["build"]` 설정을 통해 Nginx 실행 시 프론트엔드 빌드 여부를 선택할 수 있도록 개선 (2026-04-22).

* **Bento UI 고도화 완료**: 단일 벤토 박스 레이아웃 및 56px 헤더 바 표준 전면 적용.
* **조직도 로직 완결**: 재귀 탐색을 통한 말단 부서 선택 오류 및 ID 0 처리 이슈 해결.
* **DB 통합 배포 성공**: Phase 기반의 새로운 SQL 아키텍처로 전체 데이터베이스 재구축 완료.
---
