-----------------------------------------------------------
-- ⚙️ sys 도메인 (시스템 관리) - 최종 확정본
-----------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS sys;
COMMENT ON SCHEMA sys IS '시스템 관리 도메인 (도메인, 체번, 감사 로그)';

-----------------------------------------------------------
-- 1. [Table] 시스템 도메인 (system_domains)
-----------------------------------------------------------
CREATE TABLE sys.system_domains (
    id                  BIGSERIAL PRIMARY KEY,

    domain_code         VARCHAR(3) NOT NULL UNIQUE,     -- 비즈니스 식별 코드 (예: FAC, USR, CMM)
    domain_name         VARCHAR(50) NOT NULL,           -- 도메인 명칭 (예: 시설관리, 사용자관리)
    schema_name         VARCHAR(50) NOT NULL UNIQUE,    -- 물리적 DB 스키마명 (중복 불가)
    description         TEXT,                           -- 도메인 설명
    sort_order          INT DEFAULT 0,                  -- UI 표시 순서

    is_active           BOOLEAN DEFAULT true,           -- 사용 여부

    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT REFERENCES usr.users(id),
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT REFERENCES usr.users(id),
    
    CONSTRAINT chk_domain_code_format CHECK (domain_code ~ '^[A-Z]{3}$')
);

CREATE TRIGGER trg_updated_at_system_domains 
BEFORE UPDATE ON sys.system_domains 
FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();

COMMENT ON TABLE sys.system_domains IS '시스템 내 업무 도메인(모듈) 정의 테이블';
COMMENT ON COLUMN sys.system_domains.id IS '도메인 테이블 고유 ID (PK)';
COMMENT ON COLUMN sys.system_domains.domain_code IS '도메인 식별 코드 (Unique, 대문자 3자, 예: FAC)';
COMMENT ON COLUMN sys.system_domains.domain_name IS '도메인 명칭 (한글, 예: 시설관리)';
COMMENT ON COLUMN sys.system_domains.schema_name IS '데이터베이스 스키마 명칭 (예: facility)';
COMMENT ON COLUMN sys.system_domains.description IS '도메인에 대한 상세 설명';
COMMENT ON COLUMN sys.system_domains.sort_order IS 'UI 메뉴 등에서의 정렬 순서';
COMMENT ON COLUMN sys.system_domains.is_active IS '도메인 사용 여부 (False 시 비활성화)';
COMMENT ON COLUMN sys.system_domains.created_at IS '데이터 생성 일시';
COMMENT ON COLUMN sys.system_domains.created_by IS '데이터 생성자 ID';
COMMENT ON COLUMN sys.system_domains.updated_at IS '데이터 최종 수정 일시';
COMMENT ON COLUMN sys.system_domains.updated_by IS '데이터 최종 수정자 ID';

