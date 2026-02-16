-- =========================================================
-- Schema: iam (Identity & Access Management)
-- Version: 1.0.0
-- Description: 인증(Authentication), 인가(Authorization), 접근 제어
-- Author: Gemini (AI Architect)
-- Created At: 2026-02-12
-- =========================================================

-- 1. 스키마 생성
CREATE SCHEMA IF NOT EXISTS iam;
COMMENT ON SCHEMA iam IS '계정, 권한, 메뉴, 보안 및 접근 제어 관리';


-- =========================================================
-- 1. 계정 및 인증 (Authentication)
-- 설명: 로그인 아이디, 비밀번호, 계정 상태 관리 (USR 테이블과 분리)
-- =========================================================
CREATE TABLE iam.accounts (
    id SERIAL PRIMARY KEY,
    
    -- [연결] USR 도메인의 직원 정보와 1:1 매핑 (물리적 FK는 선택사항)
    user_id INT NOT NULL, 
    
    login_id VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL, -- BCrypt or Argon2 암호화 해시
    
    status VARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE(정상), LOCKED(잠김), DORMANT(휴면), EXPIRED(만료)
    login_fail_count INT DEFAULT 0,      -- 5회 실패 시 LOCKED 처리용
    
    last_login_at TIMESTAMPTZ,           -- 마지막 로그인 성공 일시
    last_login_ip VARCHAR(50),           -- 마지막 로그인 IP
    
    password_changed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, -- 비번 변경일 (3개월 변경 주기 체크용)
    refresh_token VARCHAR(500),          -- JWT 리프레시 토큰 (선택사항)
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- [주석] 계정 테이블
COMMENT ON TABLE iam.accounts IS '시스템 로그인 계정 정보 (직원 정보와 분리된 인증 전용)';
COMMENT ON COLUMN iam.accounts.id IS '계정 고유 ID (PK)';
COMMENT ON COLUMN iam.accounts.user_id IS '사용자 ID (USR 도메인 참조)';
COMMENT ON COLUMN iam.accounts.login_id IS '로그인 아이디 (Unique)';
COMMENT ON COLUMN iam.accounts.password_hash IS '암호화된 비밀번호 (평문 저장 금지)';
COMMENT ON COLUMN iam.accounts.status IS '계정 상태 (ACTIVE, LOCKED, DORMANT)';
COMMENT ON COLUMN iam.accounts.login_fail_count IS '로그인 연속 실패 횟수';
COMMENT ON COLUMN iam.accounts.last_login_at IS '마지막 로그인 일시';
COMMENT ON COLUMN iam.accounts.last_login_ip IS '마지막 접속 IP';
COMMENT ON COLUMN iam.accounts.password_changed_at IS '비밀번호 마지막 변경일';
COMMENT ON COLUMN iam.accounts.refresh_token IS 'JWT Refresh Token';
COMMENT ON COLUMN iam.accounts.created_at IS '생성 일시';
COMMENT ON COLUMN iam.accounts.updated_at IS '수정 일시';


-- =========================================================
-- 2. 역할 (Roles)
-- 설명: 권한의 집합 (예: 시스템관리자, 시설담당자, 단순조회자)
-- =========================================================
CREATE TABLE iam.roles (
    role_code VARCHAR(30) PRIMARY KEY,
    role_name VARCHAR(100) NOT NULL,
    description TEXT,
    
    is_system BOOLEAN DEFAULT false, -- 시스템 기본 역할 삭제 방지
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- [주석] 역할 정의
COMMENT ON TABLE iam.roles IS '권한 그룹 (Role) 정의';
COMMENT ON COLUMN iam.roles.role_code IS '역할 코드 (PK, 예: SYS_ADMIN, FAC_MGR)';
COMMENT ON COLUMN iam.roles.role_name IS '역할 명칭';
COMMENT ON COLUMN iam.roles.description IS '역할 설명';
COMMENT ON COLUMN iam.roles.is_system IS '시스템 기본 역할 여부 (삭제 불가)';
COMMENT ON COLUMN iam.roles.sort_order IS '화면 표시 순서';
COMMENT ON COLUMN iam.roles.is_active IS '사용 여부';
COMMENT ON COLUMN iam.roles.created_at IS '생성 일시';


-- =========================================================
-- 3. 계정-역할 매핑 (Account Roles)
-- 설명: N:M 관계 (한 사람이 여러 역할을 가질 수 있음)
-- =========================================================
CREATE TABLE iam.account_roles (
    account_id INT NOT NULL REFERENCES iam.accounts(id) ON DELETE CASCADE,
    role_code VARCHAR(30) NOT NULL REFERENCES iam.roles(role_code) ON DELETE CASCADE,
    
    granted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    granted_by INT, -- 권한 부여한 관리자 ID
    
    PRIMARY KEY (account_id, role_code)
);

-- [주석] 계정별 역할 부여
COMMENT ON TABLE iam.account_roles IS '사용자에게 부여된 역할 매핑';
COMMENT ON COLUMN iam.account_roles.account_id IS '대상 계정 ID (FK)';
COMMENT ON COLUMN iam.account_roles.role_code IS '부여된 역할 코드 (FK)';
COMMENT ON COLUMN iam.account_roles.granted_at IS '권한 부여 일시';
COMMENT ON COLUMN iam.account_roles.granted_by IS '권한 부여 수행자 ID';


-- =========================================================
-- 4. 메뉴 및 리소스 (Menus)
-- 설명: 시스템의 화면 구조 및 URL 정의 (트리 구조)
-- =========================================================
CREATE TABLE iam.menus (
    menu_code VARCHAR(50) PRIMARY KEY,
    parent_menu_code VARCHAR(50) REFERENCES iam.menus(menu_code), -- 상위 메뉴 (NULL이면 최상위)
    
    menu_name VARCHAR(100) NOT NULL,
    menu_type VARCHAR(20) DEFAULT 'PAGE', -- PAGE(화면), DIR(폴더/그룹), API(기능), BTN(버튼)
    menu_url VARCHAR(200),
    icon_name VARCHAR(50), -- UI 아이콘 (Lucide/Material)
    
    sort_order INT DEFAULT 0,
    is_visible BOOLEAN DEFAULT true, -- 네비게이션 표시 여부
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- [주석] 메뉴 관리
COMMENT ON TABLE iam.menus IS '시스템 메뉴 및 접근 리소스 정의';
COMMENT ON COLUMN iam.menus.menu_code IS '메뉴 코드 (PK, 예: FAC_001)';
COMMENT ON COLUMN iam.menus.parent_menu_code IS '상위 메뉴 코드 (Self FK, 계층 구조)';
COMMENT ON COLUMN iam.menus.menu_name IS '메뉴 명칭';
COMMENT ON COLUMN iam.menus.menu_type IS '유형 (PAGE:화면, DIR:폴더, API:기능)';
COMMENT ON COLUMN iam.menus.menu_url IS '이동 경로 (Frontend Route Path)';
COMMENT ON COLUMN iam.menus.icon_name IS '메뉴 아이콘 명칭';
COMMENT ON COLUMN iam.menus.sort_order IS '정렬 순서';
COMMENT ON COLUMN iam.menus.is_visible IS 'GNB/LNB 표시 여부 (숨김 메뉴 처리)';
COMMENT ON COLUMN iam.menus.is_active IS '사용 여부';
COMMENT ON COLUMN iam.menus.created_at IS '생성 일시';
COMMENT ON COLUMN iam.menus.updated_at IS '수정 일시';


-- =========================================================
-- 5. 역할별 메뉴 권한 (Role Menu Permissions)
-- 설명: 어떤 역할이 어떤 메뉴에 대해 무슨 권한(CRUD)을 갖는가?
-- =========================================================
CREATE TABLE iam.role_menu_perms (
    role_code VARCHAR(30) NOT NULL REFERENCES iam.roles(role_code) ON DELETE CASCADE,
    menu_code VARCHAR(50) NOT NULL REFERENCES iam.menus(menu_code) ON DELETE CASCADE,
    
    can_create BOOLEAN DEFAULT false, -- 등록/쓰기 권한
    can_read BOOLEAN DEFAULT true,    -- 조회/읽기 권한
    can_update BOOLEAN DEFAULT false, -- 수정 권한
    can_delete BOOLEAN DEFAULT false, -- 삭제 권한
    can_export BOOLEAN DEFAULT false, -- 엑셀 다운로드 권한
    
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by INT, -- 수정자
    
    PRIMARY KEY (role_code, menu_code)
);

-- [주석] 역할별 메뉴 권한
COMMENT ON TABLE iam.role_menu_perms IS '역할별 상세 메뉴 접근 권한 (CRUD 제어)';
COMMENT ON COLUMN iam.role_menu_perms.role_code IS '역할 코드 (FK)';
COMMENT ON COLUMN iam.role_menu_perms.menu_code IS '메뉴 코드 (FK)';
COMMENT ON COLUMN iam.role_menu_perms.can_create IS '생성 권한 보유 여부';
COMMENT ON COLUMN iam.role_menu_perms.can_read IS '조회 권한 보유 여부';
COMMENT ON COLUMN iam.role_menu_perms.can_update IS '수정 권한 보유 여부';
COMMENT ON COLUMN iam.role_menu_perms.can_delete IS '삭제 권한 보유 여부';
COMMENT ON COLUMN iam.role_menu_perms.can_export IS '데이터 엑셀 다운로드 권한 여부';


-- =========================================================
-- 6. 로그인 이력 (Login History)
-- 설명: 접속 로그 및 보안 감사 (성공/실패 모두 기록)
-- =========================================================
CREATE TABLE iam.login_history (
    id BIGSERIAL PRIMARY KEY,
    
    account_id INT, -- 로그인 시도 계정 (실패 시 NULL일 수 있음)
    login_id VARCHAR(50), -- 시도한 아이디 (로그용)
    
    is_success BOOLEAN NOT NULL, -- 성공 여부
    fail_reason VARCHAR(100), -- 실패 사유 (비번틀림, 잠긴계정 등)
    
    client_ip VARCHAR(50),
    user_agent TEXT, -- 브라우저/OS 정보
    session_id VARCHAR(100), -- 발급된 세션 ID 또는 토큰 서명
    
    login_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- [주석] 로그인 이력
COMMENT ON TABLE iam.login_history IS '시스템 로그인 시도 및 결과 이력';
COMMENT ON COLUMN iam.login_history.id IS '로그 ID (PK)';
COMMENT ON COLUMN iam.login_history.account_id IS '시도 계정 ID (식별 가능 시)';
COMMENT ON COLUMN iam.login_history.login_id IS '입력한 로그인 아이디';
COMMENT ON COLUMN iam.login_history.is_success IS '로그인 성공 여부';
COMMENT ON COLUMN iam.login_history.fail_reason IS '실패 사유';
COMMENT ON COLUMN iam.login_history.client_ip IS '접속 IP 주소';
COMMENT ON COLUMN iam.login_history.user_agent IS '사용자 환경 정보 (Browser/OS)';
COMMENT ON COLUMN iam.login_history.session_id IS '세션 식별자';
COMMENT ON COLUMN iam.login_history.login_at IS '로그인 시도 일시';


-- =========================================================
-- 7. API 접근 키 (API Keys - Optional)
-- 설명: 외부 시스템(IoT, 타 기관) 연동용 인증 키
-- =========================================================
CREATE TABLE iam.api_keys (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL, -- 키 용도 (예: 1처리장 TMS 연동)
    access_key VARCHAR(64) NOT NULL UNIQUE,
    secret_key VARCHAR(255) NOT NULL, -- 해시 저장 권장
    
    allowed_ips TEXT, -- 허용 IP 대역 (CIDR, 콤마 구분)
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMPTZ, -- 만료일
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- [주석] API 접근 키
COMMENT ON TABLE iam.api_keys IS 'M2M(Machine to Machine) 연동을 위한 API 키 관리';
COMMENT ON COLUMN iam.api_keys.name IS '키 명칭/용도';
COMMENT ON COLUMN iam.api_keys.access_key IS '공개 접근 키 (Client ID)';
COMMENT ON COLUMN iam.api_keys.secret_key IS '비밀 키 (Client Secret)';
COMMENT ON COLUMN iam.api_keys.allowed_ips IS '접속 허용 IP 목록 (보안)';
COMMENT ON COLUMN iam.api_keys.is_active IS '사용 여부';
COMMENT ON COLUMN iam.api_keys.expires_at IS '키 만료 일시';


-- =========================================================
-- 8. 기초 데이터 (Seed Data)
-- =========================================================

-- 8-1. 기본 역할
INSERT INTO iam.roles (role_code, role_name, description, is_system, sort_order) VALUES
('SYS_ADMIN', '시스템 관리자', '전체 메뉴 및 기능에 대한 모든 권한 (슈퍼 유저)', true, 1),
('FAC_MGR',   '시설 관리자',   '시설 및 공간 관리 권한', false, 2),
('EQP_MGR',   '설비 담당자',   '설비 이력 및 유지보수 관리', false, 3),
('WQT_OPR',   '수질 분석가',   '수질 데이터 입력 및 시험 관리', false, 4),
('VIEWER',    '단순 조회자',   '모든 데이터 조회 가능, 수정 불가', false, 99);

-- 8-2. 최상위 메뉴 그룹 (예시)
INSERT INTO iam.menus (menu_code, menu_name, menu_type, sort_order, icon_name) VALUES
('DSH', '대시보드', 'DIR', 10, 'layout-dashboard'),
('FAC', '시설관리', 'DIR', 20, 'building'),
('EQP', '설비관리', 'DIR', 30, 'settings'),
('WQT', '수질관리', 'DIR', 40, 'flask-conical'),
('SYS', '시스템관리', 'DIR', 90, 'shield');