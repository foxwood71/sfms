--
-- PostgreSQL database dump
--

\restrict Td54fw5Y0RIk4mQGWI1jE1q4XLfFdCZObguRK4qkKkD40VVT7HgnEvDZfIUSfuB

-- Dumped from database version 16.13 (Debian 16.13-1.pgdg13+1)
-- Dumped by pg_dump version 16.13 (Debian 16.13-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY usr.users DROP CONSTRAINT IF EXISTS users_org_id_fkey;
ALTER TABLE IF EXISTS ONLY usr.organizations DROP CONSTRAINT IF EXISTS organizations_parent_id_fkey;
ALTER TABLE IF EXISTS ONLY usr.users DROP CONSTRAINT IF EXISTS fk_usr_updated_by;
ALTER TABLE IF EXISTS ONLY usr.users DROP CONSTRAINT IF EXISTS fk_usr_profile_image;
ALTER TABLE IF EXISTS ONLY usr.users DROP CONSTRAINT IF EXISTS fk_usr_created_by;
ALTER TABLE IF EXISTS ONLY usr.organizations DROP CONSTRAINT IF EXISTS fk_org_updated_by;
ALTER TABLE IF EXISTS ONLY usr.organizations DROP CONSTRAINT IF EXISTS fk_org_created_by;
ALTER TABLE IF EXISTS ONLY sys.system_domains DROP CONSTRAINT IF EXISTS system_domains_updated_by_fkey;
ALTER TABLE IF EXISTS ONLY sys.system_domains DROP CONSTRAINT IF EXISTS system_domains_created_by_fkey;
ALTER TABLE IF EXISTS ONLY sys.sequence_rules DROP CONSTRAINT IF EXISTS sequence_rules_updated_by_fkey;
ALTER TABLE IF EXISTS ONLY sys.sequence_rules DROP CONSTRAINT IF EXISTS sequence_rules_domain_code_fkey;
ALTER TABLE IF EXISTS ONLY sys.sequence_rules DROP CONSTRAINT IF EXISTS sequence_rules_created_by_fkey;
ALTER TABLE IF EXISTS ONLY sys.audit_logs DROP CONSTRAINT IF EXISTS audit_logs_target_domain_fkey;
ALTER TABLE IF EXISTS ONLY sys.audit_logs DROP CONSTRAINT IF EXISTS audit_logs_actor_user_id_fkey;
ALTER TABLE IF EXISTS ONLY iam.user_roles DROP CONSTRAINT IF EXISTS user_roles_user_id_fkey;
ALTER TABLE IF EXISTS ONLY iam.user_roles DROP CONSTRAINT IF EXISTS user_roles_role_id_fkey;
ALTER TABLE IF EXISTS ONLY iam.user_roles DROP CONSTRAINT IF EXISTS user_roles_assigned_by_fkey;
ALTER TABLE IF EXISTS ONLY iam.roles DROP CONSTRAINT IF EXISTS roles_updated_by_fkey;
ALTER TABLE IF EXISTS ONLY iam.roles DROP CONSTRAINT IF EXISTS roles_created_by_fkey;
ALTER TABLE IF EXISTS ONLY fac.spaces DROP CONSTRAINT IF EXISTS spaces_updated_by_fkey;
ALTER TABLE IF EXISTS ONLY fac.spaces DROP CONSTRAINT IF EXISTS spaces_space_type_id_fkey;
ALTER TABLE IF EXISTS ONLY fac.spaces DROP CONSTRAINT IF EXISTS spaces_space_function_id_fkey;
ALTER TABLE IF EXISTS ONLY fac.spaces DROP CONSTRAINT IF EXISTS spaces_representative_image_id_fkey;
ALTER TABLE IF EXISTS ONLY fac.spaces DROP CONSTRAINT IF EXISTS spaces_parent_id_fkey;
ALTER TABLE IF EXISTS ONLY fac.spaces DROP CONSTRAINT IF EXISTS spaces_org_id_fkey;
ALTER TABLE IF EXISTS ONLY fac.spaces DROP CONSTRAINT IF EXISTS spaces_facility_id_fkey;
ALTER TABLE IF EXISTS ONLY fac.spaces DROP CONSTRAINT IF EXISTS spaces_created_by_fkey;
ALTER TABLE IF EXISTS ONLY fac.space_types DROP CONSTRAINT IF EXISTS space_types_updated_by_fkey;
ALTER TABLE IF EXISTS ONLY fac.space_types DROP CONSTRAINT IF EXISTS space_types_created_by_fkey;
ALTER TABLE IF EXISTS ONLY fac.space_functions DROP CONSTRAINT IF EXISTS space_functions_updated_by_fkey;
ALTER TABLE IF EXISTS ONLY fac.space_functions DROP CONSTRAINT IF EXISTS space_functions_created_by_fkey;
ALTER TABLE IF EXISTS ONLY fac.facility_categories DROP CONSTRAINT IF EXISTS facility_categories_updated_by_fkey;
ALTER TABLE IF EXISTS ONLY fac.facility_categories DROP CONSTRAINT IF EXISTS facility_categories_created_by_fkey;
ALTER TABLE IF EXISTS ONLY fac.facilities DROP CONSTRAINT IF EXISTS facilities_updated_by_fkey;
ALTER TABLE IF EXISTS ONLY fac.facilities DROP CONSTRAINT IF EXISTS facilities_representative_image_id_fkey;
ALTER TABLE IF EXISTS ONLY fac.facilities DROP CONSTRAINT IF EXISTS facilities_created_by_fkey;
ALTER TABLE IF EXISTS ONLY fac.facilities DROP CONSTRAINT IF EXISTS facilities_category_id_fkey;
ALTER TABLE IF EXISTS ONLY cmm.notifications DROP CONSTRAINT IF EXISTS notifications_sender_user_id_fkey;
ALTER TABLE IF EXISTS ONLY cmm.notifications DROP CONSTRAINT IF EXISTS notifications_receiver_user_id_fkey;
ALTER TABLE IF EXISTS ONLY cmm.notifications DROP CONSTRAINT IF EXISTS notifications_domain_code_fkey;
ALTER TABLE IF EXISTS ONLY cmm.code_groups DROP CONSTRAINT IF EXISTS code_groups_updated_by_fkey;
ALTER TABLE IF EXISTS ONLY cmm.code_groups DROP CONSTRAINT IF EXISTS code_groups_domain_code_fkey;
ALTER TABLE IF EXISTS ONLY cmm.code_groups DROP CONSTRAINT IF EXISTS code_groups_created_by_fkey;
ALTER TABLE IF EXISTS ONLY cmm.code_details DROP CONSTRAINT IF EXISTS code_details_updated_by_fkey;
ALTER TABLE IF EXISTS ONLY cmm.code_details DROP CONSTRAINT IF EXISTS code_details_group_code_fkey;
ALTER TABLE IF EXISTS ONLY cmm.code_details DROP CONSTRAINT IF EXISTS code_details_created_by_fkey;
ALTER TABLE IF EXISTS ONLY cmm.attachments DROP CONSTRAINT IF EXISTS attachments_updated_by_fkey;
ALTER TABLE IF EXISTS ONLY cmm.attachments DROP CONSTRAINT IF EXISTS attachments_domain_code_fkey;
ALTER TABLE IF EXISTS ONLY cmm.attachments DROP CONSTRAINT IF EXISTS attachments_created_by_fkey;
DROP TRIGGER IF EXISTS trg_updated_at_users ON usr.users;
DROP TRIGGER IF EXISTS trg_updated_at_organizations ON usr.organizations;
DROP TRIGGER IF EXISTS trg_updated_at_system_domains ON sys.system_domains;
DROP TRIGGER IF EXISTS trg_updated_at_sequence_rules ON sys.sequence_rules;
DROP TRIGGER IF EXISTS trg_updated_at_roles ON iam.roles;
DROP TRIGGER IF EXISTS trg_updated_at_spaces ON fac.spaces;
DROP TRIGGER IF EXISTS trg_updated_at_space_types ON fac.space_types;
DROP TRIGGER IF EXISTS trg_updated_at_space_functions ON fac.space_functions;
DROP TRIGGER IF EXISTS trg_updated_at_facility_categories ON fac.facility_categories;
DROP TRIGGER IF EXISTS trg_updated_at_facilities ON fac.facilities;
DROP TRIGGER IF EXISTS trg_updated_at_notifications ON cmm.notifications;
DROP TRIGGER IF EXISTS trg_updated_at_code_groups ON cmm.code_groups;
DROP TRIGGER IF EXISTS trg_updated_at_code_details ON cmm.code_details;
DROP TRIGGER IF EXISTS trg_updated_at_attachments ON cmm.attachments;
DROP INDEX IF EXISTS usr.idx_usr_users_org_id;
DROP INDEX IF EXISTS usr.idx_usr_users_metadata_gin;
DROP INDEX IF EXISTS usr.idx_usr_org_parent;
DROP INDEX IF EXISTS usr.idx_usr_name_pg;
DROP INDEX IF EXISTS usr.idx_usr_login_id;
DROP INDEX IF EXISTS sys.idx_cmm_audit_target_lookup;
DROP INDEX IF EXISTS sys.idx_cmm_audit_snap_pg;
DROP INDEX IF EXISTS sys.idx_cmm_audit_desc_pg;
DROP INDEX IF EXISTS sys.idx_cmm_audit_actor;
DROP INDEX IF EXISTS iam.idx_iam_user_roles_role_id;
DROP INDEX IF EXISTS iam.idx_iam_roles_permissions_gin;
DROP INDEX IF EXISTS fac.idx_fac_spaces_name_pg;
DROP INDEX IF EXISTS fac.idx_fac_spaces_meta_pg;
DROP INDEX IF EXISTS fac.idx_fac_spaces_meta_gin;
DROP INDEX IF EXISTS fac.idx_fac_spaces_hierarchy;
DROP INDEX IF EXISTS fac.idx_fac_name_pg;
DROP INDEX IF EXISTS fac.idx_fac_meta_gin;
DROP INDEX IF EXISTS cmm.uq_attachments_active_path;
DROP INDEX IF EXISTS cmm.idx_notifications_receiver_unread;
DROP INDEX IF EXISTS cmm.idx_code_groups_domain;
DROP INDEX IF EXISTS cmm.idx_code_details_group;
DROP INDEX IF EXISTS cmm.idx_attachments_ref;
ALTER TABLE IF EXISTS ONLY usr.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY usr.users DROP CONSTRAINT IF EXISTS users_login_id_key;
ALTER TABLE IF EXISTS ONLY usr.users DROP CONSTRAINT IF EXISTS users_emp_code_key;
ALTER TABLE IF EXISTS ONLY usr.users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE IF EXISTS ONLY usr.organizations DROP CONSTRAINT IF EXISTS organizations_pkey;
ALTER TABLE IF EXISTS ONLY usr.organizations DROP CONSTRAINT IF EXISTS organizations_code_key;
ALTER TABLE IF EXISTS ONLY sys.sequence_rules DROP CONSTRAINT IF EXISTS uq_sequence_rules_domain_prefix;
ALTER TABLE IF EXISTS ONLY sys.system_domains DROP CONSTRAINT IF EXISTS system_domains_schema_name_key;
ALTER TABLE IF EXISTS ONLY sys.system_domains DROP CONSTRAINT IF EXISTS system_domains_pkey;
ALTER TABLE IF EXISTS ONLY sys.system_domains DROP CONSTRAINT IF EXISTS system_domains_domain_code_key;
ALTER TABLE IF EXISTS ONLY sys.sequence_rules DROP CONSTRAINT IF EXISTS sequence_rules_pkey;
ALTER TABLE IF EXISTS ONLY sys.audit_logs DROP CONSTRAINT IF EXISTS audit_logs_pkey;
ALTER TABLE IF EXISTS ONLY iam.user_roles DROP CONSTRAINT IF EXISTS user_roles_pkey;
ALTER TABLE IF EXISTS ONLY iam.roles DROP CONSTRAINT IF EXISTS roles_pkey;
ALTER TABLE IF EXISTS ONLY iam.roles DROP CONSTRAINT IF EXISTS roles_code_key;
ALTER TABLE IF EXISTS ONLY fac.spaces DROP CONSTRAINT IF EXISTS uq_fac_spaces_code;
ALTER TABLE IF EXISTS ONLY fac.spaces DROP CONSTRAINT IF EXISTS spaces_pkey;
ALTER TABLE IF EXISTS ONLY fac.space_types DROP CONSTRAINT IF EXISTS space_types_pkey;
ALTER TABLE IF EXISTS ONLY fac.space_types DROP CONSTRAINT IF EXISTS space_types_code_key;
ALTER TABLE IF EXISTS ONLY fac.space_functions DROP CONSTRAINT IF EXISTS space_functions_pkey;
ALTER TABLE IF EXISTS ONLY fac.space_functions DROP CONSTRAINT IF EXISTS space_functions_code_key;
ALTER TABLE IF EXISTS ONLY fac.facility_categories DROP CONSTRAINT IF EXISTS facility_categories_pkey;
ALTER TABLE IF EXISTS ONLY fac.facility_categories DROP CONSTRAINT IF EXISTS facility_categories_code_key;
ALTER TABLE IF EXISTS ONLY fac.facilities DROP CONSTRAINT IF EXISTS facilities_pkey;
ALTER TABLE IF EXISTS ONLY fac.facilities DROP CONSTRAINT IF EXISTS facilities_code_key;
ALTER TABLE IF EXISTS ONLY cmm.code_details DROP CONSTRAINT IF EXISTS uq_code_details_group_detail;
ALTER TABLE IF EXISTS ONLY cmm.notifications DROP CONSTRAINT IF EXISTS notifications_pkey;
ALTER TABLE IF EXISTS ONLY cmm.code_groups DROP CONSTRAINT IF EXISTS code_groups_pkey;
ALTER TABLE IF EXISTS ONLY cmm.code_groups DROP CONSTRAINT IF EXISTS code_groups_group_code_key;
ALTER TABLE IF EXISTS ONLY cmm.code_details DROP CONSTRAINT IF EXISTS code_details_pkey;
ALTER TABLE IF EXISTS ONLY cmm.attachments DROP CONSTRAINT IF EXISTS attachments_pkey;
ALTER TABLE IF EXISTS usr.users ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS usr.organizations ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS sys.system_domains ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS sys.sequence_rules ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS sys.audit_logs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS iam.roles ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS fac.spaces ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS fac.space_types ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS fac.space_functions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS fac.facility_categories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS fac.facilities ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS cmm.notifications ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS cmm.code_groups ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS cmm.code_details ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS usr.users_id_seq;
DROP TABLE IF EXISTS usr.users;
DROP SEQUENCE IF EXISTS usr.organizations_id_seq;
DROP TABLE IF EXISTS usr.organizations;
DROP SEQUENCE IF EXISTS sys.system_domains_id_seq;
DROP TABLE IF EXISTS sys.system_domains;
DROP SEQUENCE IF EXISTS sys.sequence_rules_id_seq;
DROP TABLE IF EXISTS sys.sequence_rules;
DROP SEQUENCE IF EXISTS sys.audit_logs_id_seq;
DROP TABLE IF EXISTS sys.audit_logs;
DROP TABLE IF EXISTS iam.user_roles;
DROP SEQUENCE IF EXISTS iam.roles_id_seq;
DROP TABLE IF EXISTS iam.roles;
DROP SEQUENCE IF EXISTS fac.spaces_id_seq;
DROP TABLE IF EXISTS fac.spaces;
DROP SEQUENCE IF EXISTS fac.space_types_id_seq;
DROP TABLE IF EXISTS fac.space_types;
DROP SEQUENCE IF EXISTS fac.space_functions_id_seq;
DROP TABLE IF EXISTS fac.space_functions;
DROP SEQUENCE IF EXISTS fac.facility_categories_id_seq;
DROP TABLE IF EXISTS fac.facility_categories;
DROP SEQUENCE IF EXISTS fac.facilities_id_seq;
DROP TABLE IF EXISTS fac.facilities;
DROP VIEW IF EXISTS cmm.v_code_lookup;
DROP SEQUENCE IF EXISTS cmm.notifications_id_seq;
DROP TABLE IF EXISTS cmm.notifications;
DROP SEQUENCE IF EXISTS cmm.code_groups_id_seq;
DROP TABLE IF EXISTS cmm.code_groups;
DROP SEQUENCE IF EXISTS cmm.code_details_id_seq;
DROP TABLE IF EXISTS cmm.code_details;
DROP TABLE IF EXISTS cmm.attachments;
DROP FUNCTION IF EXISTS sys.trg_set_updated_at();
DROP FUNCTION IF EXISTS sys.fn_get_next_sequence(p_domain_code character varying, p_prefix character varying, p_user_id bigint);
DROP EXTENSION IF EXISTS "uuid-ossp";
DROP EXTENSION IF EXISTS pgroonga;
DROP SCHEMA IF EXISTS usr;
DROP SCHEMA IF EXISTS sys;
DROP SCHEMA IF EXISTS iam;
DROP SCHEMA IF EXISTS fac;
DROP SCHEMA IF EXISTS cmm;
--
-- Name: cmm; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA cmm;


--
-- Name: SCHEMA cmm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA cmm IS '공통 관리 도메인 (기준정보, 파일, 로그)';


--
-- Name: fac; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA fac;


--
-- Name: SCHEMA fac; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA fac IS '시설물 및 공간(Site/Location) 관리 도메인';


--
-- Name: iam; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA iam;


--
-- Name: SCHEMA iam; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA iam IS '인증 및 권한 관리 도메인';


--
-- Name: sys; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sys;


--
-- Name: SCHEMA sys; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA sys IS '시스템 관리 도메인 (도메인, 체번, 감사 로그)';


--
-- Name: usr; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA usr;


--
-- Name: SCHEMA usr; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA usr IS '사용자 및 조직 관리 도메인';


--
-- Name: pgroonga; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgroonga WITH SCHEMA public;


--
-- Name: EXTENSION pgroonga; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgroonga IS 'sfms_db 검색용 PGroonga 확장';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: fn_get_next_sequence(character varying, character varying, bigint); Type: FUNCTION; Schema: sys; Owner: -
--

CREATE FUNCTION sys.fn_get_next_sequence(p_domain_code character varying, p_prefix character varying, p_user_id bigint DEFAULT NULL::bigint) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: FUNCTION fn_get_next_sequence(p_domain_code character varying, p_prefix character varying, p_user_id bigint); Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON FUNCTION sys.fn_get_next_sequence(p_domain_code character varying, p_prefix character varying, p_user_id bigint) IS '도메인 및 접두어 기반 자동 문서 번호 생성 함수 (Concurrency Safe)';


--
-- Name: trg_set_updated_at(); Type: FUNCTION; Schema: sys; Owner: -
--

CREATE FUNCTION sys.trg_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: FUNCTION trg_set_updated_at(); Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON FUNCTION sys.trg_set_updated_at() IS '레코드 수정 시 updated_at 필드를 자동으로 갱신하는 트리거 함수';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: attachments; Type: TABLE; Schema: cmm; Owner: -
--

CREATE TABLE cmm.attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    domain_code character varying(3) NOT NULL,
    resource_type character varying(50) NOT NULL,
    ref_id bigint NOT NULL,
    category_code character varying(20) NOT NULL,
    file_name character varying(255) NOT NULL,
    file_path character varying(500) NOT NULL,
    file_size bigint DEFAULT 0 NOT NULL,
    content_type character varying(100),
    org_id bigint,
    props jsonb DEFAULT '{}'::jsonb NOT NULL,
    legacy_id integer,
    legacy_source character varying(50),
    is_deleted boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint,
    CONSTRAINT chk_attachments_size CHECK ((file_size >= 0))
);


--
-- Name: TABLE attachments; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON TABLE cmm.attachments IS '통합 첨부파일 관리 테이블';


--
-- Name: COLUMN attachments.id; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.id IS '파일 고유 식별자 (UUID)';


--
-- Name: COLUMN attachments.domain_code; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.domain_code IS '업무 도메인 코드 (FK)';


--
-- Name: COLUMN attachments.ref_id; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.ref_id IS '첨부파일이 연결된 원본 데이터의 ID';


--
-- Name: COLUMN attachments.category_code; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.category_code IS '첨부파일 분류 코드 (예: PROFILE, DOC)';


--
-- Name: COLUMN attachments.file_name; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.file_name IS '업로드된 원본 파일명';


--
-- Name: COLUMN attachments.file_path; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.file_path IS '물리적 저장 경로 (Object Storage Key)';


--
-- Name: COLUMN attachments.file_size; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.file_size IS '파일 크기 (Byte 단위)';


--
-- Name: COLUMN attachments.content_type; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.content_type IS '파일의 MIME Type (예: image/jpeg)';


--
-- Name: COLUMN attachments.org_id; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.org_id IS '관리 책임 부서 ID (부서원 공유 권한 기초)';


--
-- Name: COLUMN attachments.props; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.props IS '파일 추가 메타데이터 (JSONB)';


--
-- Name: COLUMN attachments.legacy_id; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.legacy_id IS '기존 시스템에서의 파일 ID (마이그레이션용)';


--
-- Name: COLUMN attachments.legacy_source; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.legacy_source IS '기존 시스템 출처 테이블명 (마이그레이션용)';


--
-- Name: COLUMN attachments.is_deleted; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.is_deleted IS '삭제 여부 (True: 삭제됨, 실제 파일은 배치로 정리)';


--
-- Name: COLUMN attachments.created_at; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.created_at IS '업로드 일시';


--
-- Name: COLUMN attachments.created_by; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.created_by IS '업로더 ID';


--
-- Name: COLUMN attachments.updated_at; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.updated_at IS '메타데이터 수정 일시';


--
-- Name: COLUMN attachments.updated_by; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.attachments.updated_by IS '메타데이터 수정자 ID';


--
-- Name: code_details; Type: TABLE; Schema: cmm; Owner: -
--

