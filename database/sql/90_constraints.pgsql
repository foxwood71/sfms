-- database/05_constraints.pgsql
-- ========================================================
-- [Cross-Domain FK] 도메인 간 교차 참조 외래키 설정
-- 설명: 각 도메인 테이블 생성이 모두 완료된 후, 상호 참조가 
--       필요한 컬럼들의 외래키(FK)를 일괄적으로 연결합니다.
-- ========================================================

-- USR 도메인 -> CMM 도메인 (프로필 첨부파일 참조)
ALTER TABLE usr.users 
    ADD CONSTRAINT fk_usr_profile_image 
    FOREIGN KEY (profile_image_id) 
    REFERENCES cmm.attachments(id) 
    ON UPDATE CASCADE 
    ON DELETE SET NULL;