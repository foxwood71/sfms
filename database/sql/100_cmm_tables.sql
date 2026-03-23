-----------------------------------------------------------
-- [Phase 1] CMM 도메인 테이블 (공통 관리)
-- 작성일: 2026-03-23
-----------------------------------------------------------

-- 1. [Table] 공통 코드 그룹 (code_groups)
CREATE TABLE cmm.code_groups (
    id                  BIGSERIAL PRIMARY KEY,
    group_code          VARCHAR(30) NOT NULL UNIQUE,    -- 그룹 식별 코드 (예: FAC_CATEGORY)
    domain_code         VARCHAR(3),                     -- 소속 도메인 (SYS, USR, FAC 등)
    group_name          VARCHAR(100) NOT NULL,          -- 그룹 명칭 (예: 시설 분류)
    description         TEXT,                           -- 그룹 상세 설명
    
    -- [SFMS Standard] 코드 규격 관리 필드
    code_length         INT DEFAULT 0,                  -- 권장 코드 길이 (0: 제한없음, 예: 3자)
    is_seq_used         BOOLEAN DEFAULT false,          -- 자산 코드 생성 시 접두어로 사용 여부 (True: 사용)

    is_system           BOOLEAN DEFAULT false,          -- 시스템 필수 여부 (True: 삭제 불가)
    is_active           BOOLEAN DEFAULT true,           -- 사용 여부
    
    props               JSONB DEFAULT '{}'::jsonb NOT NULL, -- UI 설정 등 부가 메타데이터

    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT,
    
    CONSTRAINT chk_group_code_format CHECK (group_code ~ '^[A-Z0-9_]+$')
);

-- 1. [Comments]
COMMENT ON TABLE cmm.code_groups IS '공통 코드 그룹 정의 테이블';
COMMENT ON COLUMN cmm.code_groups.id IS '코드 그룹 고유 ID (PK)';
COMMENT ON COLUMN cmm.code_groups.group_code IS '그룹 식별 코드 (Unique, 영문 대문자/숫자/_ 조합)';
COMMENT ON COLUMN cmm.code_groups.domain_code IS '관련 시스템 도메인 코드 (SYS, CMM, USR, IAM, FAC)';
COMMENT ON COLUMN cmm.code_groups.group_name IS '코드 그룹의 국문 명칭';
COMMENT ON COLUMN cmm.code_groups.description IS '코드 그룹에 대한 상세 설명';
COMMENT ON COLUMN cmm.code_groups.code_length IS '해당 그룹 코드들의 권장 길이 (자동 생성 규격 가이드)';
COMMENT ON COLUMN cmm.code_groups.is_seq_used IS '자산 코드(Prefix+Sequence) 생성 엔진 사용 여부';
COMMENT ON COLUMN cmm.code_groups.is_system IS '시스템 필수 코드 여부 (True인 경우 UI에서 삭제 및 코드값 변경 제한)';
COMMENT ON COLUMN cmm.code_groups.is_active IS '그룹 활성화 여부';
COMMENT ON COLUMN cmm.code_groups.props IS '그룹별 확장 속성 (JSONB)';
COMMENT ON COLUMN cmm.code_groups.created_at IS '생성 일시';
COMMENT ON COLUMN cmm.code_groups.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN cmm.code_groups.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN cmm.code_groups.updated_by IS '최종 수정자 사용자 ID';


-- 2. [Table] 공통 코드 상세 (code_details)
CREATE TABLE cmm.code_details (
    id                  BIGSERIAL PRIMARY KEY,
    group_code          VARCHAR(30) NOT NULL,           -- 소속 그룹 코드
    detail_code         VARCHAR(30) NOT NULL,           -- 상세 코드 (예: STP)
    detail_name         VARCHAR(100) NOT NULL,          -- 상세 코드명 (예: 하수처리시설)
    
    props               JSONB DEFAULT '{}'::jsonb NOT NULL, -- 코드별 확장 속성
    sort_order          INT DEFAULT 0,                  -- 정렬 순서
    is_active           BOOLEAN DEFAULT true,           -- 사용 여부

    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT,
    
    CONSTRAINT uq_code_details_group_detail UNIQUE (group_code, detail_code),
    CONSTRAINT chk_detail_code_format CHECK (detail_code ~ '^[A-Z0-9_]+$')
);

-- 2. [Comments]
COMMENT ON TABLE cmm.code_details IS '공통 코드 상세 항목 테이블';
COMMENT ON COLUMN cmm.code_details.id IS '코드 상세 고유 ID (PK)';
COMMENT ON COLUMN cmm.code_details.group_code IS '소속된 그룹의 코드 (FK)';
COMMENT ON COLUMN cmm.code_details.detail_code IS '실제 데이터로 저장되는 식별 코드';
COMMENT ON COLUMN cmm.code_details.detail_name IS '화면에 표시되는 코드 명칭';
COMMENT ON COLUMN cmm.code_details.props IS '코드별 부가 속성 (예: 색상, 아이콘 클래스 등)';
COMMENT ON COLUMN cmm.code_details.sort_order IS '화면 표시 정렬 순서 (낮은 숫자 우선)';
COMMENT ON COLUMN cmm.code_details.is_active IS '코드 사용 여부';
COMMENT ON COLUMN cmm.code_details.created_at IS '생성 일시';
COMMENT ON COLUMN cmm.code_details.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN cmm.code_details.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN cmm.code_details.updated_by IS '최종 수정자 사용자 ID';


