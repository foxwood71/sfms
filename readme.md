# SFMS (Smart Facility Management System)

## 1. 프로젝트 개요 (Project Overview)

- **프로젝트명**: SFMS
- **목표**: 하수처리시설 종합관리 시스템 구축 (추후 범용 CMMS 확장 고려)
- **핵심 가치**:
  - **Data Density High**: 엔터프라이즈급 데이터 밀집형 UI (Ant Design Pro `size="small"`)
  - **Domain Driven**: 3-Letter Code 기반의 명확한 도메인 분리
  - **Stability**: 레가시 데이터의 안정적인 마이그레이션 및 이력 관리
- **개발 환경**: 1인 개발 (Full-stack), Docker 기반의 컨테이너 환경

---

## 2. 기술 스택 (Tech Stack)

### Infrastructure (DevOps)

- **Container**: Docker, Docker Compose (v3.8+)
- **Gateway**: Nginx (Reverse Proxy)
- **Storage**: MinIO (S3 Compatible) - 도면, PDF, 문서 저장소
- **Management**: Portainer (Optional)

### Backend (Logic & Data)

- **Language**: Python 3.11+
- **Framework**: FastAPI (Async)
- **Database**: PostgreSQL 15+
- **ORM**: SQLAlchemy (Async Engine)
- **Schema Validation**: Pydantic v2
- **Linter**: Flake8

### Frontend (UI/UX)

- **Framework**: React 18 + Vite (SPA)
- **Language**: TypeScript
- **UI Library**: Ant Design v5 + ProComponents (ProTable, ProForm)
- **State Management**: TanStack Query (React Query)
- **Style**: Tailwind CSS + AntD Token System

---

## 3. 시스템 아키텍처 (Architecture)

```mermaid
graph TD
    %% 외부 사용자 정의
    User["👨‍💻 일반 사용자 (Browser)"]
    Admin["🔧 관리자 (Browser)"]

    %% 게이트웨이
    User -->|HTTP/HTTPS 80/443| Nginx["Nginx Gateway"]

    subgraph DockerNet ["🐳 Docker(sfms net)"]
        direction TB

        %% 1. 서비스 영역 (App Zone)
        subgraph AppZone ["Application Services"]
            direction TB
            Nginx -->|/| Frontend["React (Vite)"]
            Nginx -->|/api| Backend["FastAPI"]
            Nginx -->|/minio| MinIO_UI["MinIO Console"]

            Backend -->|SQL| DB[("PostgreSQL")]
            Backend -->|S3 API| MinIO_Svc[("MinIO Storage")]
        end

        %% 2. 관리 영역 (Management Zone)
        subgraph MgmtZone ["Management Tools"]
            direction TB
            %% 관리자는 보통 포트 포워딩으로 직접 접속하거나 내부망 사용
            Admin -.->|":9000"| Portainer["Portainer"]
            Admin -.->|":3000"| Gitea["Gitea"]
            Admin -.->|":5050"| PgAdmin["PgAdmin"]

            Portainer -->|Socket| DockerSocket["Docker Daemon"]
            PgAdmin -->|SQL| DB
            Gitea -->|Git Data| GiteaVol[("Gitea Volume")]
        end
    end
```

---

## 4. 도메인 정의 (Domain 3-Letter Code)

모든 디렉토리, 테이블, API 경로는 아래 코드를 기준으로 네이밍합니다.

| 코드 |     명칭     |             설명              |      비고       |
| :--: | :----------: | :---------------------------: | :-------------: |
| CMM  |    Common    |  공통코드, 파일, 알림, 로그   |   시스템 기반   |
| IAM  |   Identity   | 인증, 권한(Role), 메뉴, API키 | 보안 (USR 분리) |
| USR  |     User     |       직원 정보, 조직도       |    인사 정보    |
| FAC  |   Facility   |    시설/공간 (건축, 토목)     |    위치/장소    |
| EQP  |  Equipment   | 설비/장치 (기계, 전기, 계측)  |   핵심 도메인   |
| WQT  | WaterQuality |        수질 분석, LIMS        |  하수처리 특화  |
| INV  |  Inventory   |       자재, 재고, 약품        |                 |
| PTN  |   Partner    |           업체 관리           |                 |
| AST  |    Asset     |     일반 자산 (PC, 차량)      |                 |
| SPT  |   Support    |         게시판, 포털          |                 |
| RPT  |    Report    |         통계, 보고서          |                 |