CREATE TABLE cmm.code_details (
    id bigint NOT NULL,
    group_code character varying(30) NOT NULL,
    detail_code character varying(30) NOT NULL,
    detail_name character varying(100) NOT NULL,
    props jsonb DEFAULT '{}'::jsonb NOT NULL,
    sort_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint,
    CONSTRAINT chk_detail_code_format CHECK (((detail_code)::text ~ '^[A-Z0-9_]+$'::text))
);


--
-- Name: TABLE code_details; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON TABLE cmm.code_details IS '공통 코드 상세 (아이템) 정의 테이블';


--
-- Name: COLUMN code_details.id; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_details.id IS '코드 상세 고유 ID (PK)';


--
-- Name: COLUMN code_details.group_code; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_details.group_code IS '소속된 코드 그룹 코드 (FK)';


--
-- Name: COLUMN code_details.detail_code; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_details.detail_code IS '상세 코드 값 (실제 저장되는 값, 예: 01)';


--
-- Name: COLUMN code_details.detail_name; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_details.detail_name IS '상세 코드 명칭 (화면에 표시되는 값, 예: 1분기)';


--
-- Name: COLUMN code_details.props; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_details.props IS '코드별 확장 속성 데이터 (JSONB, 예: {color: "red"})';


--
-- Name: COLUMN code_details.sort_order; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_details.sort_order IS '코드 표시 순서';


--
-- Name: COLUMN code_details.is_active; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_details.is_active IS '코드 상세 사용 여부';


--
-- Name: COLUMN code_details.created_at; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_details.created_at IS '생성 일시';


--
-- Name: COLUMN code_details.created_by; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_details.created_by IS '생성자 ID';


--
-- Name: COLUMN code_details.updated_at; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_details.updated_at IS '수정 일시';


--
-- Name: COLUMN code_details.updated_by; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_details.updated_by IS '수정자 ID';


--
-- Name: code_details_id_seq; Type: SEQUENCE; Schema: cmm; Owner: -
--

CREATE SEQUENCE cmm.code_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: code_details_id_seq; Type: SEQUENCE OWNED BY; Schema: cmm; Owner: -
--

ALTER SEQUENCE cmm.code_details_id_seq OWNED BY cmm.code_details.id;


--
-- Name: code_groups; Type: TABLE; Schema: cmm; Owner: -
--

CREATE TABLE cmm.code_groups (
    id bigint NOT NULL,
    group_code character varying(30) NOT NULL,
    domain_code character varying(3),
    group_name character varying(100) NOT NULL,
    description text,
    is_system boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint,
    CONSTRAINT chk_group_code_format CHECK (((group_code)::text ~ '^[A-Z0-9_]+$'::text))
);


--
-- Name: TABLE code_groups; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON TABLE cmm.code_groups IS '공통 코드 그룹 (헤더) 정의 테이블';


--
-- Name: COLUMN code_groups.id; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_groups.id IS '코드 그룹 고유 ID (PK)';


--
-- Name: COLUMN code_groups.group_code; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_groups.group_code IS '그룹 식별 코드 (Unique, 예: GENDER_TYPE)';


--
-- Name: COLUMN code_groups.domain_code; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_groups.domain_code IS '해당 코드를 관리하는 도메인 코드 (FK)';


--
-- Name: COLUMN code_groups.group_name; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_groups.group_name IS '코드 그룹 명칭 (예: 성별)';


--
-- Name: COLUMN code_groups.description; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_groups.description IS '코드 그룹에 대한 설명';


--
-- Name: COLUMN code_groups.is_system; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_groups.is_system IS '시스템 필수 코드 여부 (True인 경우 UI에서 삭제 불가)';


--
-- Name: COLUMN code_groups.is_active; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_groups.is_active IS '코드 그룹 사용 여부';


--
-- Name: COLUMN code_groups.created_at; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_groups.created_at IS '생성 일시';


--
-- Name: COLUMN code_groups.created_by; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_groups.created_by IS '생성자 ID';


--
-- Name: COLUMN code_groups.updated_at; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_groups.updated_at IS '수정 일시';


--
-- Name: COLUMN code_groups.updated_by; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.code_groups.updated_by IS '수정자 ID';


--
-- Name: code_groups_id_seq; Type: SEQUENCE; Schema: cmm; Owner: -
--

CREATE SEQUENCE cmm.code_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: code_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: cmm; Owner: -
--

ALTER SEQUENCE cmm.code_groups_id_seq OWNED BY cmm.code_groups.id;


--
-- Name: notifications; Type: TABLE; Schema: cmm; Owner: -
--

CREATE TABLE cmm.notifications (
    id bigint NOT NULL,
    domain_code character varying(3),
    sender_user_id bigint,
    receiver_user_id bigint,
    category character varying(20) NOT NULL,
    priority character varying(10) DEFAULT 'NORMAL'::character varying,
    title character varying(200) NOT NULL,
    content text,
    link_url character varying(500),
    props jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_read boolean DEFAULT false,
    read_at timestamp with time zone,
    is_deleted boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_notifications_read_time CHECK (((read_at IS NULL) OR (read_at >= created_at)))
);


--
-- Name: TABLE notifications; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON TABLE cmm.notifications IS '사용자 알림 및 메시지 관리 테이블';


--
-- Name: COLUMN notifications.id; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.notifications.id IS '알림 고유 ID (PK)';


--
-- Name: COLUMN notifications.domain_code; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.notifications.domain_code IS '관련 도메인 코드';


--
-- Name: COLUMN notifications.sender_user_id; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.notifications.sender_user_id IS '보낸 사람 ID (NULL: 시스템)';


--
-- Name: COLUMN notifications.receiver_user_id; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.notifications.receiver_user_id IS '받는 사람 ID';


--
-- Name: COLUMN notifications.category; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.notifications.category IS '알림 카테고리 (예: 공지, 경고, 일반)';


--
-- Name: COLUMN notifications.priority; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.notifications.priority IS '알림 중요도 (URGENT, NORMAL, LOW)';


--
-- Name: COLUMN notifications.title; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.notifications.title IS '알림 제목';


--
-- Name: COLUMN notifications.content; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.notifications.content IS '알림 본문 내용';


--
-- Name: COLUMN notifications.link_url; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.notifications.link_url IS '알림 클릭 시 이동할 링크 URL';


--
-- Name: COLUMN notifications.props; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.notifications.props IS '알림 관련 추가 속성 (JSONB)';


--
-- Name: COLUMN notifications.is_read; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.notifications.is_read IS '수신자 확인 여부 (True: 읽음)';


--
-- Name: COLUMN notifications.read_at; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.notifications.read_at IS '수신자가 확인한 일시';


--
-- Name: COLUMN notifications.is_deleted; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.notifications.is_deleted IS '수신자 삭제(숨김) 여부';


--
-- Name: COLUMN notifications.created_at; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.notifications.created_at IS '알림 생성 일시';


--
-- Name: COLUMN notifications.updated_at; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.notifications.updated_at IS '알림 상태 수정 일시';


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: cmm; Owner: -
--

CREATE SEQUENCE cmm.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: cmm; Owner: -
--

ALTER SEQUENCE cmm.notifications_id_seq OWNED BY cmm.notifications.id;


--
-- Name: v_code_lookup; Type: VIEW; Schema: cmm; Owner: -
--

CREATE VIEW cmm.v_code_lookup AS
 SELECT g.domain_code,
    g.group_code,
    g.group_name,
    d.id AS detail_id,
    d.detail_code AS value,
    d.detail_name AS label,
    d.props,
    d.sort_order
   FROM (cmm.code_groups g
     JOIN cmm.code_details d ON (((g.group_code)::text = (d.group_code)::text)))
  WHERE ((g.is_active = true) AND (d.is_active = true))
  ORDER BY g.group_code, d.sort_order;


--
-- Name: VIEW v_code_lookup; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON VIEW cmm.v_code_lookup IS '프론트엔드 Select 컴포넌트용 통합 코드 조회 뷰 (Value/Label 매핑)';


--
-- Name: COLUMN v_code_lookup.domain_code; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.v_code_lookup.domain_code IS '도메인 구분 코드';


--
-- Name: COLUMN v_code_lookup.group_code; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.v_code_lookup.group_code IS '코드 그룹 식별자';


--
-- Name: COLUMN v_code_lookup.group_name; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.v_code_lookup.group_name IS '코드 그룹 명칭';


--
-- Name: COLUMN v_code_lookup.detail_id; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.v_code_lookup.detail_id IS '코드 상세 ID';


--
-- Name: COLUMN v_code_lookup.value; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.v_code_lookup.value IS '코드 값 (Select Box value)';


--
-- Name: COLUMN v_code_lookup.label; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.v_code_lookup.label IS '코드 표시명 (Select Box label)';


--
-- Name: COLUMN v_code_lookup.props; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.v_code_lookup.props IS '코드 확장 속성 JSON';


--
-- Name: COLUMN v_code_lookup.sort_order; Type: COMMENT; Schema: cmm; Owner: -
--

COMMENT ON COLUMN cmm.v_code_lookup.sort_order IS '정렬 순서';


--
-- Name: facilities; Type: TABLE; Schema: fac; Owner: -
--

CREATE TABLE fac.facilities (
    id bigint NOT NULL,
    category_id bigint,
    representative_image_id uuid,
    code character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    address character varying(255),
    is_active boolean DEFAULT true,
    sort_order integer DEFAULT 0,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    legacy_id integer,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint,
    CONSTRAINT chk_facility_code_upper CHECK (((code)::text = upper((code)::text)))
);


--
-- Name: TABLE facilities; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON TABLE fac.facilities IS '최상위 시설물(사업소/처리장) 정보 테이블';


--
-- Name: COLUMN facilities.id; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facilities.id IS '시설물 고유 ID (PK)';


--
-- Name: COLUMN facilities.category_id; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facilities.category_id IS '시설물 카테고리 ID (FK)';


--
-- Name: COLUMN facilities.representative_image_id; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facilities.representative_image_id IS '시설물 대표 이미지 ID (FK)';


--
-- Name: COLUMN facilities.code; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facilities.code IS '시설물 관리 코드 (Unique, 대문자)';


--
-- Name: COLUMN facilities.name; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facilities.name IS '시설물 명칭';


--
-- Name: COLUMN facilities.address; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facilities.address IS '시설물 주소';


--
-- Name: COLUMN facilities.is_active; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facilities.is_active IS '운영(활성) 여부';


--
-- Name: COLUMN facilities.sort_order; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facilities.sort_order IS '표시 정렬 순서';


--
-- Name: COLUMN facilities.metadata; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facilities.metadata IS '시설물 추가 속성 JSON (연락처, 좌표 등)';


--
-- Name: COLUMN facilities.legacy_id; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facilities.legacy_id IS '[마이그레이션] 기존 시스템 시설 ID';


--
-- Name: COLUMN facilities.created_at; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facilities.created_at IS '생성 일시';


--
-- Name: COLUMN facilities.created_by; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facilities.created_by IS '생성자 ID';


--
-- Name: COLUMN facilities.updated_at; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facilities.updated_at IS '수정 일시';


--
-- Name: COLUMN facilities.updated_by; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facilities.updated_by IS '수정자 ID';


--
-- Name: facilities_id_seq; Type: SEQUENCE; Schema: fac; Owner: -
--

CREATE SEQUENCE fac.facilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: facilities_id_seq; Type: SEQUENCE OWNED BY; Schema: fac; Owner: -
--

ALTER SEQUENCE fac.facilities_id_seq OWNED BY fac.facilities.id;


--
-- Name: facility_categories; Type: TABLE; Schema: fac; Owner: -
--

CREATE TABLE fac.facility_categories (
    id bigint NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint,
    CONSTRAINT chk_facility_categories_code_upper CHECK (((code)::text = upper((code)::text)))
);


--
-- Name: TABLE facility_categories; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON TABLE fac.facility_categories IS '시설물 유형 분류 (예: 처리장, 펌프장, 관로 등)';


--
-- Name: COLUMN facility_categories.id; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facility_categories.id IS '카테고리 ID (PK)';


--
-- Name: COLUMN facility_categories.code; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facility_categories.code IS '카테고리 식별 코드 (Unique, 대문자)';


--
-- Name: COLUMN facility_categories.name; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facility_categories.name IS '카테고리 명칭';


--
-- Name: COLUMN facility_categories.description; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facility_categories.description IS '카테고리 상세 설명';


--
-- Name: COLUMN facility_categories.is_active; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facility_categories.is_active IS '사용 여부';


--
-- Name: COLUMN facility_categories.created_at; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facility_categories.created_at IS '생성 일시';


--
-- Name: COLUMN facility_categories.created_by; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facility_categories.created_by IS '생성자 ID';


--
-- Name: COLUMN facility_categories.updated_at; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facility_categories.updated_at IS '수정 일시';


--
-- Name: COLUMN facility_categories.updated_by; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.facility_categories.updated_by IS '수정자 ID';


--
-- Name: facility_categories_id_seq; Type: SEQUENCE; Schema: fac; Owner: -
--

CREATE SEQUENCE fac.facility_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: facility_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: fac; Owner: -
--

ALTER SEQUENCE fac.facility_categories_id_seq OWNED BY fac.facility_categories.id;


--
-- Name: space_functions; Type: TABLE; Schema: fac; Owner: -
--

CREATE TABLE fac.space_functions (
    id bigint NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint,
    CONSTRAINT chk_space_functions_code_upper CHECK (((code)::text = upper((code)::text)))
);


--
-- Name: TABLE space_functions; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON TABLE fac.space_functions IS '공간의 기능적 용도 정의 (전기실, 제어실, 화장실 등)';


--
-- Name: COLUMN space_functions.id; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.space_functions.id IS '공간 기능 ID (PK)';


--
-- Name: COLUMN space_functions.code; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.space_functions.code IS '기능 식별 코드 (Unique, 대문자)';


--
-- Name: COLUMN space_functions.name; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.space_functions.name IS '기능 명칭';


--
-- Name: COLUMN space_functions.is_active; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.space_functions.is_active IS '사용 여부';


--
-- Name: COLUMN space_functions.created_at; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.space_functions.created_at IS '생성 일시';


--
-- Name: COLUMN space_functions.created_by; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.space_functions.created_by IS '생성자 ID';


--
-- Name: COLUMN space_functions.updated_at; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.space_functions.updated_at IS '수정 일시';


--
-- Name: COLUMN space_functions.updated_by; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.space_functions.updated_by IS '수정자 ID';


--
-- Name: space_functions_id_seq; Type: SEQUENCE; Schema: fac; Owner: -
--

CREATE SEQUENCE fac.space_functions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: space_functions_id_seq; Type: SEQUENCE OWNED BY; Schema: fac; Owner: -
--

ALTER SEQUENCE fac.space_functions_id_seq OWNED BY fac.space_functions.id;


--
-- Name: space_types; Type: TABLE; Schema: fac; Owner: -
--

CREATE TABLE fac.space_types (
    id bigint NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint,
    CONSTRAINT chk_space_types_code_upper CHECK (((code)::text = upper((code)::text)))
);


--
-- Name: TABLE space_types; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON TABLE fac.space_types IS '공간의 물리적 유형 정의 (건물, 층, 구역 등)';


--
-- Name: COLUMN space_types.id; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.space_types.id IS '공간 유형 ID (PK)';


--
-- Name: COLUMN space_types.code; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.space_types.code IS '유형 식별 코드 (Unique, 대문자)';


--
-- Name: COLUMN space_types.name; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.space_types.name IS '유형 명칭';


--
-- Name: COLUMN space_types.is_active; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.space_types.is_active IS '사용 여부';


--
-- Name: COLUMN space_types.created_at; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.space_types.created_at IS '생성 일시';


--
-- Name: COLUMN space_types.created_by; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.space_types.created_by IS '생성자 ID';


--
-- Name: COLUMN space_types.updated_at; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.space_types.updated_at IS '수정 일시';


--
-- Name: COLUMN space_types.updated_by; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.space_types.updated_by IS '수정자 ID';


--
-- Name: space_types_id_seq; Type: SEQUENCE; Schema: fac; Owner: -
--

CREATE SEQUENCE fac.space_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: space_types_id_seq; Type: SEQUENCE OWNED BY; Schema: fac; Owner: -
--

ALTER SEQUENCE fac.space_types_id_seq OWNED BY fac.space_types.id;


--
-- Name: spaces; Type: TABLE; Schema: fac; Owner: -
--

CREATE TABLE fac.spaces (
    id bigint NOT NULL,
    facility_id bigint NOT NULL,
    parent_id bigint,
    representative_image_id uuid,
    space_type_id bigint,
    space_function_id bigint,
    code character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    area_size numeric(10,2),
    is_active boolean DEFAULT true,
    sort_order integer DEFAULT 0,
    is_restricted boolean DEFAULT false,
    org_id bigint,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    legacy_id integer,
    legacy_source_tbl character varying(50),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint,
    CONSTRAINT chk_spaces_code_upper CHECK (((code)::text = upper((code)::text))),
    CONSTRAINT chk_spaces_parent_recursive CHECK ((id <> parent_id))
);


--
-- Name: TABLE spaces; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON TABLE fac.spaces IS '시설물 내부 공간 계층(Tree) 관리 테이블';


--
-- Name: COLUMN spaces.id; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.id IS '공간 고유 ID (PK)';


--
-- Name: COLUMN spaces.facility_id; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.facility_id IS '소속 시설물 ID (FK)';


--
-- Name: COLUMN spaces.parent_id; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.parent_id IS '상위 공간 ID (Self Reference, NULL: 최상위 공간)';


--
-- Name: COLUMN spaces.representative_image_id; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.representative_image_id IS '공간 대표 이미지 ID (FK)';


--
-- Name: COLUMN spaces.space_type_id; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.space_type_id IS '공간 물리적 유형 ID (건물, 층 등)';


--
-- Name: COLUMN spaces.space_function_id; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.space_function_id IS '공간 기능적 용도 ID (전기실, 펌프실 등)';


--
-- Name: COLUMN spaces.code; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.code IS '공간 식별 코드 (시설 내 Unique, 대문자)';


--
-- Name: COLUMN spaces.name; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.name IS '공간 명칭';


--
-- Name: COLUMN spaces.area_size; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.area_size IS '면적 (단위: m2)';


--
-- Name: COLUMN spaces.is_active; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.is_active IS '사용 여부';


--
-- Name: COLUMN spaces.sort_order; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.sort_order IS '정렬 순서';


--
-- Name: COLUMN spaces.is_restricted; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.is_restricted IS '출입 제한/보안 구역 여부';


--
-- Name: COLUMN spaces.org_id; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.org_id IS '공간 관리 책임 부서 ID (USR 도메인 연계)';


--
-- Name: COLUMN spaces.metadata; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.metadata IS '공간 추가 속성 JSON';


--
-- Name: COLUMN spaces.legacy_id; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.legacy_id IS '[마이그레이션] 기존 시스템 ID';


--
-- Name: COLUMN spaces.legacy_source_tbl; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.legacy_source_tbl IS '[마이그레이션] 데이터 원천 테이블명';


--
-- Name: COLUMN spaces.created_at; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.created_at IS '생성 일시';


--
-- Name: COLUMN spaces.created_by; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.created_by IS '생성자 ID';


--
-- Name: COLUMN spaces.updated_at; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.updated_at IS '수정 일시';


--
-- Name: COLUMN spaces.updated_by; Type: COMMENT; Schema: fac; Owner: -
--

COMMENT ON COLUMN fac.spaces.updated_by IS '수정자 ID';


--
-- Name: spaces_id_seq; Type: SEQUENCE; Schema: fac; Owner: -
--

CREATE SEQUENCE fac.spaces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: spaces_id_seq; Type: SEQUENCE OWNED BY; Schema: fac; Owner: -
--

ALTER SEQUENCE fac.spaces_id_seq OWNED BY fac.spaces.id;


--
-- Name: roles; Type: TABLE; Schema: iam; Owner: -
--

CREATE TABLE iam.roles (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(50) NOT NULL,
    permissions jsonb DEFAULT '{}'::jsonb NOT NULL,
    description text,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint,
    CONSTRAINT chk_roles_code_upper CHECK (((code)::text = upper((code)::text))),
    CONSTRAINT chk_roles_permissions_obj CHECK ((jsonb_typeof(permissions) = 'object'::text))
);


--
-- Name: TABLE roles; Type: COMMENT; Schema: iam; Owner: -
--

COMMENT ON TABLE iam.roles IS '시스템 내 역할(Role) 및 권한(Permission) 정의 테이블';


--
-- Name: COLUMN roles.id; Type: COMMENT; Schema: iam; Owner: -
--

COMMENT ON COLUMN iam.roles.id IS '역할 고유 ID (PK)';


--
-- Name: COLUMN roles.name; Type: COMMENT; Schema: iam; Owner: -
--

COMMENT ON COLUMN iam.roles.name IS '역할 명칭 (예: 시스템 관리자, 일반 사용자)';


--
-- Name: COLUMN roles.code; Type: COMMENT; Schema: iam; Owner: -
--

COMMENT ON COLUMN iam.roles.code IS '역할 식별 코드 (Unique, 대문자 필수, 예: ADMIN)';


--
-- Name: COLUMN roles.permissions; Type: COMMENT; Schema: iam; Owner: -
--

COMMENT ON COLUMN iam.roles.permissions IS '권한 설정 JSONB (Key: 메뉴/리소스, Value: 행위 배열)';


--
-- Name: COLUMN roles.description; Type: COMMENT; Schema: iam; Owner: -
--

COMMENT ON COLUMN iam.roles.description IS '역할에 대한 상세 설명';


--
-- Name: COLUMN roles.is_system; Type: COMMENT; Schema: iam; Owner: -
--

COMMENT ON COLUMN iam.roles.is_system IS '시스템 기본 역할 여부 (True인 경우 삭제 불가)';


--
-- Name: COLUMN roles.created_at; Type: COMMENT; Schema: iam; Owner: -
--