-- 3. [Table] 통합 첨부파일 (attachments)
CREATE TABLE cmm.attachments (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_code         VARCHAR(3) NOT NULL,            -- 도메인 (FAC, USR 등)
    resource_type       VARCHAR(50) NOT NULL,           -- 자원 유형 (FACILITY, USER 등)
    ref_id              BIGINT NOT NULL,                -- 참조 대상 ID
    category_code       VARCHAR(20) NOT NULL,           -- 파일 분류 (DOC, IMG 등)
    
    file_name           VARCHAR(255) NOT NULL,          -- 원본 파일명
    file_path           VARCHAR(500) NOT NULL,          -- 저장 경로
    file_size           BIGINT NOT NULL DEFAULT 0,      -- 파일 크기 (Bytes)
    content_type        VARCHAR(100),                   -- MIME Type
    
    org_id              BIGINT,                         -- 관리 부서 ID
    props               JSONB NOT NULL DEFAULT '{}'::jsonb, -- 파일 관련 추가 정보
    
    legacy_id           INTEGER,                        -- 레거시 시스템 PK
    legacy_source       VARCHAR(50),                    -- 레거시 출처
    is_deleted          BOOLEAN DEFAULT false,          -- 삭제 여부
    
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT
);

-- 3. [Comments]
COMMENT ON TABLE cmm.attachments IS '도메인 통합 첨부파일 관리 테이블';
COMMENT ON COLUMN cmm.attachments.id IS '파일 식별자 (UUID)';
COMMENT ON COLUMN cmm.attachments.domain_code IS '연결된 업무 도메인 코드';
COMMENT ON COLUMN cmm.attachments.resource_type IS '참조되는 자원 테이블명 (예: facilities)';
COMMENT ON COLUMN cmm.attachments.ref_id IS '참조 대상의 고유 ID (PK)';
COMMENT ON COLUMN cmm.attachments.category_code IS '파일 분류 코드 (예: PROFILE, DRAWING, MANUAL)';
COMMENT ON COLUMN cmm.attachments.file_name IS '사용자가 업로드한 실제 파일명';
COMMENT ON COLUMN cmm.attachments.file_path IS '파일 시스템 또는 오브젝트 스토리지 내 저장 경로';
COMMENT ON COLUMN cmm.attachments.file_size IS '파일 용량 (단위: Byte)';
COMMENT ON COLUMN cmm.attachments.content_type IS '파일의 미디어 타입 (MIME)';
COMMENT ON COLUMN cmm.attachments.org_id IS '파일에 대한 소유/관리 권한을 가진 부서 ID';
COMMENT ON COLUMN cmm.attachments.props IS '파일 추가 메타데이터 정보';
COMMENT ON COLUMN cmm.attachments.legacy_id IS '마이그레이션된 기존 시스템 파일 ID';
COMMENT ON COLUMN cmm.attachments.is_deleted IS '논리적 삭제 여부 (True: 삭제됨)';


-- 4. [Table] 시스템 알림 (notifications)
CREATE TABLE cmm.notifications (
    id                  BIGSERIAL PRIMARY KEY,
    domain_code         VARCHAR(3),                     -- 발생 도메인
    sender_user_id      BIGINT,                         -- 발신자 (NULL이면 시스템)
    receiver_user_id    BIGINT,                         -- 수신자
    
    category            VARCHAR(20) NOT NULL,           -- 알림 분류 (INFO, WARN, ERROR)
    priority            VARCHAR(10) DEFAULT 'NORMAL',   -- 중요도
    
    title               VARCHAR(200) NOT NULL,          -- 알림 제목
    content             TEXT,                           -- 알림 본문
    link_url            VARCHAR(500),                   -- 클릭 시 이동할 URL
    
    props               JSONB NOT NULL DEFAULT '{}'::jsonb, -- 추가 속성
    
    is_read             BOOLEAN DEFAULT false,          -- 읽음 여부
    read_at             TIMESTAMPTZ,                    -- 읽은 일시
    is_deleted          BOOLEAN DEFAULT false,          -- 삭제 여부
    
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. [Comments]
COMMENT ON TABLE cmm.notifications IS '사용자별 시스템 알림 관리 테이블';
COMMENT ON COLUMN cmm.notifications.id IS '알림 고유 ID (PK)';
COMMENT ON COLUMN cmm.notifications.domain_code IS '알림 발생 업무 도메인';
COMMENT ON COLUMN cmm.notifications.sender_user_id IS '알림을 보낸 사용자 ID (시스템 발생 시 NULL)';
COMMENT ON COLUMN cmm.notifications.receiver_user_id IS '알림을 받을 대상 사용자 ID';
COMMENT ON COLUMN cmm.notifications.category IS '알림 유형 (예: 공지사항, 승인요청, 시스템경고)';
COMMENT ON COLUMN cmm.notifications.priority IS '알림 우선순위 (URGENT, NORMAL, LOW)';
COMMENT ON COLUMN cmm.notifications.title IS '알림 요약 제목';
COMMENT ON COLUMN cmm.notifications.content IS '알림 상세 내용';
COMMENT ON COLUMN cmm.notifications.link_url IS '클릭 시 이동할 페이지 주소';
COMMENT ON COLUMN cmm.notifications.is_read IS '수신자 확인 여부';
COMMENT ON COLUMN cmm.notifications.read_at IS '수신자가 알림을 확인한 시각';


-- [Triggers]
CREATE TRIGGER trg_updated_at_code_groups BEFORE UPDATE ON cmm.code_groups FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();
CREATE TRIGGER trg_updated_at_code_details BEFORE UPDATE ON cmm.code_details FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();
CREATE TRIGGER trg_updated_at_attachments BEFORE UPDATE ON cmm.attachments FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();
CREATE TRIGGER trg_updated_at_notifications BEFORE UPDATE ON cmm.notifications FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();
