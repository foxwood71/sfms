-----------------------------------------------------------
-- [Phase 1] USR Domain Tables
-----------------------------------------------------------

-- 1. 조직 (Organizations)
CREATE TABLE usr.organizations (
    id                  BIGSERIAL PRIMARY KEY,
    name                VARCHAR(100) NOT NULL,
    code                VARCHAR(50) NOT NULL UNIQUE,
    parent_id           BIGINT,
    sort_order          INT DEFAULT 0,
    description         TEXT,
    is_active           BOOLEAN DEFAULT true,
    legacy_id           INTEGER,
    legacy_source       VARCHAR(20),
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT,
    CONSTRAINT chk_organizations_code_upper CHECK (code = UPPER(code))
);

COMMENT ON TABLE usr.organizations IS '조직(부서) 정보 관리 테이블';
COMMENT ON COLUMN usr.organizations.id IS '조직 고유 ID (PK)';
COMMENT ON COLUMN usr.organizations.name IS '조직(부서) 명칭';
COMMENT ON COLUMN usr.organizations.code IS '조직 식별 코드 (영문 대문자)';
COMMENT ON COLUMN usr.organizations.parent_id IS '상위 조직 ID (Self-referencing)';
COMMENT ON COLUMN usr.organizations.sort_order IS '정렬 순서';
COMMENT ON COLUMN usr.organizations.description IS '조직 상세 설명';
COMMENT ON COLUMN usr.organizations.is_active IS '사용 여부';
COMMENT ON COLUMN usr.organizations.legacy_id IS '레거시 시스템 매핑 ID';
COMMENT ON COLUMN usr.organizations.legacy_source IS '레거시 데이터 소스 구분';
COMMENT ON COLUMN usr.organizations.created_at IS '생성 일시';
COMMENT ON COLUMN usr.organizations.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN usr.organizations.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN usr.organizations.updated_by IS '최종 수정자 사용자 ID';

-- 2. 사용자 (Users)
CREATE TABLE usr.users (
    id                  BIGSERIAL PRIMARY KEY,
    org_id              BIGINT,
    profile_image_id    UUID,
    login_id            VARCHAR(50) NOT NULL UNIQUE,
    password_hash       VARCHAR(255) NOT NULL,
    emp_code            VARCHAR(16) NOT NULL UNIQUE,
    name                VARCHAR(100) NOT NULL,
    email               VARCHAR(100) NOT NULL UNIQUE,
    phone               VARCHAR(50),
    is_active           BOOLEAN DEFAULT TRUE,
    account_status      VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL,
    last_login_at       TIMESTAMPTZ,
    login_fail_count    INTEGER DEFAULT 0 NOT NULL,
    legacy_id           INTEGER,
    legacy_source       VARCHAR(20),
    metadata            JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT,
    CONSTRAINT chk_users_login_id_lower CHECK (login_id = LOWER(login_id)),
    CONSTRAINT chk_users_email_lower CHECK (email = LOWER(email))
);

COMMENT ON TABLE usr.users IS '시스템 사용자 계정 정보 테이블';
COMMENT ON COLUMN usr.users.id IS '사용자 고유 ID (PK)';
COMMENT ON COLUMN usr.users.org_id IS '소속 조직 ID (usr.organizations.id)';
COMMENT ON COLUMN usr.users.profile_image_id IS '프로필 이미지 첨부파일 ID (cmm.attachments.id)';
COMMENT ON COLUMN usr.users.login_id IS '로그인 계정 ID (영문 소문자 고정)';
COMMENT ON COLUMN usr.users.password_hash IS '암호화된 비밀번호 해시';
COMMENT ON COLUMN usr.users.emp_code IS '사번 또는 식별 코드';
COMMENT ON COLUMN usr.users.name IS '사용자 성명';
COMMENT ON COLUMN usr.users.email IS '이메일 주소 (영문 소문자 고정)';
COMMENT ON COLUMN usr.users.phone IS '연락처 (전화번호)';
COMMENT ON COLUMN usr.users.is_active IS '재직/활성 여부 (False: 퇴사/비활성)';
COMMENT ON COLUMN usr.users.account_status IS '계정 상태 (ACTIVE: 정상, BLOCKED: 잠금, PENDING: 승인대기)';
COMMENT ON COLUMN usr.users.last_login_at IS '마지막 성공 로그인 일시';
COMMENT ON COLUMN usr.users.login_fail_count IS '로그인 연속 실패 횟수';
COMMENT ON COLUMN usr.users.legacy_id IS '레거시 시스템 매핑 ID';
COMMENT ON COLUMN usr.users.legacy_source IS '레거시 데이터 소스 구분';
COMMENT ON COLUMN usr.users.metadata IS '사용자 부가 정보 (직위, 직책 등 JSONB 데이터)';
COMMENT ON COLUMN usr.users.created_at IS '생성 일시';
COMMENT ON COLUMN usr.users.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN usr.users.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN usr.users.updated_by IS '최종 수정자 사용자 ID';

-- Indices
CREATE INDEX idx_usr_org_parent ON usr.organizations (parent_id);
CREATE INDEX idx_usr_users_org_id ON usr.users (org_id);

-- Triggers
CREATE TRIGGER trg_updated_at_organizations BEFORE UPDATE ON usr.organizations FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();
CREATE TRIGGER trg_updated_at_users BEFORE UPDATE ON usr.users FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();
