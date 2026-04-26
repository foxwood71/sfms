-----------------------------------------------------------
-- [Phase 9] IAM Domain Seed Data
-- 시스템 기본 권한 항목 및 표준 역할 정의
-----------------------------------------------------------

-- 1. 세부 권한 항목 (Permissions) 등록
-- 중복 등록 방지를 위해 ON CONFLICT DO NOTHING 추가
INSERT INTO iam.permissions (domain_code, resource, action, description) VALUES
-- 시스템 및 보안
('SYS', 'AUDIT', 'READ', '시스템 감사 로그 조회'),
('SYS', 'CONFIG', 'READ', '시스템 설정 조회'),
('SYS', 'CONFIG', 'WRITE', '시스템 설정 변경'),
('IAM', 'ROLE', 'READ', '역할 정보 조회'),
('IAM', 'ROLE', 'WRITE', '역할 생성 및 권한 설정'),
('IAM', 'POLICY', 'WRITE', '보안 정책 및 필터링 설정'),

-- 조직 및 사용자
('USR', 'ORG', 'READ', '조직도 및 부서 정보 조회'),
('USR', 'ORG', 'WRITE', '부서 생성 및 수정'),
('USR', 'USER', 'READ', '사용자 목록 조회'),
('USR', 'USER', 'WRITE', '사용자 계정 관리'),

-- 공통 기능
('CMM', 'CODE', 'READ', '공통 코드 조회'),
('CMM', 'CODE', 'WRITE', '공통 코드 및 채번 관리'),
('CMM', 'FILE', 'READ', '첨부파일 다운로드'),
('CMM', 'FILE', 'WRITE', '파일 업로드'),
('CMM', 'FILE', 'DELETE', '파일 삭제'),

-- 시설 및 자산 (FAC)
('FAC', 'ASSET', 'READ', '자산/설비 마스터 조회'),
('FAC', 'ASSET', 'WRITE', '자산 정보 등록 및 수정'),
('FAC', 'ASSET', 'DELETE', '자산 정보 삭제'),
('FAC', 'SPACE', 'READ', '공간 및 도면 정보 조회'),
('FAC', 'MAINT', 'READ', '유지보수 이력 조회'),
('FAC', 'MAINT', 'WRITE', '유지보수 결과 기록'),

-- 실험실 관리 (LIM)
('LIM', 'ANALYSIS', 'READ', '실험 분석 데이터 조회'),
('LIM', 'ANALYSIS', 'WRITE', '실험 분석 데이터 입력'),
('LIM', 'ANALYSIS', 'APPROVE', '분석 결과 검토 및 승인'),
('LIM', 'LAB_EQUIP', 'READ', '실험 장비 정보 조회'),
('LIM', 'LAB_EQUIP', 'WRITE', '실험 장비 보정 및 관리'),

-- 자재 관리 (MAT)
('MAT', 'MASTER', 'READ', '자재 마스터 조회'),
('MAT', 'MASTER', 'WRITE', '자재 코드 및 단가 관리'),
('MAT', 'STOCK', 'READ', '재고 현황 조회'),
('MAT', 'STOCK', 'WRITE', '입출고 및 재고 조정')
ON CONFLICT (perm_code) DO NOTHING;


-- 2. 표준 역할 (Roles) 등록
INSERT INTO iam.roles (code, name, description, permissions, is_system) VALUES
('SYS_ADMIN', '시스템 관리자', '전체 시스템 제어 및 모든 데이터 접근 권한', '{"ALL": ["*"]}', true),

('OPS_MANAGER', '운영 관리자', '인사, 조직, 공통 코드 및 시스템 로그 관리', 
 '{"USR": ["*"], "IAM": ["*"], "CMM": ["*"], "SYS": ["READ"]}', false),

('FAC_MANAGER', '시설 관리자', '시설물 및 자산 관리 총괄', 
 '{"FAC": ["*"], "CMM": ["READ"], "USR": ["READ"]}', false),

('LAB_MANAGER', '실험실 관리자', '실험실 분석 및 장비 관리 총괄', 
 '{"LIM": ["*"], "FAC": ["READ"], "MAT": ["READ"]}', false),

('MAT_ADMIN', '자재 관리자', '전사 자재 수급 및 재고 관리 총괄', 
 '{"MAT": ["*"], "CMM": ["READ"]}', false),

('DEPT_HEAD', '부서장', '소속 부서 데이터 조회 및 승인 권한', 
 '{"FAC": ["READ", "WRITE"], "LIM": ["READ", "APPROVE"], "MAT": ["READ"]}', false),

('DEPT_MEMBER', '부서원', '일반 실무 수행 및 데이터 입력 권한', 
 '{"FAC": ["READ", "WRITE"], "LIM": ["READ", "WRITE"], "MAT": ["READ"]}', false),

('GUEST', '조회자', '시스템 전반에 대한 단순 조회 권한', 
 '{"FAC": ["READ"], "LIM": ["READ"], "MAT": ["READ"], "CMM": ["READ"]}', false)
ON CONFLICT (code) DO NOTHING;