---

## 5. 디렉토리 구조 (Directory Structure)

### 5.1 Backend (/backend)

파이썬의 "명시적 해결책" 철학을 준수하며, 기능별로 파일을 분리

```text
backend/
├── app/
│   ├── core/
│   │   ├── config.py          # 환경설정 (.env 로드)
│   │   └── database.py        # DB 세션 (app.core.database)
│   ├── api/
│   │   └── v1/
│   │       ├── endpoints/     # API 라우터 (도메인별 분리)
│   │       │   ├── cmm.py
│   │       │   ├── fac.py
│   │       │   └── eqp.py
│   │       └── api.py         # 라우터 통합
│   ├── schemas/               # Pydantic 모델 (Request/Response)
│   │   ├── fac_schema.py
│   │   └── eqp_schema.py
│   ├── models/                # SQLAlchemy 모델 (DB Tables)
│   │   ├── fac_model.py
│   │   └── eqp_model.py
│   └── services/              # 비즈니스 로직
│       ├── fac_service.py
│       └── eqp_service.py
├── tests/                     # Pytest
├── Dockerfile
├── requirements.txt
└── main.py                    # 앱 진입점
```

### 5.2 Frontend (/frontend)

Vite 기반 React 프로젝트 구조입니다.

```text
frontend/
├── src/
│   ├── assets/
│   ├── components/            # 공통 컴포넌트
│   ├── pages/                 # 화면 단위 (도메인별 폴더링)
│   │   ├── FAC/               # [시설]
│   │   │   ├── FacilityList.tsx
│   │   │   └── FacilityDetail.tsx
│   │   ├── EQP/               # [설비]
│   │   │   ├── EquipmentList.tsx
│   │   │   └── EquipmentRegister.tsx
│   │   └── ...
│   ├── services/              # API 호출 함수 (Axios)
│   │   ├── facService.ts
│   │   └── eqpService.ts
│   ├── types/                 # TypeScript 인터페이스
│   │   ├── fac.d.ts
│   │   └── eqp.d.ts
│   └── App.tsx
├── Dockerfile
├── package.json
└── vite.config.ts
```

### 5.3 Infrastructure (/infra)

Vite 기반 React 프로젝트 구조입니다.

```text
infra/
├── docker-compose.yml         # 전체 컨테이너 오케스트레이션
├── nginx/
│   └── default.conf           # 라우팅 설정
├── pgsql/
│    └── init.sql              # DB 초기화 스크립트
├── pgadmin/
├── gitea/
└── data/               # [데이터] DB, 파일, 로그 저장소 (Git 관리 X !!!)
    ├── pgsql/          # PostgreSQL 데이터 파일들이 저장될 곳
    ├── minio/          # MinIO에 업로드된 PDF, 도면 파일들
    ├── logs/           # 백엔드/프론트엔드 로그 파일
    ├── gitea/          # Offline 버전관리 프로그램
    └── pgadm/          # Database 관리프로그램
```

---

## 6. 개발 규칙 (Convention)

### 6.1 Database (PostgreSQL)

1. Naming: Snake Case (eqp_master, created_at).
2. Comment: 모든 테이블과 컬럼에 COMMENT ON 필수 작성.
3. Migration: Alembic 사용, 버전 파일은 Git 관리.

### 6.2 Python (Backend)

1. Style: Flake8 준수.

2. Indent: Space 4 (Tabs 금지).

3. Inline Comment: 코드와 주석 사이에 Space 2개 삽입 (code # comment).

4. DB Connection: DB 연결 객체 명칭은 app.core.database로 통일.

### 6.3 TypeScript (Frontend)

1. UI: Ant Design ProTable 적극 활용 (size="small").

2. Popup: 상세 화면은 Modal보다 Drawer(우측 패널) 우선 사용.

3. Structure: View(Component)와 Logic(Service)의 철저한 분리.

4. any와 unknow의 사용의 최대한 억제

---

## 7. 주요 구현 로드맵 (Roadmap)

1. Phase 1 (환경 구축): Docker Compose (DB, MinIO, FastAPI, React) 실행 확인.

2. Phase 2 (기반 마련): IAM(로그인), CMM(공통코드) 구현.

3. Phase 3 (핵심 마이그레이션): 레가시 DB 분석 -> FAC(시설), EQP(설비) 신규 설계 및 이관.