COMMENT ON COLUMN iam.roles.created_at IS '생성 일시';


--
-- Name: COLUMN roles.created_by; Type: COMMENT; Schema: iam; Owner: -
--

COMMENT ON COLUMN iam.roles.created_by IS '생성자 ID';


--
-- Name: COLUMN roles.updated_at; Type: COMMENT; Schema: iam; Owner: -
--

COMMENT ON COLUMN iam.roles.updated_at IS '수정 일시';


--
-- Name: COLUMN roles.updated_by; Type: COMMENT; Schema: iam; Owner: -
--

COMMENT ON COLUMN iam.roles.updated_by IS '수정자 ID';


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: iam; Owner: -
--

CREATE SEQUENCE iam.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: iam; Owner: -
--

ALTER SEQUENCE iam.roles_id_seq OWNED BY iam.roles.id;


--
-- Name: user_roles; Type: TABLE; Schema: iam; Owner: -
--

CREATE TABLE iam.user_roles (
    user_id bigint NOT NULL,
    role_id bigint NOT NULL,
    assigned_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    assigned_by bigint
);


--
-- Name: TABLE user_roles; Type: COMMENT; Schema: iam; Owner: -
--

COMMENT ON TABLE iam.user_roles IS '사용자와 역할 간의 N:M 매핑 테이블';


--
-- Name: COLUMN user_roles.user_id; Type: COMMENT; Schema: iam; Owner: -
--

COMMENT ON COLUMN iam.user_roles.user_id IS '대상 사용자 ID (FK)';


--
-- Name: COLUMN user_roles.role_id; Type: COMMENT; Schema: iam; Owner: -
--

COMMENT ON COLUMN iam.user_roles.role_id IS '부여된 역할 ID (FK)';


--
-- Name: COLUMN user_roles.assigned_at; Type: COMMENT; Schema: iam; Owner: -
--

COMMENT ON COLUMN iam.user_roles.assigned_at IS '역할 부여 일시';


--
-- Name: COLUMN user_roles.assigned_by; Type: COMMENT; Schema: iam; Owner: -
--

COMMENT ON COLUMN iam.user_roles.assigned_by IS '역할을 부여한 관리자 ID';


--
-- Name: audit_logs; Type: TABLE; Schema: sys; Owner: -
--

