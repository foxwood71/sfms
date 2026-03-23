-----------------------------------------------------------
-- [Phase 9] CMM Seed Data (Base Codes)
-- 작성일: 2026-03-23
-----------------------------------------------------------

-- 1. [Table] 공통 코드 그룹 등록 및 규격 설정
INSERT INTO cmm.code_groups (group_code, domain_code, group_name, description, code_length, is_seq_used, is_system) VALUES
-- 사용자 도메인
('JOB_POSITION', 'USR', '직위', '임직원 직위 분류 (STF, MGR 등)', 3, false, true),
('JOB_DUTY',     'USR', '직책', '임직원 직책 분류 (MBR, TLD 등)', 3, false, true),
-- 시설 및 공간 도메인 (자산 코드 자동 생성 대상)
('FAC_CATEGORY', 'FAC', '시설 분류', '시설물 유형 분류 (STP, PMP 등)', 3, true, true),
('SPACE_TYPE',   'FAC', '공간 물리 유형', '공간의 물리적 성격 (BLD, FLR 등)', 3, true, true),
('SPACE_FUNC',   'FAC', '공간 기능 용도', '공간의 기능적 목적 (OFC, ELC 등)', 3, true, true)
ON CONFLICT (group_code) DO UPDATE SET 
    group_name = EXCLUDED.group_name,
    code_length = EXCLUDED.code_length,
    is_seq_used = EXCLUDED.is_seq_used;

-- 2. [Table] 상세 코드 등록 (3자 표준 규격)
INSERT INTO cmm.code_details (group_code, detail_code, detail_name, sort_order) VALUES
-- 직위 (JOB_POSITION)
('JOB_POSITION', 'STF', '사원', 10),
('JOB_POSITION', 'AST', '주임', 20),
('JOB_POSITION', 'ASC', '대리', 30),
('JOB_POSITION', 'MGR', '과장', 40),
('JOB_POSITION', 'SNR', '차장', 50),
('JOB_POSITION', 'DIR', '부장', 60),

-- 직책 (JOB_DUTY)
('JOB_DUTY', 'MBR', '팀원', 10),
('JOB_DUTY', 'PLD', '파트장', 20),
('JOB_DUTY', 'TLD', '팀장', 30),
('JOB_DUTY', 'HLD', '부서장', 40),
('JOB_DUTY', 'GLD', '본부장', 50),

-- 시설 분류 (FAC_CATEGORY) - 자산코드 생성 Prefix
('FAC_CATEGORY', 'STP', '하수처리시설', 10),
('FAC_CATEGORY', 'PMP', '중계펌프장', 20),
('FAC_CATEGORY', 'ADM', '관리/사무동', 30),
('FAC_CATEGORY', 'PRK', '공원/녹지', 40),
('FAC_CATEGORY', 'SOC', '주민편의시설', 50),

-- 공간 물리 유형 (SPACE_TYPE) - 공간코드 생성 Prefix
('SPACE_TYPE', 'BLD', '건물', 10),
('SPACE_TYPE', 'FLR', '층', 20),
('SPACE_TYPE', 'ZON', '구역', 30),
('SPACE_TYPE', 'ROM', '호실', 40),
('SPACE_TYPE', 'OUT', '실외/외부', 50),

-- 공간 기능 용도 (SPACE_FUNC)
('SPACE_FUNC', 'OFC', '사무실', 10),
('SPACE_FUNC', 'ELC', '전기실', 20),
('SPACE_FUNC', 'MCH', '기계실', 30),
('SPACE_FUNC', 'WTR', '수처리실', 40),
('SPACE_FUNC', 'LAB', '실험실', 50),
('SPACE_FUNC', 'TOL', '화장실', 60),
('SPACE_FUNC', 'STR', '창고', 70),
('SPACE_FUNC', 'PKS', '주차장', 80)
ON CONFLICT (group_code, detail_code) DO UPDATE SET detail_name = EXCLUDED.detail_name;
