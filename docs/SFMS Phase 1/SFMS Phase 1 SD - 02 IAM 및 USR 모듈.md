# 📐 SFMS Phase 1 - 핵심 로직 시퀀스 다이어그램 (02. IAM & 03. USR)

* **문서 버전:** v1.0
* **작성일:** 2026-02-17
* **관련 모듈:** `IAM(Auth, Roles)`, `USR(Users, Orgs)`

---

## 1. 🔐 IAM: 로그인 및 토큰 발급 (Login & Token Issue)

단순한 ID/PW 확인을 넘어, **계정 잠금(Brute Force 방어)**, **감사 로그**, **Refresh Token 저장**까지 포함된 보안 흐름입니다.

### 1.1 핵심 로직 설명

1. **Rate Limiting:** IP 기반의 로그인 시도 횟수를 Redis로 제한합니다.
2. **Account Lock:** 연속 5회 실패 시 계정을 잠급니다 (`is_locked` 또는 `fail_count` 체크).
3. **Audit Log:** 로그인 성공/실패 여부를 반드시 기록합니다 (보안 감사 필수 요건).
4. **Token Pair:** Access Token(Stateless)과 Refresh Token(Stateful in Redis)을 동시 발급합니다.

### 1.2 Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor Client
    participant API as Auth Controller
    participant Service as AuthService
    participant Redis as Redis (Limit/Token)
    participant DB as PostgreSQL

    Client->>API: POST /auth/login (id, pw)
    
    API->>Service: authenticate_user()
    
    activate Service
    
    Service->>Redis: Check Rate Limit (IP)
    alt Limit Exceeded
        Redis-->>Service: Block
        Service-->>Client: 429 Too Many Requests
    end
    
    Service->>DB: SELECT * FROM users WHERE login_id=?
    
    alt User Not Found
        Service-->>Client: 401 Auth Failed (Generic Msg)
    else User Found
        alt Is Locked? (fail_count >= 5)
            Service-->>Client: 403 Account Locked
        end
        
        Service->>Service: Verify Password (Bcrypt)
        
        alt Password Mismatch
            Service->>DB: UPDATE fail_count + 1
            Service->>DB: INSERT audit_log (LOGIN_FAIL)
            Service-->>Client: 401 Auth Failed
        else Password Match
            Service->>DB: UPDATE fail_count = 0, last_login = Now
            Service->>DB: INSERT audit_log (LOGIN_SUCCESS)
            
            Service->>Service: Create Access Token (JWT)
            Service->>Service: Create Refresh Token (Random String)
            
            Service->>Redis: SET refresh:{user_id} = {token} (TTL 2 weeks)
            
            Service-->>Client: 200 OK (Tokens + User Info)
        end
    end
    deactivate Service

```

---

## 2. 🛡️ IAM: 권한 인가 가드 (Authorization Guard)

모든 API 요청 시 수행되는 **미들웨어(Dependency)** 레벨의 로직입니다.

### 2.1 핵심 로직 설명

1. **JWT Verification:** 서명(Signature)과 만료(Exp)를 확인합니다.
2. **Blacklist Check:** 로그아웃된 토큰인지 Redis에서 확인합니다.
3. **Permission Check:** 해당 API가 요구하는 권한(예: `FAC:UPDATE`)을 유저가 보유했는지 확인합니다.
* *최적화:* 매번 DB에서 권한을 조회하면 느리므로, 로그인 시 발급된 **Token의 Payload(Claims)** 또는 **Redis 캐시**를 활용합니다.



### 2.2 Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor Client
    participant Guard as Auth Middleware (Depends)
    participant JWT as JWT Handler
    participant Redis as Redis (Blacklist)
    participant API as Target API (e.g., DELETE /facilities/1)

    Client->>Guard: Request + Header [Bearer Token]
    
    Guard->>JWT: Decode & Verify Token
    
    alt Invalid / Expired
        JWT-->>Guard: Error
        Guard-->>Client: 401 Unauthorized
    end
    
    Guard->>Redis: GET blacklist:{jti}
    alt Is Blacklisted?
        Redis-->>Guard: True
        Guard-->>Client: 401 Token Invalidated (Logout)
    end
    
    Note right of Guard: 권한 검증 (Permission Check)
    
    Guard->>Guard: Check user_permissions vs Required("FAC:DELETE")
    
    alt Has Permission
        Guard->>API: Call Endpoint (Inject current_user)
        API-->>Client: 200 OK
    else No Permission
        Guard-->>Client: 403 Forbidden
    end

```