CREATE TABLE sys.audit_logs (
    id bigint NOT NULL,
    actor_user_id bigint,
    action_type character varying(20) NOT NULL,
    target_domain character varying(3) NOT NULL,
    target_table character varying(50) NOT NULL,
    target_id character varying(50) NOT NULL,
    snapshot jsonb DEFAULT '{}'::jsonb NOT NULL,
    client_ip character varying(50),
    user_agent text,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE audit_logs; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON TABLE sys.audit_logs IS '시스템 감사 로그 및 주요 행위 추적 테이블';


--
-- Name: COLUMN audit_logs.id; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.audit_logs.id IS '로그 고유 ID (PK)';


--
-- Name: COLUMN audit_logs.actor_user_id; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.audit_logs.actor_user_id IS '행위를 수행한 사용자 ID (NULL이면 시스템)';


--
-- Name: COLUMN audit_logs.action_type; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.audit_logs.action_type IS '행위 유형 (C:생성, U:수정, D:삭제, L:로그인 등)';


--
-- Name: COLUMN audit_logs.target_domain; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.audit_logs.target_domain IS '대상 데이터의 도메인 코드';


--
-- Name: COLUMN audit_logs.target_table; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.audit_logs.target_table IS '대상 데이터의 테이블명';


--
-- Name: COLUMN audit_logs.target_id; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.audit_logs.target_id IS '대상 데이터의 식별자(PK)';


--
-- Name: COLUMN audit_logs.snapshot; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.audit_logs.snapshot IS '변경 데이터 스냅샷 (JSONB)';


--
-- Name: COLUMN audit_logs.client_ip; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.audit_logs.client_ip IS '요청 클라이언트 IP 주소';


--
-- Name: COLUMN audit_logs.user_agent; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.audit_logs.user_agent IS '요청 클라이언트 User-Agent 정보';


--
-- Name: COLUMN audit_logs.description; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.audit_logs.description IS '로그 내용 텍스트 설명';


--
-- Name: COLUMN audit_logs.created_at; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.audit_logs.created_at IS '로그 발생 일시';


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: sys; Owner: -
--

CREATE SEQUENCE sys.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: sys; Owner: -
--

ALTER SEQUENCE sys.audit_logs_id_seq OWNED BY sys.audit_logs.id;


--
-- Name: sequence_rules; Type: TABLE; Schema: sys; Owner: -
--

CREATE TABLE sys.sequence_rules (
    id bigint NOT NULL,
    domain_code character varying(3) NOT NULL,
    prefix character varying(10) NOT NULL,
    year_format character varying(4) DEFAULT 'YYYY'::character varying,
    separator character(1) DEFAULT '-'::bpchar,
    padding_length integer DEFAULT 4,
    current_year character varying(4) NOT NULL,
    current_seq bigint DEFAULT 0 NOT NULL,
    reset_type character varying(10) DEFAULT 'YEARLY'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint,
    CONSTRAINT chk_sequence_current_seq CHECK ((current_seq >= 0)),
    CONSTRAINT chk_sequence_padding CHECK (((padding_length >= 1) AND (padding_length <= 10)))
);


--
-- Name: TABLE sequence_rules; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON TABLE sys.sequence_rules IS '문서 번호 자동 채번 규칙 정의 테이블';


--
-- Name: COLUMN sequence_rules.id; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.sequence_rules.id IS '채번 규칙 고유 ID (PK)';


--
-- Name: COLUMN sequence_rules.domain_code; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.sequence_rules.domain_code IS '해당 규칙을 사용하는 도메인 코드';


--
-- Name: COLUMN sequence_rules.prefix; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.sequence_rules.prefix IS '문서 번호 접두어 (예: ORD)';


--
-- Name: COLUMN sequence_rules.year_format; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.sequence_rules.year_format IS '연도 표시 형식 (YYYY: 2024, YY: 24)';


--
-- Name: COLUMN sequence_rules.separator; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.sequence_rules.separator IS '접두어, 연도, 번호 사이의 구분자';


--
-- Name: COLUMN sequence_rules.padding_length; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.sequence_rules.padding_length IS '일련번호의 자릿수 (LPAD 처리)';


--
-- Name: COLUMN sequence_rules.current_year; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.sequence_rules.current_year IS '현재 채번이 진행 중인 연도';


--
-- Name: COLUMN sequence_rules.current_seq; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.sequence_rules.current_seq IS '마지막으로 발급된 일련번호';


--
-- Name: COLUMN sequence_rules.reset_type; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.sequence_rules.reset_type IS '일련번호 초기화 방식 (YEARLY: 매년 1로 초기화)';


--
-- Name: COLUMN sequence_rules.is_active; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.sequence_rules.is_active IS '규칙 사용 여부';


--
-- Name: COLUMN sequence_rules.created_at; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.sequence_rules.created_at IS '규칙 생성 일시';


--
-- Name: COLUMN sequence_rules.created_by; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.sequence_rules.created_by IS '규칙 생성자 ID';


--
-- Name: COLUMN sequence_rules.updated_at; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.sequence_rules.updated_at IS '규칙 수정 일시';


--
-- Name: COLUMN sequence_rules.updated_by; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.sequence_rules.updated_by IS '규칙 수정자 ID';


--
-- Name: sequence_rules_id_seq; Type: SEQUENCE; Schema: sys; Owner: -
--

CREATE SEQUENCE sys.sequence_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sequence_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: sys; Owner: -
--

ALTER SEQUENCE sys.sequence_rules_id_seq OWNED BY sys.sequence_rules.id;


--
-- Name: system_domains; Type: TABLE; Schema: sys; Owner: -
--

CREATE TABLE sys.system_domains (
    id bigint NOT NULL,
    domain_code character varying(3) NOT NULL,
    domain_name character varying(50) NOT NULL,
    schema_name character varying(50) NOT NULL,
    description text,
    sort_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint,
    CONSTRAINT chk_domain_code_format CHECK (((domain_code)::text ~ '^[A-Z]{3}$'::text))
);


--
-- Name: TABLE system_domains; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON TABLE sys.system_domains IS '시스템 내 업무 도메인(모듈) 정의 테이블';


--
-- Name: COLUMN system_domains.id; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.system_domains.id IS '도메인 테이블 고유 ID (PK)';


--
-- Name: COLUMN system_domains.domain_code; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.system_domains.domain_code IS '도메인 식별 코드 (Unique, 대문자 3자, 예: FAC)';


--
-- Name: COLUMN system_domains.domain_name; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.system_domains.domain_name IS '도메인 명칭 (한글, 예: 시설관리)';


--
-- Name: COLUMN system_domains.schema_name; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.system_domains.schema_name IS '데이터베이스 스키마 명칭 (예: facility)';


--
-- Name: COLUMN system_domains.description; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.system_domains.description IS '도메인에 대한 상세 설명';


--
-- Name: COLUMN system_domains.sort_order; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.system_domains.sort_order IS 'UI 메뉴 등에서의 정렬 순서';


--
-- Name: COLUMN system_domains.is_active; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.system_domains.is_active IS '도메인 사용 여부 (False 시 비활성화)';


--
-- Name: COLUMN system_domains.created_at; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.system_domains.created_at IS '데이터 생성 일시';


--
-- Name: COLUMN system_domains.created_by; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.system_domains.created_by IS '데이터 생성자 ID';


--
-- Name: COLUMN system_domains.updated_at; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.system_domains.updated_at IS '데이터 최종 수정 일시';


--
-- Name: COLUMN system_domains.updated_by; Type: COMMENT; Schema: sys; Owner: -
--

COMMENT ON COLUMN sys.system_domains.updated_by IS '데이터 최종 수정자 ID';


--
-- Name: system_domains_id_seq; Type: SEQUENCE; Schema: sys; Owner: -
--

CREATE SEQUENCE sys.system_domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_domains_id_seq; Type: SEQUENCE OWNED BY; Schema: sys; Owner: -
--

ALTER SEQUENCE sys.system_domains_id_seq OWNED BY sys.system_domains.id;


--
-- Name: organizations; Type: TABLE; Schema: usr; Owner: -
--

CREATE TABLE usr.organizations (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(50) NOT NULL,
    parent_id bigint,
    sort_order integer DEFAULT 0,
    description text,
    is_active boolean DEFAULT true,
    legacy_id integer,
    legacy_source character varying(20),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint,
    CONSTRAINT chk_organizations_code_upper CHECK (((code)::text = upper((code)::text))),
    CONSTRAINT chk_organizations_parent_recursive CHECK ((id <> parent_id))
);


--
-- Name: TABLE organizations; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON TABLE usr.organizations IS '조직(부서) 계층 정보 관리 테이블';


--
-- Name: COLUMN organizations.id; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.organizations.id IS '조직 고유 ID (PK)';


--
-- Name: COLUMN organizations.name; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.organizations.name IS '조직 및 부서 명칭';


--
-- Name: COLUMN organizations.code; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.organizations.code IS '조직 식별 코드 (Unique, 대문자 필수)';


--
-- Name: COLUMN organizations.parent_id; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.organizations.parent_id IS '상위 조직 ID (Self Reference, NULL: 최상위)';


--
-- Name: COLUMN organizations.sort_order; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.organizations.sort_order IS '동일 레벨 내 정렬 순서';


--
-- Name: COLUMN organizations.description; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.organizations.description IS '조직의 역할 및 기능 설명';


--
-- Name: COLUMN organizations.is_active; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.organizations.is_active IS '조직 활성화 여부 (False: 폐쇄/미사용)';


--
-- Name: COLUMN organizations.legacy_id; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.organizations.legacy_id IS '[마이그레이션] 기존 시스템의 조직 ID';


--
-- Name: COLUMN organizations.legacy_source; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.organizations.legacy_source IS '[마이그레이션] 데이터 원천 시스템명';


--
-- Name: COLUMN organizations.created_at; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.organizations.created_at IS '데이터 생성 일시';


--
-- Name: COLUMN organizations.created_by; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.organizations.created_by IS '데이터 생성자 ID (User FK)';


--
-- Name: COLUMN organizations.updated_at; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.organizations.updated_at IS '데이터 최종 수정 일시';


--
-- Name: COLUMN organizations.updated_by; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.organizations.updated_by IS '데이터 최종 수정자 ID (User FK)';


--
-- Name: organizations_id_seq; Type: SEQUENCE; Schema: usr; Owner: -
--

CREATE SEQUENCE usr.organizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: usr; Owner: -
--

ALTER SEQUENCE usr.organizations_id_seq OWNED BY usr.organizations.id;


--
-- Name: users; Type: TABLE; Schema: usr; Owner: -
--

CREATE TABLE usr.users (
    id bigint NOT NULL,
    org_id bigint,
    profile_image_id uuid,
    login_id character varying(50) NOT NULL,
    password_hash character varying(255) NOT NULL,
    emp_code character varying(16) NOT NULL,
    name character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    phone character varying(50),
    is_active boolean DEFAULT true,
    last_login_at timestamp with time zone,
    login_fail_count integer DEFAULT 0 NOT NULL,
    legacy_id integer,
    legacy_source character varying(20),
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint,
    account_status character varying(20) DEFAULT 'ACTIVE'::character varying,
    CONSTRAINT chk_users_email_format CHECK (((email)::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text)),
    CONSTRAINT chk_users_email_lower CHECK (((email)::text = lower((email)::text))),
    CONSTRAINT chk_users_emp_code_not_empty CHECK ((length(TRIM(BOTH FROM emp_code)) > 0)),
    CONSTRAINT chk_users_login_id_lower CHECK (((login_id)::text = lower((login_id)::text)))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON TABLE usr.users IS '시스템 사용자(임직원) 계정 정보 테이블';


--
-- Name: COLUMN users.id; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.id IS '사용자 고유 ID (PK)';


--
-- Name: COLUMN users.org_id; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.org_id IS '소속 조직 ID (FK)';


--
-- Name: COLUMN users.profile_image_id; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.profile_image_id IS '프로필 이미지 파일 ID (UUID FK)';


--
-- Name: COLUMN users.login_id; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.login_id IS '로그인 계정 ID (Unique, 소문자)';


--
-- Name: COLUMN users.password_hash; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.password_hash IS '단방향 암호화된 비밀번호';


--
-- Name: COLUMN users.emp_code; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.emp_code IS '사원 번호 (인사 시스템 매핑용)';


--
-- Name: COLUMN users.name; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.name IS '사용자 성명';


--
-- Name: COLUMN users.email; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.email IS '이메일 주소 (Unique, 소문자)';


--
-- Name: COLUMN users.phone; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.phone IS '전화번호 또는 휴대전화번호';


--
-- Name: COLUMN users.is_active; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.is_active IS '계정 사용 가능 여부 (False: 잠김/퇴사)';


--
-- Name: COLUMN users.last_login_at; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.last_login_at IS '최근 로그인 성공 일시';


--
-- Name: COLUMN users.login_fail_count; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.login_fail_count IS '로그인 실패 횟수';


--
-- Name: COLUMN users.legacy_id; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.legacy_id IS '[마이그레이션] 기존 시스템 사용자 ID';


--
-- Name: COLUMN users.legacy_source; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.legacy_source IS '[마이그레이션] 데이터 원천';


--
-- Name: COLUMN users.metadata; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.metadata IS '사용자 설정 및 확장 속성 (JSONB)';


--
-- Name: COLUMN users.created_at; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.created_at IS '계정 생성 일시';


--
-- Name: COLUMN users.created_by; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.created_by IS '계정 생성자 ID (관리자)';


--
-- Name: COLUMN users.updated_at; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.updated_at IS '계정 정보 수정 일시';


--
-- Name: COLUMN users.updated_by; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.updated_by IS '계정 정보 수정자 ID';


--
-- Name: COLUMN users.account_status; Type: COMMENT; Schema: usr; Owner: -
--

COMMENT ON COLUMN usr.users.account_status IS '계정 상태 (ACTIVE: 정상, BLOCKED: 차단)';


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: usr; Owner: -
--

CREATE SEQUENCE usr.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: usr; Owner: -
--

ALTER SEQUENCE usr.users_id_seq OWNED BY usr.users.id;


--
-- Name: code_details id; Type: DEFAULT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.code_details ALTER COLUMN id SET DEFAULT nextval('cmm.code_details_id_seq'::regclass);


--
-- Name: code_groups id; Type: DEFAULT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.code_groups ALTER COLUMN id SET DEFAULT nextval('cmm.code_groups_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.notifications ALTER COLUMN id SET DEFAULT nextval('cmm.notifications_id_seq'::regclass);


--
-- Name: facilities id; Type: DEFAULT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.facilities ALTER COLUMN id SET DEFAULT nextval('fac.facilities_id_seq'::regclass);


--
-- Name: facility_categories id; Type: DEFAULT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.facility_categories ALTER COLUMN id SET DEFAULT nextval('fac.facility_categories_id_seq'::regclass);


--
-- Name: space_functions id; Type: DEFAULT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.space_functions ALTER COLUMN id SET DEFAULT nextval('fac.space_functions_id_seq'::regclass);


--
-- Name: space_types id; Type: DEFAULT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.space_types ALTER COLUMN id SET DEFAULT nextval('fac.space_types_id_seq'::regclass);


--
-- Name: spaces id; Type: DEFAULT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.spaces ALTER COLUMN id SET DEFAULT nextval('fac.spaces_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: iam; Owner: -
--

ALTER TABLE ONLY iam.roles ALTER COLUMN id SET DEFAULT nextval('iam.roles_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: sys; Owner: -
--

ALTER TABLE ONLY sys.audit_logs ALTER COLUMN id SET DEFAULT nextval('sys.audit_logs_id_seq'::regclass);


--
-- Name: sequence_rules id; Type: DEFAULT; Schema: sys; Owner: -
--

ALTER TABLE ONLY sys.sequence_rules ALTER COLUMN id SET DEFAULT nextval('sys.sequence_rules_id_seq'::regclass);


--
-- Name: system_domains id; Type: DEFAULT; Schema: sys; Owner: -
--

ALTER TABLE ONLY sys.system_domains ALTER COLUMN id SET DEFAULT nextval('sys.system_domains_id_seq'::regclass);


--
-- Name: organizations id; Type: DEFAULT; Schema: usr; Owner: -
--

ALTER TABLE ONLY usr.organizations ALTER COLUMN id SET DEFAULT nextval('usr.organizations_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: usr; Owner: -
--

ALTER TABLE ONLY usr.users ALTER COLUMN id SET DEFAULT nextval('usr.users_id_seq'::regclass);


--
-- Data for Name: attachments; Type: TABLE DATA; Schema: cmm; Owner: -
--

COPY cmm.attachments (id, domain_code, resource_type, ref_id, category_code, file_name, file_path, file_size, content_type, org_id, props, legacy_id, legacy_source, is_deleted, created_at, created_by, updated_at, updated_by) FROM stdin;
41f293d4-bd53-488d-82b0-7d11ee60d715	USR	PROFILE	68	GENERAL	images.jpeg	USR/PROFILE/41f293d4bd53488d82b07d11ee60d715.jpeg	7325	image/jpeg	\N	{}	\N	\N	f	2026-03-10 22:59:37.385556+09	1	2026-03-10 22:59:37.385556+09	\N
7948c1ed-7063-4eb6-a4ad-4a17d07f2485	USR	PROFILE	68	GENERAL	images.jpeg	USR/PROFILE/7948c1ed70634eb6a4ad4a17d07f2485.jpeg	7325	image/jpeg	\N	{}	\N	\N	f	2026-03-10 23:00:30.756556+09	1	2026-03-10 23:00:30.756556+09	\N
13298b2f-fffb-441f-a8f4-4a9d36990df4	USR	PROFILE	68	GENERAL	images.jpeg	USR/PROFILE/13298b2ffffb441fa8f44a9d36990df4.jpeg	7325	image/jpeg	\N	{}	\N	\N	f	2026-03-10 23:00:47.702452+09	1	2026-03-10 23:00:47.702452+09	\N
c92f7284-7016-4b90-a68e-da621995d673	USR	PROFILE	68	GENERAL	images.jpeg	USR/PROFILE/c92f728470164b90a68eda621995d673.jpeg	7325	image/jpeg	\N	{}	\N	\N	f	2026-03-10 23:01:56.905154+09	1	2026-03-10 23:01:56.905154+09	\N
8952329a-706d-4158-a902-37230054413c	USR	PROFILE	68	GENERAL	images.jpeg	USR/PROFILE/8952329a706d4158a90237230054413c.jpeg	7325	image/jpeg	\N	{}	\N	\N	f	2026-03-10 23:13:25.963472+09	1	2026-03-10 23:13:25.963472+09	\N
1917b49a-e479-4d9c-bb9c-c1a80f4346ed	USR	PROFILE	68	GENERAL	images22.jpeg	USR/PROFILE/1917b49ae4794d9cbb9cc1a80f4346ed.jpeg	7020	image/jpeg	\N	{}	\N	\N	f	2026-03-10 23:13:33.065635+09	1	2026-03-10 23:13:33.065635+09	\N
cb3d2c12-f3d6-4958-9c5a-c66262a0ae7e	USR	PROFILE	68	GENERAL	images.jpeg	USR/PROFILE/cb3d2c12f3d649589c5ac66262a0ae7e.jpeg	7325	image/jpeg	\N	{}	\N	\N	f	2026-03-10 23:13:44.548347+09	1	2026-03-10 23:13:44.548347+09	\N
183b7901-4aa8-4246-925e-7fa6a9b977a9	USR	PROFILE	67	GENERAL	images33.jpeg	USR/PROFILE/183b79014aa84246925e7fa6a9b977a9.jpeg	15901	image/jpeg	\N	{}	\N	\N	f	2026-03-10 23:13:54.623472+09	1	2026-03-10 23:13:54.623472+09	\N
7ad1d8ae-9c57-4862-8658-8307c904a487	USR	PROFILE	68	GENERAL	images.jpeg	USR/PROFILE/7ad1d8ae9c57486286588307c904a487.jpeg	7325	image/jpeg	\N	{}	\N	\N	f	2026-03-10 23:14:20.742009+09	1	2026-03-10 23:14:20.742009+09	\N
c4a693ac-c986-4508-a9a7-251accb32104	USR	PROFILE	67	GENERAL	images22.jpeg	USR/PROFILE/c4a693acc9864508a9a7251accb32104.jpeg	7020	image/jpeg	\N	{}	\N	\N	f	2026-03-11 21:19:01.044774+09	1	2026-03-11 21:19:01.044774+09	\N
2dfecc7a-6c12-4aaf-9b55-cc15a027611b	USR	PROFILE	64	GENERAL	images33.jpeg	USR/PROFILE/2dfecc7a6c124aaf9b55cc15a027611b.jpeg	15901	image/jpeg	\N	{}	\N	\N	f	2026-03-11 21:20:28.361307+09	1	2026-03-11 21:20:28.361307+09	\N
4eec622d-1419-4fb9-95f9-c23737ca6e22	USR	PROFILE	1	GENERAL	images.jpeg	USR/PROFILE/4eec622d14194fb995f9c23737ca6e22.jpeg	7325	image/jpeg	0	{}	\N	\N	f	2026-03-11 22:35:21.765682+09	1	2026-03-11 22:35:21.765682+09	\N
28ed1c85-9018-4827-9ffd-d04f0cd3653b	USR	PROFILE	1	GENERAL	images.jpeg	USR/PROFILE/28ed1c85901848279ffdd04f0cd3653b.jpeg	7325	image/jpeg	0	{}	\N	\N	f	2026-03-11 23:37:30.835232+09	1	2026-03-11 23:37:30.835232+09	\N
9dc2dfcb-5084-4663-9ec4-35c67bdd34d0	USR	PROFILE	1	GENERAL	images.jpeg	USR/PROFILE/9dc2dfcb508446639ec435c67bdd34d0.jpeg	7325	image/jpeg	0	{}	\N	\N	f	2026-03-11 23:40:19.345805+09	1	2026-03-11 23:40:19.345805+09	\N
b5217547-8573-4c61-9de4-18c39cd3bb4b	USR	PROFILE	69	GENERAL	images33.jpeg	USR/PROFILE/b521754785734c619de418c39cd3bb4b.jpeg	15901	image/jpeg	0	{}	\N	\N	f	2026-03-11 23:42:01.116105+09	1	2026-03-11 23:42:01.116105+09	\N
27cc0694-6c2e-4b34-828b-519e4c475b5c	USR	PROFILE	1	GENERAL	images.jpeg	USR/PROFILE/27cc06946c2e4b34828b519e4c475b5c.jpeg	7325	image/jpeg	0	{}	\N	\N	f	2026-03-11 23:44:59.975344+09	1	2026-03-11 23:44:59.975344+09	\N
82b9fe60-401e-451f-a109-90341b3eae69	USR	PROFILE	69	GENERAL	images33.jpeg	USR/PROFILE/82b9fe60401e451fa10990341b3eae69.jpeg	15901	image/jpeg	0	{}	\N	\N	f	2026-03-11 23:46:59.009058+09	1	2026-03-11 23:46:59.009058+09	\N
2e6eda61-43d7-4a28-a203-06b554a29520	USR	PROFILE	69	GENERAL	images.jpeg	USR/PROFILE/2e6eda6143d74a28a20306b554a29520.jpeg	7325	image/jpeg	0	{}	\N	\N	f	2026-03-11 23:57:23.544753+09	1	2026-03-11 23:57:23.544753+09	\N
9c7df744-db92-475f-be3a-cdbb13f09ae3	USR	PROFILE	69	GENERAL	images33.jpeg	USR/PROFILE/9c7df744db92475fbe3acdbb13f09ae3.jpeg	15901	image/jpeg	0	{}	\N	\N	f	2026-03-11 23:57:37.785233+09	1	2026-03-11 23:57:37.785233+09	\N
6ab167d4-a8d5-4b3b-9f82-c88cfc6d4b64	USR	PROFILE	1	GENERAL	images.jpeg	USR/PROFILE/6ab167d4a8d54b3b9f82c88cfc6d4b64.jpeg	7325	image/jpeg	0	{}	\N	\N	f	2026-03-11 23:57:53.224953+09	1	2026-03-11 23:57:53.224953+09	\N
b1223073-ec23-43c9-a7c9-ea9f3c969f6c	USR	PROFILE	68	GENERAL	images22.jpeg	USR/PROFILE/b1223073ec2343c9a7c9ea9f3c969f6c.jpeg	7020	image/jpeg	0	{}	\N	\N	f	2026-03-11 23:58:08.061646+09	1	2026-03-11 23:58:08.061646+09	\N
\.


--
-- Data for Name: code_details; Type: TABLE DATA; Schema: cmm; Owner: -
--

COPY cmm.code_details (id, group_code, detail_code, detail_name, props, sort_order, is_active, created_at, created_by, updated_at, updated_by) FROM stdin;
1	SYS_USE_YN	Y	사용	{"color": "green"}	1	t	2026-03-08 19:48:02.20599+09	\N	2026-03-08 19:48:02.20599+09	\N
2	SYS_USE_YN	N	미사용	{"color": "red"}	2	t	2026-03-08 19:48:02.20599+09	\N	2026-03-08 19:48:02.20599+09	\N
3	FILE_CATEGORY	DWG	CAD 도면	{"ext": "dwg", "icon": "FileDoneOutlined"}	1	t	2026-03-08 19:48:02.20599+09	\N	2026-03-08 19:48:02.20599+09	\N
4	FILE_CATEGORY	DOC	일반 문서	{"ext": "pdf,docx", "icon": "FileTextOutlined"}	2	t	2026-03-08 19:48:02.20599+09	\N	2026-03-08 19:48:02.20599+09	\N
5	FILE_CATEGORY	IMG	현장 사진	{"ext": "jpg,png", "icon": "PictureOutlined"}	3	t	2026-03-08 19:48:02.20599+09	\N	2026-03-08 19:48:02.20599+09	\N
6	EQP_STATUS	RUN	가동 중	{"color": "#52c41a", "status": "processing"}	1	t	2026-03-08 19:48:02.20599+09	\N	2026-03-08 19:48:02.20599+09	\N
7	EQP_STATUS	STP	정지	{"color": "#bfbfbf", "status": "default"}	2	t	2026-03-08 19:48:02.20599+09	\N	2026-03-08 19:48:02.20599+09	\N
8	EQP_STATUS	ERR	장애	{"color": "#f5222d", "status": "error"}	3	t	2026-03-08 19:48:02.20599+09	\N	2026-03-08 19:48:02.20599+09	\N
48	USR_STATUS	ACTIVE	정상	{"color": "green"}	10	t	2026-03-10 22:34:54.459972+09	\N	2026-03-10 22:34:54.459972+09	\N
49	USR_STATUS	BLOCKED	차단	{"color": "red"}	20	t	2026-03-10 22:34:54.459972+09	\N	2026-03-10 22:34:54.459972+09	\N
30	FAC_CATEGORY	PKS	주차장	{}	0	t	2026-03-08 22:44:05.560286+09	1	2026-03-11 22:54:13.98743+09	1
31	FAC_CATEGORY	PAK	공원	{}	2	t	2026-03-08 22:44:15.223375+09	1	2026-03-11 22:54:24.141882+09	1
29	FAC_CATEGORY	STP	하수처리시설	{}	1	t	2026-03-08 22:43:22.640139+09	1	2026-03-11 22:54:27.887128+09	1
51	POS_TYPE	SENIOR	수석	{}	55	t	2026-03-11 22:59:09.156366+09	1	2026-03-11 22:59:09.156366+09	1
52	DUTY_TYPE	HEAD	부서장	{}	25	t	2026-03-11 22:59:33.061684+09	1	2026-03-11 22:59:33.061684+09	1
32	POS_TYPE	STAFF	사원	{}	10	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
33	POS_TYPE	ASSISTANT	대리	{}	20	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
34	POS_TYPE	MANAGER	과장	{}	30	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
35	POS_TYPE	DEPUTY	차장	{}	40	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
36	POS_TYPE	HEAD	부장	{}	50	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
37	POS_TYPE	DIRECTOR	이사	{}	60	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
38	POS_TYPE	MD	상무	{}	70	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
39	POS_TYPE	SMD	전무	{}	80	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
40	POS_TYPE	EVP	부사장	{}	90	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
41	POS_TYPE	CEO	사장	{}	100	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
42	DUTY_TYPE	MEMBER	팀원	{}	10	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
43	DUTY_TYPE	LEADER	팀장	{}	20	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
44	DUTY_TYPE	CHIEF	실장	{}	30	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
45	DUTY_TYPE	DIVISION_HEAD	본부장	{}	40	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
46	DUTY_TYPE	DIRECTOR_HEAD	부문장	{}	50	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
47	DUTY_TYPE	PRESIDENT	대표이사	{}	60	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
\.


--
-- Data for Name: code_groups; Type: TABLE DATA; Schema: cmm; Owner: -
--

COPY cmm.code_groups (id, group_code, domain_code, group_name, description, is_system, is_active, created_at, created_by, updated_at, updated_by) FROM stdin;
2	FILE_CATEGORY	\N	파일 분류	문서, 도면, 사진 등 파일 유형	t	t	2026-03-08 19:48:02.203688+09	\N	2026-03-08 19:48:02.203688+09	\N
3	EQP_STATUS	\N	설비 상태	설비의 현재 가동 상태	f	t	2026-03-08 19:48:02.203688+09	\N	2026-03-08 19:48:02.203688+09	\N
34	POS_TYPE	\N	직위/직급	사용자의 직위 및 직급 정보	t	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
35	DUTY_TYPE	\N	직책	사용자의 보직 및 직책 정보	t	t	2026-03-10 22:24:28.525309+09	\N	2026-03-10 22:24:28.525309+09	\N
36	USR_STATUS	\N	계정 상태	사용자 계정의 활성/차단 상태	t	t	2026-03-10 22:34:54.459972+09	\N	2026-03-10 22:34:54.459972+09	\N
32	FAC_CATEGORY	\N	설비 분류 코드	설비 분류 코드 그룹	f	t	2026-03-08 22:43:08.973869+09	1	2026-03-11 22:54:34.141978+09	1
1	SYS_USE_YN	\N	사용 여부	시스템 전반 활성화 상태 구분	t	t	2026-03-08 19:48:02.203688+09	\N	2026-03-08 22:13:13.171902+09	1
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: cmm; Owner: -
--

COPY cmm.notifications (id, domain_code, sender_user_id, receiver_user_id, category, priority, title, content, link_url, props, is_read, read_at, is_deleted, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: facilities; Type: TABLE DATA; Schema: fac; Owner: -
--

COPY fac.facilities (id, category_id, representative_image_id, code, name, address, is_active, sort_order, metadata, legacy_id, created_at, created_by, updated_at, updated_by) FROM stdin;
1	\N	\N	SITE_AD55	테스트 사업소	\N	t	1	{"type": "WATER"}	\N	2026-03-08 20:31:24.027797+09	1	2026-03-08 20:31:24.027797+09	1
2	\N	\N	SEC_C0B3	보안테스트	\N	t	0	{}	\N	2026-03-08 20:31:24.682397+09	1	2026-03-08 20:31:24.682397+09	1
3	\N	\N	SITE_6411	테스트 사업소	\N	t	1	{"type": "WATER"}	\N	2026-03-08 20:32:43.952596+09	1	2026-03-08 20:32:43.952596+09	1
4	\N	\N	SEC_7F4D	보안테스트	\N	t	0	{}	\N	2026-03-08 20:32:44.208234+09	1	2026-03-08 20:32:44.208234+09	1
5	\N	\N	SITE_DCF2	테스트 사업소	\N	t	1	{"type": "WATER"}	\N	2026-03-08 20:33:35.929019+09	1	2026-03-08 20:33:35.929019+09	1
6	\N	\N	SEC_6B1C	보안테스트	\N	t	0	{}	\N	2026-03-08 20:33:36.187943+09	1	2026-03-08 20:33:36.187943+09	1
7	\N	\N	FAC_ABD6	제1처리장_ABD6	\N	t	0	{"manager_org": 5}	\N	2026-03-08 20:33:37.147703+09	1	2026-03-08 20:33:37.147703+09	1
8	\N	\N	SITE_E8C3	테스트 사업소	\N	t	1	{"type": "WATER"}	\N	2026-03-08 20:36:24.322693+09	1	2026-03-08 20:36:24.322693+09	1
9	\N	\N	SEC_FEA6	보안테스트	\N	t	0	{}	\N	2026-03-08 20:36:24.583604+09	1	2026-03-08 20:36:24.583604+09	1
10	\N	\N	SITE_C0FC	테스트 사업소	\N	t	1	{"type": "WATER"}	\N	2026-03-08 20:37:18.286697+09	1	2026-03-08 20:37:18.286697+09	1
11	\N	\N	SEC_9E17	보안테스트	\N	t	0	{}	\N	2026-03-08 20:37:18.546394+09	1	2026-03-08 20:37:18.546394+09	1
12	\N	\N	SITE_96CB	테스트 사업소	\N	t	1	{"type": "WATER"}	\N	2026-03-08 20:37:50.773019+09	1	2026-03-08 20:37:50.773019+09	1
13	\N	\N	SEC_E430	보안테스트	\N	t	0	{}	\N	2026-03-08 20:37:51.025066+09	1	2026-03-08 20:37:51.025066+09	1
14	\N	\N	FAC_B3D9	제1처리장_B3D9	\N	t	0	{"manager_org": 48}	\N	2026-03-08 20:38:01.347673+09	1	2026-03-08 20:38:01.347673+09	1
15	\N	\N	SITE_4266	테스트 사업소	\N	t	1	{"type": "WATER"}	\N	2026-03-08 20:38:29.683112+09	1	2026-03-08 20:38:29.683112+09	1
16	\N	\N	SEC_37BC	보안테스트	\N	t	0	{}	\N	2026-03-08 20:38:29.945086+09	1	2026-03-08 20:38:29.945086+09	1
17	\N	\N	SITE_E969	테스트 사업소	\N	t	1	{"type": "WATER"}	\N	2026-03-08 20:39:12.948253+09	1	2026-03-08 20:39:12.948253+09	1
18	\N	\N	SEC_EC5E	보안테스트	\N	t	0	{}	\N	2026-03-08 20:39:13.205866+09	1	2026-03-08 20:39:13.205866+09	1
19	\N	\N	SITE_23D1	통합테스트사업소_23D1	\N	t	99	{}	\N	2026-03-08 20:39:14.165383+09	1	2026-03-08 20:39:14.165383+09	1
20	\N	\N	SITE_5FED	테스트 사업소	\N	t	1	{"type": "WATER"}	\N	2026-03-08 20:39:41.73265+09	1	2026-03-08 20:39:41.73265+09	1
21	\N	\N	SEC_843D	보안테스트	\N	t	0	{}	\N	2026-03-08 20:39:41.982069+09	1	2026-03-08 20:39:41.982069+09	1
22	\N	\N	SITE_C158	통합테스트사업소_C158	\N	t	99	{}	\N	2026-03-08 20:39:52.41367+09	1	2026-03-08 20:39:52.41367+09	1
23	\N	\N	SITE_CB8C	테스트 사업소	\N	t	1	{"type": "WATER"}	\N	2026-03-08 20:40:21.463134+09	1	2026-03-08 20:40:21.463134+09	1
24	\N	\N	SEC_07C0	보안테스트	\N	t	0	{}	\N	2026-03-08 20:40:21.719244+09	1	2026-03-08 20:40:21.719244+09	1
25	\N	\N	SITE_5A60	통합테스트사업소_5A60	\N	t	99	{}	\N	2026-03-08 20:40:32.375846+09	1	2026-03-08 20:40:32.375846+09	1
26	\N	\N	SITE_E6AE	테스트 사업소	\N	t	1	{"type": "WATER"}	\N	2026-03-08 20:40:58.155068+09	1	2026-03-08 20:40:58.155068+09	1
27	\N	\N	SEC_A39E	보안테스트	\N	t	0	{}	\N	2026-03-08 20:40:58.424815+09	1	2026-03-08 20:40:58.424815+09	1
28	\N	\N	SITE_ECAC	테스트 사업소	\N	t	1	{"type": "WATER"}	\N	2026-03-08 20:41:23.212756+09	1	2026-03-08 20:41:23.212756+09	1
29	\N	\N	SEC_AD0D	보안테스트	\N	t	0	{}	\N	2026-03-08 20:41:23.478261+09	1	2026-03-08 20:41:23.478261+09	1
30	\N	\N	SITE_C136	통합테스트사업소_C136	\N	t	99	{}	\N	2026-03-08 20:41:55.949602+09	1	2026-03-08 20:41:55.949602+09	1
31	\N	\N	SITE_AF1C	테스트 사업소	\N	t	1	{"type": "WATER"}	\N	2026-03-08 20:42:23.3959+09	1	2026-03-08 20:42:23.3959+09	1
32	\N	\N	SEC_2631	보안테스트	\N	t	0	{}	\N	2026-03-08 20:42:23.667106+09	1	2026-03-08 20:42:23.667106+09	1
33	\N	\N	SITE_89BF	테스트 사업소	\N	t	1	{"type": "WATER"}	\N	2026-03-08 20:42:54.1472+09	1	2026-03-08 20:42:54.1472+09	1
34	\N	\N	SEC_0927	보안테스트	\N	t	0	{}	\N	2026-03-08 20:42:54.430619+09	1	2026-03-08 20:42:54.430619+09	1
35	\N	\N	SITE_BD02	통합테스트사업소_BD02	\N	t	99	{}	\N	2026-03-08 20:42:55.268549+09	1	2026-03-08 20:42:55.268549+09	1
36	\N	\N	SITE_283F	테스트 사업소	\N	t	1	{"type": "WATER"}	\N	2026-03-08 20:43:29.498784+09	1	2026-03-08 20:43:29.498784+09	1
37	\N	\N	SEC_AF98	보안테스트	\N	t	0	{}	\N	2026-03-08 20:43:29.775063+09	1	2026-03-08 20:43:29.775063+09	1
38	\N	\N	SITE_CB67	통합테스트사업소_CB67	\N	t	99	{}	\N	2026-03-08 20:43:31.204873+09	1	2026-03-08 20:43:31.204873+09	1
39	\N	\N	SITE_FB22	테스트 사업소	\N	t	1	{"type": "WATER"}	\N	2026-03-08 20:46:55.993827+09	1	2026-03-08 20:46:55.993827+09	1
40	\N	\N	SEC_AF6F	보안테스트	\N	t	0	{}	\N	2026-03-08 20:46:56.280496+09	1	2026-03-08 20:46:56.280496+09	1
41	\N	\N	SITE_48BF	통합테스트사업소_48BF	\N	t	99	{}	\N	2026-03-08 20:46:57.656002+09	1	2026-03-08 20:46:57.656002+09	1
\.


--
-- Data for Name: facility_categories; Type: TABLE DATA; Schema: fac; Owner: -
--

COPY fac.facility_categories (id, code, name, description, is_active, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- Data for Name: space_functions; Type: TABLE DATA; Schema: fac; Owner: -
--

COPY fac.space_functions (id, code, name, is_active, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- Data for Name: space_types; Type: TABLE DATA; Schema: fac; Owner: -
--

COPY fac.space_types (id, code, name, is_active, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- Data for Name: spaces; Type: TABLE DATA; Schema: fac; Owner: -
--

COPY fac.spaces (id, facility_id, parent_id, representative_image_id, space_type_id, space_function_id, code, name, area_size, is_active, sort_order, is_restricted, org_id, metadata, legacy_id, legacy_source_tbl, created_at, created_by, updated_at, updated_by) FROM stdin;
1	1	\N	\N	\N	\N	BLDG_01	본관	\N	t	1	f	\N	{}	\N	\N	2026-03-08 20:31:24.049342+09	1	2026-03-08 20:31:24.049342+09	1
4	3	\N	\N	\N	\N	BLDG_01	본관	\N	t	1	f	\N	{}	\N	\N	2026-03-08 20:32:43.966317+09	1	2026-03-08 20:32:43.966317+09	1
7	5	\N	\N	\N	\N	BLDG_01	본관	\N	t	1	f	\N	{}	\N	\N	2026-03-08 20:33:35.944695+09	1	2026-03-08 20:33:35.944695+09	1
11	8	\N	\N	\N	\N	BLDG_01	본관	\N	t	1	f	\N	{}	\N	\N	2026-03-08 20:36:24.336534+09	1	2026-03-08 20:36:24.336534+09	1
14	10	\N	\N	\N	\N	BLDG_01	본관	\N	t	1	f	\N	{}	\N	\N	2026-03-08 20:37:18.303243+09	1	2026-03-08 20:37:18.303243+09	1
17	12	\N	\N	\N	\N	BLDG_01	본관	\N	t	1	f	\N	{}	\N	\N	2026-03-08 20:37:50.78543+09	1	2026-03-08 20:37:50.78543+09	1
21	15	\N	\N	\N	\N	BLDG_01	본관	\N	t	1	f	\N	{}	\N	\N	2026-03-08 20:38:29.698852+09	1	2026-03-08 20:38:29.698852+09	1
24	17	\N	\N	\N	\N	BLDG_01	본관	\N	t	1	f	\N	{}	\N	\N	2026-03-08 20:39:12.961023+09	1	2026-03-08 20:39:12.961023+09	1
28	20	\N	\N	\N	\N	BLDG_01	본관	\N	t	1	f	\N	{}	\N	\N	2026-03-08 20:39:41.745488+09	1	2026-03-08 20:39:41.745488+09	1
32	23	\N	\N	\N	\N	BLDG_01	본관	\N	t	1	f	\N	{}	\N	\N	2026-03-08 20:40:21.476652+09	1	2026-03-08 20:40:21.476652+09	1
36	26	\N	\N	\N	\N	BLDG_01	본관	\N	t	1	f	\N	{}	\N	\N	2026-03-08 20:40:58.168832+09	1	2026-03-08 20:40:58.168832+09	1
39	28	\N	\N	\N	\N	BLDG_01	본관	\N	t	1	f	\N	{}	\N	\N	2026-03-08 20:41:23.226733+09	1	2026-03-08 20:41:23.226733+09	1
43	31	\N	\N	\N	\N	BLDG_01	본관	\N	t	1	f	\N	{}	\N	\N	2026-03-08 20:42:23.411392+09	1	2026-03-08 20:42:23.411392+09	1
46	33	\N	\N	\N	\N	BLDG_01	본관	\N	t	1	f	\N	{}	\N	\N	2026-03-08 20:42:54.16295+09	1	2026-03-08 20:42:54.16295+09	1
50	36	\N	\N	\N	\N	BLDG_01	본관	\N	t	1	f	\N	{}	\N	\N	2026-03-08 20:43:29.515045+09	1	2026-03-08 20:43:29.515045+09	1
54	39	\N	\N	\N	\N	BLDG_01	본관	\N	t	1	f	\N	{}	\N	\N	2026-03-08 20:46:56.012529+09	1	2026-03-08 20:46:56.012529+09	1
57	41	\N	\N	\N	\N	ROOM_48BF	제어실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:46:57.664282+09	1	2026-03-09 20:52:52.896892+09	1
56	40	\N	\N	\N	\N	OUR_01	이름변경성공	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:46:56.288485+09	1	2026-03-09 20:52:57.706191+09	1
55	39	54	\N	\N	\N	ROOM_101	운영실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:46:56.032943+09	1	2026-03-09 20:54:09.595395+09	1
53	38	\N	\N	\N	\N	ROOM_CB67	제어실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:43:31.213194+09	1	2026-03-09 20:54:13.437184+09	1
52	37	\N	\N	\N	\N	OUR_01	이름변경성공	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:43:29.783901+09	1	2026-03-09 20:54:16.781721+09	1
51	36	50	\N	\N	\N	ROOM_101	운영실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:43:29.533273+09	1	2026-03-09 20:54:20.027617+09	1
30	21	\N	\N	\N	\N	OUR_01	이름변경성공	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:39:41.990519+09	1	2026-03-09 20:54:31.056511+09	1
29	20	28	\N	\N	\N	ROOM_101	운영실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:39:41.763292+09	1	2026-03-09 20:55:17.825302+09	1
49	35	\N	\N	\N	\N	ROOM_BD02	제어실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:42:55.276905+09	1	2026-03-09 20:55:20.654578+09	1
48	34	\N	\N	\N	\N	OUR_01	이름변경성공	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:42:54.440319+09	1	2026-03-09 20:55:28.439731+09	1
47	33	46	\N	\N	\N	ROOM_101	운영실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:42:54.182591+09	1	2026-03-09 20:55:32.194663+09	1
27	19	\N	\N	\N	\N	ROOM_23D1	제어실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:39:14.173179+09	1	2026-03-09 20:55:34.996905+09	1
26	18	\N	\N	\N	\N	OUR_01	이름변경성공	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:39:13.213986+09	1	2026-03-09 20:55:46.697885+09	1
25	17	24	\N	\N	\N	ROOM_101	운영실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:39:12.977935+09	1	2026-03-09 20:55:50.119629+09	1
45	32	\N	\N	\N	\N	OUR_01	이름변경성공	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:42:23.675503+09	1	2026-03-09 20:55:52.913003+09	1
44	31	43	\N	\N	\N	ROOM_101	운영실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:42:23.430546+09	1	2026-03-09 20:56:01.794279+09	1
23	16	\N	\N	\N	\N	OUR_01	이름변경성공	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:38:29.955862+09	1	2026-03-09 20:56:25.351103+09	1
22	15	21	\N	\N	\N	ROOM_101	운영실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:38:29.716521+09	1	2026-03-09 20:56:30.367511+09	1
20	14	\N	\N	\N	\N	ELEC_01	전기실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:38:01.363119+09	1	2026-03-09 20:56:33.380544+09	1
42	30	\N	\N	\N	\N	ROOM_C136	제어실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:41:55.964266+09	1	2026-03-09 20:56:36.346534+09	1
19	13	\N	\N	\N	\N	OUR_01	이름변경성공	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:37:51.032855+09	1	2026-03-09 20:57:15.201382+09	1
18	12	17	\N	\N	\N	ROOM_101	운영실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:37:50.801351+09	1	2026-03-09 20:57:17.689415+09	1
41	29	\N	\N	\N	\N	OUR_01	이름변경성공	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:41:23.486289+09	1	2026-03-09 20:57:20.122341+09	1
40	28	39	\N	\N	\N	ROOM_101	운영실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:41:23.243593+09	1	2026-03-09 20:57:23.001925+09	1
16	11	\N	\N	\N	\N	OUR_01	이름변경성공	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:37:18.55392+09	1	2026-03-09 20:57:25.541136+09	1
15	10	14	\N	\N	\N	ROOM_101	운영실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:37:18.321231+09	1	2026-03-09 20:57:28.860295+09	1
38	27	\N	\N	\N	\N	OUR_01	이름변경성공	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:40:58.432611+09	1	2026-03-09 20:57:59.928037+09	1
37	26	36	\N	\N	\N	ROOM_101	운영실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:40:58.187096+09	1	2026-03-09 20:58:04.408961+09	1
35	25	\N	\N	\N	\N	ROOM_5A60	제어실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:40:32.396402+09	1	2026-03-09 20:58:07.115763+09	1
13	9	\N	\N	\N	\N	OUR_01	이름변경성공	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:36:24.592743+09	1	2026-03-09 20:58:09.61092+09	1
12	8	11	\N	\N	\N	ROOM_101	운영실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:36:24.352071+09	1	2026-03-09 20:58:13.849089+09	1
34	24	\N	\N	\N	\N	OUR_01	이름변경성공	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:40:21.728739+09	1	2026-03-09 20:59:00.064337+09	1
33	23	32	\N	\N	\N	ROOM_101	운영실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:40:21.49379+09	1	2026-03-09 20:59:04.009694+09	1
31	22	\N	\N	\N	\N	ROOM_C158	제어실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:39:52.454802+09	1	2026-03-09 20:59:06.482023+09	1
10	7	\N	\N	\N	\N	ELEC_01	전기실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:33:37.156791+09	1	2026-03-09 20:59:16.500552+09	1
9	6	\N	\N	\N	\N	OUR_01	이름변경성공	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:33:36.195159+09	1	2026-03-09 21:00:02.463278+09	1
8	5	7	\N	\N	\N	ROOM_101	운영실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:33:35.962162+09	1	2026-03-09 21:00:05.643694+09	1
6	4	\N	\N	\N	\N	OUR_01	이름변경성공	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:32:44.218533+09	1	2026-03-09 21:00:08.516376+09	1
5	3	4	\N	\N	\N	ROOM_101	운영실	\N	t	0	f	\N	{}	\N	\N	2026-03-08 20:32:43.985272+09	1	2026-03-09 21:00:10.965188+09	1
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: iam; Owner: -
--

COPY iam.roles (id, name, code, permissions, description, is_system, created_at, created_by, updated_at, updated_by) FROM stdin;
1	슈퍼 관리자	SUPER_ADMIN	{"all": ["*"]}	\N	t	2026-03-08 19:48:01.891748+09	\N	2026-03-08 19:48:01.891748+09	\N
2	일반 사용자	USER	{"dashboard": ["read"]}	\N	t	2026-03-08 19:48:01.891748+09	\N	2026-03-08 19:48:01.891748+09	\N
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: iam; Owner: -
--

COPY iam.user_roles (user_id, role_id, assigned_at, assigned_by) FROM stdin;
1	1	2026-03-08 20:46:56.837884+09	1
63	2	2026-03-11 22:39:36.127685+09	1
67	2	2026-03-11 23:08:36.305687+09	1
0	2	2026-03-11 23:11:46.708095+09	1
69	2	2026-03-11 23:19:15.501029+09	1
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: sys; Owner: -
--

COPY sys.audit_logs (id, actor_user_id, action_type, target_domain, target_table, target_id, snapshot, client_ip, user_agent, description, created_at) FROM stdin;
1	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 20:08:47.482472+09
2	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 20:09:31.052192+09
3	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 20:13:33.656498+09
4	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:27:51.593719+09
5	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 관리자에게 권한 그룹 [1] 할당	2026-03-08 20:27:51.930867+09
6	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:27:52.018531+09
7	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:31:22.741387+09
8	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:31:22.992675+09
9	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:31:23.19684+09
10	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:31:23.435018+09
11	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:31:23.62599+09
12	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:31:23.831212+09
13	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:31:24.495098+09
14	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:31:25.180458+09
15	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:31:25.423888+09
16	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 관리자에게 권한 그룹 [1] 할당	2026-03-08 20:31:25.621388+09
17	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:31:25.637691+09
18	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:32:42.649639+09
19	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:32:42.90434+09
20	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:32:43.103323+09
21	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:32:43.347792+09
22	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:32:43.548891+09
23	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:32:43.752343+09
24	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:32:44.010622+09
25	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:32:44.348081+09
26	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:32:44.581087+09
27	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 관리자에게 권한 그룹 [1] 할당	2026-03-08 20:32:44.775707+09
28	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:32:44.789013+09
29	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:34.609215+09
30	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:34.868109+09
31	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:35.069638+09
32	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:35.30609+09
33	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:35.520304+09
34	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:35.724681+09
35	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:35.988603+09
36	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:36.30371+09
37	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:36.53604+09
38	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 관리자에게 권한 그룹 [1] 할당	2026-03-08 20:33:36.730712+09
39	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:36.743439+09
40	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:36.94477+09
41	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:37.189961+09
42	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:37.41688+09
43	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:37.621464+09
44	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:37.861008+09
45	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:38.140394+09
46	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:38.383368+09
47	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:33:38.794195+09
49	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:23.000583+09
50	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:23.253258+09
51	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:23.464361+09
52	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:23.707625+09
53	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:23.913641+09
54	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:24.121043+09
55	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:24.379592+09
56	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:24.721395+09
57	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:24.956621+09
58	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 수정된이름에게 권한 그룹 [1] 할당	2026-03-08 20:36:25.158154+09
59	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:25.172379+09
60	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:25.365869+09
61	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:25.559619+09
62	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:25.753886+09
63	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:25.947135+09
64	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:26.189828+09
65	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:26.475707+09
66	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:26.701805+09
67	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:36:27.104217+09
69	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:16.903815+09
70	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:17.174653+09
71	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:17.376714+09
72	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:17.631167+09
73	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:17.870746+09
74	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:18.080045+09
75	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:18.347981+09
76	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:18.661321+09
77	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:18.897697+09
78	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 수정된이름에게 권한 그룹 [1] 할당	2026-03-08 20:37:19.099125+09
79	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:19.115429+09
80	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:19.316518+09
81	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:19.554416+09
82	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:19.749786+09
83	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:19.948695+09
84	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:20.198122+09
85	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:20.489656+09
86	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:20.71757+09
87	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:21.120496+09
89	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:49.391626+09
90	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:49.653188+09
91	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:49.856451+09
92	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:50.111452+09
93	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:50.361487+09
94	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:50.569367+09
95	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:50.825988+09
96	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:51.154316+09
97	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:51.400141+09
98	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 수정된이름에게 권한 그룹 [1] 할당	2026-03-08 20:37:51.600038+09
99	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:51.614195+09
100	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:51.811498+09
101	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:52.04628+09
102	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:52.288072+09
103	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:52.494824+09
104	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:52.754596+09
105	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:53.030213+09
106	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:53.260369+09
107	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:37:53.666832+09
109	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:01.075525+09
110	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:28.312018+09
111	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:28.568062+09
112	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:28.774958+09
113	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:29.017802+09
114	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:29.263647+09
115	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:29.474715+09
116	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:29.743076+09
117	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:30.072417+09
118	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:30.318104+09
119	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 수정된이름에게 권한 그룹 [1] 할당	2026-03-08 20:38:30.516008+09
120	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:30.529802+09
121	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:30.730644+09
122	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:30.972611+09
123	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:31.220956+09
124	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:31.429346+09
125	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:31.671619+09
126	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:31.969457+09
127	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:32.208678+09
128	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:38:32.624681+09
130	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:11.591652+09
131	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:11.846566+09
132	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:12.045443+09
133	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:12.297165+09
134	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:12.538749+09
135	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:12.74606+09
136	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:13.00485+09
137	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:13.319123+09
138	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:13.564153+09
139	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 수정된이름에게 권한 그룹 [1] 할당	2026-03-08 20:39:13.758832+09
140	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:13.771851+09
141	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:13.971827+09
142	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:14.240579+09
143	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:14.467866+09
144	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:14.67834+09
145	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:14.923137+09
146	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:15.203353+09
147	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:15.427555+09
148	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:15.834454+09
150	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:40.360352+09
151	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:40.628813+09
152	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:40.838602+09
153	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:41.084171+09
154	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:41.325656+09
155	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:41.533252+09
156	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:41.78747+09
157	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:42.099842+09
158	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:42.333078+09
159	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 수정된이름에게 권한 그룹 [1] 할당	2026-03-08 20:39:42.529888+09
160	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:42.544753+09
161	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:42.743865+09
162	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:42.979543+09
163	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:43.218078+09
164	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:43.425002+09
165	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:43.671559+09
166	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:43.965483+09
167	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:44.210927+09
168	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:44.619736+09
170	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:39:52.124007+09
171	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:20.117162+09
172	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:20.36884+09
173	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:20.568522+09
174	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:20.81012+09
175	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:21.051414+09
176	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:21.262414+09
177	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:21.517782+09
178	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:21.828236+09
179	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:22.068327+09
180	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 수정된이름에게 권한 그룹 [1] 할당	2026-03-08 20:40:22.273479+09
181	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:22.287988+09
182	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:22.486427+09
183	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:22.719575+09
184	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:22.910514+09
185	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:23.120187+09
186	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:23.373785+09
187	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:23.664596+09
188	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:23.915701+09
189	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:24.328232+09
191	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:32.098231+09
192	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:56.737566+09
193	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:56.987733+09
194	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:57.200279+09
195	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:57.457973+09
196	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:57.716157+09
197	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:57.933681+09
198	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:58.211997+09
199	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:58.536107+09
200	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:58.779963+09
201	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 수정된이름에게 권한 그룹 [1] 할당	2026-03-08 20:40:58.992678+09
202	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:59.008792+09
203	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:59.215707+09
204	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:59.45046+09
205	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:59.656081+09
206	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:40:59.865014+09
207	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:00.125629+09
208	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:00.434257+09
209	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:00.678002+09
210	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:01.103479+09
212	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:21.788707+09
213	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:22.047909+09
214	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:22.260568+09
215	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:22.519073+09
216	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:22.777025+09
217	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:23.001729+09
218	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:23.268978+09
219	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:23.594915+09
220	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:23.843843+09
221	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 수정된이름에게 권한 그룹 [1] 할당	2026-03-08 20:41:24.054584+09
222	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:24.071898+09
223	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:24.285183+09
224	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:24.513643+09
225	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:24.720403+09
226	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:24.93042+09
227	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:25.190982+09
228	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:25.488983+09
229	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:25.725716+09
230	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:26.157062+09
232	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:41:55.684772+09
233	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:21.965168+09
234	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:22.218846+09
235	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:22.436797+09
236	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:22.696312+09
237	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:22.959232+09
238	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:23.182837+09
239	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:23.456422+09
240	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:23.775534+09
241	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:24.022768+09
242	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 수정된이름에게 권한 그룹 [1] 할당	2026-03-08 20:42:24.234906+09
243	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:24.250406+09
244	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:24.465321+09
245	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:24.713177+09
246	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:24.924391+09
247	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:25.142331+09
248	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:25.405774+09
249	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:25.70923+09
250	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:25.951199+09
251	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:26.39843+09
253	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:52.706512+09
254	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:52.953998+09
255	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:53.178745+09
256	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:53.440224+09
257	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:53.695274+09
258	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:53.914246+09
259	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:54.212525+09
260	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:54.540959+09
261	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:54.786381+09
262	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 수정된이름에게 권한 그룹 [1] 할당	2026-03-08 20:42:55.003629+09
263	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:55.065624+09
264	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:55.318702+09
265	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:55.574734+09
266	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:55.794991+09
267	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:56.047788+09
268	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:56.360888+09
269	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:56.608059+09
270	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:42:57.023571+09
272	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:28.017714+09
273	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:28.28263+09
274	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:28.513389+09
275	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:28.782068+09
276	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:29.053984+09
277	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:29.276549+09
278	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:29.559828+09
279	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:29.879013+09
280	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:30.132437+09
281	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 수정된이름에게 권한 그룹 [1] 할당	2026-03-08 20:43:30.382227+09
282	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:30.399821+09
283	14	LOGIN	IAM	users	14	{}	127.0.0.1	python-httpx/0.28.1	사용자 'tmp_731dca' 로그인 성공	2026-03-08 20:43:30.799168+09
284	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:30.998746+09
285	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:31.25858+09
286	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:31.50555+09
287	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:31.727542+09
288	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:31.990596+09
289	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:32.310391+09
290	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:32.55838+09
291	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:43:32.977309+09
293	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:54.560167+09
294	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:54.824783+09
295	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:55.040997+09
296	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:55.300075+09
297	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:55.550466+09
298	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:55.768232+09
299	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:56.064491+09
300	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:56.387449+09
301	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:56.630577+09
302	1	GRANT_ROLE	IAM	user_roles	1	{"assigned_role_ids": [1]}	127.0.0.1	python-httpx/0.28.1	사용자 수정된이름에게 권한 그룹 [1] 할당	2026-03-08 20:46:56.837884+09
303	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:56.852385+09
304	16	LOGIN	IAM	users	16	{}	127.0.0.1	python-httpx/0.28.1	사용자 'tmp_bf9747' 로그인 성공	2026-03-08 20:46:57.257431+09
305	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:57.452449+09
306	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:57.711813+09
307	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:57.933379+09
308	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:58.149887+09
309	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:58.407643+09
310	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:58.698864+09
311	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:58.941882+09
312	1	LOGIN	IAM	users	1	{}	127.0.0.1	python-httpx/0.28.1	사용자 'admin' 로그인 성공	2026-03-08 20:46:59.352399+09
314	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:15:08.661188+09
315	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:15:12.085996+09
316	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:15:12.351815+09
317	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:15:12.60421+09
318	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:15:12.850796+09
319	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:15:25.164703+09
320	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:15:25.687918+09
321	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:15:26.118644+09
322	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:15:26.511096+09
323	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:16:43.4298+09
324	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:16:45.556013+09
325	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:16:46.665968+09
326	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:16:47.839529+09
327	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:16:48.119362+09
328	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:16:48.798438+09
329	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:16:49.216458+09
330	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:16:49.590736+09
331	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:16:49.942052+09
332	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:16:50.29523+09
333	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:17:47.364206+09
334	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:17:51.158368+09
335	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:18:45.274279+09
336	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:19:28.671015+09
337	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:20:27.516012+09
338	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:23:51.905709+09
339	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:26:44.8425+09
340	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:50:41.430474+09
341	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 21:55:11.599484+09
342	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 22:25:55.156902+09
343	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 22:29:35.497189+09
344	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-08 23:00:15.801316+09
345	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-09 20:48:04.825572+09
346	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-09 21:20:02.256775+09
347	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-09 21:50:43.964488+09
348	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-09 22:22:25.164861+09
349	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-09 22:54:22.98843+09
350	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-10 19:47:17.880929+09
351	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-10 20:17:42.340413+09
352	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-10 20:49:17.45275+09
353	1	ORG_CHANGE	USR	users	62	{"new_org_id": 172, "old_org_id": 169}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 윤도윤의 부서 변경	2026-03-10 21:04:08.736695+09
354	1	ORG_CHANGE	USR	users	63	{"new_org_id": 169, "old_org_id": 172}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 정도윤의 부서 변경	2026-03-10 21:04:31.463352+09
355	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-10 21:20:44.186595+09
356	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-10 21:33:50.68608+09
357	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-10 21:51:48.269334+09
358	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	사용자 'admin' 로그인 성공	2026-03-10 22:00:08.670245+09
359	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-10 22:04:44.107049+09
360	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-10 22:36:52.941504+09
361	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-10 23:13:11.907044+09
362	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-10 23:19:16.134991+09
363	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 20:40:22.468022+09
364	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 20:40:27.715135+09
365	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 20:41:44.875396+09
368	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 20:42:14.019835+09
370	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 20:44:09.373139+09
373	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 20:49:06.644107+09
374	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 20:50:31.824392+09
366	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 20:41:56.37022+09
367	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 20:42:04.835611+09
369	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 20:44:04.394357+09
371	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 20:47:20.28907+09
372	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 20:47:35.22258+09
375	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 21:25:05.610753+09
376	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 21:57:32.259489+09
377	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 22:27:39.624872+09
378	1	ORG_CHANGE	USR	users	1	{"new_org_id": 0, "old_org_id": null}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 시스템관리자의 부서 변경	2026-03-11 22:32:40.373161+09
379	1	GRANT_ROLE	IAM	user_roles	63	{"assigned_role_ids": [2]}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 정도윤에게 권한 그룹 [2] 할당	2026-03-11 22:37:07.16836+09
380	1	GRANT_ROLE	IAM	user_roles	63	{"assigned_role_ids": [2]}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 정도윤에게 권한 그룹 [2] 할당	2026-03-11 22:39:19.523158+09
381	1	GRANT_ROLE	IAM	user_roles	63	{"assigned_role_ids": [2]}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 정도윤에게 권한 그룹 [2] 할당	2026-03-11 22:39:36.127685+09
382	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 22:57:45.033863+09
383	1	GRANT_ROLE	IAM	user_roles	67	{"assigned_role_ids": [2]}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 조수아에게 권한 그룹 [2] 할당	2026-03-11 23:08:36.305687+09
384	1	GRANT_ROLE	IAM	user_roles	0	{"assigned_role_ids": [2]}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 시스템에게 권한 그룹 [2] 할당	2026-03-11 23:11:46.708095+09
385	1	GRANT_ROLE	IAM	user_roles	69	{"assigned_role_ids": [2]}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 부관리자에게 권한 그룹 [2] 할당	2026-03-11 23:19:15.501029+09
386	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-11 23:20:49.241733+09
387	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 23:25:21.502939+09
388	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-11 23:46:43.256591+09
389	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-11 23:54:29.819136+09
390	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:24:54.257054+09
391	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:26:27.424853+09
392	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:27:57.312094+09
393	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:29:56.813918+09
394	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:34:40.338877+09
395	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:34:43.619774+09
396	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:35:03.229759+09
397	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:35:46.988219+09
398	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:35:58.730765+09
399	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:38:20.521463+09
400	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:40:18.446741+09
401	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:40:33.426081+09
402	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:43:39.740197+09
403	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:44:10.721325+09
404	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:46:40.18537+09
405	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:49:25.182911+09
406	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:51:16.069206+09
407	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:52:47.429501+09
408	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:53:10.420703+09
409	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:53:16.867007+09
410	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:54:00.100445+09
411	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:54:14.911084+09
412	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:56:52.744942+09
413	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 22:58:09.582784+09
414	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-13 22:59:07.254816+09
415	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-13 22:59:59.123062+09
416	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:00:12.874369+09
417	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0	사용자 'admin' 로그인 성공	2026-03-13 23:00:46.275501+09
418	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:01:52.353519+09
419	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:04:10.79692+09
420	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:10:12.887069+09
421	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:10:28.343697+09
422	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:11:22.712813+09
423	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:12:29.314566+09
424	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:15:44.470173+09
425	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:19:27.462836+09
426	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:20:58.085169+09
427	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:25:13.737863+09
428	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:25:31.339774+09
429	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:27:24.942183+09
430	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:29:57.896673+09
431	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:39:37.008771+09
432	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:42:59.211736+09
433	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:43:50.102698+09
434	1	LOGIN	IAM	users	1	{}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	사용자 'admin' 로그인 성공	2026-03-13 23:44:57.441507+09
\.


--
-- Data for Name: sequence_rules; Type: TABLE DATA; Schema: sys; Owner: -
--

COPY sys.sequence_rules (id, domain_code, prefix, year_format, separator, padding_length, current_year, current_seq, reset_type, is_active, created_at, created_by, updated_at, updated_by) FROM stdin;
1	FAC	FAC	YYYY	-	4	2026	0	YEARLY	t	2026-03-08 19:48:02.201425+09	\N	2026-03-08 19:48:02.201425+09	\N
2	EQP	EQP	YYYY	-	4	2026	0	YEARLY	t	2026-03-08 19:48:02.201425+09	\N	2026-03-08 19:48:02.201425+09	\N
3	WQT	WQT	YYYY	-	4	2026	0	YEARLY	t	2026-03-08 19:48:02.201425+09	\N	2026-03-08 19:48:02.201425+09	\N
4	FAC	ASSET_ABD6	YYYY	-	4	2026	1	YEARLY	t	2026-03-08 20:33:37.164999+09	1	2026-03-08 20:33:37.175578+09	1
7	FAC	ASSET_B3D9	YYYY	-	4	2026	1	YEARLY	t	2026-03-08 20:38:01.384328+09	1	2026-03-08 20:38:01.396874+09	1
9	FAC	AST23	YYYY	-	4	2026	0	YEARLY	t	2026-03-08 20:39:14.181664+09	1	2026-03-08 20:39:14.181664+09	1
12	FAC	ASTC1	YYYY	-	4	2026	0	YEARLY	t	2026-03-08 20:39:52.484829+09	1	2026-03-08 20:39:52.484829+09	1
13	FAC	AST5A	YYYY	-	4	2026	1	YEARLY	t	2026-03-08 20:40:32.419857+09	1	2026-03-08 20:40:32.434989+09	1
15	FAC	ABD02	YYYY	-	4	2026	1	YEARLY	t	2026-03-08 20:42:55.285903+09	1	2026-03-08 20:42:55.298164+09	1
17	FAC	ACB67	YYYY	-	4	2026	1	YEARLY	t	2026-03-08 20:43:31.222977+09	1	2026-03-08 20:43:31.236336+09	1
19	FAC	A48BF	YYYY	-	4	2026	1	YEARLY	t	2026-03-08 20:46:57.672785+09	1	2026-03-08 20:46:57.695707+09	1
20	FAC	TA40	YYYY	-	4	2026	1	YEARLY	t	2026-03-08 20:46:57.915128+09	1	2026-03-08 20:46:57.921964+09	1
\.


--
-- Data for Name: system_domains; Type: TABLE DATA; Schema: sys; Owner: -
--

COPY sys.system_domains (id, domain_code, domain_name, schema_name, description, sort_order, is_active, created_at, created_by, updated_at, updated_by) FROM stdin;
1	SYS	System	sys	시스템 관리 도메인	1	t	2026-03-08 19:48:02.199204+09	\N	2026-03-08 19:48:02.199204+09	\N
2	CMM	Common	cmm	공통 관리 도메인	1	t	2026-03-08 19:48:02.199204+09	\N	2026-03-08 19:48:02.199204+09	\N
3	IAM	Identity	iam	인증 및 권한 관리	2	t	2026-03-08 19:48:02.199204+09	\N	2026-03-08 19:48:02.199204+09	\N
4	USR	User	usr	사용자 및 조직 관리	3	t	2026-03-08 19:48:02.199204+09	\N	2026-03-08 19:48:02.199204+09	\N
5	FAC	Facility	fac	시설 및 공간 관리	4	t	2026-03-08 19:48:02.199204+09	\N	2026-03-08 19:48:02.199204+09	\N
6	EQP	Equipment	eqp	설비 관리	5	t	2026-03-08 19:48:02.199204+09	\N	2026-03-08 19:48:02.199204+09	\N
7	WQT	Water Quality	wqt	수질 관리	6	t	2026-03-08 19:48:02.199204+09	\N	2026-03-08 19:48:02.199204+09	\N
\.


--
-- Data for Name: organizations; Type: TABLE DATA; Schema: usr; Owner: -
--

COPY usr.organizations (id, name, code, parent_id, sort_order, description, is_active, legacy_id, legacy_source, created_at, created_by, updated_at, updated_by) FROM stdin;
0	시스템 관리	SYSTEM	\N	-1	시스템 자동 생성 및 관리를 위한 가상 최상위 조직	t	\N	\N	2026-03-08 19:48:01.546333+09	0	2026-03-08 19:48:01.546333+09	0
166	환경사업본부	STP	\N	1	환경사업본부	t	\N	\N	2026-03-09 21:00:32.208464+09	1	2026-03-09 22:41:46.063034+09	1
173	체육사업처	SPT_ORG	\N	10	체육사업처	t	\N	\N	2026-03-09 21:42:17.458708+09	1	2026-03-09 22:42:00.678725+09	1
171	경안센터	STP_0001	170	1	12121212	t	\N	\N	2026-03-09 21:39:31.82486+09	1	2026-03-09 22:57:06.446081+09	1
170	공공하수처리시설	STP_00	166	10	\N	t	\N	\N	2026-03-09 21:39:10.479905+09	1	2026-03-09 21:39:10.479905+09	1
172	오포센터	STP_0002	170	2	\N	t	\N	\N	2026-03-09 21:39:51.729211+09	1	2026-03-09 21:39:51.729211+09	1
168	시설팀	ENV_T2	166	3	\N	t	\N	\N	2026-03-09 21:05:27.040357+09	1	2026-03-09 22:02:49.637378+09	1
169	수질팀	ENV_T3	173	2	\N	t	\N	\N	2026-03-09 21:05:46.328818+09	1	2026-03-09 22:30:59.741772+09	1
167	기획팀	ENV_T1	166	1	121212	t	\N	\N	2026-03-09 21:02:14.081169+09	1	2026-03-09 22:37:13.803236+09	1
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: usr; Owner: -
--

COPY usr.users (id, org_id, profile_image_id, login_id, password_hash, emp_code, name, email, phone, is_active, last_login_at, login_fail_count, legacy_id, legacy_source, metadata, created_at, created_by, updated_at, updated_by, account_status) FROM stdin;
6	\N	\N	user_957087	$2b$12$HqJoVOb.KpAOlm012r5DCexATn9NLp2W6saPL0swvLLVyK4URypI6	2DC8ABC0	테스트유저	user_957087@example.com	\N	f	\N	0	\N	\N	{"retired_at": "2026-03-08T20:38:32.617352"}	2026-03-08 20:38:32.402235+09	1	2026-03-08 20:38:32.613754+09	1	ACTIVE
20	170	\N	testuser_003	$2b$12$VDKPDkQDP2SxweYSTafitOcRWKXW/UVgxuUZvK9pykr2YCA0cdMs2	STP-1003	장서윤	testuser_003@example.com	010-1234-0003	t	\N	0	\N	\N	{"pos": "MANAGER", "duty": "MEMBER"}	2026-03-10 20:25:36.662621+09	0	2026-03-10 20:25:36.662621+09	0	ACTIVE
21	167	\N	testuser_004	$2b$12$rAJ.ABhEl4Kf9PJgIRugEus2OQmdB8gUFV4RwPChOl.88qjJrsLoK	STP-1004	최하윤	testuser_004@example.com	010-1234-0004	t	\N	0	\N	\N	{"pos": "MANAGER", "duty": "HEAD"}	2026-03-10 20:25:36.852572+09	0	2026-03-10 20:25:36.852572+09	0	ACTIVE
11	\N	\N	user_b32111	$2b$12$.riid4h3rflCNRhD1CSwH.vNCvQYDhxCYxzsB0YDsSLKTwUHjfNBa	8461CADA	테스트유저	user_b32111@example.com	\N	f	\N	0	\N	\N	{"retired_at": "2026-03-08T20:41:26.149188"}	2026-03-08 20:41:25.943044+09	1	2026-03-08 20:41:26.145239+09	1	ACTIVE
5	\N	\N	user_b8ff40	$2b$12$FT6arNuUx3IHgkD9yBgUOO8oZX7kPOyR5x5q91BmQhF9oFkNTzBvS	024E024A	테스트유저	user_b8ff40@example.com	\N	f	\N	0	\N	\N	{"retired_at": "2026-03-08T20:37:53.659364"}	2026-03-08 20:37:53.449262+09	1	2026-03-08 20:37:53.655267+09	1	ACTIVE
2	\N	\N	user_94fdcb	$2b$12$EChxgsR0uq1lPYw18NrsZOqAa2kmiDD6oMOCDTPNVEQ3y2x3S180m	31F1707A	테스트유저	user_94fdcb@example.com	\N	f	\N	0	\N	\N	{"retired_at": "2026-03-08T20:33:38.787192"}	2026-03-08 20:33:38.580811+09	1	2026-03-08 20:33:38.784242+09	1	ACTIVE
10	\N	\N	user_92c87f	$2b$12$hrCevovJuxLqTiOGtiQeReucRnWgvtFJiDS8pBERCAMjt6B2XPVmK	60B25D80	테스트유저	user_92c87f@example.com	\N	f	\N	0	\N	\N	{"retired_at": "2026-03-08T20:41:01.096890"}	2026-03-08 20:41:00.878889+09	1	2026-03-08 20:41:01.093714+09	1	ACTIVE
9	\N	\N	user_9f5878	$2b$12$120V5KDeoBhveWeyDB0nI.pLNCSixWHRhvCR7wb.2SEO8Y5hvkl8e	EA15B23D	테스트유저	user_9f5878@example.com	\N	f	\N	0	\N	\N	{"retired_at": "2026-03-08T20:40:24.319841"}	2026-03-08 20:40:24.108243+09	1	2026-03-08 20:40:24.315197+09	1	ACTIVE
4	\N	\N	user_16c337	$2b$12$km9sGPZ61.b9BW1kE42FLebUr1sbSAt0Gn0q.7L1skxgyX0jrIgyO	BDFB183C	테스트유저	user_16c337@example.com	\N	f	\N	0	\N	\N	{"retired_at": "2026-03-08T20:37:21.113730"}	2026-03-08 20:37:20.90857+09	1	2026-03-08 20:37:21.110775+09	1	ACTIVE
8	\N	\N	user_e1cbf7	$2b$12$WLmib5tr.uqUQkdISF3ky.XlfBMH7jeaCbRwfYs6JrLZD9zq2hM6y	234DC983	테스트유저	user_e1cbf7@example.com	\N	f	\N	0	\N	\N	{"retired_at": "2026-03-08T20:39:44.612930"}	2026-03-08 20:39:44.405465+09	1	2026-03-08 20:39:44.60999+09	1	ACTIVE
12	\N	\N	user_56a0bb	$2b$12$yIlewuaGY9a2QyK//0gMmOmLEl6PAuw3hzHzqB0xWD2K3z38ixuNa	D911EE35	테스트유저	user_56a0bb@example.com	\N	f	\N	0	\N	\N	{"retired_at": "2026-03-08T20:42:26.390857"}	2026-03-08 20:42:26.151833+09	1	2026-03-08 20:42:26.385937+09	1	ACTIVE
13	\N	\N	user_05ec3e	$2b$12$UMeXKonJyNtvjeLfJuPDGeW52jLaXbqqhn9X9TXXFs3br0ugI1T36	B7F96103	테스트유저	user_05ec3e@example.com	\N	f	\N	0	\N	\N	{"retired_at": "2026-03-08T20:42:57.015989"}	2026-03-08 20:42:56.80785+09	1	2026-03-08 20:42:57.01176+09	1	ACTIVE
3	\N	\N	user_b459ad	$2b$12$yHli/7XqSBfG.uuoRY4pQum2N33Ud2n6Uc2kGYsT.ivnmTB3iOBOK	14958B9A	테스트유저	user_b459ad@example.com	\N	f	\N	0	\N	\N	{"retired_at": "2026-03-08T20:36:27.097667"}	2026-03-08 20:36:26.893785+09	1	2026-03-08 20:36:27.094885+09	1	ACTIVE
7	\N	\N	user_a5a35a	$2b$12$NXzdxaoO3mcgnxOPwfz/U.TVIRwjLtPjzg2PaE1dyK2pOo.OsAMoi	0FC5DA37	테스트유저	user_a5a35a@example.com	\N	f	\N	0	\N	\N	{"retired_at": "2026-03-08T20:39:15.826845"}	2026-03-08 20:39:15.616186+09	1	2026-03-08 20:39:15.822087+09	1	ACTIVE
16	\N	\N	tmp_bf9747	$2b$12$XuLzZ6/Um7bjzHa.0UYUo.AIvxpT2ioPZzmXFsiEegVZihXbnjIC2	EMP_BF9747	임시사용자	tmp_bf9747@example.com	\N	t	2026-03-08 20:46:57.441512+09	0	\N	\N	{}	2026-03-08 20:46:57.044469+09	1	2026-03-08 20:46:57.257431+09	1	ACTIVE
22	171	\N	testuser_005	$2b$12$t70LVI5oWLgFuU4Sn40sxOoc4/RhlnyThVI4.u38CHsUnkstKCAMS	STP-1005	이시우	testuser_005@example.com	010-1234-0005	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "HEAD"}	2026-03-10 20:25:37.04777+09	0	2026-03-10 20:25:37.04777+09	0	ACTIVE
15	\N	\N	user_cc6f60	$2b$12$x/HCAP2oKzUa//OiK0LNceZCMI85GVqduCQn/W8Jf4dskQL7Kle8m	9E0967B4	테스트유저	user_cc6f60@example.com	\N	f	\N	0	\N	\N	{"retired_at": "2026-03-08T20:43:32.969785"}	2026-03-08 20:43:32.763149+09	1	2026-03-08 20:43:32.966465+09	1	ACTIVE
23	171	\N	testuser_006	$2b$12$oJxgaRMakkXOGoAOzPmcE.2LyVF8XzN9Gbw8zswtS.EBmZztmBwPS	STP-1006	이서연	testuser_006@example.com	010-1234-0006	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "MEMBER"}	2026-03-10 20:25:37.23781+09	0	2026-03-10 20:25:37.23781+09	0	ACTIVE
24	168	\N	testuser_007	$2b$12$Xta00pyFbf4UVDVNrm41zun0uuT4/SN/4XX0L4yQtoZ0OW5Pmtofm	STP-1007	정시우	testuser_007@example.com	010-1234-0007	t	\N	0	\N	\N	{"pos": "SENIOR", "duty": "MEMBER"}	2026-03-10 20:25:37.433025+09	0	2026-03-10 20:25:37.433025+09	0	ACTIVE
25	169	\N	testuser_008	$2b$12$l14CHcq51JsaaKb0igT3OevHUnKGkNCZu5s4ofTs2LsPAiBE/cT3S	STP-1008	최지호	testuser_008@example.com	010-1234-0008	t	\N	0	\N	\N	{"pos": "DIRECTOR", "duty": "MEMBER"}	2026-03-10 20:25:37.630293+09	0	2026-03-10 20:25:37.630293+09	0	ACTIVE
26	170	\N	testuser_009	$2b$12$0eTgnDb1iaEF1VKI8v.tt.7Dlr1fZOlSZfmrRzFP4p3euadiWwV5K	STP-1009	박서윤	testuser_009@example.com	010-1234-0009	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "LEADER"}	2026-03-10 20:25:37.822731+09	0	2026-03-10 20:25:37.822731+09	0	ACTIVE
27	168	\N	testuser_010	$2b$12$cNFjPMT/hqfkQrL5MaDv1OKgcc/fHtWk7EVs/ZdRsuSCOIcUA314a	STP-1010	이민준	testuser_010@example.com	010-1234-0010	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "HEAD"}	2026-03-10 20:25:38.01706+09	0	2026-03-10 20:25:38.01706+09	0	ACTIVE
14	\N	\N	tmp_731dca	$2b$12$swul7DYVS07cQs/RfM63fOiI2cHCL1cwtLHPFJcA/wTIQyJ5e074.	EMP_731DCA	임시사용자	tmp_731dca@example.com	\N	t	2026-03-08 20:43:30.987619+09	0	\N	\N	{}	2026-03-08 20:43:30.592877+09	1	2026-03-08 20:43:30.799168+09	1	ACTIVE
28	167	\N	testuser_011	$2b$12$dE6KMeuL4Q0qoZ/uafOk0eegzrAgjLT9Q4m..6KNyHrDXvpyD7XYe	STP-1011	조지우	testuser_011@example.com	010-1234-0011	t	\N	0	\N	\N	{"pos": "SENIOR", "duty": "MEMBER"}	2026-03-10 20:25:38.209408+09	0	2026-03-10 20:25:38.209408+09	0	ACTIVE
17	\N	\N	user_f964c1	$2b$12$RAYI9.GD.88OAL1UfAIZhejF3URVC/ozjik47YZJlWWXEqr9EWeqq	722B0D1E	테스트유저	user_f964c1@example.com	\N	f	\N	0	\N	\N	{"retired_at": "2026-03-08T20:46:59.345565"}	2026-03-08 20:46:59.145069+09	1	2026-03-08 20:46:59.341943+09	1	ACTIVE
29	168	\N	testuser_012	$2b$12$7r9x.f4iHJTY6jfKiNnk8.szjFCtgYXUZRTD9DpqxHa.DNBfLWHEa	STP-1012	장시우	testuser_012@example.com	010-1234-0012	t	\N	0	\N	\N	{"pos": "MANAGER", "duty": "LEADER"}	2026-03-10 20:25:38.401405+09	0	2026-03-10 20:25:38.401405+09	0	ACTIVE
30	169	\N	testuser_013	$2b$12$NWqPt/SYTZBizV7Dhk9Kz.7EJFSngQuYX6tBunFEcOwGLNcMffg8y	STP-1013	최하윤	testuser_013@example.com	010-1234-0013	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "HEAD"}	2026-03-10 20:25:38.604928+09	0	2026-03-10 20:25:38.604928+09	0	ACTIVE
18	166	\N	testuser_001	$2b$12$kkaAVpS0TJLQc72GbwV96u37o/JXDDOlwTjHd13Wti3F/u42bQP1.	STP-1001	조서연	testuser_001@example.com	010-1234-0001	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "LEADER"}	2026-03-10 20:25:36.084918+09	0	2026-03-10 20:25:36.084918+09	0	ACTIVE
19	168	\N	testuser_002	$2b$12$zZybv8vHiKYe3oWiu2skQe16sx99jim77udOz1Bc0mr3plkkyaMMq	STP-1002	정수아	testuser_002@example.com	010-1234-0002	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "LEADER"}	2026-03-10 20:25:36.475178+09	0	2026-03-10 20:25:36.475178+09	0	ACTIVE
31	172	\N	testuser_014	$2b$12$MbmceSq.Ujs6H2X7mGZojOnebR1dmgZkIFNQzKSJJWKrAFOxy1h/a	STP-1014	이서윤	testuser_014@example.com	010-1234-0014	t	\N	0	\N	\N	{"pos": "SENIOR", "duty": "LEADER"}	2026-03-10 20:25:38.803771+09	0	2026-03-10 20:25:38.803771+09	0	ACTIVE
32	168	\N	testuser_015	$2b$12$2s/jz1nYjxfEZ2yvU2I3WehSJgXpz.6zOKfDKNaeR7VEhIWB5ZclW	STP-1015	임서연	testuser_015@example.com	010-1234-0015	t	\N	0	\N	\N	{"pos": "SENIOR", "duty": "LEADER"}	2026-03-10 20:25:39.009768+09	0	2026-03-10 20:25:39.009768+09	0	ACTIVE
33	171	\N	testuser_016	$2b$12$wb99MiCpSkKHyHvrcc8pEeQ2XaJXT9LvQA/FEWpJCO9yNjnydYCfO	STP-1016	김하윤	testuser_016@example.com	010-1234-0016	t	\N	0	\N	\N	{"pos": "DIRECTOR", "duty": "MEMBER"}	2026-03-10 20:25:39.201662+09	0	2026-03-10 20:25:39.201662+09	0	ACTIVE
34	167	\N	testuser_017	$2b$12$zkot0yK5JN1bxChcPHxXXuOOIO9KsqmfOifApf/i1fW4DsGH4ToD2	STP-1017	박시우	testuser_017@example.com	010-1234-0017	t	\N	0	\N	\N	{"pos": "DIRECTOR", "duty": "LEADER"}	2026-03-10 20:25:39.396688+09	0	2026-03-10 20:25:39.396688+09	0	ACTIVE
35	171	\N	testuser_018	$2b$12$5OXKH4u17b7Q4mRjy7nn3.Z6ZXOtF0W4N81bJ6pqf.Er4Sbu7.td6	STP-1018	김서연	testuser_018@example.com	010-1234-0018	t	\N	0	\N	\N	{"pos": "SENIOR", "duty": "HEAD"}	2026-03-10 20:25:39.589109+09	0	2026-03-10 20:25:39.589109+09	0	ACTIVE
36	172	\N	testuser_019	$2b$12$dy06bNvopp/o7DELJFrXXOQjUPTrrrEZAyy//l/wbuNxl8sH1wozq	STP-1019	김지호	testuser_019@example.com	010-1234-0019	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "LEADER"}	2026-03-10 20:25:39.78912+09	0	2026-03-10 20:25:39.78912+09	0	ACTIVE
37	167	\N	testuser_020	$2b$12$BXAY6up30mi2HPEvToQ3le/usIDHs8NBkiVVGlhu6RqzWGzSOJHXm	STP-1020	이시우	testuser_020@example.com	010-1234-0020	t	\N	0	\N	\N	{"pos": "SENIOR", "duty": "HEAD"}	2026-03-10 20:25:39.982069+09	0	2026-03-10 20:25:39.982069+09	0	ACTIVE
38	172	\N	testuser_021	$2b$12$4fHdARXEqpO5ds4ElHazdukTGuyF4oQo2efTmr2HYhWZUCOIFtSau	STP-1021	장도윤	testuser_021@example.com	010-1234-0021	t	\N	0	\N	\N	{"pos": "SENIOR", "duty": "LEADER"}	2026-03-10 20:25:40.172946+09	0	2026-03-10 20:25:40.172946+09	0	ACTIVE
39	173	\N	testuser_022	$2b$12$Lz6EmnLDr3TQkRm7jG2NzelhiY2YKQQqcD1s5H/mUq6Lr8rSQACsm	STP-1022	최지우	testuser_022@example.com	010-1234-0022	t	\N	0	\N	\N	{"pos": "SENIOR", "duty": "LEADER"}	2026-03-10 20:25:40.370107+09	0	2026-03-10 20:25:40.370107+09	0	ACTIVE
40	171	\N	testuser_023	$2b$12$7ZWkUWQsVypxqqBQdmFecuzwFOB.BfGosJQ3eCwYUgKRQuTd/qpT.	STP-1023	강서윤	testuser_023@example.com	010-1234-0023	t	\N	0	\N	\N	{"pos": "SENIOR", "duty": "MEMBER"}	2026-03-10 20:25:40.574113+09	0	2026-03-10 20:25:40.574113+09	0	ACTIVE
41	172	\N	testuser_024	$2b$12$UQ2oUipZ5IBl0xqddogvW.LkRz4D0fj3TlxltTr4ayaW1k3/YAEse	STP-1024	임하준	testuser_024@example.com	010-1234-0024	t	\N	0	\N	\N	{"pos": "DIRECTOR", "duty": "MEMBER"}	2026-03-10 20:25:40.772541+09	0	2026-03-10 20:25:40.772541+09	0	ACTIVE
42	171	\N	testuser_025	$2b$12$1TtAAQQYEpK/q/7JlSDoOu6NsIcMBqRk.1S.tJ5Ez1X62M4iL00Nq	STP-1025	최하윤	testuser_025@example.com	010-1234-0025	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "HEAD"}	2026-03-10 20:25:40.966839+09	0	2026-03-10 20:25:40.966839+09	0	ACTIVE
43	168	\N	testuser_026	$2b$12$WINuvLz1cxs6ZYBDjnbUqu0/Lt.d3kYprVqpki4WhM5wu/HBBB.P2	STP-1026	김서연	testuser_026@example.com	010-1234-0026	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "LEADER"}	2026-03-10 20:25:41.160973+09	0	2026-03-10 20:25:41.160973+09	0	ACTIVE
44	173	\N	testuser_027	$2b$12$CTs05Wsyfe/9LkHpZDO8M.YD9NRhm0rHeCTKmG.APYY90IZN6qQj6	STP-1027	박시우	testuser_027@example.com	010-1234-0027	t	\N	0	\N	\N	{"pos": "MANAGER", "duty": "MEMBER"}	2026-03-10 20:25:41.355055+09	0	2026-03-10 20:25:41.355055+09	0	ACTIVE
45	171	\N	testuser_028	$2b$12$6ddZD5If0cJoMc5lIGOHcOJHe2C.UvVJwBN1VebcuqglQNpOLZhZi	STP-1028	이서윤	testuser_028@example.com	010-1234-0028	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "LEADER"}	2026-03-10 20:25:41.541896+09	0	2026-03-10 20:25:41.541896+09	0	ACTIVE
46	166	\N	testuser_029	$2b$12$1dJb.RAdCNo1kmAwoHs7BeF30K8o0ALP.9u5.D2GKkz/EUE1079da	STP-1029	조시우	testuser_029@example.com	010-1234-0029	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "MEMBER"}	2026-03-10 20:25:41.732442+09	0	2026-03-10 20:25:41.732442+09	0	ACTIVE
47	166	\N	testuser_030	$2b$12$IWHx3Apjb66BgnOrbltucOXF2jJYvb3vBhBF7g1bwxVLiLcNyQija	STP-1030	최도윤	testuser_030@example.com	010-1234-0030	t	\N	0	\N	\N	{"pos": "SENIOR", "duty": "LEADER"}	2026-03-10 20:25:41.917979+09	0	2026-03-10 20:25:41.917979+09	0	ACTIVE
48	171	\N	testuser_031	$2b$12$R52VKL7AgGm4P7M1zt/.suD1GiF7zFjVCG5y1mWkq5hNGudXAXFUW	STP-1031	최민준	testuser_031@example.com	010-1234-0031	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "HEAD"}	2026-03-10 20:25:42.114009+09	0	2026-03-10 20:25:42.114009+09	0	ACTIVE
49	166	\N	testuser_032	$2b$12$h5SwSf3JYNJkVGGyW.gbEuBBCcclxqX9RVozXwj9yU7E1tDE1eKi.	STP-1032	김서윤	testuser_032@example.com	010-1234-0032	t	\N	0	\N	\N	{"pos": "MANAGER", "duty": "LEADER"}	2026-03-10 20:25:42.313888+09	0	2026-03-10 20:25:42.313888+09	0	ACTIVE
50	166	\N	testuser_033	$2b$12$MkEQyJqpEXUIRKDt97b99OjYU6SO1QwBXCmDTPO.luxQmA7tVGluS	STP-1033	최민준	testuser_033@example.com	010-1234-0033	t	\N	0	\N	\N	{"pos": "MANAGER", "duty": "MEMBER"}	2026-03-10 20:25:42.508996+09	0	2026-03-10 20:25:42.508996+09	0	ACTIVE
51	172	\N	testuser_034	$2b$12$yNdKYFJSxMsfFRu6oqNa4.HEbJSU.edWlhXCIN2vn/IPvKTNoE5r.	STP-1034	박지우	testuser_034@example.com	010-1234-0034	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "MEMBER"}	2026-03-10 20:25:42.70306+09	0	2026-03-10 20:25:42.70306+09	0	ACTIVE
52	170	\N	testuser_035	$2b$12$mjKPB8xSF2k5pCQE/C5iEO4tjPf2KG/7pnHxFzMgoFQ9wjyzSQsLW	STP-1035	김서윤	testuser_035@example.com	010-1234-0035	t	\N	0	\N	\N	{"pos": "SENIOR", "duty": "LEADER"}	2026-03-10 20:25:42.895043+09	0	2026-03-10 20:25:42.895043+09	0	ACTIVE
53	173	\N	testuser_036	$2b$12$Iw.F3VtfiomKqGLLR7w.tO/DlUKZ8O9hnCZR1wTsl2Evob0ZElNJG	STP-1036	정하준	testuser_036@example.com	010-1234-0036	t	\N	0	\N	\N	{"pos": "SENIOR", "duty": "LEADER"}	2026-03-10 20:25:43.089183+09	0	2026-03-10 20:25:43.089183+09	0	ACTIVE
54	166	\N	testuser_037	$2b$12$HV.faZxkHal3c9ktYVs1x.p6Tb/45g944VpAQ6MZo5bbBoW0M.mYG	STP-1037	최서연	testuser_037@example.com	010-1234-0037	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "MEMBER"}	2026-03-10 20:25:43.28666+09	0	2026-03-10 20:25:43.28666+09	0	ACTIVE
55	168	\N	testuser_038	$2b$12$lB0C9yI73InEdyANe7XFwOkh2.XE.Znusx8S5gFL.aDnl4BXZaL.2	STP-1038	강지우	testuser_038@example.com	010-1234-0038	t	\N	0	\N	\N	{"pos": "DIRECTOR", "duty": "HEAD"}	2026-03-10 20:25:43.486191+09	0	2026-03-10 20:25:43.486191+09	0	ACTIVE
56	166	\N	testuser_039	$2b$12$AXHszHI3.91jz7lB7wZa4ut7zP9pMuKEtP0lu8Uq.kvIeUHVoLyTK	STP-1039	김도윤	testuser_039@example.com	010-1234-0039	t	\N	0	\N	\N	{"pos": "MANAGER", "duty": "MEMBER"}	2026-03-10 20:25:43.682052+09	0	2026-03-10 20:25:43.682052+09	0	ACTIVE
57	169	\N	testuser_040	$2b$12$UEin56kQJl9AyG8p7F00.uUyiy1QhvnWrSU3fNG5FJjyVKcB.GFze	STP-1040	장도윤	testuser_040@example.com	010-1234-0040	t	\N	0	\N	\N	{"pos": "MANAGER", "duty": "LEADER"}	2026-03-10 20:25:43.878559+09	0	2026-03-10 20:25:43.878559+09	0	ACTIVE
58	167	\N	testuser_041	$2b$12$urzAtdZ92pppzFZMGCurE.UzYbpAsXqmlbOetPmMLjV91fj5lQ8H.	STP-1041	김지우	testuser_041@example.com	010-1234-0041	t	\N	0	\N	\N	{"pos": "DIRECTOR", "duty": "MEMBER"}	2026-03-10 20:25:44.069985+09	0	2026-03-10 20:25:44.069985+09	0	ACTIVE
59	166	\N	testuser_042	$2b$12$xtifRV5iAiKaHYDhuHcIEeF6nVZZ/5rGmL9NNNz9zUDH/A1qVjhku	STP-1042	최시우	testuser_042@example.com	010-1234-0042	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "LEADER"}	2026-03-10 20:25:44.264237+09	0	2026-03-10 20:25:44.264237+09	0	ACTIVE
60	172	\N	testuser_043	$2b$12$H4mBUqdn2HXQNRU9kYJQ.e/7CXoxtXGT/iHyjXKEjWx5ZDv/B23qa	STP-1043	김서연	testuser_043@example.com	010-1234-0043	t	\N	0	\N	\N	{"pos": "DIRECTOR", "duty": "LEADER"}	2026-03-10 20:25:44.460519+09	0	2026-03-10 20:25:44.460519+09	0	ACTIVE
61	171	\N	testuser_044	$2b$12$Lrj8n3ZyrTwoP90.K6gONOXCC0cFemMouWsE.gkCOlNsYziVmma5S	STP-1044	임서연	testuser_044@example.com	010-1234-0044	t	\N	0	\N	\N	{"pos": "SENIOR", "duty": "HEAD"}	2026-03-10 20:25:44.664616+09	0	2026-03-10 20:25:44.664616+09	0	ACTIVE
0	0	\N	system	$6$SYSTEM_ACCOUNT_NO_LOGIN$	0000	시스템	system@sfms.com	\N	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "MEMBER", "role": "internal_system"}	2026-03-08 19:48:01.548509+09	0	2026-03-12 00:01:11.396461+09	1	ACTIVE
66	168	\N	testuser_049	$2b$12$8zu/BiPCaLQGyp8PSlR.nusZwolEZTUIcSS80L9fAFuFvwHkn8ROa	STP-1049	최하윤	testuser_049@example.com	010-1234-0049	f	\N	0	\N	\N	{}	2026-03-10 20:25:45.640976+09	0	2026-03-10 21:00:33.532658+09	1	ACTIVE
65	168	\N	testuser_048	$2b$12$bNFUSFJUFJDv.KTF5Js3NuGPOYafsV23h3TGYRhyoorKVfcdSuiYG	STP-1048	장지우	testuser_048@example.com	010-1234-0048	f	\N	0	\N	\N	{}	2026-03-10 20:25:45.441483+09	0	2026-03-10 21:01:42.97024+09	1	ACTIVE
62	172	\N	testuser_045	$2b$12$SCnB.DT6xKLMCSzl4/O7E.7GjvJR9bCvj8O1gGLZqG6qAY9mDE6zS	STP-1045	윤도윤	testuser_045@example.com	010-1234-0045	f	\N	0	\N	\N	{}	2026-03-10 20:25:44.859954+09	0	2026-03-10 21:04:08.736695+09	1	ACTIVE
63	169	\N	testuser_046	$2b$12$NrHl9ux.HTvYsh9p4wS2U.97dddKR9SBud2/KNytJ59M7xNLQzEU2	STP-1046	정도윤	testuser_046@example.com	010-1234-0046	t	\N	0	\N	\N	{"pos": "ASSISTANT", "duty": "LEADER"}	2026-03-10 20:25:45.052341+09	0	2026-03-11 22:43:49.384265+09	1	ACTIVE
67	170	c4a693ac-c986-4508-a9a7-251accb32104	testuser_050	$2b$12$I7uG7ixQ.NH4os4G4MS2UeHcdnsEbaqUo/gnfulWPHPM1YJrYto1C	STP-1050	조수아	testuser_050@example.com	010-1234-0050	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "MEMBER"}	2026-03-10 20:25:45.841246+09	0	2026-03-11 23:09:19.034292+09	1	ACTIVE
1	0	6ab167d4-a8d5-4b3b-9f82-c88cfc6d4b64	admin	$2b$12$XlORhOti8FkZmZzdgSbOVOzksmhyKIbkP9AfDPOW85Ixk2qo7ZCqK	ADMIN001	시스템관리자	admin@color.com	010-0000-0000	t	2026-03-13 23:44:57.620325+09	0	\N	\N	{"pos": "HEAD", "duty": "LEADER"}	2026-03-08 19:52:47.433495+09	\N	2026-03-13 23:44:57.441507+09	1	ACTIVE
64	166	2dfecc7a-6c12-4aaf-9b55-cc15a027611b	testuser_047	$2b$12$XoLdyIr870PcYYumJi6T4.4w4YxUoDXhsavvUkZx09MMOdhS6Ffhm	STP-1047	조지우	testuser_047@example.com	010-1234-0047	t	\N	0	\N	\N	{"pos": "MANAGER", "duty": "LEADER"}	2026-03-10 20:25:45.247234+09	0	2026-03-11 21:20:30.69291+09	1	ACTIVE
69	0	9c7df744-db92-475f-be3a-cdbb13f09ae3	sub_admin	$2b$12$DJnHigpAblC1zE1RzryLx.iGDyqHIFBxTuFhkCA/sn4GfmPZptaay	SUB-0000	부관리	sub@color.com	010-1111-1111	t	\N	0	\N	\N	{"pos": "STAFF", "duty": "MEMBER"}	2026-03-11 23:18:51.156379+09	1	2026-03-11 23:57:39.29443+09	1	ACTIVE
68	0	b1223073-ec23-43c9-a7c9-ea9f3c969f6c	sysadmin	$2b$12$uvyQQnxw0TZcbOc82cjsruk8mmKqn/pPdwFCuDQY0yqcuVNX/tw6W	SYS-0001	관리자	admin@blue.com	010-0000-0000	t	\N	0	\N	\N	{"retired_at": "2026-03-11T22:34:35.962302"}	2026-03-10 21:09:22.524314+09	1	2026-03-11 23:58:09.872896+09	1	ACTIVE
\.


