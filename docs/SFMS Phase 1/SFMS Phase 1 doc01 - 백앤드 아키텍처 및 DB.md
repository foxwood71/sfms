# 📘 SFMS Phase 1: 통합 설계서 (Foundation & Security)

* **프로젝트명:** SFMS (Sewage Facility Management System)
* **최종 수정일:** 2026-03-08
* **단계:** Phase 1 (기반 구축 및 보안)
* **기술 스택:**
    * **Backend:** Python 3.13, FastAPI, SQLAlchemy 2.0 (Async), Pydantic v2
    * **Database:** PostgreSQL 16 + **PGroonga** (한글/JSONB 검색 최적화)
    * **Caching:** Redis (Session, Blacklist, Sequence Lock)
    * **Testing:** Pytest + **AnyIO** (pytest-asyncio 미사용)

---

## 1. 🏗️ 프로젝트 구조 (Project Structure)

**Domain-Driven Design (DDD)**의 경량화 버전인 Modular Monolith 구조를 채택하여 도메인 간 독립성을 유지합니다.

```text
backend/
├── app/
│   ├── core/               # 전역 설정 및 인프라 레이어
│   │   ├── config.py       # 환경변수 및 전역 설정
│   │   ├── database.py     # SQLAlchemy 엔진 및 세션 관리
│   │   ├── security.py     # bcrypt(Python 3.13) 암호화 및 JWT 로직
│   │   ├── responses.py    # APIResponse 표준 규격 정의
│   │   ├── dependencies.py # Annotated 기반 공통 의존성
│   │   ├── codes.py        # 시스템 공통 에러/성공 코드
│   │   └── exceptions.py   # 커스텀 예외 클래스
│   ├── api/v1/             # API 엔드포인트 통합 레이어
│   │   └── api_router.py   # 모든 도메인 라우터 통합
│   ├── domains/            # 비즈니스 로직 레이어 (도메인별 격리)
│   │   ├── {domain}/       # cmm, sys, iam, usr, fac 등
│   │   │   ├── __init__.py # 도메인 코드 정의 (DOMAIN = "FAC" 등)
│   │   │   ├── models.py   # SQLAlchemy 테이블 모델
│   │   │   ├── schemas.py  # Pydantic 데이터 검증 스키마
│   │   │   ├── services.py # 핵심 비즈니스 로직 (Service Class)
│   │   │   └── router.py   # FastAPI API 엔드포인트
│   └── main.py             # FastAPI 애플리케이션 진입점
├── database/               # PGSQL 스키마 DDL 및 시드 데이터
├── scripts/                # 관리용 쉘/파이썬 스크립트
└── tests/                  # AnyIO 기반 도메인/통합 테스트
```

---

## 📜 2. 코드 문서화 표준 (Python Docstrings)

백엔드 모든 코드는 **Google Style Docstrings**를 표준으로 사용하며, VS Code 인텔리센스 지원을 극대화합니다.

### 2.1 클래스 및 메서드 가이드
* 모든 도메인 서비스(`Service`) 및 라우터(`Router`) 메서드는 독스트링을 필수로 포함합니다.
* 클래스 상단에는 클래스의 역할과 책임을 기술합니다.

```python
class FacilityService:
    """시설물 관련 비즈니스 로직을 처리하는 클래스입니다.
    
    이 클래스는 시설의 생성, 수정, 삭제 및 공간 계층 구조 조립을 담당합니다.
    """

    @staticmethod
    async def create_facility(db: AsyncSession, obj_in: FacilityCreate, actor_id: int) -> FacilityRead:
        """신규 시설을 데이터베이스에 등록합니다.

        Args:
            db (AsyncSession): 비동기 DB 세션
            obj_in (FacilityCreate): 시설 생성 정보 스키마
            actor_id (int): 행위 수행자의 고유 ID

        Returns:
            FacilityRead: 생성된 시설 정보 (지연 로딩 방지를 위해 스키마로 변환됨)

        Raises:
            ConflictException: 동일한 시설 코드가 이미 존재할 경우 발생
        """
        # ... 구현부
```

---

## 🗄️ 3. 데이터베이스 및 삭제 정책

### 3.1 삭제 전략 (Delete Policy)

데이터의 성격에 따라 삭제 방식을 이원화하여 데이터 무결성을 보장합니다.

* **Soft Delete (논리 삭제)**: 참조 관계가 복잡하고 이력 보존이 중요한 엔티티.
    * 대상: `User` (`is_active` 필드 사용), `Attachment` (`is_deleted` 필드 사용).
* **Hard Delete (물리 삭제 + 제약)**: 구조적 틀을 형성하는 엔티티.
    * 대상: `Organization`, `Space`, `Role`, `SequenceRule`.
    * 제약: 하위 데이터(자식 노드 또는 소속 사용자)가 존재할 경우 삭제가 엄격히 차단됨 (`ConflictException`).

---

## 🛠️ 4. 백엔드 개발 표준 (Engineering Standards)

### 4.1 의존성 주입 (Dependency Injection)
반드시 `Annotated` 문법을 사용하며, 기본값이 있는 인자(`Query` 등)는 매개변수 목록의 가장 뒤에 배치합니다.
```python
db: Annotated[AsyncSession, Depends(get_db)]
```

### 4.2 서비스 레이어 및 지연 로딩 방지 (중요)
비동기 환경에서의 `MissingGreenlet` 에러를 원천 차단하기 위해, 서비스 레이어는 항상 **SQLAlchemy 모델 대신 Pydantic Read 스키마를 반환**해야 합니다.
* **전략**: 트리 구조 조립 시 모델 데이터를 딕셔너리로 추출하여 스키마를 생성하거나, `joinedload`를 통해 관계를 즉시 로드합니다.

### 4.3 보안 (Security)
* **Password**: Python 3.13 호환성을 위해 `passlib` 대신 **`bcrypt` 라이브러리를 직접 호출**하여 해싱합니다.
* **JWT**: 리프레시 토큰 로테이션(RTR) 및 Redis 기반 블랙리스트를 필수로 적용합니다.

---

## 📡 5. 인터페이스 규격 (API Standard)

### 5.1 공통 응답 (Envelope Pattern)
모든 응답은 `APIResponse` 클래스를 사용하며, 생성 시 해당 도메인 코드를 인자로 전달합니다.
```json
{
  "success": true,
  "domain": "FAC",
  "code": 200,
  "message": "성공",
  "data": { ... }
}
```
---
