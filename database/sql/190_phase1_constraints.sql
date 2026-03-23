-----------------------------------------------------------
-- [Phase 1] Integrity & Hardening (Constraints)
-----------------------------------------------------------

-- 1. USR Domain
ALTER TABLE usr.organizations
    ADD CONSTRAINT fk_org_parent FOREIGN KEY (parent_id) REFERENCES usr.organizations(id),
    ADD CONSTRAINT fk_org_created_by FOREIGN KEY (created_by) REFERENCES usr.users(id),
    ADD CONSTRAINT fk_org_updated_by FOREIGN KEY (updated_by) REFERENCES usr.users(id);

ALTER TABLE usr.users
    ADD CONSTRAINT fk_usr_org FOREIGN KEY (org_id) REFERENCES usr.organizations(id),
    ADD CONSTRAINT fk_usr_created_by FOREIGN KEY (created_by) REFERENCES usr.users(id),
    ADD CONSTRAINT fk_usr_updated_by FOREIGN KEY (updated_by) REFERENCES usr.users(id);

-- 2. CMM Domain
ALTER TABLE cmm.code_groups
    ADD CONSTRAINT fk_cg_created_by FOREIGN KEY (created_by) REFERENCES usr.users(id),
    ADD CONSTRAINT fk_cg_updated_by FOREIGN KEY (updated_by) REFERENCES usr.users(id);

ALTER TABLE cmm.code_details
    ADD CONSTRAINT fk_cd_group FOREIGN KEY (group_code) REFERENCES cmm.code_groups(group_code) ON DELETE CASCADE,
    ADD CONSTRAINT fk_cd_created_by FOREIGN KEY (created_by) REFERENCES usr.users(id),
    ADD CONSTRAINT fk_cd_updated_by FOREIGN KEY (updated_by) REFERENCES usr.users(id);

-- 3. FAC Domain (Composite Foreign Keys)
ALTER TABLE fac.facilities
    ADD CONSTRAINT fk_fac_facilities_category 
        FOREIGN KEY (category_group_code, category_code) 
        REFERENCES cmm.code_details (group_code, detail_code),
    ADD CONSTRAINT fk_fac_created_by FOREIGN KEY (created_by) REFERENCES usr.users(id),
    ADD CONSTRAINT fk_fac_updated_by FOREIGN KEY (updated_by) REFERENCES usr.users(id);

ALTER TABLE fac.spaces
    ADD CONSTRAINT fk_fac_spaces_facility FOREIGN KEY (facility_id) REFERENCES fac.facilities(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_fac_spaces_parent FOREIGN KEY (parent_id) REFERENCES fac.spaces(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_fac_spaces_type 
        FOREIGN KEY (space_type_group_code, space_type_code) 
        REFERENCES cmm.code_details (group_code, detail_code),
    ADD CONSTRAINT fk_fac_spaces_func 
        FOREIGN KEY (space_func_group_code, space_func_code) 
        REFERENCES cmm.code_details (group_code, detail_code),
    ADD CONSTRAINT fk_fac_spaces_org FOREIGN KEY (org_id) REFERENCES usr.organizations(id),
    ADD CONSTRAINT fk_fac_spaces_created_by FOREIGN KEY (created_by) REFERENCES usr.users(id),
    ADD CONSTRAINT fk_fac_spaces_updated_by FOREIGN KEY (updated_by) REFERENCES usr.users(id);

-- 4. SYS Domain
ALTER TABLE sys.audit_logs
    ADD CONSTRAINT fk_audit_actor FOREIGN KEY (actor_user_id) REFERENCES usr.users(id);
