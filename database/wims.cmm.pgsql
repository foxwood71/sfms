-- =========================================================
-- Schema: com (Common Module)
-- Version: 1.0.0
-- Description: 하수처리시설 관리 시스템 공통 기준정보 및 유틸리티
-- Author: Gemini (AI Architect)
-- Created At: 2026-02-12
-- =========================================================

-- 1. 스키마 생성
CREATE SCHEMA IF NOT EXISTS com;
COMMENT ON SCHEMA com IS '공통 관리 도메인 (코드, 채번, 로그, 알림 등)';


-- =========================================================
-- 1. 시스템 도메인 레지스트리 (Domain Registry)
-- 설명: 시스템을 구성하는 모듈(FAC, EQP, WQT 등)을 정의
-- =========================================================
CREATE TABLE com.system_domains (
    domain_code VARCHAR(3) PRIMARY KEY,
    domain_name VARCHAR(50) NOT NULL,
    schema_name VARCHAR(50) NOT NULL,
    description TEXT,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- [주석] 도메인 레지스트리
COMMENT ON TABLE com.system_domains IS '시스템 도메인 정의 (모듈 목록)';
COMMENT ON COLUMN com.system_domains.domain_code IS '도메인 코드 (PK, 3자리 영문, 예: FAC)';
COMMENT ON COLUMN com.system_domains.domain_name IS '도메인 한글 명칭 (예: 시설관리)';
COMMENT ON COLUMN com.system_domains.schema_name IS '매핑된 DB 스키마명 (예: fac)';
COMMENT ON COLUMN com.system_domains.description IS '도메인 역할 설명';
COMMENT ON COLUMN com.system_domains.sort_order IS '메뉴 표시 순서';
COMMENT ON COLUMN com.system_domains.is_active IS '사용 여부';
COMMENT ON COLUMN com.system_domains.created_at IS '생성 일시';


-- =========================================================
-- 2. 공통 코드 그룹 (Code Groups)
-- 설명: 코드의 대분류 (예: 단위, 진행상태, 자재유형)
-- =========================================================
CREATE TABLE com.code_groups (
    group_code VARCHAR(30) PRIMARY KEY,
    group_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_system BOOLEAN DEFAULT false, -- 시스템 필수 코드 여부 (삭제 불가)
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- [주석] 공통 코드 그룹
COMMENT ON TABLE com.code_groups IS '공통 코드 그룹 (Master Code)';
COMMENT ON COLUMN com.code_groups.group_code IS '그룹 코드 (PK, 예: UNIT_TYPE)';
COMMENT ON COLUMN com.code_groups.group_name IS '그룹 명칭 (예: 계량 단위)';
COMMENT ON COLUMN com.code_groups.description IS '그룹 설명';
COMMENT ON COLUMN com.code_groups.is_system IS '시스템 내부용 여부 (True면 UI에서 삭제 불가)';
COMMENT ON COLUMN com.code_groups.is_active IS '사용 여부';
COMMENT ON COLUMN com.code_groups.created_at IS '생성 일시';
COMMENT ON COLUMN com.code_groups.updated_at IS '수정 일시';


-- =========================================================
-- 3. 공통 코드 상세 (Code Details)
-- 설명: 실제 사용하는 코드 값 (예: mg/L, kg, 개)
-- =========================================================
CREATE TABLE com.code_details (
    group_code VARCHAR(30) NOT NULL REFERENCES com.code_groups(group_code) ON DELETE CASCADE,
    detail_code VARCHAR(30) NOT NULL,
    detail_name VARCHAR(100) NOT NULL,
    
    ref_val_1 VARCHAR(100), -- 참조값 1 (예: 환산계수)
    ref_val_2 VARCHAR(100), -- 참조값 2
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (group_code, detail_code)
);

-- [주석] 공통 코드 상세
COMMENT ON TABLE com.code_details IS '공통 코드 상세 값';
COMMENT ON COLUMN com.code_details.group_code IS '그룹 코드 (FK)';
COMMENT ON COLUMN com.code_details.detail_code IS '상세 코드 (PK, 실제 저장되는 값)';
COMMENT ON COLUMN com.code_details.detail_name IS '상세 명칭 (화면 표시 값)';
COMMENT ON COLUMN com.code_details.ref_val_1 IS '추가 참조값 1 (예: 옵션, 색상코드)';
COMMENT ON COLUMN com.code_details.ref_val_2 IS '추가 참조값 2';
COMMENT ON COLUMN com.code_details.sort_order IS '정렬 순서';
COMMENT ON COLUMN com.code_details.is_active IS '사용 여부';
COMMENT ON COLUMN com.code_details.created_at IS '생성 일시';
COMMENT ON COLUMN com.code_details.updated_at IS '수정 일시';


-- =========================================================
-- 4. 자동 채번 규칙 (Sequence Rules)
-- 설명: 도메인별 ID 생성 규칙 관리 (Prefix + Year + Seq)
-- =========================================================
CREATE TABLE com.sequence_rules (
    domain_code VARCHAR(3) PRIMARY KEY REFERENCES com.system_domains(domain_code),
    prefix VARCHAR(10) NOT NULL,      -- 접두어 (예: REQ)
    year_format VARCHAR(4) DEFAULT 'YYYY', -- YYYY 또는 YY
    separator CHAR(1) DEFAULT '-',    -- 구분자
    
    current_year VARCHAR(4) NOT NULL, -- 현재 관리 중인 연도
    current_seq INT DEFAULT 0,        -- 현재 마지막 번호
    
    reset_type VARCHAR(10) DEFAULT 'YEARLY', -- 리셋 주기 (YEARLY, NONE)
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- [주석] 자동 채번 규칙
COMMENT ON TABLE com.sequence_rules IS '문서/코드 자동 채번 규칙 관리';
COMMENT ON COLUMN com.sequence_rules.domain_code IS '도메인 코드 (FK)';
COMMENT ON COLUMN com.sequence_rules.prefix IS '채번 접두어 (예: FAC, REQ)';
COMMENT ON COLUMN com.sequence_rules.year_format IS '연도 표기 방식 (YYYY: 2026, YY: 26)';
COMMENT ON COLUMN com.sequence_rules.separator IS '구분자 (-, _ 등)';
COMMENT ON COLUMN com.sequence_rules.current_year IS '현재 기준 연도';
COMMENT ON COLUMN com.sequence_rules.current_seq IS '현재 발급된 마지막 순번';
COMMENT ON COLUMN com.sequence_rules.reset_type IS '번호 리셋 기준 (YEARLY: 매년 1로 초기화)';
COMMENT ON COLUMN com.sequence_rules.updated_at IS '마지막 채번 일시';


-- =========================================================
-- 5. 시스템 알림 (Notifications)
-- 설명: 사용자에게 발송된 알림 이력 (Web Push, SMS 등)
-- =========================================================
CREATE TABLE com.notifications (
    id SERIAL PRIMARY KEY,
    
    -- USR 도메인이 나중에 생성되므로 여기서는 물리적 FK를 걸지 않음 (느슨한 연결)
    receiver_user_id INT NOT NULL, 
    
    category VARCHAR(20) NOT NULL, -- ALARM, NOTICE, APPROVAL
    title VARCHAR(200) NOT NULL,
    content TEXT,
    
    link_url VARCHAR(500), -- 클릭 시 이동할 URL
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- [주석] 시스템 알림
COMMENT ON TABLE com.notifications IS '사용자 알림 내역';
COMMENT ON COLUMN com.notifications.id IS '알림 고유 ID (PK)';
COMMENT ON COLUMN com.notifications.receiver_user_id IS '수신자 ID (USR 테이블 참조)';
COMMENT ON COLUMN com.notifications.category IS '알림 유형 (경고, 공지, 결재 등)';
COMMENT ON COLUMN com.notifications.title IS '알림 제목';
COMMENT ON COLUMN com.notifications.content IS '알림 내용';
COMMENT ON COLUMN com.notifications.link_url IS '관련 화면 URL';
COMMENT ON COLUMN com.notifications.is_read IS '읽음 여부';
COMMENT ON COLUMN com.notifications.read_at IS '읽은 시간';
COMMENT ON COLUMN com.notifications.created_at IS '발송 시간';


-- =========================================================
-- 6. 시스템 로그 (Audit Logs)
-- 설명: 주요 데이터 변경 및 접근 이력 (보안 감사용)
-- =========================================================
CREATE TABLE com.audit_logs (
    id BIGSERIAL PRIMARY KEY,
    
    actor_user_id INT, -- 행위자 (없으면 시스템)
    action_type VARCHAR(20) NOT NULL, -- CREATE, UPDATE, DELETE, LOGIN
    
    target_domain VARCHAR(3), -- FAC, EQP 등
    target_id VARCHAR(50), -- 변경된 대상의 ID
    
    client_ip VARCHAR(50),
    user_agent TEXT,
    description TEXT, -- 변경 내용 요약
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- [주석] 시스템 로그
COMMENT ON TABLE com.audit_logs IS '시스템 감사 로그 (Audit Trail)';
COMMENT ON COLUMN com.audit_logs.id IS '로그 고유 ID (PK)';
COMMENT ON COLUMN com.audit_logs.actor_user_id IS '수행자 ID';
COMMENT ON COLUMN com.audit_logs.action_type IS '행위 유형 (입력,수정,삭제)';
COMMENT ON COLUMN com.audit_logs.target_domain IS '대상 도메인 코드';
COMMENT ON COLUMN com.audit_logs.target_id IS '대상 데이터 ID';
COMMENT ON COLUMN com.audit_logs.client_ip IS '접속 IP';
COMMENT ON COLUMN com.audit_logs.user_agent IS '브라우저 정보';
COMMENT ON COLUMN com.audit_logs.description IS '상세 내용';
COMMENT ON COLUMN com.audit_logs.created_at IS '발생 일시';


-- =========================================================
-- 7. [함수] 자동 채번 생성기 (Sequence Generator Function)
-- 사용법: SELECT com.get_next_sequence('EQP'); -> 'EQP-2026-0005'
-- =========================================================
CREATE OR REPLACE FUNCTION com.get_next_sequence(p_domain_code VARCHAR)
RETURNS VARCHAR AS $$
DECLARE
    v_rule RECORD;
    v_year VARCHAR(4);
    v_new_seq INT;
    v_result VARCHAR(50);
BEGIN
    -- 1. 현재 연도 구하기
    v_year := TO_CHAR(CURRENT_DATE, 'YYYY');

    -- 2. 해당 도메인의 규칙 가져오기 (Row Lock)
    SELECT * INTO v_rule 
    FROM com.sequence_rules 
    WHERE domain_code = p_domain_code 
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION '채번 규칙이 존재하지 않습니다: %', p_domain_code;
    END IF;

    -- 3. 연도가 바뀌었으면 리셋 (YEARLY 옵션일 경우)
    IF v_rule.reset_type = 'YEARLY' AND v_rule.current_year != v_year THEN
        v_new_seq := 1;
        UPDATE com.sequence_rules
        SET current_year = v_year,
            current_seq = v_new_seq,
            updated_at = CURRENT_TIMESTAMP
        WHERE domain_code = p_domain_code;
    ELSE
        v_new_seq := v_rule.current_seq + 1;
        UPDATE com.sequence_rules
        SET current_seq = v_new_seq,
            updated_at = CURRENT_TIMESTAMP
        WHERE domain_code = p_domain_code;
    END IF;

    -- 4. 포맷팅 (Prefix + Separator + Year + Seq)
    -- 예: EQP-2026-0001
    v_result := v_rule.prefix || v_rule.separator || 
                CASE WHEN v_rule.year_format = 'YY' THEN SUBSTRING(v_year, 3, 2) ELSE v_year END || 
                v_rule.separator || 
                LPAD(v_new_seq::TEXT, 4, '0'); -- 기본 4자리 패딩

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION com.get_next_sequence(VARCHAR) IS '도메인별 자동 채번 함수 (예: FAC-2026-001)';


-- =========================================================
-- 8. 기초 데이터 (Seed Data)
-- =========================================================

-- 8-1. 도메인 등록
INSERT INTO com.system_domains (domain_code, domain_name, schema_name, description, sort_order) VALUES
('CMM', '공통관리', 'com', '기준정보, 코드, 시스템 관리', 0),
('FAC', '시설관리', 'fac', '건축물, 토목구조물, 공간 관리', 1),
('EQP', '설비관리', 'eqp', '기계/전기 설비 및 계측기 통합 관리', 2),
('WQT', '수질관리', 'wqt', '수질분석(LIMS), 현장측정 데이터', 3),
('AST', '자산관리', 'ast', 'OA, 차량, 비품 등 일반자산', 4),
('INV', '재고관리', 'inv', '자재, 예비품, 시약 수불 관리', 5),
('PTN', '업체관리', 'ptn', '시공사, 협력사, 공급사 정보', 6),
('USR', '운영관리', 'usr', '사용자, 조직, 근무조 관리', 7);

-- 8-2. 채번 규칙 초기화
INSERT INTO com.sequence_rules (domain_code, prefix, year_format, separator, current_year) VALUES
('FAC', 'FAC', 'YYYY', '-', TO_CHAR(CURRENT_DATE, 'YYYY')),
('EQP', 'EQP', 'YYYY', '-', TO_CHAR(CURRENT_DATE, 'YYYY')),
('WQT', 'REQ', 'YYYY', '-', TO_CHAR(CURRENT_DATE, 'YYYY')), -- 수질의뢰는 REQ로 시작
('INV', 'MAT', 'NONE', '',  TO_CHAR(CURRENT_DATE, 'YYYY')); -- 자재코드는 연도 없이 (예: MAT0001) 등 커스텀 필요시 수정

-- 8-3. 기초 공통 코드 그룹 (하수처리장 필수 코드)
INSERT INTO com.code_groups (group_code, group_name, description, is_system) VALUES
('UNIT_TYPE', '계량 단위', '길이, 무게, 부피, 농도 등', true),
('PROG_STAT', '진행 상태', '결재 및 업무 진행 단계', true),
('EQP_CAT',  '설비 분류', '기계, 전기, 계측 등 대분류', true);

-- 8-4. 기초 공통 코드 상세
INSERT INTO com.code_details (group_code, detail_code, detail_name, sort_order) VALUES
-- 단위
('UNIT_TYPE', 'EA',   '개', 1),
('UNIT_TYPE', 'M',    '미터', 2),
('UNIT_TYPE', 'KG',   '킬로그램', 3),
('UNIT_TYPE', 'MGL',  'mg/L', 4),
('UNIT_TYPE', 'PPM',  'ppm', 5),
-- 상태
('PROG_STAT', 'TMP',  '임시저장', 1),
('PROG_STAT', 'REQ',  '승인요청', 2),
('PROG_STAT', 'APR',  '승인완료', 3),
('PROG_STAT', 'REJ',  '반려', 4),
-- 설비분류
('EQP_CAT', 'MECH', '기계설비', 1),
('EQP_CAT', 'ELEC', '전기설비', 2),
('EQP_CAT', 'INST', '계측제어', 3);