-----------------------------------------------------------
-- 2. [Table] 시스템 감사 로그 (audit_logs)
-----------------------------------------------------------
CREATE TABLE sys.audit_logs (
    id                  BIGSERIAL PRIMARY KEY,
    
    actor_user_id       BIGINT REFERENCES usr.users(id),    
    
    action_type         VARCHAR(20) NOT NULL,             
    
    target_domain       VARCHAR(3) NOT NULL REFERENCES sys.system_domains(domain_code),
    target_table        VARCHAR(50) NOT NULL,               
    target_id           VARCHAR(50) NOT NULL,               

    snapshot            JSONB NOT NULL DEFAULT '{}'::jsonb, 

    client_ip           VARCHAR(50),                        
    user_agent          TEXT,                        
    
    description         TEXT,                               

    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_cmm_audit_target_lookup ON sys.audit_logs (target_table, target_id);
CREATE INDEX idx_cmm_audit_actor ON sys.audit_logs (actor_user_id);
CREATE INDEX idx_cmm_audit_desc_pg ON sys.audit_logs USING pgroonga (description) with (tokenizer='TokenMecab', normalizer='NormalizerAuto');
CREATE INDEX idx_cmm_audit_snap_pg ON sys.audit_logs USING pgroonga (snapshot) with (tokenizer='TokenMecab', normalizer='NormalizerAuto');

COMMENT ON TABLE sys.audit_logs IS '시스템 감사 로그 및 주요 행위 추적 테이블';
COMMENT ON COLUMN sys.audit_logs.id IS '로그 고유 ID (PK)';
COMMENT ON COLUMN sys.audit_logs.actor_user_id IS '행위를 수행한 사용자 ID (NULL이면 시스템)';
COMMENT ON COLUMN sys.audit_logs.action_type IS '행위 유형 (C:생성, U:수정, D:삭제, L:로그인 등)';
COMMENT ON COLUMN sys.audit_logs.target_domain IS '대상 데이터의 도메인 코드';
COMMENT ON COLUMN sys.audit_logs.target_table IS '대상 데이터의 테이블명';
COMMENT ON COLUMN sys.audit_logs.target_id IS '대상 데이터의 식별자(PK)';
COMMENT ON COLUMN sys.audit_logs.snapshot IS '변경 데이터 스냅샷 (JSONB)';
COMMENT ON COLUMN sys.audit_logs.client_ip IS '요청 클라이언트 IP 주소';
COMMENT ON COLUMN sys.audit_logs.user_agent IS '요청 클라이언트 User-Agent 정보';
COMMENT ON COLUMN sys.audit_logs.description IS '로그 내용 텍스트 설명';
COMMENT ON COLUMN sys.audit_logs.created_at IS '로그 발생 일시';

-----------------------------------------------------------
-- 3. [Table] 채번 규칙 (sequence_rules)
-----------------------------------------------------------
CREATE TABLE sys.sequence_rules (
    id                  BIGSERIAL PRIMARY KEY,
    domain_code         VARCHAR(3) NOT NULL REFERENCES sys.system_domains(domain_code),
  
    prefix              VARCHAR(10) NOT NULL,           
    year_format         VARCHAR(4) DEFAULT 'YYYY',      
    separator           CHAR(1) DEFAULT '-',            
    padding_length      INT DEFAULT 4,                  

    current_year        VARCHAR(4) NOT NULL,    
    current_seq         BIGINT NOT NULL DEFAULT 0,      
    reset_type          VARCHAR(10) DEFAULT 'YEARLY',   

    is_active           BOOLEAN DEFAULT true,           

    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT REFERENCES usr.users(id),
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT REFERENCES usr.users(id),

    CONSTRAINT uq_sequence_rules_domain_prefix UNIQUE (domain_code, prefix),
    CONSTRAINT chk_sequence_current_seq CHECK (current_seq >= 0),
    CONSTRAINT chk_sequence_padding CHECK (padding_length BETWEEN 1 AND 10)
);

CREATE TRIGGER trg_updated_at_sequence_rules 
BEFORE UPDATE ON sys.sequence_rules 
FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();

COMMENT ON TABLE sys.sequence_rules IS '문서 번호 자동 채번 규칙 정의 테이블';
COMMENT ON COLUMN sys.sequence_rules.id IS '채번 규칙 고유 ID (PK)';
COMMENT ON COLUMN sys.sequence_rules.domain_code IS '해당 규칙을 사용하는 도메인 코드';
COMMENT ON COLUMN sys.sequence_rules.prefix IS '문서 번호 접두어 (예: ORD)';
COMMENT ON COLUMN sys.sequence_rules.year_format IS '연도 표시 형식 (YYYY: 2024, YY: 24)';
COMMENT ON COLUMN sys.sequence_rules.separator IS '접두어, 연도, 번호 사이의 구분자';
COMMENT ON COLUMN sys.sequence_rules.padding_length IS '일련번호의 자릿수 (LPAD 처리)';
COMMENT ON COLUMN sys.sequence_rules.current_year IS '현재 채번이 진행 중인 연도';
COMMENT ON COLUMN sys.sequence_rules.current_seq IS '마지막으로 발급된 일련번호';
COMMENT ON COLUMN sys.sequence_rules.reset_type IS '일련번호 초기화 방식 (YEARLY: 매년 1로 초기화)';
COMMENT ON COLUMN sys.sequence_rules.is_active IS '규칙 사용 여부';
COMMENT ON COLUMN sys.sequence_rules.created_at IS '규칙 생성 일시';
COMMENT ON COLUMN sys.sequence_rules.created_by IS '규칙 생성자 ID';
COMMENT ON COLUMN sys.sequence_rules.updated_at IS '규칙 수정 일시';
COMMENT ON COLUMN sys.sequence_rules.updated_by IS '규칙 수정자 ID';

-----------------------------------------------------------
-- 4. [Function] 자동 채번 함수 (fn_get_next_sequence)
-----------------------------------------------------------
CREATE OR REPLACE FUNCTION sys.fn_get_next_sequence(
    p_domain_code VARCHAR, 
    p_prefix VARCHAR, 
    p_user_id BIGINT DEFAULT NULL
)
RETURNS VARCHAR AS $$
DECLARE
    v_rec RECORD;
    v_new_seq BIGINT;
    v_now_year VARCHAR(4);
    v_formatted_year VARCHAR(4);
    v_result VARCHAR(100);
BEGIN
    v_now_year := TO_CHAR(CURRENT_TIMESTAMP, 'YYYY');

    SELECT * INTO v_rec FROM sys.sequence_rules 
    WHERE domain_code = p_domain_code AND prefix = p_prefix AND is_active = true FOR UPDATE;

    IF NOT FOUND THEN RAISE EXCEPTION 'No active sequence rule for %:%', p_domain_code, p_prefix; END IF;

    IF v_rec.reset_type = 'YEARLY' AND v_rec.current_year <> v_now_year THEN 
        v_new_seq := 1;
    ELSE 
        v_new_seq := v_rec.current_seq + 1;
    END IF;

    UPDATE sys.sequence_rules 
    SET current_seq = v_new_seq, 
        current_year = v_now_year, 
        updated_by = p_user_id, 
        updated_at = CURRENT_TIMESTAMP 
    WHERE id = v_rec.id;

    v_formatted_year := CASE 
        WHEN v_rec.year_format = 'YYYY' THEN v_now_year 
        WHEN v_rec.year_format = 'YY' THEN RIGHT(v_now_year, 2)
        ELSE '' END;

    v_result := v_rec.prefix ||
                CASE WHEN v_formatted_year <> '' THEN v_rec.separator || v_formatted_year ELSE '' END 
                ||
                v_rec.separator || LPAD(v_new_seq::text, v_rec.padding_length, '0');

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION sys.fn_get_next_sequence IS '도메인 및 접두어 기반 자동 문서 번호 생성 함수 (Concurrency Safe)';