---

## 3. 🌳 USR: 조직도 트리 조회 (Organization Tree Assembly)

DB의 Flat 데이터(Adjacency List)를 프론트엔드용 **계층형 트리(Nested JSON)**로 변환하는 로직입니다.

### 3.1 핵심 로직 설명

1. **Fetch All:** DB에서는 `WHERE is_active=true` 조건으로 전체 목록을 한 번에 가져옵니다 (N+1 문제 방지).
2. **In-Memory Build:** Python의 Dictionary Reference를 활용하여 O(N) 복잡도로 트리를 조립합니다.
3. **Cache:** 조직도는 변경 빈도가 낮고 조회 빈도가 높으므로 **Redis 캐싱**이 필수입니다.

### 3.2 Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor Client
    participant API as Org Controller
    participant Redis as Redis Cache
    participant DB as PostgreSQL
    participant Util as Tree Builder (Python)

    Client->>API: GET /orgs?mode=tree
    
    API->>Redis: GET "usr:org_tree"
    
    alt Cache Hit
        Redis-->>API: Return JSON Tree
        API-->>Client: 200 OK
    else Cache Miss
        API->>DB: SELECT * FROM organizations ORDER BY sort_order
        DB-->>API: List[Org] (Flat Data)
        
        activate Util
        API->>Util: list_to_tree(flat_data)
        Util->>Util: Iterate & Link Parent-Child
        Util-->>API: List[OrgNode] (Nested)
        deactivate Util
        
        API->>Redis: SETEX "usr:org_tree", 3600, JSON
        API-->>Client: 200 OK
    end

```

---

## 4. 🔄 USR: 조직 이동 및 순환 참조 방지 (Circular Check)

부서 이동 시 **자신의 하위 부서 밑으로 들어가는 모순(Cycle)**을 방지하는 로직입니다.

### 4.1 핵심 로직 설명

1. **Validation:** 자기 자신을 부모로 설정하는지 확인.
2. **Descendant Check:** 이동하려는 `target_parent_id`가 나의 자손(Descendant)인지 확인해야 합니다.
* DB의 `RECURSIVE CTE` 쿼리나, 메모리에 로드된 트리에서 탐색을 수행합니다.


3. **Cache Eviction:** 구조가 변경되면 Redis의 `usr:org_tree` 키를 삭제합니다.

### 4.2 Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor Client
    participant API as Org Controller
    participant Service as Org Service
    participant DB as PostgreSQL
    participant Redis as Redis

    Client->>API: PATCH /orgs/10 (parent_id=50)
    Note right of Client: 10번 부서를 50번 산하로 이동 시도
    
    API->>Service: update_organization(id=10, parent_id=50)
    
    activate Service
    Service->>DB: SELECT * FROM organizations (All or CTE)
    DB-->>Service: Org Structure
    
    Service->>Service: Check Circular Dependency
    Note right of Service: 50번이 10번의 자식/손자인가?
    
    alt Is Circular? (Yes)
        Service-->>API: Raise CircularReferenceError
        API-->>Client: 400 Bad Request ("하위 부서로 이동 불가")
    else Valid (No)
        Service->>DB: UPDATE organizations SET parent_id=50 WHERE id=10
        
        Service->>Redis: DEL "usr:org_tree" (Cache Clear)
        
        Service-->>API: Return Updated Org
        API-->>Client: 200 OK
    end
    deactivate Service

```

---

## 5. 👨‍💻 개발자 구현 가이드 (Implementation Tips)

### 1. IAM (인증)

* **비밀번호 해싱:** `passlib.context.CryptContext(schemes=["bcrypt"])` 사용을 권장합니다.
* **JWT 라이브러리:** `PyJWT` 또는 `python-jose`를 사용하며, 알고리즘은 `HS256`이 가장 무난합니다.

### 2. USR (조직)

* **트리 조립 유틸리티 (Python 예시):**
```python
def list_to_tree(nodes):
    tree = []
    node_map = {node['id']: node for node in nodes}
    for node in nodes:
        node['children'] = []  # 초기화
    for node in nodes:
        parent_id = node.get('parent_id')
        if parent_id and parent_id in node_map:
            node_map[parent_id]['children'].append(node)
        else:
            tree.append(node) # 최상위 노드
    return tree

```


* **순환 참조 방지:** DB 쿼리보다는 **메모리 상에서 전체 트리를 로드한 후 검사**하는 것이 구현 난이도가 낮고 성능상(데이터가 1만 건 이하라면) 큰 문제가 없습니다.