--
-- Name: code_details_id_seq; Type: SEQUENCE SET; Schema: cmm; Owner: -
--

SELECT pg_catalog.setval('cmm.code_details_id_seq', 52, true);


--
-- Name: code_groups_id_seq; Type: SEQUENCE SET; Schema: cmm; Owner: -
--

SELECT pg_catalog.setval('cmm.code_groups_id_seq', 36, true);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: cmm; Owner: -
--

SELECT pg_catalog.setval('cmm.notifications_id_seq', 1, false);


--
-- Name: facilities_id_seq; Type: SEQUENCE SET; Schema: fac; Owner: -
--

SELECT pg_catalog.setval('fac.facilities_id_seq', 41, true);


--
-- Name: facility_categories_id_seq; Type: SEQUENCE SET; Schema: fac; Owner: -
--

SELECT pg_catalog.setval('fac.facility_categories_id_seq', 1, false);


--
-- Name: space_functions_id_seq; Type: SEQUENCE SET; Schema: fac; Owner: -
--

SELECT pg_catalog.setval('fac.space_functions_id_seq', 1, false);


--
-- Name: space_types_id_seq; Type: SEQUENCE SET; Schema: fac; Owner: -
--

SELECT pg_catalog.setval('fac.space_types_id_seq', 1, false);


