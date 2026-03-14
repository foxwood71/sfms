# SFMS Phase 1 작업 진행 상황

## 📋 프로젝트 개요

- **목표**: 시설 유지보수 관리 시스템(SFMS) 1단계 기반 구축
- **기술 스택**: FastAPI, React 19, PostgreSQL 16, Redis, Podman
- **현재 가동 포트**: 8000 (Backend), 5173 (Frontend)

## 🛠️ 세부 진행 현황

### 1. 인프라 및 설정 (CORE)

- [x] Podman 기반 컨테이너 환경 구축 (PgSQL, Redis, MinIO)
- [x] Redis 7 인증 및 권한 설정 (Fail-open 정책 적용)
- [x] MinIO 스토리지 연동 및 버킷 설정
- [x] **DB 통합 배포 스크립트 완성** (`00_deploy.pgsql`): 계정 생성, 권한 부여, 기초 데이터 일괄 처리
- [x] **VSCode 설정 최적화**: Biome 중심의 포매팅/린팅 표준화 및 이식성 개선

### 2. 프론트엔드 공통 (SHARED) - ✅ 표준화 완료 (2026-03-14)

- [x] **Bento Standard v1.0 수립**: 100vh 고정 레이아웃, Splitter 비율 유지, 12px 라운드 박스 스타일
- [x] **Smart Scroll 정책 적용**: Zero-Card-Scroll 및 10-Row Rule (테이블/트리 공통)
- [x] **글로벌 i18n 시스템 구축**: `messages.ts` 기반 Zero Hardcoded Strings 원칙 수립
- [x] **범용 엑셀(Excel) 모듈 완성**: 멀티 시트 다운로드, 안전 업로드(확인 모달), 공통 유틸리티화
- [x] **멀티 테마 시스템**: Deep Navy, K-Gov, Soft Mac 등 5가지 테마 선택 및 영속성 구현
- [x] **가독성 최적화**: Noto Sans KR 및 Pretendard 폰트 전역 적용

### 3. 인증 및 권한 (IAM / USR)

- [x] JWT 기반 로그인/로그아웃 및 RTR(Rotation) 구현
- [x] 사용자 권한(Resource/Action) 기반 **동적 메뉴 필터링**
- [x] **시스템 관리자 정보 갱신**: ID: `admin`, PW: `admin1234`, Role: `SUPER_USER`

### 4. 사용자 및 조직 관리 (USR) - ✅ Bento 표준 적용 완료

- [x] **조직도 관리 고도화**: Bento 레이아웃 적용, 가상 루트(회사명) 트리 구조 통일
- [x] **사용자 관리 기능 완성**: 스마트 스크롤 테이블, 드로어 기반 상세/편집, 텍스트 가독성 강화
- [x] **데이터 정합성**: 사번/계정 상태 관리 보강 및 더미 데이터(20여명) 구축

### 5. 공통 기능 (CMM) - ✅ Bento 표준 적용 완료

- [x] **공통 코드 관리 리팩토링**: Splitter 기반 그룹/상세 분할 레이아웃, 드로어 편집 시스템
- [x] **엑셀 통합**: 전역 코드 백업 및 상세 코드 대량 등록을 위한 엑셀 모듈 연동
- [x] **백엔드 고도화**: 전체 상세 코드 조회 API (`/details/all`) 및 데이터 백업 로직 추가

### 6. 시스템 및 감사 (SYS)

- [ ] 감사 로그(Audit Log) 조회 및 상세 필터링 페이지 (다음 작업 예정)
- [x] API 테스터 도구 통합 및 표준 레이아웃 적용

---

## 📝 향후 개선 과제 (TODO)

- [ ] **엑셀 Bulk 저장 (Back-end) 완성**
  - **목표**: 프론트엔드에서 파싱된 엑셀 데이터를 실제 DB에 일괄 저장(`Upsert`)하는 로직 구현.
- [ ] **시설 관리(FAC) 도메인 고도화**
  - 공간 및 시설 정보 등록/조회 기능에 Bento Standard v1.0 이식 및 엑셀 기능 확장.
- [ ] **대시보드(Dashboard) 시각화**
  - 시설 가동 현황 및 점검 통계 위젯(Chart) 구성.
- [ ] **다국어 리소스 확장**
  - `en/messages.ts` 추가를 통한 영문 버전 테스트.
