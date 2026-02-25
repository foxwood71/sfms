-- =========================================================
-- WIMS Location Module - Sample Data Seed Script (v3)
-- 파일명: wins.loc.seed.pgsql
-- 설명: 최신 스키마(address 포함, lat/long 제외)에 맞는 테스트 데이터 생성
-- =========================================================

BEGIN;

-- 1. 기존 데이터 초기화 (FK 제약조건 무시하고 삭제 & 시퀀스 초기화)
TRUNCATE TABLE loc.spaces, loc.facilities, loc.space_functions, loc.space_types, loc.facility_categories RESTART IDENTITY CASCADE;

-- ---------------------------------------------------------
-- 2. 기초 코드 데이터 생성 (Code Tables)
-- ---------------------------------------------------------

-- 2-1. 시설 카테고리
INSERT INTO loc.facility_categories (code, name, description) VALUES
('STP', '공공하수처리시설', 'Sewage Treatment Plant'),
('WTP', '정수처리시설', 'Water Treatment Plant'),
('PS',  '펌프장', 'Pumping Station'),
('ETC', '기타시설', 'Other Facilities');

-- 2-2. 공간 유형
INSERT INTO loc.space_types (code, name, description) VALUES
('BLD',  '건물', 'Building (관리동, 처리동 등)'),
('FLR',  '층',   'Floor (1층, 2층, 지하1층)'),
('ROOM', '실',   'Room (사무실, 제어실, 전기실)'),
('TANK', '수조', 'Tank (침전지, 포기조, 농축조)'),
('ZONE', '구역', 'Zone (실외 구역, 작업 구역)'),
('PIPE', '관로', 'Pipeline (지하 매설 관로 등)');

-- 2-3. 공간 기능
INSERT INTO loc.space_functions (code, name, category, description) VALUES
('ADMIN', '행정/사무', '일반', '사무실, 회의실, 휴게실'),
('MECH',  '기계설비',  '설비', '펌프실, 송풍기실, 기계실'),
('ELEC',  '전기설비',  '설비', 'MCC실, 변전실, 전기실'),
('INST',  '계측제어',  '제어', '중앙제어실, TMS실, 서버실'),
('CHEM',  '약품설비',  '화학', '약품투입동, 저장소'),
('PROC',  '수처리공정','공정', '침사지, 침전지, 생물반응조');


-- ---------------------------------------------------------
-- 3. 시설 데이터 생성 (Facilities)
-- ---------------------------------------------------------
-- [수정됨] address 컬럼 데이터 추가 (latitude, longitude 제외)

INSERT INTO loc.facilities (category_id, code, name, description, address, sort_order) VALUES
-- ID: 1
((SELECT id FROM loc.facility_categories WHERE code='STP'), 'FAC-001', '제1하수처리장', '메인 하수처리 시설입니다.', '경기도 광주시 초월읍 경충대로 1234', 1),
-- ID: 2
((SELECT id FROM loc.facility_categories WHERE code='PS'),  'FAC-002', '북부 중계펌프장', '북부 지역 오수 중계 시설', '경기도 광주시 곤지암읍 평촌길 56', 2),
-- ID: 3
((SELECT id FROM loc.facility_categories WHERE code='WTP'), 'FAC-003', '동부 정수장', '동부 지역 식수 공급 시설', '경기도 광주시 남한산성면 성남대로 789', 3);


-- ---------------------------------------------------------
-- 4. 공간 데이터 생성 (Spaces)
-- ---------------------------------------------------------

-- [시설 1: 제1하수처리장]

-- 4-1. Level 1 (건물/구조물)
INSERT INTO loc.spaces (id, facility_id, parent_id, space_type_id, space_function_id, code, name, area_size, is_restricted) VALUES
(1, 1, NULL, (SELECT id FROM loc.space_types WHERE code='BLD'), (SELECT id FROM loc.space_functions WHERE code='ADMIN'), 'BLD-MAIN', '관리동', 1500.00, false),
(2, 1, NULL, (SELECT id FROM loc.space_types WHERE code='BLD'), (SELECT id FROM loc.space_functions WHERE code='PROC'),  'BLD-TRT',  '수처리동', 2000.00, true),
(3, 1, NULL, (SELECT id FROM loc.space_types WHERE code='TANK'), (SELECT id FROM loc.space_functions WHERE code='PROC'), 'TNK-001',  '제1침전지', 500.00, true);

-- 4-2. Level 2 (층) - 관리동(ID:1) 하위
INSERT INTO loc.spaces (id, facility_id, parent_id, space_type_id, space_function_id, code, name, area_size) VALUES
(4, 1, 1, (SELECT id FROM loc.space_types WHERE code='FLR'), NULL, 'FLR-1F', '1층', 750.00),
(5, 1, 1, (SELECT id FROM loc.space_types WHERE code='FLR'), NULL, 'FLR-2F', '2층', 750.00);

-- 4-3. Level 3 (실) - 1층(ID:4) 하위
INSERT INTO loc.spaces (id, facility_id, parent_id, space_type_id, space_function_id, code, name, area_size, is_restricted) VALUES
(6, 1, 4, (SELECT id FROM loc.space_types WHERE code='ROOM'), (SELECT id FROM loc.space_functions WHERE code='INST'), 'RM-101', '중앙제어실', 100.00, true),
(7, 1, 4, (SELECT id FROM loc.space_types WHERE code='ROOM'), (SELECT id FROM loc.space_functions WHERE code='ADMIN'), 'RM-102', '운영사무실', 200.00, false);

-- 4-4. Level 3 (실) - 2층(ID:5) 하위
INSERT INTO loc.spaces (id, facility_id, parent_id, space_type_id, space_function_id, code, name, area_size) VALUES
(8, 1, 5, (SELECT id FROM loc.space_types WHERE code='ROOM'), (SELECT id FROM loc.space_functions WHERE code='ADMIN'), 'RM-201', '대회의실', 150.00),
(9, 1, 5, (SELECT id FROM loc.space_types WHERE code='ROOM'), (SELECT id FROM loc.space_functions WHERE code='ELEC'),  'RM-202', '서버실', 50.00);


-- [시설 2: 북부 중계펌프장]

INSERT INTO loc.spaces (id, facility_id, parent_id, space_type_id, space_function_id, code, name, area_size, is_restricted) VALUES
(10, 2, NULL, (SELECT id FROM loc.space_types WHERE code='ROOM'), (SELECT id FROM loc.space_functions WHERE code='MECH'), 'PM-ROOM', '지하 펌프실', 300.00, true),
(11, 2, NULL, (SELECT id FROM loc.space_types WHERE code='ROOM'), (SELECT id FROM loc.space_functions WHERE code='ELEC'), 'EL-ROOM', '전기실', 100.00, true);


-- ---------------------------------------------------------
-- 5. 시퀀스 동기화 (필수)
-- ---------------------------------------------------------
SELECT setval('loc.facility_categories_id_seq', (SELECT MAX(id) FROM loc.facility_categories));
SELECT setval('loc.space_types_id_seq', (SELECT MAX(id) FROM loc.space_types));
SELECT setval('loc.space_functions_id_seq', (SELECT MAX(id) FROM loc.space_functions));
SELECT setval('loc.facilities_id_seq', (SELECT MAX(id) FROM loc.facilities));
SELECT setval('loc.spaces_id_seq', (SELECT MAX(id) FROM loc.spaces));

COMMIT;

-- 6. 결과 확인
SELECT 'Facilities' as type, count(*) as count FROM loc.facilities
UNION ALL
SELECT 'Spaces', count(*) FROM loc.spaces;