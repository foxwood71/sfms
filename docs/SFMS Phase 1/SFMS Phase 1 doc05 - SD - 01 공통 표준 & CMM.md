# 📐 SFMS Phase 1 - 핵심 로직 시퀀스 다이어그램 (01. 공통 표준 & CMM)

* **문서 버전:** v1.0
* **작성일:** 2026-02-17
* **관련 모듈:** `Core(Middleware)`, `CMM(Codes, Files, Sequence)`

---

## 1. 🌐 표준 요청/응답 및 예외 처리 흐름 (Global Request Flow)

모든 API 요청이 거쳐가는 **미들웨어(Middleware)**와 **전역 예외 처리(Global Exception Handler)**의 작동 원리를 정의합니다.

### 1.1 핵심 로직 설명

1. **Annotated Pattern:** 모든 의존성 주입(`Depends`) 및 요청 파라미터(`Query`, `Path`)는 `Annotated[Type, Component]` 문법을 사용합니다. 기본값은 반드시 `Annotated[...] = default` 형태로 외부에 선언합니다.
2. **Schema-First Service:** 서비스 레이어는 SQLAlchemy 모델 대신 **Pydantic 스키마(Read Schema)**를 반환하여 지연 로딩(Lazy Loading) 충돌 및 직렬화 오류를 사전에 방지합니다.
3. **Trace ID:** 요청 진입 시 `X-Request-ID`가 없으면 생성하여 `ContextVar`에 저장 (로그 추적용).
4. **Global Handler:** 비즈니스 로직에서 `SFMSException`이 발생하면, 이를 가로채어 표준 `APIResponse` 포맷으로 변환합니다.
5. **Response Wrapper:** 모든 응답은 `APIResponse` 객체로 감싸서 일관된 포맷을 보장합니다. (위치/키워드 인자 모두 지원)

### 1.2 Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor Client as Client (React)
    participant Nginx as Web Server (Nginx)
    participant Mid as Middleware (FastAPI)
    participant Router as API Router
    participant Service as Domain Service
    participant ErrHandler as Global Exception Handler

    Note over Client, Mid: Standard HTTP Request

    Client->>Nginx: API Request (GET /users)
    Nginx->>Mid: Forward Request
    
    activate Mid
    Mid->>Mid: Generate Trace ID (UUID)<br/>Set to ContextVar
    
    Mid->>Router: Call Endpoint
    activate Router
    
    Router->>Service: Execute Logic
    activate Service
    
    alt 정상 처리 (Success)
        Service-->>Router: Return Data (List[User])
        Router-->>Mid: Return Response
        Mid-->>Client: 200 OK + ApiResponse (Success=True)
        
    else 예외 발생 (Business Error)
        Service-->>Router: Raise SFMSException(domain="USR", error_code=4090)
        deactivate Service
        Router-->>ErrHandler: Catch Exception
        deactivate Router
        
        activate ErrHandler
        ErrHandler->>ErrHandler: Format Error Response<br/>(Include Trace ID)
        ErrHandler-->>Mid: Return JSONResponse
        deactivate ErrHandler
        
        Mid-->>Client: 409 Conflict + ApiResponse (Success=False)
    end
    
    deactivate Mid

```

---

## 2. 🗂️ 공통 코드 조회 및 캐싱 전략 (Code Lookup with Cache)

프론트엔드 성능 최적화를 위해 **Redis Cache-Aside 패턴**을 적용한 코드 조회 로직입니다.

### 2.1 핵심 로직 설명

1. **Cache First:** DB보다 Redis를 먼저 조회합니다.
2. **DB Fallback:** 캐시 미스(Miss) 시 DB에서 조회하고 Redis에 적재(TTL 설정)합니다.
3. **Structure:** 프론트엔드 컴포넌트(`Select`, `Radio`)가 바로 사용할 수 있는 `{value, label}` 형태로 반환합니다.

### 2.2 Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor Client
    participant API as CMM Controller
    participant Redis as Redis Cache
    participant DB as PostgreSQL

    Client->>API: GET /codes/{group_code}/lookup
    
    API->>Redis: GET "cmm:codes:{group_code}"
    
    alt Cache Hit (캐시 있음)
        Redis-->>API: Return JSON String
        API-->>Client: Return Cached Data (Fast)
    
    else Cache Miss (캐시 없음)
        Redis-->>API: Null
        
        API->>DB: SELECT * FROM code_details<br/>WHERE group_code=? AND is_active=true<br/>ORDER BY sort_order
        DB-->>API: Return Rows
        
        API->>API: Serialize to List[CodeLookUpItem]
        
        API->>Redis: SETEX "cmm:codes:{group_code}", 3600, JSON
        API-->>Client: Return Data (DB Loaded)
    end

```

---

## 3. 📂 다중 파일 업로드 및 이미지 처리 (Multi-Upload & Processing)