--
-- Name: spaces_id_seq; Type: SEQUENCE SET; Schema: fac; Owner: -
--

SELECT pg_catalog.setval('fac.spaces_id_seq', 57, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: iam; Owner: -
--

SELECT pg_catalog.setval('iam.roles_id_seq', 19, true);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: sys; Owner: -
--

SELECT pg_catalog.setval('sys.audit_logs_id_seq', 434, true);


--
-- Name: sequence_rules_id_seq; Type: SEQUENCE SET; Schema: sys; Owner: -
--

SELECT pg_catalog.setval('sys.sequence_rules_id_seq', 20, true);


--
-- Name: system_domains_id_seq; Type: SEQUENCE SET; Schema: sys; Owner: -
--

SELECT pg_catalog.setval('sys.system_domains_id_seq', 7, true);


--
-- Name: organizations_id_seq; Type: SEQUENCE SET; Schema: usr; Owner: -
--

SELECT pg_catalog.setval('usr.organizations_id_seq', 173, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: usr; Owner: -
--

SELECT pg_catalog.setval('usr.users_id_seq', 69, true);


--
-- Name: attachments attachments_pkey; Type: CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.attachments
    ADD CONSTRAINT attachments_pkey PRIMARY KEY (id);


--
-- Name: code_details code_details_pkey; Type: CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.code_details
    ADD CONSTRAINT code_details_pkey PRIMARY KEY (id);


--
-- Name: code_groups code_groups_group_code_key; Type: CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.code_groups
    ADD CONSTRAINT code_groups_group_code_key UNIQUE (group_code);


--
-- Name: code_groups code_groups_pkey; Type: CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.code_groups
    ADD CONSTRAINT code_groups_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: code_details uq_code_details_group_detail; Type: CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.code_details
    ADD CONSTRAINT uq_code_details_group_detail UNIQUE (group_code, detail_code);


--
-- Name: facilities facilities_code_key; Type: CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.facilities
    ADD CONSTRAINT facilities_code_key UNIQUE (code);


--
-- Name: facilities facilities_pkey; Type: CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.facilities
    ADD CONSTRAINT facilities_pkey PRIMARY KEY (id);


--
-- Name: facility_categories facility_categories_code_key; Type: CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.facility_categories
    ADD CONSTRAINT facility_categories_code_key UNIQUE (code);


--
-- Name: facility_categories facility_categories_pkey; Type: CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.facility_categories
    ADD CONSTRAINT facility_categories_pkey PRIMARY KEY (id);


--
-- Name: space_functions space_functions_code_key; Type: CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.space_functions
    ADD CONSTRAINT space_functions_code_key UNIQUE (code);


--
-- Name: space_functions space_functions_pkey; Type: CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.space_functions
    ADD CONSTRAINT space_functions_pkey PRIMARY KEY (id);


--
-- Name: space_types space_types_code_key; Type: CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.space_types
    ADD CONSTRAINT space_types_code_key UNIQUE (code);


--
-- Name: space_types space_types_pkey; Type: CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.space_types
    ADD CONSTRAINT space_types_pkey PRIMARY KEY (id);


--
-- Name: spaces spaces_pkey; Type: CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.spaces
    ADD CONSTRAINT spaces_pkey PRIMARY KEY (id);


--
-- Name: spaces uq_fac_spaces_code; Type: CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.spaces
    ADD CONSTRAINT uq_fac_spaces_code UNIQUE (facility_id, code);


--
-- Name: roles roles_code_key; Type: CONSTRAINT; Schema: iam; Owner: -
--

ALTER TABLE ONLY iam.roles
    ADD CONSTRAINT roles_code_key UNIQUE (code);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: iam; Owner: -
--

ALTER TABLE ONLY iam.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: iam; Owner: -
--

ALTER TABLE ONLY iam.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: sys; Owner: -
--

ALTER TABLE ONLY sys.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: sequence_rules sequence_rules_pkey; Type: CONSTRAINT; Schema: sys; Owner: -
--

ALTER TABLE ONLY sys.sequence_rules
    ADD CONSTRAINT sequence_rules_pkey PRIMARY KEY (id);


--
-- Name: system_domains system_domains_domain_code_key; Type: CONSTRAINT; Schema: sys; Owner: -
--

ALTER TABLE ONLY sys.system_domains
    ADD CONSTRAINT system_domains_domain_code_key UNIQUE (domain_code);


--
-- Name: system_domains system_domains_pkey; Type: CONSTRAINT; Schema: sys; Owner: -
--

ALTER TABLE ONLY sys.system_domains
    ADD CONSTRAINT system_domains_pkey PRIMARY KEY (id);


--
-- Name: system_domains system_domains_schema_name_key; Type: CONSTRAINT; Schema: sys; Owner: -
--

ALTER TABLE ONLY sys.system_domains
    ADD CONSTRAINT system_domains_schema_name_key UNIQUE (schema_name);


--
-- Name: sequence_rules uq_sequence_rules_domain_prefix; Type: CONSTRAINT; Schema: sys; Owner: -
--

ALTER TABLE ONLY sys.sequence_rules
    ADD CONSTRAINT uq_sequence_rules_domain_prefix UNIQUE (domain_code, prefix);


--
-- Name: organizations organizations_code_key; Type: CONSTRAINT; Schema: usr; Owner: -
--

ALTER TABLE ONLY usr.organizations
    ADD CONSTRAINT organizations_code_key UNIQUE (code);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: usr; Owner: -
--

ALTER TABLE ONLY usr.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: usr; Owner: -
--

ALTER TABLE ONLY usr.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_emp_code_key; Type: CONSTRAINT; Schema: usr; Owner: -
--

ALTER TABLE ONLY usr.users
    ADD CONSTRAINT users_emp_code_key UNIQUE (emp_code);


--
-- Name: users users_login_id_key; Type: CONSTRAINT; Schema: usr; Owner: -
--

ALTER TABLE ONLY usr.users
    ADD CONSTRAINT users_login_id_key UNIQUE (login_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: usr; Owner: -
--

ALTER TABLE ONLY usr.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_attachments_ref; Type: INDEX; Schema: cmm; Owner: -
--

CREATE INDEX idx_attachments_ref ON cmm.attachments USING btree (domain_code, resource_type, ref_id);


--
-- Name: idx_code_details_group; Type: INDEX; Schema: cmm; Owner: -
--

CREATE INDEX idx_code_details_group ON cmm.code_details USING btree (group_code);


--
-- Name: idx_code_groups_domain; Type: INDEX; Schema: cmm; Owner: -
--

CREATE INDEX idx_code_groups_domain ON cmm.code_groups USING btree (domain_code);


--
-- Name: idx_notifications_receiver_unread; Type: INDEX; Schema: cmm; Owner: -
--

CREATE INDEX idx_notifications_receiver_unread ON cmm.notifications USING btree (receiver_user_id, is_read, created_at DESC) WHERE (is_deleted IS FALSE);


--
-- Name: uq_attachments_active_path; Type: INDEX; Schema: cmm; Owner: -
--

CREATE UNIQUE INDEX uq_attachments_active_path ON cmm.attachments USING btree (file_path) WHERE (is_deleted IS FALSE);


--
-- Name: idx_fac_meta_gin; Type: INDEX; Schema: fac; Owner: -
--

CREATE INDEX idx_fac_meta_gin ON fac.facilities USING gin (metadata);


--
-- Name: idx_fac_name_pg; Type: INDEX; Schema: fac; Owner: -
--

CREATE INDEX idx_fac_name_pg ON fac.facilities USING pgroonga (name) WITH (tokenizer='TokenMecab', normalizer='NormalizerAuto');


--
-- Name: idx_fac_spaces_hierarchy; Type: INDEX; Schema: fac; Owner: -
--

CREATE INDEX idx_fac_spaces_hierarchy ON fac.spaces USING btree (facility_id, parent_id);


--
-- Name: idx_fac_spaces_meta_gin; Type: INDEX; Schema: fac; Owner: -
--

CREATE INDEX idx_fac_spaces_meta_gin ON fac.spaces USING gin (metadata);


--
-- Name: idx_fac_spaces_meta_pg; Type: INDEX; Schema: fac; Owner: -
--

CREATE INDEX idx_fac_spaces_meta_pg ON fac.spaces USING pgroonga (metadata) WITH (tokenizer='TokenMecab', normalizer='NormalizerAuto');


--
-- Name: idx_fac_spaces_name_pg; Type: INDEX; Schema: fac; Owner: -
--

CREATE INDEX idx_fac_spaces_name_pg ON fac.spaces USING pgroonga (name) WITH (tokenizer='TokenMecab', normalizer='NormalizerAuto');


--
-- Name: idx_iam_roles_permissions_gin; Type: INDEX; Schema: iam; Owner: -
--

CREATE INDEX idx_iam_roles_permissions_gin ON iam.roles USING gin (permissions);


--
-- Name: idx_iam_user_roles_role_id; Type: INDEX; Schema: iam; Owner: -
--

CREATE INDEX idx_iam_user_roles_role_id ON iam.user_roles USING btree (role_id);


--
-- Name: idx_cmm_audit_actor; Type: INDEX; Schema: sys; Owner: -
--

CREATE INDEX idx_cmm_audit_actor ON sys.audit_logs USING btree (actor_user_id);


--
-- Name: idx_cmm_audit_desc_pg; Type: INDEX; Schema: sys; Owner: -
--

CREATE INDEX idx_cmm_audit_desc_pg ON sys.audit_logs USING pgroonga (description) WITH (tokenizer='TokenMecab', normalizer='NormalizerAuto');


--
-- Name: idx_cmm_audit_snap_pg; Type: INDEX; Schema: sys; Owner: -
--

CREATE INDEX idx_cmm_audit_snap_pg ON sys.audit_logs USING pgroonga (snapshot) WITH (tokenizer='TokenMecab', normalizer='NormalizerAuto');


--
-- Name: idx_cmm_audit_target_lookup; Type: INDEX; Schema: sys; Owner: -
--

CREATE INDEX idx_cmm_audit_target_lookup ON sys.audit_logs USING btree (target_table, target_id);


--
-- Name: idx_usr_login_id; Type: INDEX; Schema: usr; Owner: -
--

CREATE INDEX idx_usr_login_id ON usr.users USING btree (login_id);


--
-- Name: idx_usr_name_pg; Type: INDEX; Schema: usr; Owner: -
--

CREATE INDEX idx_usr_name_pg ON usr.users USING pgroonga (name) WITH (tokenizer='TokenMecab', normalizer='NormalizerAuto');


--
-- Name: idx_usr_org_parent; Type: INDEX; Schema: usr; Owner: -
--

CREATE INDEX idx_usr_org_parent ON usr.organizations USING btree (parent_id);


--
-- Name: idx_usr_users_metadata_gin; Type: INDEX; Schema: usr; Owner: -
--

CREATE INDEX idx_usr_users_metadata_gin ON usr.users USING gin (metadata);


--
-- Name: idx_usr_users_org_id; Type: INDEX; Schema: usr; Owner: -
--

CREATE INDEX idx_usr_users_org_id ON usr.users USING btree (org_id);


--
-- Name: attachments trg_updated_at_attachments; Type: TRIGGER; Schema: cmm; Owner: -
--

CREATE TRIGGER trg_updated_at_attachments BEFORE UPDATE ON cmm.attachments FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();


--
-- Name: code_details trg_updated_at_code_details; Type: TRIGGER; Schema: cmm; Owner: -
--

CREATE TRIGGER trg_updated_at_code_details BEFORE UPDATE ON cmm.code_details FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();


--
-- Name: code_groups trg_updated_at_code_groups; Type: TRIGGER; Schema: cmm; Owner: -
--

CREATE TRIGGER trg_updated_at_code_groups BEFORE UPDATE ON cmm.code_groups FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();


--
-- Name: notifications trg_updated_at_notifications; Type: TRIGGER; Schema: cmm; Owner: -
--

CREATE TRIGGER trg_updated_at_notifications BEFORE UPDATE ON cmm.notifications FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();


--
-- Name: facilities trg_updated_at_facilities; Type: TRIGGER; Schema: fac; Owner: -
--

CREATE TRIGGER trg_updated_at_facilities BEFORE UPDATE ON fac.facilities FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();


--
-- Name: facility_categories trg_updated_at_facility_categories; Type: TRIGGER; Schema: fac; Owner: -
--

CREATE TRIGGER trg_updated_at_facility_categories BEFORE UPDATE ON fac.facility_categories FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();


--
-- Name: space_functions trg_updated_at_space_functions; Type: TRIGGER; Schema: fac; Owner: -
--

CREATE TRIGGER trg_updated_at_space_functions BEFORE UPDATE ON fac.space_functions FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();


--
-- Name: space_types trg_updated_at_space_types; Type: TRIGGER; Schema: fac; Owner: -
--

CREATE TRIGGER trg_updated_at_space_types BEFORE UPDATE ON fac.space_types FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();


--
-- Name: spaces trg_updated_at_spaces; Type: TRIGGER; Schema: fac; Owner: -
--

CREATE TRIGGER trg_updated_at_spaces BEFORE UPDATE ON fac.spaces FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();


--
-- Name: roles trg_updated_at_roles; Type: TRIGGER; Schema: iam; Owner: -
--

CREATE TRIGGER trg_updated_at_roles BEFORE UPDATE ON iam.roles FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();


--
-- Name: sequence_rules trg_updated_at_sequence_rules; Type: TRIGGER; Schema: sys; Owner: -
--

CREATE TRIGGER trg_updated_at_sequence_rules BEFORE UPDATE ON sys.sequence_rules FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();


--
-- Name: system_domains trg_updated_at_system_domains; Type: TRIGGER; Schema: sys; Owner: -
--

CREATE TRIGGER trg_updated_at_system_domains BEFORE UPDATE ON sys.system_domains FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();


--
-- Name: organizations trg_updated_at_organizations; Type: TRIGGER; Schema: usr; Owner: -
--

CREATE TRIGGER trg_updated_at_organizations BEFORE UPDATE ON usr.organizations FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();


--
-- Name: users trg_updated_at_users; Type: TRIGGER; Schema: usr; Owner: -
--

CREATE TRIGGER trg_updated_at_users BEFORE UPDATE ON usr.users FOR EACH ROW EXECUTE FUNCTION sys.trg_set_updated_at();


--
-- Name: attachments attachments_created_by_fkey; Type: FK CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.attachments
    ADD CONSTRAINT attachments_created_by_fkey FOREIGN KEY (created_by) REFERENCES usr.users(id);


--
-- Name: attachments attachments_domain_code_fkey; Type: FK CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.attachments
    ADD CONSTRAINT attachments_domain_code_fkey FOREIGN KEY (domain_code) REFERENCES sys.system_domains(domain_code);


--
-- Name: attachments attachments_updated_by_fkey; Type: FK CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.attachments
    ADD CONSTRAINT attachments_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES usr.users(id);


--
-- Name: code_details code_details_created_by_fkey; Type: FK CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.code_details
    ADD CONSTRAINT code_details_created_by_fkey FOREIGN KEY (created_by) REFERENCES usr.users(id);


--
-- Name: code_details code_details_group_code_fkey; Type: FK CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.code_details
    ADD CONSTRAINT code_details_group_code_fkey FOREIGN KEY (group_code) REFERENCES cmm.code_groups(group_code) ON DELETE CASCADE;


--
-- Name: code_details code_details_updated_by_fkey; Type: FK CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.code_details
    ADD CONSTRAINT code_details_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES usr.users(id);


--
-- Name: code_groups code_groups_created_by_fkey; Type: FK CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.code_groups
    ADD CONSTRAINT code_groups_created_by_fkey FOREIGN KEY (created_by) REFERENCES usr.users(id);


--
-- Name: code_groups code_groups_domain_code_fkey; Type: FK CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.code_groups
    ADD CONSTRAINT code_groups_domain_code_fkey FOREIGN KEY (domain_code) REFERENCES sys.system_domains(domain_code) ON UPDATE CASCADE;


--
-- Name: code_groups code_groups_updated_by_fkey; Type: FK CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.code_groups
    ADD CONSTRAINT code_groups_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES usr.users(id);


--
-- Name: notifications notifications_domain_code_fkey; Type: FK CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.notifications
    ADD CONSTRAINT notifications_domain_code_fkey FOREIGN KEY (domain_code) REFERENCES sys.system_domains(domain_code);


--
-- Name: notifications notifications_receiver_user_id_fkey; Type: FK CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.notifications
    ADD CONSTRAINT notifications_receiver_user_id_fkey FOREIGN KEY (receiver_user_id) REFERENCES usr.users(id);


--
-- Name: notifications notifications_sender_user_id_fkey; Type: FK CONSTRAINT; Schema: cmm; Owner: -
--

ALTER TABLE ONLY cmm.notifications
    ADD CONSTRAINT notifications_sender_user_id_fkey FOREIGN KEY (sender_user_id) REFERENCES usr.users(id);


--
-- Name: facilities facilities_category_id_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.facilities
    ADD CONSTRAINT facilities_category_id_fkey FOREIGN KEY (category_id) REFERENCES fac.facility_categories(id);


--
-- Name: facilities facilities_created_by_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.facilities
    ADD CONSTRAINT facilities_created_by_fkey FOREIGN KEY (created_by) REFERENCES usr.users(id);


--
-- Name: facilities facilities_representative_image_id_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.facilities
    ADD CONSTRAINT facilities_representative_image_id_fkey FOREIGN KEY (representative_image_id) REFERENCES cmm.attachments(id) ON DELETE SET NULL;


--
-- Name: facilities facilities_updated_by_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.facilities
    ADD CONSTRAINT facilities_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES usr.users(id);


--
-- Name: facility_categories facility_categories_created_by_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.facility_categories
    ADD CONSTRAINT facility_categories_created_by_fkey FOREIGN KEY (created_by) REFERENCES usr.users(id);


--
-- Name: facility_categories facility_categories_updated_by_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.facility_categories
    ADD CONSTRAINT facility_categories_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES usr.users(id);


--
-- Name: space_functions space_functions_created_by_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.space_functions
    ADD CONSTRAINT space_functions_created_by_fkey FOREIGN KEY (created_by) REFERENCES usr.users(id);


--
-- Name: space_functions space_functions_updated_by_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.space_functions
    ADD CONSTRAINT space_functions_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES usr.users(id);


--
-- Name: space_types space_types_created_by_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.space_types
    ADD CONSTRAINT space_types_created_by_fkey FOREIGN KEY (created_by) REFERENCES usr.users(id);


--
-- Name: space_types space_types_updated_by_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.space_types
    ADD CONSTRAINT space_types_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES usr.users(id);


--
-- Name: spaces spaces_created_by_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.spaces
    ADD CONSTRAINT spaces_created_by_fkey FOREIGN KEY (created_by) REFERENCES usr.users(id);


--
-- Name: spaces spaces_facility_id_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.spaces
    ADD CONSTRAINT spaces_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES fac.facilities(id) ON DELETE CASCADE;


--
-- Name: spaces spaces_org_id_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.spaces
    ADD CONSTRAINT spaces_org_id_fkey FOREIGN KEY (org_id) REFERENCES usr.organizations(id) ON DELETE SET NULL;


--
-- Name: spaces spaces_parent_id_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.spaces
    ADD CONSTRAINT spaces_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES fac.spaces(id) ON DELETE CASCADE;


--
-- Name: spaces spaces_representative_image_id_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.spaces
    ADD CONSTRAINT spaces_representative_image_id_fkey FOREIGN KEY (representative_image_id) REFERENCES cmm.attachments(id) ON DELETE SET NULL;


--
-- Name: spaces spaces_space_function_id_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.spaces
    ADD CONSTRAINT spaces_space_function_id_fkey FOREIGN KEY (space_function_id) REFERENCES fac.space_functions(id);


--
-- Name: spaces spaces_space_type_id_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.spaces
    ADD CONSTRAINT spaces_space_type_id_fkey FOREIGN KEY (space_type_id) REFERENCES fac.space_types(id);


--
-- Name: spaces spaces_updated_by_fkey; Type: FK CONSTRAINT; Schema: fac; Owner: -
--

ALTER TABLE ONLY fac.spaces
    ADD CONSTRAINT spaces_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES usr.users(id);


--
-- Name: roles roles_created_by_fkey; Type: FK CONSTRAINT; Schema: iam; Owner: -
--

ALTER TABLE ONLY iam.roles
    ADD CONSTRAINT roles_created_by_fkey FOREIGN KEY (created_by) REFERENCES usr.users(id);


--
-- Name: roles roles_updated_by_fkey; Type: FK CONSTRAINT; Schema: iam; Owner: -
--

ALTER TABLE ONLY iam.roles
    ADD CONSTRAINT roles_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES usr.users(id);


--
-- Name: user_roles user_roles_assigned_by_fkey; Type: FK CONSTRAINT; Schema: iam; Owner: -
--

ALTER TABLE ONLY iam.user_roles
    ADD CONSTRAINT user_roles_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES usr.users(id) ON DELETE SET NULL;


--
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: iam; Owner: -
--

ALTER TABLE ONLY iam.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES iam.roles(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: iam; Owner: -
--

ALTER TABLE ONLY iam.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES usr.users(id) ON DELETE CASCADE;


--
-- Name: audit_logs audit_logs_actor_user_id_fkey; Type: FK CONSTRAINT; Schema: sys; Owner: -
--

ALTER TABLE ONLY sys.audit_logs
    ADD CONSTRAINT audit_logs_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES usr.users(id);


--
-- Name: audit_logs audit_logs_target_domain_fkey; Type: FK CONSTRAINT; Schema: sys; Owner: -
--

ALTER TABLE ONLY sys.audit_logs
    ADD CONSTRAINT audit_logs_target_domain_fkey FOREIGN KEY (target_domain) REFERENCES sys.system_domains(domain_code);


--
-- Name: sequence_rules sequence_rules_created_by_fkey; Type: FK CONSTRAINT; Schema: sys; Owner: -
--

ALTER TABLE ONLY sys.sequence_rules
    ADD CONSTRAINT sequence_rules_created_by_fkey FOREIGN KEY (created_by) REFERENCES usr.users(id);


--
-- Name: sequence_rules sequence_rules_domain_code_fkey; Type: FK CONSTRAINT; Schema: sys; Owner: -
--

ALTER TABLE ONLY sys.sequence_rules
    ADD CONSTRAINT sequence_rules_domain_code_fkey FOREIGN KEY (domain_code) REFERENCES sys.system_domains(domain_code);


--
-- Name: sequence_rules sequence_rules_updated_by_fkey; Type: FK CONSTRAINT; Schema: sys; Owner: -
--

ALTER TABLE ONLY sys.sequence_rules
    ADD CONSTRAINT sequence_rules_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES usr.users(id);


--
-- Name: system_domains system_domains_created_by_fkey; Type: FK CONSTRAINT; Schema: sys; Owner: -
--

ALTER TABLE ONLY sys.system_domains
    ADD CONSTRAINT system_domains_created_by_fkey FOREIGN KEY (created_by) REFERENCES usr.users(id);


--
-- Name: system_domains system_domains_updated_by_fkey; Type: FK CONSTRAINT; Schema: sys; Owner: -
--

ALTER TABLE ONLY sys.system_domains
    ADD CONSTRAINT system_domains_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES usr.users(id);


--
-- Name: organizations fk_org_created_by; Type: FK CONSTRAINT; Schema: usr; Owner: -
--

ALTER TABLE ONLY usr.organizations
    ADD CONSTRAINT fk_org_created_by FOREIGN KEY (created_by) REFERENCES usr.users(id);


--
-- Name: organizations fk_org_updated_by; Type: FK CONSTRAINT; Schema: usr; Owner: -
--

ALTER TABLE ONLY usr.organizations
    ADD CONSTRAINT fk_org_updated_by FOREIGN KEY (updated_by) REFERENCES usr.users(id);


--
-- Name: users fk_usr_created_by; Type: FK CONSTRAINT; Schema: usr; Owner: -
--

ALTER TABLE ONLY usr.users
    ADD CONSTRAINT fk_usr_created_by FOREIGN KEY (created_by) REFERENCES usr.users(id);


--
-- Name: users fk_usr_profile_image; Type: FK CONSTRAINT; Schema: usr; Owner: -
--

ALTER TABLE ONLY usr.users
    ADD CONSTRAINT fk_usr_profile_image FOREIGN KEY (profile_image_id) REFERENCES cmm.attachments(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: users fk_usr_updated_by; Type: FK CONSTRAINT; Schema: usr; Owner: -
--

ALTER TABLE ONLY usr.users
    ADD CONSTRAINT fk_usr_updated_by FOREIGN KEY (updated_by) REFERENCES usr.users(id);


--
-- Name: organizations organizations_parent_id_fkey; Type: FK CONSTRAINT; Schema: usr; Owner: -
--

ALTER TABLE ONLY usr.organizations
    ADD CONSTRAINT organizations_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES usr.organizations(id);


--
-- Name: users users_org_id_fkey; Type: FK CONSTRAINT; Schema: usr; Owner: -
--

ALTER TABLE ONLY usr.users
    ADD CONSTRAINT users_org_id_fkey FOREIGN KEY (org_id) REFERENCES usr.organizations(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict Td54fw5Y0RIk4mQGWI1jE1q4XLfFdCZObguRK4qkKkD40VVT7HgnEvDZfIUSfuB