**트랜잭션 관리**와 **이미지 후처리(Thumbnail)**가 복합된 가장 복잡한 로직입니다.

### 3.1 핵심 로직 설명

1. **Validation:** 파일별 확장자 및 용량을 검사합니다.
2. **Processing:** 이미지(`Pillow`)는 메타데이터 제거 및 썸네일 생성을 수행합니다.
3. **IO Separation:** 스토리지 업로드(I/O)는 **DB 트랜잭션 외부**에서 수행하여 DB Lock 점유 시간을 최소화합니다.
4. **Transaction:** 모든 파일 처리가 끝난 후(또는 건별) 성공한 건에 대해서만 DB에 Insert 합니다.

### 3.2 Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor Client
    participant API as CMM File Controller
    participant Proc as Image Processor (Pillow)
    participant Storage as File Storage (Disk/S3)
    participant DB as PostgreSQL

    Client->>API: POST /files/upload (Files[])
    
    loop For Each File
        API->>API: Validate (Ext, Size)
        
        alt is Image?
            API->>Proc: Create Thumbnail & Strip Exif
            Proc-->>API: Optimized Bytes & Thumbnail Bytes
        end
        
        API->>Storage: Save File (UUID Name)
        API->>Storage: Save Thumbnail (Option)
        Storage-->>API: Return Paths
    end
    
    rect rgb(240, 248, 255)
        Note right of API: DB Transaction Start
        API->>DB: INSERT INTO cmm.attachments (Batch)
        DB-->>API: Commit
        Note right of API: DB Transaction End
    end
    
    alt All Success
        API-->>Client: 200 OK (All Files)
    else Partial Success
        API-->>Client: 200 OK (Results + Error List)
    end

```

---

## 4. 🔢 동시성 제어 채번 로직 (Atomic Sequence Generation)

여러 사용자가 동시에 문서를 생성할 때 **중복 번호**가 발생하지 않도록 보장하는 로직입니다(시스템 성능을 위해 결번 허용).

### 4.1 핵심 로직 설명

1. **Row Lock:** `SELECT ... FOR UPDATE`를 사용하여 해당 도메인의 채번 규칙 Row를 잠급니다.
2. **Atomic Increment:** 현재 순번을 메모리가 아닌 DB 레벨에서 증가시킵니다.
3. **Formatting:** `PREFIX` + `YEAR` + `LPAD(SEQ)` 형태로 포맷팅합니다.

### 4.2 Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    participant Service as Business Logic (e.g., Facility Service)
    participant Seq as Sequence Utils
    participant DB as PostgreSQL

    Note over Service: 시설물 생성 요청 발생

    Service->>Seq: get_next_sequence("FAC")
    
    rect rgb(255, 240, 240)
        Note right of DB: Transaction Start (Lock Scope)
        
        Seq->>DB: SELECT current_seq, prefix, year<br/>FROM sequence_rules<br/>WHERE domain="FAC" FOR UPDATE
        
        Note right of DB: Row Locked (Others wait)
        
        DB-->>Seq: Return (Seq=100, Year=2026)
        
        alt Year Changed? (Current != 2026)
            Seq->>Seq: Reset Seq = 1, Update Year
        else
            Seq->>Seq: Seq = Seq + 1 (101)
        end
        
        Seq->>DB: UPDATE sequence_rules SET current_seq=101
        
        Note right of DB: Transaction Commit (Lock Released)
    end
    
    Seq-->>Service: Return "FAC-2026-00101"
    
    Service->>DB: INSERT INTO facilities (code=...)

```

---

## 5. 🏥 시스템 헬스 체크 흐름 (System Health Check)

L4/L7 스위치나 K8s가 서비스 가용성을 판단하는 흐름입니다.

### 5.1 핵심 로직 설명

1. **Auth Bypass:** 인증 토큰 없이 접근 가능해야 합니다.
2. **Deep Check:** 단순히 API 서버가 뜬 것뿐만 아니라, **DB와 Redis 연결 상태**까지 확인합니다.
3. **Timeout:** 연결 확인은 1~2초 내에 빠르게 타임아웃 처리되어야 합니다.

### 5.2 Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    participant LB as Load Balancer / K8s
    participant API as System Controller
    participant DB as PostgreSQL
    participant Redis as Redis

    LB->>API: GET /system/health (No Auth)
    
    par Check DB
        API->>DB: SELECT 1
        alt Success
            DB-->>API: OK
        else Fail
            DB-->>API: Connection Error
        end
    and Check Redis
        API->>Redis: PING
        alt Success
            Redis-->>API: PONG
        else Fail
            Redis-->>API: Connection Error
        end
    end
    
    alt Both OK
        API-->>LB: 200 OK (Status: OK)
    else Any Fail
        API-->>LB: 503 Service Unavailable
        Note right of LB: Remove Instance from Pool
    end

```
