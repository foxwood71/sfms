--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5 (Debian 17.5-1.pgdg120+1)
-- Dumped by pg_dump version 17.5

-- Started on 2025-06-09 21:26:29

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 7 (class 2615 OID 53131)
-- Name: app; Type: SCHEMA; Schema: -; Owner: lims
--

CREATE SCHEMA app;


ALTER SCHEMA app OWNER TO lims;

--
-- TOC entry 8 (class 2615 OID 53132)
-- Name: inv; Type: SCHEMA; Schema: -; Owner: lims
--

CREATE SCHEMA inv;


ALTER SCHEMA inv OWNER TO lims;

--
-- TOC entry 9 (class 2615 OID 53133)
-- Name: lims; Type: SCHEMA; Schema: -; Owner: lims
--

CREATE SCHEMA lims;


ALTER SCHEMA lims OWNER TO lims;

--
-- TOC entry 10 (class 2615 OID 53134)
-- Name: users; Type: SCHEMA; Schema: -; Owner: gumc
--

CREATE SCHEMA users;


ALTER SCHEMA users OWNER TO gumc;

--
-- TOC entry 11 (class 2615 OID 53135)
-- Name: wqm; Type: SCHEMA; Schema: -; Owner: lims
--

CREATE SCHEMA wqm;


ALTER SCHEMA wqm OWNER TO lims;

--
-- TOC entry 4126 (class 0 OID 0)
-- Dependencies: 11
-- Name: SCHEMA wqm; Type: COMMENT; Schema: -; Owner: lims
--

COMMENT ON SCHEMA wqm IS 'Water Quality Management';


--
-- TOC entry 2 (class 3079 OID 53136)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA users;


--
-- TOC entry 4127 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 361 (class 1255 OID 53173)
-- Name: before_insert_sample(); Type: FUNCTION; Schema: lims; Owner: lims
--

CREATE FUNCTION lims.before_insert_sample() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    sample_date CHAR(8) :=  to_char(NEW.sampling_date, 'YYYYMMDD');
  BEGIN
    NEW.code := lpad(LEFT(NEW.order_code::text,4),4,'0') ||
                lpad(NEW.smp_code::text,8,'0') ||
                sample_date ||  
                lpad(RIGHT(NEW.id::text,4),4,'0');
    -- RAISE NOTICE 'Value: %, % ', NEW.id, NEW.code;
    RETURN NEW;
  END; 
$$;


ALTER FUNCTION lims.before_insert_sample() OWNER TO lims;

--
-- TOC entry 362 (class 1255 OID 53174)
-- Name: before_insert_test_request(); Type: FUNCTION; Schema: lims; Owner: lims
--

CREATE FUNCTION lims.before_insert_test_request() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	DECLARE
		request_date CHAR(8) := to_char(NEW.request_date, 'YYYYMMDD');
	BEGIN
		NEW.code := lpad(RIGHT(NEW.project_code::text,4),4,'0') ||
				lpad(RIGHT(NEW.department_code::text,4),4,'0') ||
				request_date ||  
				lpad(RIGHT(NEW.id::text,4),4,'0');
		RETURN NEW;
	END; 
$$;


ALTER FUNCTION lims.before_insert_test_request() OWNER TO lims;

--
-- TOC entry 363 (class 1255 OID 53175)
-- Name: date_serial(date, date); Type: FUNCTION; Schema: lims; Owner: postgres
--

CREATE FUNCTION lims.date_serial(p_start date, p_stop date) RETURNS TABLE(dates date)
    LANGUAGE plpgsql
    AS $$
DECLARE 
-- t_start date;
-- t_stop date;
  t_sql text;
BEGIN
  t_sql = 'SELECT t.ts::date as dates ' ||
          'FROM generate_series(''' || p_start || ''',''' || p_stop || ''', ''1day''::interval) AS t(ts);';
          
  return query execute t_sql;

      
END $$;


ALTER FUNCTION lims.date_serial(p_start date, p_stop date) OWNER TO postgres;

--
-- TOC entry 364 (class 1255 OID 53176)
-- Name: get_container(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_container(integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$

  DECLARE
    _code ALIAS FOR $1;
    _name TEXT;
  BEGIN
  	SELECT INTO _name name FROM lims.tblsample_containers
    WHERE lims.tblsample_containers.code = _code;
    
    RETURN _name;
   END;
 
$_$;


ALTER FUNCTION public.get_container(integer) OWNER TO postgres;

--
-- TOC entry 365 (class 1255 OID 53177)
-- Name: get_parameter(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_parameter(text) RETURNS text
    LANGUAGE plpgsql
    AS $_$

  DECLARE
    _code ALIAS FOR $1;
    _name TEXT;
  BEGIN
  	SELECT INTO _name name FROM lims.tblparameters
    WHERE lims.tblparameters.code = _code;
    
    RETURN _name;
   END;
 
$_$;


ALTER FUNCTION public.get_parameter(text) OWNER TO postgres;

--
-- TOC entry 366 (class 1255 OID 53178)
-- Name: get_plst(json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_plst(json) RETURNS text
    LANGUAGE plpgsql
    AS $_$
  
    DECLARE
        _json_in ALIAS FOR $1;
        _item json;
        _code TEXT;
        _name TEXT;
        _list TEXT; 

    BEGIN
    	_list='';
        -- Parse through Input Json and push each key into hstore 
        FOR _item IN SELECT row_to_json(t.*) FROM json_each_text(_json_in) AS t
        LOOP
            IF _item->>'value' = '1' then 
                SELECT INTO _name name FROM lims.tblparameters as t
                WHERE t.code = _item->>'key';
                _list = _list || _name || ',';
                -- RAISE NOTICE 'Parsing Item % % % %', _list, _name, _item->>'key', _item->>'value';
            END IF;
        END LOOP;
        
        RETURN regexp_replace(_list, ',$', '');
    END;

$_$;


ALTER FUNCTION public.get_plst(json) OWNER TO postgres;

--
-- TOC entry 367 (class 1255 OID 53179)
-- Name: get_site(text); Type: FUNCTION; Schema: public; Owner: lims
--

CREATE FUNCTION public.get_site(text) RETURNS text
    LANGUAGE plpgsql
    AS $_$

  DECLARE
    _smp_code ALIAS FOR $1;
    _site_code TEXT;
    _site_name TEXT;
  BEGIN
  	SELECT INTO _site_code site_code FROM lims.tblsmp 
    WHERE lims.tblsmp.smp_code = _smp_code;
     
    SELECT INTO _site_name site_name FROM lims.tblsite 
    WHERE lims.tblsite.site_code = _site_code;
    RETURN _site_name;
   END;
 
$_$;


ALTER FUNCTION public.get_site(text) OWNER TO lims;

--
-- TOC entry 378 (class 1255 OID 53180)
-- Name: get_smp(text); Type: FUNCTION; Schema: public; Owner: lims
--

CREATE FUNCTION public.get_smp(text) RETURNS text
    LANGUAGE plpgsql
    AS $_$

  DECLARE
    _smp_code ALIAS FOR $1;
    _smp_name TEXT;
  BEGIN
    SELECT INTO _smp_name smp_loc_name FROM lims.tblsmp 
    WHERE lims.tblsmp.smp_code = _smp_code;
    RETURN _smp_name;
   END;
 
$_$;


ALTER FUNCTION public.get_smp(text) OWNER TO lims;

--
-- TOC entry 380 (class 1255 OID 53181)
-- Name: get_type(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_type(integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$

  DECLARE
    _code ALIAS FOR $1;
    _name TEXT;
  BEGIN
  	SELECT INTO _name name FROM lims.tblsample_types
    WHERE lims.tblsample_types.code = _code;
    
    RETURN _name;
   END;
 
$_$;


ALTER FUNCTION public.get_type(integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 223 (class 1259 OID 53182)
-- Name: tblversions; Type: TABLE; Schema: app; Owner: lims
--

CREATE TABLE app.tblversions (
    version_id integer NOT NULL,
    version character varying(50),
    public_date date,
    note text
);


ALTER TABLE app.tblversions OWNER TO lims;

--
-- TOC entry 224 (class 1259 OID 53187)
-- Name: tblversions_version_id_seq; Type: SEQUENCE; Schema: app; Owner: lims
--

CREATE SEQUENCE app.tblversions_version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE app.tblversions_version_id_seq OWNER TO lims;

--
-- TOC entry 4128 (class 0 OID 0)
-- Dependencies: 224
-- Name: tblversions_version_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: lims
--

ALTER SEQUENCE app.tblversions_version_id_seq OWNED BY app.tblversions.version_id;


--
-- TOC entry 225 (class 1259 OID 53188)
-- Name: tblcategories; Type: TABLE; Schema: inv; Owner: lims
--

CREATE TABLE inv.tblcategories (
    category_id integer NOT NULL,
    group_id integer,
    code character varying(4),
    name character varying(50),
    note text,
    registered_date timestamp without time zone DEFAULT now()
);


ALTER TABLE inv.tblcategories OWNER TO lims;

--
-- TOC entry 226 (class 1259 OID 53194)
-- Name: tblcategories_category_id_seq; Type: SEQUENCE; Schema: inv; Owner: lims
--

CREATE SEQUENCE inv.tblcategories_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE inv.tblcategories_category_id_seq OWNER TO lims;

--
-- TOC entry 4129 (class 0 OID 0)
-- Dependencies: 226
-- Name: tblcategories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: inv; Owner: lims
--

ALTER SEQUENCE inv.tblcategories_category_id_seq OWNED BY inv.tblcategories.category_id;


--
-- TOC entry 227 (class 1259 OID 53195)
-- Name: tblimages; Type: TABLE; Schema: inv; Owner: lims
--

CREATE TABLE inv.tblimages (
    image_id integer NOT NULL,
    image bytea,
    registered_date timestamp without time zone DEFAULT now()
);


ALTER TABLE inv.tblimages OWNER TO lims;

--
-- TOC entry 228 (class 1259 OID 53201)
-- Name: tblimages_image_id_seq; Type: SEQUENCE; Schema: inv; Owner: lims
--

CREATE SEQUENCE inv.tblimages_image_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE inv.tblimages_image_id_seq OWNER TO lims;

--
-- TOC entry 4130 (class 0 OID 0)
-- Dependencies: 228
-- Name: tblimages_image_id_seq; Type: SEQUENCE OWNED BY; Schema: inv; Owner: lims
--

ALTER SEQUENCE inv.tblimages_image_id_seq OWNED BY inv.tblimages.image_id;


--
-- TOC entry 229 (class 1259 OID 53202)
-- Name: tblinout; Type: TABLE; Schema: inv; Owner: lims
--

CREATE TABLE inv.tblinout (
    inout_id integer NOT NULL,
    instrument_id integer NOT NULL,
    inout_date timestamp without time zone,
    inout_type integer DEFAULT 0 NOT NULL,
    location_id integer,
    pickup_by character varying(50),
    description text,
    registered_date timestamp without time zone DEFAULT now()
);


ALTER TABLE inv.tblinout OWNER TO lims;

--
-- TOC entry 230 (class 1259 OID 53209)
-- Name: tblinout_inout_id_seq; Type: SEQUENCE; Schema: inv; Owner: lims
--

CREATE SEQUENCE inv.tblinout_inout_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE inv.tblinout_inout_id_seq OWNER TO lims;

--
-- TOC entry 4131 (class 0 OID 0)
-- Dependencies: 230
-- Name: tblinout_inout_id_seq; Type: SEQUENCE OWNED BY; Schema: inv; Owner: lims
--

ALTER SEQUENCE inv.tblinout_inout_id_seq OWNED BY inv.tblinout.inout_id;


--
-- TOC entry 231 (class 1259 OID 53210)
-- Name: tblinstruments; Type: TABLE; Schema: inv; Owner: lims
--

CREATE TABLE inv.tblinstruments (
    instrument_id integer NOT NULL,
    code character varying(20),
    category_id integer,
    name character varying(255),
    purpose_of_use character varying(255),
    maker_id integer,
    model character varying(255),
    serial character varying(255),
    location_id integer,
    status_id integer,
    spec text,
    buyers character varying(50),
    management_classification integer,
    purchase_type character varying(50),
    purchase_date timestamp without time zone,
    purchase_price numeric(19,4),
    usefull_life integer,
    expiration_date timestamp without time zone,
    status_registered_date timestamp without time zone,
    note text,
    image0_id integer,
    image0_title character varying(255),
    image0_registered_date timestamp without time zone,
    image1_id integer,
    image1_title character varying(255),
    image1_registered_date timestamp without time zone,
    image2_id integer,
    image2_title character varying(255),
    image2_registered_date timestamp without time zone,
    image3_id integer,
    image3_title character varying(255),
    image3_registered_date timestamp without time zone,
    registered_date timestamp without time zone DEFAULT now()
);


ALTER TABLE inv.tblinstruments OWNER TO lims;

--
-- TOC entry 232 (class 1259 OID 53216)
-- Name: tblinstruments_instrument_id_seq; Type: SEQUENCE; Schema: inv; Owner: lims
--

CREATE SEQUENCE inv.tblinstruments_instrument_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE inv.tblinstruments_instrument_id_seq OWNER TO lims;

--
-- TOC entry 4132 (class 0 OID 0)
-- Dependencies: 232
-- Name: tblinstruments_instrument_id_seq; Type: SEQUENCE OWNED BY; Schema: inv; Owner: lims
--

ALTER SEQUENCE inv.tblinstruments_instrument_id_seq OWNED BY inv.tblinstruments.instrument_id;


--
-- TOC entry 233 (class 1259 OID 53217)
-- Name: tblinventories; Type: TABLE; Schema: inv; Owner: lims
--

CREATE TABLE inv.tblinventories (
    inventory_id integer NOT NULL,
    code character varying(20),
    category_id integer,
    name character varying(255),
    spec character varying(255),
    counting_unit_id integer,
    maker_id integer,
    discontinued boolean DEFAULT false,
    reorder_level integer,
    instrument_id integer,
    replacement_cycle double precision DEFAULT 0,
    replacement_cycle_unit character varying(255) DEFAULT '시간'::character varying,
    note text,
    image_id integer,
    image_title character varying(255),
    image_path character varying(255),
    image_registered_date timestamp without time zone,
    registered_date timestamp without time zone DEFAULT now()
);


ALTER TABLE inv.tblinventories OWNER TO lims;

--
-- TOC entry 234 (class 1259 OID 53226)
-- Name: tblinventories_inventory_id_seq; Type: SEQUENCE; Schema: inv; Owner: lims
--

CREATE SEQUENCE inv.tblinventories_inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE inv.tblinventories_inventory_id_seq OWNER TO lims;

--
-- TOC entry 4133 (class 0 OID 0)
-- Dependencies: 234
-- Name: tblinventories_inventory_id_seq; Type: SEQUENCE OWNED BY; Schema: inv; Owner: lims
--

ALTER SEQUENCE inv.tblinventories_inventory_id_seq OWNED BY inv.tblinventories.inventory_id;


--
-- TOC entry 235 (class 1259 OID 53227)
-- Name: tblmaintenance; Type: TABLE; Schema: inv; Owner: lims
--

CREATE TABLE inv.tblmaintenance (
    maintenance_id integer NOT NULL,
    instrument_id integer NOT NULL,
    outsourcing boolean DEFAULT false NOT NULL,
    maintenance_type_id integer DEFAULT 0 NOT NULL,
    location_id integer,
    performed_date timestamp without time zone,
    service_provider_id integer,
    performed_by character varying(50),
    cost numeric(19,4) DEFAULT 0,
    nextservice_date timestamp without time zone,
    description text,
    registered_date timestamp without time zone DEFAULT now()
);


ALTER TABLE inv.tblmaintenance OWNER TO lims;

--
-- TOC entry 236 (class 1259 OID 53236)
-- Name: tblmaintenance_maintenance_id_seq; Type: SEQUENCE; Schema: inv; Owner: lims
--

CREATE SEQUENCE inv.tblmaintenance_maintenance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE inv.tblmaintenance_maintenance_id_seq OWNER TO lims;

--
-- TOC entry 4134 (class 0 OID 0)
-- Dependencies: 236
-- Name: tblmaintenance_maintenance_id_seq; Type: SEQUENCE OWNED BY; Schema: inv; Owner: lims
--

ALTER SEQUENCE inv.tblmaintenance_maintenance_id_seq OWNED BY inv.tblmaintenance.maintenance_id;


--
-- TOC entry 237 (class 1259 OID 53237)
-- Name: tbltransactions; Type: TABLE; Schema: inv; Owner: lims
--

CREATE TABLE inv.tbltransactions (
    transaction_id integer NOT NULL,
    date timestamp without time zone,
    type integer DEFAULT 1,
    inventory_id integer NOT NULL,
    supplier_id integer,
    location_id integer,
    amount integer DEFAULT 0,
    unit_price numeric(19,4) DEFAULT 0,
    maintenance_id integer,
    note text,
    registered_date timestamp without time zone DEFAULT now()
);


ALTER TABLE inv.tbltransactions OWNER TO lims;

--
-- TOC entry 238 (class 1259 OID 53246)
-- Name: tbltransactions_transaction_id_seq; Type: SEQUENCE; Schema: inv; Owner: lims
--

CREATE SEQUENCE inv.tbltransactions_transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE inv.tbltransactions_transaction_id_seq OWNER TO lims;

--
-- TOC entry 4135 (class 0 OID 0)
-- Dependencies: 238
-- Name: tbltransactions_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: inv; Owner: lims
--

ALTER SEQUENCE inv.tbltransactions_transaction_id_seq OWNED BY inv.tbltransactions.transaction_id;


--
-- TOC entry 239 (class 1259 OID 53247)
-- Name: tblvendors; Type: TABLE; Schema: inv; Owner: lims
--

CREATE TABLE inv.tblvendors (
    vendor_id integer NOT NULL,
    company_name character varying(50),
    postal_code character varying(7),
    address text,
    contact_name character varying(50),
    contact_title character varying(50),
    contact_hp character varying(50),
    contact_phone character varying(255),
    contact_fax character varying(255),
    contact_email character varying(255),
    webpage text,
    note text,
    registered_date timestamp without time zone DEFAULT now()
);


ALTER TABLE inv.tblvendors OWNER TO lims;

--
-- TOC entry 240 (class 1259 OID 53253)
-- Name: tblvendors_vendor_id_seq; Type: SEQUENCE; Schema: inv; Owner: lims
--

CREATE SEQUENCE inv.tblvendors_vendor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE inv.tblvendors_vendor_id_seq OWNER TO lims;

--
-- TOC entry 4136 (class 0 OID 0)
-- Dependencies: 240
-- Name: tblvendors_vendor_id_seq; Type: SEQUENCE OWNED BY; Schema: inv; Owner: lims
--

ALTER SEQUENCE inv.tblvendors_vendor_id_seq OWNED BY inv.tblvendors.vendor_id;


--
-- TOC entry 241 (class 1259 OID 53254)
-- Name: tblparameters; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblparameters (
    id integer NOT NULL,
    code character varying(4) DEFAULT NULL::character varying,
    name character varying(255) DEFAULT NULL::character varying,
    units character varying(255) DEFAULT NULL::character varying,
    method character varying(255) DEFAULT NULL::character varying,
    detection_limit_low numeric(28,8) DEFAULT NULL::numeric,
    detection_limit_high numeric(28,8) DEFAULT NULL::numeric,
    quantification_limit numeric(28,8) DEFAULT NULL::numeric,
    default_value0 character varying(255) DEFAULT NULL::character varying,
    default_value1 character varying(255) DEFAULT NULL::character varying,
    default_value2 character varying(255) DEFAULT NULL::character varying,
    instrument_id integer,
    instrument_code character varying(255) DEFAULT NULL::character varying,
    price money,
    description text,
    sort_order integer NOT NULL,
    registered_on timestamp without time zone DEFAULT now()
);


ALTER TABLE lims.tblparameters OWNER TO lims;

--
-- TOC entry 242 (class 1259 OID 53271)
-- Name: tblparameters_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblparameters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblparameters_id_seq OWNER TO lims;

--
-- TOC entry 4137 (class 0 OID 0)
-- Dependencies: 242
-- Name: tblparameters_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblparameters_id_seq OWNED BY lims.tblparameters.id;


--
-- TOC entry 243 (class 1259 OID 53272)
-- Name: tblpr_views; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblpr_views (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    user_id integer NOT NULL,
    site_id integer NOT NULL,
    smp_codes text NOT NULL,
    pr_codes text NOT NULL,
    memo text
);


ALTER TABLE lims.tblpr_views OWNER TO lims;

--
-- TOC entry 244 (class 1259 OID 53277)
-- Name: tblpr_views_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblpr_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblpr_views_id_seq OWNER TO lims;

--
-- TOC entry 4138 (class 0 OID 0)
-- Dependencies: 244
-- Name: tblpr_views_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblpr_views_id_seq OWNED BY lims.tblpr_views.id;


--
-- TOC entry 245 (class 1259 OID 53278)
-- Name: tblprojects; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblprojects (
    id integer NOT NULL,
    code character varying(4) DEFAULT NULL::character varying,
    name character varying(255),
    startdate date NOT NULL,
    enddate date NOT NULL,
    description text,
    registered_on timestamp without time zone DEFAULT now()
);


ALTER TABLE lims.tblprojects OWNER TO lims;

--
-- TOC entry 246 (class 1259 OID 53285)
-- Name: tblprojects_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblprojects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblprojects_id_seq OWNER TO lims;

--
-- TOC entry 4139 (class 0 OID 0)
-- Dependencies: 246
-- Name: tblprojects_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblprojects_id_seq OWNED BY lims.tblprojects.id;


--
-- TOC entry 247 (class 1259 OID 53286)
-- Name: tblsample_containers; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblsample_containers (
    id integer NOT NULL,
    code integer NOT NULL,
    name character varying(255) NOT NULL,
    memo text,
    registered_on timestamp without time zone DEFAULT now()
);


ALTER TABLE lims.tblsample_containers OWNER TO lims;

--
-- TOC entry 248 (class 1259 OID 53292)
-- Name: tblsample_containers_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblsample_containers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblsample_containers_id_seq OWNER TO lims;

--
-- TOC entry 4140 (class 0 OID 0)
-- Dependencies: 248
-- Name: tblsample_containers_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblsample_containers_id_seq OWNED BY lims.tblsample_containers.id;


--
-- TOC entry 249 (class 1259 OID 53293)
-- Name: tblsample_types; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblsample_types (
    id integer NOT NULL,
    code integer NOT NULL,
    name character varying(255) NOT NULL,
    memo text,
    registered_on timestamp without time zone DEFAULT now()
);


ALTER TABLE lims.tblsample_types OWNER TO lims;

--
-- TOC entry 250 (class 1259 OID 53299)
-- Name: tblsample_types_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblsample_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblsample_types_id_seq OWNER TO lims;

--
-- TOC entry 4141 (class 0 OID 0)
-- Dependencies: 250
-- Name: tblsample_types_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblsample_types_id_seq OWNED BY lims.tblsample_types.id;


--
-- TOC entry 251 (class 1259 OID 53300)
-- Name: tblsamples; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblsamples (
    id integer NOT NULL,
    code character varying(24),
    order_code character varying(20) NOT NULL,
    order_sht_idx integer,
    smp_code character varying(32) NOT NULL,
    sampling_date date NOT NULL,
    sampling_time time without time zone,
    sampling_weather integer,
    sampler character varying(32) DEFAULT NULL::character varying,
    sample_temp real,
    sample_type integer NOT NULL,
    container integer NOT NULL,
    parameters jsonb NOT NULL,
    amount integer DEFAULT 1 NOT NULL,
    storage_location character varying(255) DEFAULT NULL::character varying,
    analyze_state integer,
    request_date date,
    collected_date date,
    analyze_date date,
    complete_date date,
    disposal_date date,
    storage_period integer,
    collector character varying(255) DEFAULT NULL::character varying,
    manager character varying(255) DEFAULT NULL::character varying,
    memo text,
    registered_on timestamp without time zone DEFAULT now()
);


ALTER TABLE lims.tblsamples OWNER TO lims;

--
-- TOC entry 252 (class 1259 OID 53311)
-- Name: tblsamples_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblsamples_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblsamples_id_seq OWNER TO lims;

--
-- TOC entry 4142 (class 0 OID 0)
-- Dependencies: 252
-- Name: tblsamples_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblsamples_id_seq OWNED BY lims.tblsamples.id;


--
-- TOC entry 253 (class 1259 OID 53312)
-- Name: tblsite; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblsite (
    site_id integer NOT NULL,
    site_code character varying(5),
    site_name character varying(255),
    site_manager character varying(50),
    site_tel character varying(50),
    site_fax character varying(50),
    site_address text,
    memo text,
    sort_order integer,
    is_stp boolean
);


ALTER TABLE lims.tblsite OWNER TO lims;

--
-- TOC entry 254 (class 1259 OID 53317)
-- Name: tblsite_site_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblsite_site_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblsite_site_id_seq OWNER TO lims;

--
-- TOC entry 4143 (class 0 OID 0)
-- Dependencies: 254
-- Name: tblsite_site_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblsite_site_id_seq OWNED BY lims.tblsite.site_id;


--
-- TOC entry 255 (class 1259 OID 53318)
-- Name: tblsmp; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblsmp (
    smp_id integer NOT NULL,
    smp_code character varying(10),
    smp_loc_name character varying(255),
    site_id integer,
    memo text,
    site_code character varying(5)
);


ALTER TABLE lims.tblsmp OWNER TO lims;

--
-- TOC entry 256 (class 1259 OID 53323)
-- Name: tblsmp_smp_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblsmp_smp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblsmp_smp_id_seq OWNER TO lims;

--
-- TOC entry 4144 (class 0 OID 0)
-- Dependencies: 256
-- Name: tblsmp_smp_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblsmp_smp_id_seq OWNED BY lims.tblsmp.smp_id;


--
-- TOC entry 257 (class 1259 OID 53324)
-- Name: tbltest_request_templates; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tbltest_request_templates (
    id integer NOT NULL,
    name character varying(255),
    user_id integer NOT NULL,
    serialized_text text,
    registered_on timestamp without time zone DEFAULT now()
);


ALTER TABLE lims.tbltest_request_templates OWNER TO lims;

--
-- TOC entry 258 (class 1259 OID 53330)
-- Name: tbltest_request_templates_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tbltest_request_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tbltest_request_templates_id_seq OWNER TO lims;

--
-- TOC entry 4145 (class 0 OID 0)
-- Dependencies: 258
-- Name: tbltest_request_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tbltest_request_templates_id_seq OWNED BY lims.tbltest_request_templates.id;


--
-- TOC entry 259 (class 1259 OID 53331)
-- Name: tbltest_requests; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tbltest_requests (
    id integer NOT NULL,
    code character varying(20),
    request_date date NOT NULL,
    project_code character varying(4) NOT NULL,
    department_code character varying(4) NOT NULL,
    user_id integer NOT NULL,
    requester character varying(255) NOT NULL,
    title text NOT NULL,
    label_printed boolean DEFAULT false,
    memo text,
    submitted_on timestamp without time zone,
    registered_on timestamp without time zone DEFAULT now(),
    sampling_date date,
    sampling_time_from time without time zone,
    sampling_time_to time without time zone,
    sampling_weather integer,
    sampler character varying(32) DEFAULT NULL::character varying,
    water_temp real,
    air_temp real
);


ALTER TABLE lims.tbltest_requests OWNER TO lims;

--
-- TOC entry 4146 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN tbltest_requests.sampling_date; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tbltest_requests.sampling_date IS '채수일자';


--
-- TOC entry 4147 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN tbltest_requests.sampling_time_from; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tbltest_requests.sampling_time_from IS '채수시각(시)';


--
-- TOC entry 4148 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN tbltest_requests.sampling_time_to; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tbltest_requests.sampling_time_to IS '채수시각(종)';


--
-- TOC entry 4149 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN tbltest_requests.sampling_weather; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tbltest_requests.sampling_weather IS '날씨';


--
-- TOC entry 4150 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN tbltest_requests.sampler; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tbltest_requests.sampler IS '채수자';


--
-- TOC entry 4151 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN tbltest_requests.water_temp; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tbltest_requests.water_temp IS '수온';


--
-- TOC entry 4152 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN tbltest_requests.air_temp; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tbltest_requests.air_temp IS '기온';


--
-- TOC entry 260 (class 1259 OID 53339)
-- Name: tbltest_requests_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tbltest_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tbltest_requests_id_seq OWNER TO lims;

--
-- TOC entry 4153 (class 0 OID 0)
-- Dependencies: 260
-- Name: tbltest_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tbltest_requests_id_seq OWNED BY lims.tbltest_requests.id;


--
-- TOC entry 261 (class 1259 OID 53340)
-- Name: tblweather; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblweather (
    id integer NOT NULL,
    code integer NOT NULL,
    wx_status character varying(255) NOT NULL,
    memo text,
    registered_on timestamp without time zone DEFAULT now()
);


ALTER TABLE lims.tblweather OWNER TO lims;

--
-- TOC entry 262 (class 1259 OID 53346)
-- Name: tblweather_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblweather_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblweather_id_seq OWNER TO lims;

--
-- TOC entry 4154 (class 0 OID 0)
-- Dependencies: 262
-- Name: tblweather_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblweather_id_seq OWNED BY lims.tblweather.id;


--
-- TOC entry 263 (class 1259 OID 53347)
-- Name: tblws; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblws (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    memo text,
    sort_order integer
);


ALTER TABLE lims.tblws OWNER TO lims;

--
-- TOC entry 264 (class 1259 OID 53352)
-- Name: tblws_bd00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblws_bd00 (
    id integer NOT NULL,
    date date NOT NULL,
    ana_method character varying(255),
    person character varying(255),
    device character varying(255),
    incubator1 character varying(255),
    ref_temp1 character varying(255),
    pv_temp1 real,
    smp_temp real,
    memo text,
    job_position character varying(255) DEFAULT NULL::character varying,
    incubator2 character varying(255) DEFAULT NULL::character varying,
    ref_temp2 character varying(255) DEFAULT NULL::character varying,
    pv_temp2 real
);


ALTER TABLE lims.tblws_bd00 OWNER TO lims;

--
-- TOC entry 265 (class 1259 OID 53360)
-- Name: tblws_bd00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblws_bd00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblws_bd00_id_seq OWNER TO lims;

--
-- TOC entry 4155 (class 0 OID 0)
-- Dependencies: 265
-- Name: tblws_bd00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblws_bd00_id_seq OWNED BY lims.tblws_bd00.id;


--
-- TOC entry 266 (class 1259 OID 53361)
-- Name: tblws_cd00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblws_cd00 (
    id integer NOT NULL,
    date date NOT NULL,
    ana_method character varying(255),
    person character varying(255),
    device character varying(255),
    ref_temp character varying(255),
    pv_temp real,
    memo text,
    job_position character varying(255) DEFAULT NULL::character varying,
    fact_calc character varying(255) DEFAULT NULL::character varying
);


ALTER TABLE lims.tblws_cd00 OWNER TO lims;

--
-- TOC entry 267 (class 1259 OID 53368)
-- Name: tblws_cd00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblws_cd00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblws_cd00_id_seq OWNER TO lims;

--
-- TOC entry 4156 (class 0 OID 0)
-- Dependencies: 267
-- Name: tblws_cd00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblws_cd00_id_seq OWNED BY lims.tblws_cd00.id;


--
-- TOC entry 268 (class 1259 OID 53369)
-- Name: tblws_ec00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblws_ec00 (
    id integer NOT NULL,
    date date NOT NULL,
    ana_method character varying(255),
    person character varying(255),
    device character varying(255),
    incubator character varying(255),
    pv_temp real,
    job_position character varying(255) DEFAULT NULL::character varying,
    media_ref_temp character varying(255) DEFAULT NULL::character varying,
    media_pv_temp real,
    memo text,
    ref_temp character varying(255) DEFAULT NULL::character varying
);


ALTER TABLE lims.tblws_ec00 OWNER TO lims;

--
-- TOC entry 269 (class 1259 OID 53377)
-- Name: tblws_ec00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblws_ec00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblws_ec00_id_seq OWNER TO lims;

--
-- TOC entry 4157 (class 0 OID 0)
-- Dependencies: 269
-- Name: tblws_ec00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblws_ec00_id_seq OWNED BY lims.tblws_ec00.id;


--
-- TOC entry 270 (class 1259 OID 53378)
-- Name: tblws_ec01; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblws_ec01 (
    id integer NOT NULL,
    date date NOT NULL,
    ana_method character varying(255),
    person character varying(255),
    device character varying(255),
    incubator character varying(255),
    pv_temp real,
    job_position character varying(255) DEFAULT NULL::character varying,
    media_ref_temp character varying(255) DEFAULT NULL::character varying,
    media_pv_temp real,
    memo text,
    ref_temp character varying(255) DEFAULT NULL::character varying
);


ALTER TABLE lims.tblws_ec01 OWNER TO lims;

--
-- TOC entry 271 (class 1259 OID 53386)
-- Name: tblws_ec01_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblws_ec01_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblws_ec01_id_seq OWNER TO lims;

--
-- TOC entry 4158 (class 0 OID 0)
-- Dependencies: 271
-- Name: tblws_ec01_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblws_ec01_id_seq OWNED BY lims.tblws_ec01.id;


--
-- TOC entry 272 (class 1259 OID 53387)
-- Name: tblws_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblws_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblws_id_seq OWNER TO lims;

--
-- TOC entry 4159 (class 0 OID 0)
-- Dependencies: 272
-- Name: tblws_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblws_id_seq OWNED BY lims.tblws.id;


--
-- TOC entry 273 (class 1259 OID 53388)
-- Name: tblws_items; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblws_items (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    priority_order integer NOT NULL,
    xls_cell_address character varying(24) NOT NULL,
    name character varying(255) NOT NULL,
    label character varying(255) NOT NULL,
    type integer NOT NULL,
    format character varying(255) NOT NULL,
    unit character varying(8),
    memo text,
    registered_on timestamp without time zone DEFAULT now()
);


ALTER TABLE lims.tblws_items OWNER TO lims;

--
-- TOC entry 274 (class 1259 OID 53394)
-- Name: tblws_items_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblws_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblws_items_id_seq OWNER TO lims;

--
-- TOC entry 4160 (class 0 OID 0)
-- Dependencies: 274
-- Name: tblws_items_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblws_items_id_seq OWNED BY lims.tblws_items.id;


--
-- TOC entry 275 (class 1259 OID 53395)
-- Name: tblws_kt00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblws_kt00 (
    id integer NOT NULL,
    date date NOT NULL,
    ana_method character varying(255),
    person character varying(255),
    device character varying(255),
    memo text,
    job_position character varying(255) DEFAULT NULL::character varying,
    heating character varying(255) DEFAULT NULL::character varying,
    range_tn character varying(255) DEFAULT NULL::character varying,
    range_tp character varying(255) DEFAULT NULL::character varying
);


ALTER TABLE lims.tblws_kt00 OWNER TO lims;

--
-- TOC entry 276 (class 1259 OID 53404)
-- Name: tblws_kt00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblws_kt00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblws_kt00_id_seq OWNER TO lims;

--
-- TOC entry 4161 (class 0 OID 0)
-- Dependencies: 276
-- Name: tblws_kt00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblws_kt00_id_seq OWNED BY lims.tblws_kt00.id;


--
-- TOC entry 277 (class 1259 OID 53405)
-- Name: tblws_ml00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblws_ml00 (
    id integer NOT NULL,
    date date NOT NULL,
    ana_method character varying(255),
    person character varying(255),
    device character varying(255),
    dryer character varying(255),
    ref_temp character varying(255),
    pv_temp real,
    pv_humidity real,
    memo text,
    job_position character varying(255) DEFAULT NULL::character varying
);


ALTER TABLE lims.tblws_ml00 OWNER TO lims;

--
-- TOC entry 278 (class 1259 OID 53411)
-- Name: tblws_ml00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblws_ml00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblws_ml00_id_seq OWNER TO lims;

--
-- TOC entry 4162 (class 0 OID 0)
-- Dependencies: 278
-- Name: tblws_ml00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblws_ml00_id_seq OWNED BY lims.tblws_ml00.id;


--
-- TOC entry 279 (class 1259 OID 53412)
-- Name: tblws_nn00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblws_nn00 (
    id integer NOT NULL,
    date date NOT NULL,
    ana_method character varying(255),
    person character varying(255),
    device character varying(255),
    range_nh3_h character varying(255),
    range_nh3_l character varying(255),
    range_no3_h character varying(255),
    range_po4_l character varying(255),
    memo text,
    job_position character varying(255) DEFAULT NULL::character varying,
    heating character varying(255) DEFAULT NULL::character varying
);


ALTER TABLE lims.tblws_nn00 OWNER TO lims;

--
-- TOC entry 280 (class 1259 OID 53419)
-- Name: tblws_nn00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblws_nn00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblws_nn00_id_seq OWNER TO lims;

--
-- TOC entry 4163 (class 0 OID 0)
-- Dependencies: 280
-- Name: tblws_nn00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblws_nn00_id_seq OWNED BY lims.tblws_nn00.id;


--
-- TOC entry 281 (class 1259 OID 53420)
-- Name: tblws_np00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblws_np00 (
    id integer NOT NULL,
    date date NOT NULL,
    ana_method character varying(255),
    person character varying(255),
    device character varying(255),
    pretreatment_temp real DEFAULT 0,
    pretreatment_ps real DEFAULT 0,
    range_tn character varying(255),
    range_tp character varying(255) DEFAULT 0,
    tn_cal_curve_a real,
    tn_cal_curve_b real,
    tn_cal_curve_r real,
    tp_cal_curve_a real,
    tp_cal_curve_b real,
    tp_cal_curve_r real,
    memo text,
    job_position character varying(255) DEFAULT NULL::character varying
);


ALTER TABLE lims.tblws_np00 OWNER TO lims;

--
-- TOC entry 282 (class 1259 OID 53429)
-- Name: tblws_np00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblws_np00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblws_np00_id_seq OWNER TO lims;

--
-- TOC entry 4164 (class 0 OID 0)
-- Dependencies: 282
-- Name: tblws_np00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblws_np00_id_seq OWNED BY lims.tblws_np00.id;


--
-- TOC entry 283 (class 1259 OID 53430)
-- Name: tblws_ss00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblws_ss00 (
    id integer NOT NULL,
    date date NOT NULL,
    ana_method character varying(255),
    person character varying(255),
    device character varying(255),
    dryer character varying(255),
    ref_temp character varying(255),
    pv_temp real,
    pv_humidity real,
    memo text,
    job_position character varying(255) DEFAULT NULL::character varying
);


ALTER TABLE lims.tblws_ss00 OWNER TO lims;

--
-- TOC entry 284 (class 1259 OID 53436)
-- Name: tblws_ss00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblws_ss00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblws_ss00_id_seq OWNER TO lims;

--
-- TOC entry 4165 (class 0 OID 0)
-- Dependencies: 284
-- Name: tblws_ss00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblws_ss00_id_seq OWNED BY lims.tblws_ss00.id;


--
-- TOC entry 285 (class 1259 OID 53437)
-- Name: tblws_tc00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblws_tc00 (
    id integer NOT NULL,
    date date NOT NULL,
    ana_method character varying(255),
    job_position character varying(255),
    person character varying(255),
    device character varying(255),
    incubator character varying(255),
    pretreatment_temp character varying(255),
    pretreatment_ps character varying(255),
    range_npoc character varying(255),
    range_tcic character varying(255),
    memo text
);


ALTER TABLE lims.tblws_tc00 OWNER TO lims;

--
-- TOC entry 286 (class 1259 OID 53442)
-- Name: tblws_tc00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblws_tc00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblws_tc00_id_seq OWNER TO lims;

--
-- TOC entry 4166 (class 0 OID 0)
-- Dependencies: 286
-- Name: tblws_tc00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblws_tc00_id_seq OWNED BY lims.tblws_tc00.id;


--
-- TOC entry 287 (class 1259 OID 53443)
-- Name: tblws_ts00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblws_ts00 (
    id integer NOT NULL,
    date date NOT NULL,
    ana_method character varying(255),
    person character varying(255),
    device character varying(255),
    dryer character varying(255),
    ref_temp character varying(255),
    pv_temp real,
    memo text,
    job_position character varying(255) DEFAULT NULL::character varying
);


ALTER TABLE lims.tblws_ts00 OWNER TO lims;

--
-- TOC entry 288 (class 1259 OID 53449)
-- Name: tblws_ts00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblws_ts00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblws_ts00_id_seq OWNER TO lims;

--
-- TOC entry 4167 (class 0 OID 0)
-- Dependencies: 288
-- Name: tblws_ts00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblws_ts00_id_seq OWNED BY lims.tblws_ts00.id;


--
-- TOC entry 289 (class 1259 OID 53450)
-- Name: tblwsds_bd00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblwsds_bd00 (
    id integer NOT NULL,
    ws_id integer NOT NULL,
    smp_date date,
    smp_code character varying(10),
    site_code character varying(5),
    dilution_rate real,
    smp_vol real,
    smp_d1 real,
    smp_d2 real,
    consumption_rate real,
    ana_val real,
    bd0 real,
    memo text,
    confirm_date date,
    confirm boolean DEFAULT false,
    sample_code character varying(24),
    chlorine real,
    ph real
);


ALTER TABLE lims.tblwsds_bd00 OWNER TO lims;

--
-- TOC entry 4168 (class 0 OID 0)
-- Dependencies: 289
-- Name: COLUMN tblwsds_bd00.sample_code; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_bd00.sample_code IS '시료번호';


--
-- TOC entry 4169 (class 0 OID 0)
-- Dependencies: 289
-- Name: COLUMN tblwsds_bd00.chlorine; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_bd00.chlorine IS '잔류염소';


--
-- TOC entry 4170 (class 0 OID 0)
-- Dependencies: 289
-- Name: COLUMN tblwsds_bd00.ph; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_bd00.ph IS '수소이온농도';


--
-- TOC entry 290 (class 1259 OID 53456)
-- Name: tblwsds_bd00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblwsds_bd00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblwsds_bd00_id_seq OWNER TO lims;

--
-- TOC entry 4171 (class 0 OID 0)
-- Dependencies: 290
-- Name: tblwsds_bd00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblwsds_bd00_id_seq OWNED BY lims.tblwsds_bd00.id;


--
-- TOC entry 291 (class 1259 OID 53457)
-- Name: tblwsds_cd00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblwsds_cd00 (
    id integer NOT NULL,
    ws_id integer NOT NULL,
    smp_date date,
    smp_code character varying(10),
    site_code character varying(5),
    smp_vol real,
    blank real,
    consumption_rate real,
    factor real,
    cd0 real,
    memo text,
    confirm_date date,
    confirm boolean DEFAULT false,
    sample_code character varying(24),
    dilution_rate real,
    chlorine real,
    kmno4 real
);


ALTER TABLE lims.tblwsds_cd00 OWNER TO lims;

--
-- TOC entry 4172 (class 0 OID 0)
-- Dependencies: 291
-- Name: COLUMN tblwsds_cd00.consumption_rate; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_cd00.consumption_rate IS '기존 KMnO4(%)';


--
-- TOC entry 4173 (class 0 OID 0)
-- Dependencies: 291
-- Name: COLUMN tblwsds_cd00.factor; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_cd00.factor IS '기존 water bath';


--
-- TOC entry 4174 (class 0 OID 0)
-- Dependencies: 291
-- Name: COLUMN tblwsds_cd00.sample_code; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_cd00.sample_code IS '시료번호';


--
-- TOC entry 4175 (class 0 OID 0)
-- Dependencies: 291
-- Name: COLUMN tblwsds_cd00.chlorine; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_cd00.chlorine IS '잔류염소';


--
-- TOC entry 4176 (class 0 OID 0)
-- Dependencies: 291
-- Name: COLUMN tblwsds_cd00.kmno4; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_cd00.kmno4 IS 'KMnO4 ml';


--
-- TOC entry 292 (class 1259 OID 53463)
-- Name: tblwsds_cd00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblwsds_cd00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblwsds_cd00_id_seq OWNER TO lims;

--
-- TOC entry 4177 (class 0 OID 0)
-- Dependencies: 292
-- Name: tblwsds_cd00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblwsds_cd00_id_seq OWNED BY lims.tblwsds_cd00.id;


--
-- TOC entry 293 (class 1259 OID 53464)
-- Name: tblwsds_ec00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblwsds_ec00 (
    id integer NOT NULL,
    ws_id integer NOT NULL,
    smp_date date,
    smp_code character varying(10),
    site_code character varying(5),
    dilution_rate_1st real,
    col_count_1st real,
    dilution_rate_2nd real,
    col_count_2nd real,
    dilution_rate_3rd real,
    col_count_3rd real,
    dilution_rate_4th real,
    col_count_4th real,
    ec0 real,
    memo text,
    confirm_date date,
    confirm boolean DEFAULT false,
    sample_code character varying(24),
    chlorine real
);


ALTER TABLE lims.tblwsds_ec00 OWNER TO lims;

--
-- TOC entry 4178 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN tblwsds_ec00.sample_code; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_ec00.sample_code IS '시료번호';


--
-- TOC entry 4179 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN tblwsds_ec00.chlorine; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_ec00.chlorine IS '잔류염소';


--
-- TOC entry 294 (class 1259 OID 53470)
-- Name: tblwsds_ec00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblwsds_ec00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblwsds_ec00_id_seq OWNER TO lims;

--
-- TOC entry 4180 (class 0 OID 0)
-- Dependencies: 294
-- Name: tblwsds_ec00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblwsds_ec00_id_seq OWNED BY lims.tblwsds_ec00.id;


--
-- TOC entry 295 (class 1259 OID 53471)
-- Name: tblwsds_ec01; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblwsds_ec01 (
    id integer NOT NULL,
    ws_id integer NOT NULL,
    smp_date date,
    smp_code character varying(10),
    site_code character varying(5),
    dilution_rate_1st real,
    col_count_1st real,
    dilution_rate_2nd real,
    col_count_2nd real,
    dilution_rate_3rd real,
    col_count_3rd real,
    ec1 real,
    memo text,
    confirm_date date,
    confirm boolean DEFAULT false,
    sample_code character varying(24),
    dilution_rate_4th real,
    col_count_4th real,
    chlorine real
);


ALTER TABLE lims.tblwsds_ec01 OWNER TO lims;

--
-- TOC entry 4181 (class 0 OID 0)
-- Dependencies: 295
-- Name: COLUMN tblwsds_ec01.sample_code; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_ec01.sample_code IS '시료번호';


--
-- TOC entry 296 (class 1259 OID 53477)
-- Name: tblwsds_ec01_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblwsds_ec01_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblwsds_ec01_id_seq OWNER TO lims;

--
-- TOC entry 4182 (class 0 OID 0)
-- Dependencies: 296
-- Name: tblwsds_ec01_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblwsds_ec01_id_seq OWNED BY lims.tblwsds_ec01.id;


--
-- TOC entry 297 (class 1259 OID 53478)
-- Name: tblwsds_items; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblwsds_items (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    priority_order integer NOT NULL,
    name character varying(255) NOT NULL,
    label character varying(255) NOT NULL,
    type integer NOT NULL,
    format character varying(255) NOT NULL,
    unit character varying(8),
    lo_rang_sym character varying(8),
    lo_rang_val integer DEFAULT '-1'::integer,
    hi_rang_sym character varying(8),
    hi_rang_val integer DEFAULT '-9'::integer,
    pr_code character varying(255),
    memo text,
    registered_on timestamp without time zone DEFAULT now()
);


ALTER TABLE lims.tblwsds_items OWNER TO lims;

--
-- TOC entry 298 (class 1259 OID 53486)
-- Name: tblwsds_items_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblwsds_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblwsds_items_id_seq OWNER TO lims;

--
-- TOC entry 4183 (class 0 OID 0)
-- Dependencies: 298
-- Name: tblwsds_items_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblwsds_items_id_seq OWNED BY lims.tblwsds_items.id;


--
-- TOC entry 299 (class 1259 OID 53487)
-- Name: tblwsds_kt00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblwsds_kt00 (
    id integer NOT NULL,
    ws_id integer NOT NULL,
    smp_date date,
    smp_code character varying(10),
    site_code character varying(5),
    dilution_rate_tp real,
    tp1 real,
    dilution_rate_tn real,
    tn1 real,
    memo text,
    confirm_date date,
    confirm boolean DEFAULT false,
    sample_code character varying(24),
    dilutions_tp real,
    dilutions_tn real
);


ALTER TABLE lims.tblwsds_kt00 OWNER TO lims;

--
-- TOC entry 4184 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN tblwsds_kt00.sample_code; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_kt00.sample_code IS '시료번호';


--
-- TOC entry 300 (class 1259 OID 53493)
-- Name: tblwsds_kt00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblwsds_kt00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblwsds_kt00_id_seq OWNER TO lims;

--
-- TOC entry 4185 (class 0 OID 0)
-- Dependencies: 300
-- Name: tblwsds_kt00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblwsds_kt00_id_seq OWNED BY lims.tblwsds_kt00.id;


--
-- TOC entry 301 (class 1259 OID 53494)
-- Name: tblwsds_ml00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblwsds_ml00 (
    id integer NOT NULL,
    ws_id integer NOT NULL,
    smp_date date,
    smp_code character varying(10),
    site_code character varying(5),
    sv0 real,
    smp_vol real,
    weight_before_dry real,
    weight_after_dry real,
    weight_difference real,
    ml0 real,
    memo text,
    confirm_date date,
    confirm boolean DEFAULT false,
    sample_code character varying(24)
);


ALTER TABLE lims.tblwsds_ml00 OWNER TO lims;

--
-- TOC entry 4186 (class 0 OID 0)
-- Dependencies: 301
-- Name: COLUMN tblwsds_ml00.sample_code; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_ml00.sample_code IS '시료번호';


--
-- TOC entry 302 (class 1259 OID 53500)
-- Name: tblwsds_ml00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblwsds_ml00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblwsds_ml00_id_seq OWNER TO lims;

--
-- TOC entry 4187 (class 0 OID 0)
-- Dependencies: 302
-- Name: tblwsds_ml00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblwsds_ml00_id_seq OWNED BY lims.tblwsds_ml00.id;


--
-- TOC entry 303 (class 1259 OID 53501)
-- Name: tblwsds_nn00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblwsds_nn00 (
    id integer NOT NULL,
    ws_id integer NOT NULL,
    smp_date date,
    smp_code character varying(255),
    site_code character varying(255),
    dilution_rate_nh3 real,
    nh0 real,
    dilution_rate_no3 real,
    no0 real,
    dilution_rate_po4 real,
    po0 real,
    memo text,
    confirm_date date,
    confirm boolean DEFAULT false,
    sample_code character varying(24),
    dilutions_nh3 real,
    dilutions_no3 real,
    dilutions_po4 real
);


ALTER TABLE lims.tblwsds_nn00 OWNER TO lims;

--
-- TOC entry 4188 (class 0 OID 0)
-- Dependencies: 303
-- Name: COLUMN tblwsds_nn00.sample_code; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_nn00.sample_code IS '시료번호';


--
-- TOC entry 304 (class 1259 OID 53507)
-- Name: tblwsds_nn00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblwsds_nn00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblwsds_nn00_id_seq OWNER TO lims;

--
-- TOC entry 4189 (class 0 OID 0)
-- Dependencies: 304
-- Name: tblwsds_nn00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblwsds_nn00_id_seq OWNED BY lims.tblwsds_nn00.id;


--
-- TOC entry 305 (class 1259 OID 53508)
-- Name: tblwsds_np00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblwsds_np00 (
    id integer NOT NULL,
    ws_id integer NOT NULL,
    smp_date date,
    smp_code character varying(10),
    site_code character varying(5),
    dilution_rate_tn real,
    dilutions_tn real,
    tn0 real,
    dilutions_tp real,
    tp0 real,
    memo text,
    confirm_date date,
    confirm boolean DEFAULT false,
    dilution_rate_tp real,
    sample_code character varying(24),
    ph real
);


ALTER TABLE lims.tblwsds_np00 OWNER TO lims;

--
-- TOC entry 4190 (class 0 OID 0)
-- Dependencies: 305
-- Name: COLUMN tblwsds_np00.sample_code; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_np00.sample_code IS '시료번호';


--
-- TOC entry 306 (class 1259 OID 53514)
-- Name: tblwsds_np00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblwsds_np00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblwsds_np00_id_seq OWNER TO lims;

--
-- TOC entry 4191 (class 0 OID 0)
-- Dependencies: 306
-- Name: tblwsds_np00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblwsds_np00_id_seq OWNED BY lims.tblwsds_np00.id;


--
-- TOC entry 307 (class 1259 OID 53515)
-- Name: tblwsds_ss00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblwsds_ss00 (
    id integer NOT NULL,
    ws_id integer NOT NULL,
    smp_date date,
    smp_code character varying(10),
    site_code character varying(5),
    dilution_rate real,
    smp_vol real,
    weight_before_dry real,
    weight_after_dry real,
    weight_difference real,
    ss0 real,
    memo text,
    confirm_date date,
    confirm boolean DEFAULT false,
    sample_code character varying(24)
);


ALTER TABLE lims.tblwsds_ss00 OWNER TO lims;

--
-- TOC entry 4192 (class 0 OID 0)
-- Dependencies: 307
-- Name: COLUMN tblwsds_ss00.sample_code; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_ss00.sample_code IS '시료번호';


--
-- TOC entry 308 (class 1259 OID 53521)
-- Name: tblwsds_ss00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblwsds_ss00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblwsds_ss00_id_seq OWNER TO lims;

--
-- TOC entry 4193 (class 0 OID 0)
-- Dependencies: 308
-- Name: tblwsds_ss00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblwsds_ss00_id_seq OWNED BY lims.tblwsds_ss00.id;


--
-- TOC entry 309 (class 1259 OID 53522)
-- Name: tblwsds_tc00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblwsds_tc00 (
    id integer NOT NULL,
    ws_id integer NOT NULL,
    smp_date date,
    smp_code character varying(10),
    site_code character varying(5),
    dilution_rate real,
    tc_concns real,
    ic_concns real,
    npoc_concns real,
    tc0 real,
    memo text,
    confirm_date date,
    confirm boolean DEFAULT false,
    sample_code character varying(24)
);


ALTER TABLE lims.tblwsds_tc00 OWNER TO lims;

--
-- TOC entry 4194 (class 0 OID 0)
-- Dependencies: 309
-- Name: COLUMN tblwsds_tc00.tc_concns; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_tc00.tc_concns IS 'TC측정농도';


--
-- TOC entry 4195 (class 0 OID 0)
-- Dependencies: 309
-- Name: COLUMN tblwsds_tc00.ic_concns; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_tc00.ic_concns IS 'IC측정농도';


--
-- TOC entry 4196 (class 0 OID 0)
-- Dependencies: 309
-- Name: COLUMN tblwsds_tc00.npoc_concns; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_tc00.npoc_concns IS 'NPOC측정농도';


--
-- TOC entry 4197 (class 0 OID 0)
-- Dependencies: 309
-- Name: COLUMN tblwsds_tc00.sample_code; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_tc00.sample_code IS '시료번호';


--
-- TOC entry 310 (class 1259 OID 53528)
-- Name: tblwsds_tc00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblwsds_tc00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblwsds_tc00_id_seq OWNER TO lims;

--
-- TOC entry 4198 (class 0 OID 0)
-- Dependencies: 310
-- Name: tblwsds_tc00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblwsds_tc00_id_seq OWNED BY lims.tblwsds_tc00.id;


--
-- TOC entry 311 (class 1259 OID 53529)
-- Name: tblwsds_ts00; Type: TABLE; Schema: lims; Owner: lims
--

CREATE TABLE lims.tblwsds_ts00 (
    id integer NOT NULL,
    ws_id integer NOT NULL,
    smp_date date,
    smp_code character varying(10),
    site_code character varying(5),
    tare_weight real,
    smp_vol real,
    gross_weight real,
    weight_after_dry real,
    weight_after_burn real,
    mc0 real,
    ts0 real,
    fs0 real,
    vs0 real,
    memo text,
    confirm_date date,
    confirm boolean DEFAULT false,
    sample_code character varying(24)
);


ALTER TABLE lims.tblwsds_ts00 OWNER TO lims;

--
-- TOC entry 4199 (class 0 OID 0)
-- Dependencies: 311
-- Name: COLUMN tblwsds_ts00.sample_code; Type: COMMENT; Schema: lims; Owner: lims
--

COMMENT ON COLUMN lims.tblwsds_ts00.sample_code IS '시료번호';


--
-- TOC entry 312 (class 1259 OID 53535)
-- Name: tblwsds_ts00_id_seq; Type: SEQUENCE; Schema: lims; Owner: lims
--

CREATE SEQUENCE lims.tblwsds_ts00_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE lims.tblwsds_ts00_id_seq OWNER TO lims;

--
-- TOC entry 4200 (class 0 OID 0)
-- Dependencies: 312
-- Name: tblwsds_ts00_id_seq; Type: SEQUENCE OWNED BY; Schema: lims; Owner: lims
--

ALTER SEQUENCE lims.tblwsds_ts00_id_seq OWNED BY lims.tblwsds_ts00.id;


--
-- TOC entry 313 (class 1259 OID 53536)
-- Name: tbldepartments; Type: TABLE; Schema: users; Owner: gumc
--

CREATE TABLE users.tbldepartments (
    department_id integer NOT NULL,
    code character varying(4),
    name character varying(50) NOT NULL,
    note text,
    sort_order integer,
    registered_date timestamp without time zone DEFAULT now(),
    site_list text
);


ALTER TABLE users.tbldepartments OWNER TO gumc;

--
-- TOC entry 4201 (class 0 OID 0)
-- Dependencies: 313
-- Name: COLUMN tbldepartments.site_list; Type: COMMENT; Schema: users; Owner: gumc
--

COMMENT ON COLUMN users.tbldepartments.site_list IS '관할 처리시설 목록';


--
-- TOC entry 314 (class 1259 OID 53542)
-- Name: tbldepartments_department_id_seq; Type: SEQUENCE; Schema: users; Owner: gumc
--

CREATE SEQUENCE users.tbldepartments_department_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE users.tbldepartments_department_id_seq OWNER TO gumc;

--
-- TOC entry 4202 (class 0 OID 0)
-- Dependencies: 314
-- Name: tbldepartments_department_id_seq; Type: SEQUENCE OWNED BY; Schema: users; Owner: gumc
--

ALTER SEQUENCE users.tbldepartments_department_id_seq OWNED BY users.tbldepartments.department_id;


--
-- TOC entry 315 (class 1259 OID 53543)
-- Name: tblusers; Type: TABLE; Schema: users; Owner: gumc
--

CREATE TABLE users.tblusers (
    user_id integer NOT NULL,
    name character varying(25),
    password character varying(255),
    department_id integer,
    roll integer DEFAULT 100 NOT NULL,
    code character varying(16)
);


ALTER TABLE users.tblusers OWNER TO gumc;

--
-- TOC entry 316 (class 1259 OID 53547)
-- Name: tblusers_user_id_seq; Type: SEQUENCE; Schema: users; Owner: gumc
--

CREATE SEQUENCE users.tblusers_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE users.tblusers_user_id_seq OWNER TO gumc;

--
-- TOC entry 4203 (class 0 OID 0)
-- Dependencies: 316
-- Name: tblusers_user_id_seq; Type: SEQUENCE OWNED BY; Schema: users; Owner: gumc
--

ALTER SEQUENCE users.tblusers_user_id_seq OWNED BY users.tblusers.user_id;


--
-- TOC entry 317 (class 1259 OID 53548)
-- Name: tbllines; Type: TABLE; Schema: wqm; Owner: lims
--

CREATE TABLE wqm.tbllines (
    id integer NOT NULL,
    code character varying(10) NOT NULL,
    name character varying(255) NOT NULL,
    capacity integer DEFAULT 0 NOT NULL,
    plant_code character varying(5) NOT NULL,
    memo text,
    sort_order integer,
    registered_on timestamp without time zone DEFAULT now()
);


ALTER TABLE wqm.tbllines OWNER TO lims;

--
-- TOC entry 4204 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN tbllines.id; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tbllines.id IS '계열ID';


--
-- TOC entry 4205 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN tbllines.code; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tbllines.code IS '계열CODE';


--
-- TOC entry 4206 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN tbllines.name; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tbllines.name IS '계열명';


--
-- TOC entry 4207 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN tbllines.capacity; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tbllines.capacity IS '계열 처리용량';


--
-- TOC entry 4208 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN tbllines.plant_code; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tbllines.plant_code IS '처리시설CODE';


--
-- TOC entry 318 (class 1259 OID 53555)
-- Name: tbllines_id_seq; Type: SEQUENCE; Schema: wqm; Owner: lims
--

CREATE SEQUENCE wqm.tbllines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE wqm.tbllines_id_seq OWNER TO lims;

--
-- TOC entry 4209 (class 0 OID 0)
-- Dependencies: 318
-- Name: tbllines_id_seq; Type: SEQUENCE OWNED BY; Schema: wqm; Owner: lims
--

ALTER SEQUENCE wqm.tbllines_id_seq OWNED BY wqm.tbllines.id;


--
-- TOC entry 319 (class 1259 OID 53556)
-- Name: tblop_lines; Type: TABLE; Schema: wqm; Owner: lims
--

CREATE TABLE wqm.tblop_lines (
    id integer NOT NULL,
    op_plant_id integer NOT NULL,
    line_code character varying(10) NOT NULL,
    op_date date DEFAULT now() NOT NULL,
    influent integer DEFAULT 0 NOT NULL,
    rejectwater integer DEFAULT 0 NOT NULL,
    sv30 real,
    mlss integer,
    svi integer,
    fm_rate real,
    rt_mlss integer,
    ex_sluge integer,
    srt real,
    rt_sluge integer,
    mldo real,
    wt real,
    hrt integer,
    moisture real,
    memo text,
    registered_on timestamp without time zone DEFAULT now()
);


ALTER TABLE wqm.tblop_lines OWNER TO lims;

--
-- TOC entry 4210 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.id; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.id IS '처리시설운영id';


--
-- TOC entry 4211 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.line_code; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.line_code IS '계열CODE';


--
-- TOC entry 4212 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.op_date; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.op_date IS '일자';


--
-- TOC entry 4213 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.influent; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.influent IS '유입량';


--
-- TOC entry 4214 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.rejectwater; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.rejectwater IS '반류량';


--
-- TOC entry 4215 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.sv30; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.sv30 IS '30분후 Sludge Volume';


--
-- TOC entry 4216 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.mlss; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.mlss IS '폭기조 내의 현탁물질 농도';


--
-- TOC entry 4217 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.svi; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.svi IS 'Sludge Volume index';


--
-- TOC entry 4218 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.fm_rate; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.fm_rate IS '탄소 영양물과 활성 미생물의 비율';


--
-- TOC entry 4219 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.rt_mlss; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.rt_mlss IS '반송MLSS';


--
-- TOC entry 4220 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.ex_sluge; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.ex_sluge IS '잉여슬러지';


--
-- TOC entry 4221 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.srt; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.srt IS '고형물 체류시간';


--
-- TOC entry 4222 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.rt_sluge; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.rt_sluge IS '반송량';


--
-- TOC entry 4223 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.mldo; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.mldo IS '반응조내 용존산소';


--
-- TOC entry 4224 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.wt; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.wt IS '수온';


--
-- TOC entry 4225 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.hrt; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.hrt IS '수리학적인 체류시간';


--
-- TOC entry 4226 (class 0 OID 0)
-- Dependencies: 319
-- Name: COLUMN tblop_lines.moisture; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_lines.moisture IS '함수율';


--
-- TOC entry 320 (class 1259 OID 53565)
-- Name: tblop_lines_id_seq; Type: SEQUENCE; Schema: wqm; Owner: lims
--

CREATE SEQUENCE wqm.tblop_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE wqm.tblop_lines_id_seq OWNER TO lims;

--
-- TOC entry 4227 (class 0 OID 0)
-- Dependencies: 320
-- Name: tblop_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: wqm; Owner: lims
--

ALTER SEQUENCE wqm.tblop_lines_id_seq OWNED BY wqm.tblop_lines.id;


--
-- TOC entry 321 (class 1259 OID 53566)
-- Name: tblop_plants; Type: TABLE; Schema: wqm; Owner: lims
--

CREATE TABLE wqm.tblop_plants (
    id integer NOT NULL,
    plant_code character varying(5) NOT NULL,
    op_date date DEFAULT now() NOT NULL,
    influent integer DEFAULT 0 NOT NULL,
    effluent integer DEFAULT 0 NOT NULL,
    offload integer DEFAULT 0 NOT NULL,
    rainfall integer DEFAULT 0 NOT NULL,
    influent_ph real DEFAULT 0.0 NOT NULL,
    effluent_ph real DEFAULT 0.0 NOT NULL,
    memo text,
    registered_on timestamp without time zone DEFAULT now()
);


ALTER TABLE wqm.tblop_plants OWNER TO lims;

--
-- TOC entry 4228 (class 0 OID 0)
-- Dependencies: 321
-- Name: COLUMN tblop_plants.id; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_plants.id IS '처리시설ID';


--
-- TOC entry 4229 (class 0 OID 0)
-- Dependencies: 321
-- Name: COLUMN tblop_plants.plant_code; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_plants.plant_code IS '처리시설CODE';


--
-- TOC entry 4230 (class 0 OID 0)
-- Dependencies: 321
-- Name: COLUMN tblop_plants.op_date; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_plants.op_date IS '일자';


--
-- TOC entry 4231 (class 0 OID 0)
-- Dependencies: 321
-- Name: COLUMN tblop_plants.influent; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_plants.influent IS '총유입량';


--
-- TOC entry 4232 (class 0 OID 0)
-- Dependencies: 321
-- Name: COLUMN tblop_plants.effluent; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_plants.effluent IS '총방류량';


--
-- TOC entry 4233 (class 0 OID 0)
-- Dependencies: 321
-- Name: COLUMN tblop_plants.offload; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_plants.offload IS '부하분산-연계';


--
-- TOC entry 4234 (class 0 OID 0)
-- Dependencies: 321
-- Name: COLUMN tblop_plants.rainfall; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_plants.rainfall IS '강우량';


--
-- TOC entry 4235 (class 0 OID 0)
-- Dependencies: 321
-- Name: COLUMN tblop_plants.influent_ph; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_plants.influent_ph IS '유입하수 수소이온 농도';


--
-- TOC entry 4236 (class 0 OID 0)
-- Dependencies: 321
-- Name: COLUMN tblop_plants.effluent_ph; Type: COMMENT; Schema: wqm; Owner: lims
--

COMMENT ON COLUMN wqm.tblop_plants.effluent_ph IS '처리수 수소이온 농도';


--
-- TOC entry 322 (class 1259 OID 53579)
-- Name: tblop_plants_id_seq; Type: SEQUENCE; Schema: wqm; Owner: lims
--

CREATE SEQUENCE wqm.tblop_plants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE wqm.tblop_plants_id_seq OWNER TO lims;

--
-- TOC entry 4237 (class 0 OID 0)
-- Dependencies: 322
-- Name: tblop_plants_id_seq; Type: SEQUENCE OWNED BY; Schema: wqm; Owner: lims
--

ALTER SEQUENCE wqm.tblop_plants_id_seq OWNED BY wqm.tblop_plants.id;


--
-- TOC entry 323 (class 1259 OID 53580)
-- Name: tblviews; Type: TABLE; Schema: wqm; Owner: lims
--

CREATE TABLE wqm.tblviews (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    user_id integer NOT NULL,
    plant_code text NOT NULL,
    line_codes text NOT NULL,
    smp_codes text NOT NULL,
    memo text,
    registered_on timestamp without time zone DEFAULT now()
);


ALTER TABLE wqm.tblviews OWNER TO lims;

--
-- TOC entry 324 (class 1259 OID 53586)
-- Name: tblviews_id_seq; Type: SEQUENCE; Schema: wqm; Owner: lims
--

CREATE SEQUENCE wqm.tblviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE wqm.tblviews_id_seq OWNER TO lims;

--
-- TOC entry 4238 (class 0 OID 0)
-- Dependencies: 324
-- Name: tblviews_id_seq; Type: SEQUENCE OWNED BY; Schema: wqm; Owner: lims
--

ALTER SEQUENCE wqm.tblviews_id_seq OWNED BY wqm.tblviews.id;


--
-- TOC entry 3513 (class 2604 OID 53587)
-- Name: tblversions version_id; Type: DEFAULT; Schema: app; Owner: lims
--

ALTER TABLE ONLY app.tblversions ALTER COLUMN version_id SET DEFAULT nextval('app.tblversions_version_id_seq'::regclass);


--
-- TOC entry 3514 (class 2604 OID 53588)
-- Name: tblcategories category_id; Type: DEFAULT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblcategories ALTER COLUMN category_id SET DEFAULT nextval('inv.tblcategories_category_id_seq'::regclass);


--
-- TOC entry 3516 (class 2604 OID 53589)
-- Name: tblimages image_id; Type: DEFAULT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblimages ALTER COLUMN image_id SET DEFAULT nextval('inv.tblimages_image_id_seq'::regclass);


--
-- TOC entry 3518 (class 2604 OID 53590)
-- Name: tblinout inout_id; Type: DEFAULT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblinout ALTER COLUMN inout_id SET DEFAULT nextval('inv.tblinout_inout_id_seq'::regclass);


--
-- TOC entry 3521 (class 2604 OID 53591)
-- Name: tblinstruments instrument_id; Type: DEFAULT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblinstruments ALTER COLUMN instrument_id SET DEFAULT nextval('inv.tblinstruments_instrument_id_seq'::regclass);


--
-- TOC entry 3523 (class 2604 OID 53592)
-- Name: tblinventories inventory_id; Type: DEFAULT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblinventories ALTER COLUMN inventory_id SET DEFAULT nextval('inv.tblinventories_inventory_id_seq'::regclass);


--
-- TOC entry 3528 (class 2604 OID 53593)
-- Name: tblmaintenance maintenance_id; Type: DEFAULT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblmaintenance ALTER COLUMN maintenance_id SET DEFAULT nextval('inv.tblmaintenance_maintenance_id_seq'::regclass);


--
-- TOC entry 3533 (class 2604 OID 53594)
-- Name: tbltransactions transaction_id; Type: DEFAULT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tbltransactions ALTER COLUMN transaction_id SET DEFAULT nextval('inv.tbltransactions_transaction_id_seq'::regclass);


--
-- TOC entry 3538 (class 2604 OID 53595)
-- Name: tblvendors vendor_id; Type: DEFAULT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblvendors ALTER COLUMN vendor_id SET DEFAULT nextval('inv.tblvendors_vendor_id_seq'::regclass);


--
-- TOC entry 3540 (class 2604 OID 53596)
-- Name: tblparameters id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblparameters ALTER COLUMN id SET DEFAULT nextval('lims.tblparameters_id_seq'::regclass);


--
-- TOC entry 3553 (class 2604 OID 53597)
-- Name: tblpr_views id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblpr_views ALTER COLUMN id SET DEFAULT nextval('lims.tblpr_views_id_seq'::regclass);


--
-- TOC entry 3554 (class 2604 OID 53598)
-- Name: tblprojects id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblprojects ALTER COLUMN id SET DEFAULT nextval('lims.tblprojects_id_seq'::regclass);


--
-- TOC entry 3557 (class 2604 OID 53599)
-- Name: tblsample_containers id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsample_containers ALTER COLUMN id SET DEFAULT nextval('lims.tblsample_containers_id_seq'::regclass);


--
-- TOC entry 3559 (class 2604 OID 53600)
-- Name: tblsample_types id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsample_types ALTER COLUMN id SET DEFAULT nextval('lims.tblsample_types_id_seq'::regclass);


--
-- TOC entry 3561 (class 2604 OID 53601)
-- Name: tblsamples id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsamples ALTER COLUMN id SET DEFAULT nextval('lims.tblsamples_id_seq'::regclass);


--
-- TOC entry 3568 (class 2604 OID 53602)
-- Name: tblsite site_id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsite ALTER COLUMN site_id SET DEFAULT nextval('lims.tblsite_site_id_seq'::regclass);


--
-- TOC entry 3569 (class 2604 OID 53603)
-- Name: tblsmp smp_id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsmp ALTER COLUMN smp_id SET DEFAULT nextval('lims.tblsmp_smp_id_seq'::regclass);


--
-- TOC entry 3570 (class 2604 OID 53604)
-- Name: tbltest_request_templates id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tbltest_request_templates ALTER COLUMN id SET DEFAULT nextval('lims.tbltest_request_templates_id_seq'::regclass);


--
-- TOC entry 3572 (class 2604 OID 53605)
-- Name: tbltest_requests id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tbltest_requests ALTER COLUMN id SET DEFAULT nextval('lims.tbltest_requests_id_seq'::regclass);


--
-- TOC entry 3576 (class 2604 OID 53606)
-- Name: tblweather id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblweather ALTER COLUMN id SET DEFAULT nextval('lims.tblweather_id_seq'::regclass);


--
-- TOC entry 3578 (class 2604 OID 53607)
-- Name: tblws id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws ALTER COLUMN id SET DEFAULT nextval('lims.tblws_id_seq'::regclass);


--
-- TOC entry 3579 (class 2604 OID 53608)
-- Name: tblws_bd00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_bd00 ALTER COLUMN id SET DEFAULT nextval('lims.tblws_bd00_id_seq'::regclass);


--
-- TOC entry 3583 (class 2604 OID 53609)
-- Name: tblws_cd00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_cd00 ALTER COLUMN id SET DEFAULT nextval('lims.tblws_cd00_id_seq'::regclass);


--
-- TOC entry 3586 (class 2604 OID 53610)
-- Name: tblws_ec00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_ec00 ALTER COLUMN id SET DEFAULT nextval('lims.tblws_ec00_id_seq'::regclass);


--
-- TOC entry 3590 (class 2604 OID 53611)
-- Name: tblws_ec01 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_ec01 ALTER COLUMN id SET DEFAULT nextval('lims.tblws_ec01_id_seq'::regclass);


--
-- TOC entry 3594 (class 2604 OID 53612)
-- Name: tblws_items id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_items ALTER COLUMN id SET DEFAULT nextval('lims.tblws_items_id_seq'::regclass);


--
-- TOC entry 3596 (class 2604 OID 53613)
-- Name: tblws_kt00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_kt00 ALTER COLUMN id SET DEFAULT nextval('lims.tblws_kt00_id_seq'::regclass);


--
-- TOC entry 3601 (class 2604 OID 53614)
-- Name: tblws_ml00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_ml00 ALTER COLUMN id SET DEFAULT nextval('lims.tblws_ml00_id_seq'::regclass);


--
-- TOC entry 3603 (class 2604 OID 53615)
-- Name: tblws_nn00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_nn00 ALTER COLUMN id SET DEFAULT nextval('lims.tblws_nn00_id_seq'::regclass);


--
-- TOC entry 3606 (class 2604 OID 53616)
-- Name: tblws_np00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_np00 ALTER COLUMN id SET DEFAULT nextval('lims.tblws_np00_id_seq'::regclass);


--
-- TOC entry 3611 (class 2604 OID 53617)
-- Name: tblws_ss00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_ss00 ALTER COLUMN id SET DEFAULT nextval('lims.tblws_ss00_id_seq'::regclass);


--
-- TOC entry 3613 (class 2604 OID 53618)
-- Name: tblws_tc00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_tc00 ALTER COLUMN id SET DEFAULT nextval('lims.tblws_tc00_id_seq'::regclass);


--
-- TOC entry 3614 (class 2604 OID 53619)
-- Name: tblws_ts00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_ts00 ALTER COLUMN id SET DEFAULT nextval('lims.tblws_ts00_id_seq'::regclass);


--
-- TOC entry 3616 (class 2604 OID 53620)
-- Name: tblwsds_bd00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_bd00 ALTER COLUMN id SET DEFAULT nextval('lims.tblwsds_bd00_id_seq'::regclass);


--
-- TOC entry 3618 (class 2604 OID 53621)
-- Name: tblwsds_cd00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_cd00 ALTER COLUMN id SET DEFAULT nextval('lims.tblwsds_cd00_id_seq'::regclass);


--
-- TOC entry 3620 (class 2604 OID 53622)
-- Name: tblwsds_ec00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ec00 ALTER COLUMN id SET DEFAULT nextval('lims.tblwsds_ec00_id_seq'::regclass);


--
-- TOC entry 3622 (class 2604 OID 53623)
-- Name: tblwsds_ec01 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ec01 ALTER COLUMN id SET DEFAULT nextval('lims.tblwsds_ec01_id_seq'::regclass);


--
-- TOC entry 3624 (class 2604 OID 53624)
-- Name: tblwsds_items id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_items ALTER COLUMN id SET DEFAULT nextval('lims.tblwsds_items_id_seq'::regclass);


--
-- TOC entry 3628 (class 2604 OID 53625)
-- Name: tblwsds_kt00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_kt00 ALTER COLUMN id SET DEFAULT nextval('lims.tblwsds_kt00_id_seq'::regclass);


--
-- TOC entry 3630 (class 2604 OID 53626)
-- Name: tblwsds_ml00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ml00 ALTER COLUMN id SET DEFAULT nextval('lims.tblwsds_ml00_id_seq'::regclass);


--
-- TOC entry 3632 (class 2604 OID 53627)
-- Name: tblwsds_nn00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_nn00 ALTER COLUMN id SET DEFAULT nextval('lims.tblwsds_nn00_id_seq'::regclass);


--
-- TOC entry 3634 (class 2604 OID 53628)
-- Name: tblwsds_np00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_np00 ALTER COLUMN id SET DEFAULT nextval('lims.tblwsds_np00_id_seq'::regclass);


--
-- TOC entry 3636 (class 2604 OID 53629)
-- Name: tblwsds_ss00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ss00 ALTER COLUMN id SET DEFAULT nextval('lims.tblwsds_ss00_id_seq'::regclass);


--
-- TOC entry 3638 (class 2604 OID 53630)
-- Name: tblwsds_tc00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_tc00 ALTER COLUMN id SET DEFAULT nextval('lims.tblwsds_tc00_id_seq'::regclass);


--
-- TOC entry 3640 (class 2604 OID 53631)
-- Name: tblwsds_ts00 id; Type: DEFAULT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ts00 ALTER COLUMN id SET DEFAULT nextval('lims.tblwsds_ts00_id_seq'::regclass);


--
-- TOC entry 3642 (class 2604 OID 53632)
-- Name: tbldepartments department_id; Type: DEFAULT; Schema: users; Owner: gumc
--

ALTER TABLE ONLY users.tbldepartments ALTER COLUMN department_id SET DEFAULT nextval('users.tbldepartments_department_id_seq'::regclass);


--
-- TOC entry 3644 (class 2604 OID 53633)
-- Name: tblusers user_id; Type: DEFAULT; Schema: users; Owner: gumc
--

ALTER TABLE ONLY users.tblusers ALTER COLUMN user_id SET DEFAULT nextval('users.tblusers_user_id_seq'::regclass);


--
-- TOC entry 3646 (class 2604 OID 53634)
-- Name: tbllines id; Type: DEFAULT; Schema: wqm; Owner: lims
--

ALTER TABLE ONLY wqm.tbllines ALTER COLUMN id SET DEFAULT nextval('wqm.tbllines_id_seq'::regclass);


--
-- TOC entry 3649 (class 2604 OID 53635)
-- Name: tblop_lines id; Type: DEFAULT; Schema: wqm; Owner: lims
--

ALTER TABLE ONLY wqm.tblop_lines ALTER COLUMN id SET DEFAULT nextval('wqm.tblop_lines_id_seq'::regclass);


--
-- TOC entry 3654 (class 2604 OID 53636)
-- Name: tblop_plants id; Type: DEFAULT; Schema: wqm; Owner: lims
--

ALTER TABLE ONLY wqm.tblop_plants ALTER COLUMN id SET DEFAULT nextval('wqm.tblop_plants_id_seq'::regclass);


--
-- TOC entry 3663 (class 2604 OID 53637)
-- Name: tblviews id; Type: DEFAULT; Schema: wqm; Owner: lims
--

ALTER TABLE ONLY wqm.tblviews ALTER COLUMN id SET DEFAULT nextval('wqm.tblviews_id_seq'::regclass);


--
-- TOC entry 3666 (class 2606 OID 53783)
-- Name: tblversions tblversions_pkey; Type: CONSTRAINT; Schema: app; Owner: lims
--

ALTER TABLE ONLY app.tblversions
    ADD CONSTRAINT tblversions_pkey PRIMARY KEY (version_id);


--
-- TOC entry 3668 (class 2606 OID 53785)
-- Name: tblcategories tblcategories_category_code_key; Type: CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblcategories
    ADD CONSTRAINT tblcategories_category_code_key UNIQUE (code);


--
-- TOC entry 3670 (class 2606 OID 53787)
-- Name: tblcategories tblcategories_pkey; Type: CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblcategories
    ADD CONSTRAINT tblcategories_pkey PRIMARY KEY (category_id);


--
-- TOC entry 3672 (class 2606 OID 53789)
-- Name: tblimages tblimages_pkey; Type: CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblimages
    ADD CONSTRAINT tblimages_pkey PRIMARY KEY (image_id);


--
-- TOC entry 3675 (class 2606 OID 53791)
-- Name: tblinout tblinout_pkey; Type: CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblinout
    ADD CONSTRAINT tblinout_pkey PRIMARY KEY (inout_id);


--
-- TOC entry 3678 (class 2606 OID 53793)
-- Name: tblinstruments tblinstruments_code_uq; Type: CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblinstruments
    ADD CONSTRAINT tblinstruments_code_uq UNIQUE (code);


--
-- TOC entry 3683 (class 2606 OID 53795)
-- Name: tblinstruments tblinstruments_pkey; Type: CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblinstruments
    ADD CONSTRAINT tblinstruments_pkey PRIMARY KEY (instrument_id);


--
-- TOC entry 3689 (class 2606 OID 53797)
-- Name: tblinventories tblinventories_pkey; Type: CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblinventories
    ADD CONSTRAINT tblinventories_pkey PRIMARY KEY (inventory_id);


--
-- TOC entry 3694 (class 2606 OID 53799)
-- Name: tblmaintenance tblmaintenance_pkey; Type: CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblmaintenance
    ADD CONSTRAINT tblmaintenance_pkey PRIMARY KEY (maintenance_id);


--
-- TOC entry 3699 (class 2606 OID 53801)
-- Name: tbltransactions tbltransactions_pkey; Type: CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tbltransactions
    ADD CONSTRAINT tbltransactions_pkey PRIMARY KEY (transaction_id);


--
-- TOC entry 3702 (class 2606 OID 53803)
-- Name: tblvendors tblvendors_pkey; Type: CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblvendors
    ADD CONSTRAINT tblvendors_pkey PRIMARY KEY (vendor_id);


--
-- TOC entry 3705 (class 2606 OID 53805)
-- Name: tblparameters tblparameters_code_uq; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblparameters
    ADD CONSTRAINT tblparameters_code_uq UNIQUE (code);


--
-- TOC entry 3707 (class 2606 OID 53807)
-- Name: tblparameters tblparameters_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblparameters
    ADD CONSTRAINT tblparameters_pk PRIMARY KEY (id);


--
-- TOC entry 3710 (class 2606 OID 53809)
-- Name: tblpr_views tblpr_views_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblpr_views
    ADD CONSTRAINT tblpr_views_pk PRIMARY KEY (id);


--
-- TOC entry 3712 (class 2606 OID 53811)
-- Name: tblprojects tblprojects_code_u; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblprojects
    ADD CONSTRAINT tblprojects_code_u UNIQUE (code);


--
-- TOC entry 3714 (class 2606 OID 53813)
-- Name: tblprojects tblprojects_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblprojects
    ADD CONSTRAINT tblprojects_pk PRIMARY KEY (id);


--
-- TOC entry 3717 (class 2606 OID 53815)
-- Name: tblsample_containers tblsample_containers_code_uq; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsample_containers
    ADD CONSTRAINT tblsample_containers_code_uq UNIQUE (code);


--
-- TOC entry 3719 (class 2606 OID 53817)
-- Name: tblsample_containers tblsample_containers_name_uq; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsample_containers
    ADD CONSTRAINT tblsample_containers_name_uq UNIQUE (name);


--
-- TOC entry 3721 (class 2606 OID 53819)
-- Name: tblsample_containers tblsample_containers_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsample_containers
    ADD CONSTRAINT tblsample_containers_pk PRIMARY KEY (id);


--
-- TOC entry 3724 (class 2606 OID 53821)
-- Name: tblsample_types tblsample_types_code_uq; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsample_types
    ADD CONSTRAINT tblsample_types_code_uq UNIQUE (code);


--
-- TOC entry 3726 (class 2606 OID 53823)
-- Name: tblsample_types tblsample_types_name_uq; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsample_types
    ADD CONSTRAINT tblsample_types_name_uq UNIQUE (name);


--
-- TOC entry 3728 (class 2606 OID 53825)
-- Name: tblsample_types tblsample_types_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsample_types
    ADD CONSTRAINT tblsample_types_pk PRIMARY KEY (id);


--
-- TOC entry 3732 (class 2606 OID 53827)
-- Name: tblsamples tblsamples_code_uq; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsamples
    ADD CONSTRAINT tblsamples_code_uq UNIQUE (code);


--
-- TOC entry 3734 (class 2606 OID 53829)
-- Name: tblsamples tblsamples_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsamples
    ADD CONSTRAINT tblsamples_pk PRIMARY KEY (id);


--
-- TOC entry 3736 (class 2606 OID 53831)
-- Name: tblsite tblsite_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsite
    ADD CONSTRAINT tblsite_pk PRIMARY KEY (site_id);


--
-- TOC entry 3739 (class 2606 OID 53833)
-- Name: tblsite tblsite_site_code_uq; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsite
    ADD CONSTRAINT tblsite_site_code_uq UNIQUE (site_code);


--
-- TOC entry 3743 (class 2606 OID 53835)
-- Name: tblsmp tblsmp_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsmp
    ADD CONSTRAINT tblsmp_pk PRIMARY KEY (smp_id);


--
-- TOC entry 3747 (class 2606 OID 53837)
-- Name: tblsmp tblsmp_smp_code_uq; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsmp
    ADD CONSTRAINT tblsmp_smp_code_uq UNIQUE (smp_code);


--
-- TOC entry 3750 (class 2606 OID 53839)
-- Name: tbltest_request_templates tbltest_request_templates_name_user_id_key; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tbltest_request_templates
    ADD CONSTRAINT tbltest_request_templates_name_user_id_key UNIQUE (name, user_id);


--
-- TOC entry 3752 (class 2606 OID 53841)
-- Name: tbltest_request_templates tbltest_request_templates_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tbltest_request_templates
    ADD CONSTRAINT tbltest_request_templates_pk PRIMARY KEY (id);


--
-- TOC entry 3755 (class 2606 OID 53843)
-- Name: tbltest_requests tbltest_requests_code_uq; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tbltest_requests
    ADD CONSTRAINT tbltest_requests_code_uq UNIQUE (code);


--
-- TOC entry 3757 (class 2606 OID 53845)
-- Name: tbltest_requests tbltest_requests_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tbltest_requests
    ADD CONSTRAINT tbltest_requests_pk PRIMARY KEY (id);


--
-- TOC entry 3761 (class 2606 OID 53847)
-- Name: tblweather tblweather_code_uq; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblweather
    ADD CONSTRAINT tblweather_code_uq UNIQUE (code);


--
-- TOC entry 3763 (class 2606 OID 53849)
-- Name: tblweather tblweather_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblweather
    ADD CONSTRAINT tblweather_pk PRIMARY KEY (id);


--
-- TOC entry 3766 (class 2606 OID 53851)
-- Name: tblweather tblweather_wx_status_uq; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblweather
    ADD CONSTRAINT tblweather_wx_status_uq UNIQUE (wx_status);


--
-- TOC entry 3775 (class 2606 OID 53853)
-- Name: tblws_bd00 tblws_bd00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_bd00
    ADD CONSTRAINT tblws_bd00_pk PRIMARY KEY (id);


--
-- TOC entry 3779 (class 2606 OID 53855)
-- Name: tblws_cd00 tblws_cd00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_cd00
    ADD CONSTRAINT tblws_cd00_pk PRIMARY KEY (id);


--
-- TOC entry 3769 (class 2606 OID 53857)
-- Name: tblws tblws_code_uq; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws
    ADD CONSTRAINT tblws_code_uq UNIQUE (code);


--
-- TOC entry 3783 (class 2606 OID 53859)
-- Name: tblws_ec00 tblws_ec00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_ec00
    ADD CONSTRAINT tblws_ec00_pk PRIMARY KEY (id);


--
-- TOC entry 3787 (class 2606 OID 53861)
-- Name: tblws_ec01 tblws_ec01_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_ec01
    ADD CONSTRAINT tblws_ec01_pk PRIMARY KEY (id);


--
-- TOC entry 3790 (class 2606 OID 53863)
-- Name: tblws_items tblws_items_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_items
    ADD CONSTRAINT tblws_items_pk PRIMARY KEY (id);


--
-- TOC entry 3794 (class 2606 OID 53865)
-- Name: tblws_kt00 tblws_kt00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_kt00
    ADD CONSTRAINT tblws_kt00_pk PRIMARY KEY (id);


--
-- TOC entry 3798 (class 2606 OID 53867)
-- Name: tblws_ml00 tblws_ml00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_ml00
    ADD CONSTRAINT tblws_ml00_pk PRIMARY KEY (id);


--
-- TOC entry 3802 (class 2606 OID 53869)
-- Name: tblws_nn00 tblws_nn00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_nn00
    ADD CONSTRAINT tblws_nn00_pk PRIMARY KEY (id);


--
-- TOC entry 3806 (class 2606 OID 53871)
-- Name: tblws_np00 tblws_np00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_np00
    ADD CONSTRAINT tblws_np00_pk PRIMARY KEY (id);


--
-- TOC entry 3771 (class 2606 OID 53873)
-- Name: tblws tblws_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws
    ADD CONSTRAINT tblws_pk PRIMARY KEY (id);


--
-- TOC entry 3810 (class 2606 OID 53875)
-- Name: tblws_ss00 tblws_ss00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_ss00
    ADD CONSTRAINT tblws_ss00_pk PRIMARY KEY (id);


--
-- TOC entry 3814 (class 2606 OID 53877)
-- Name: tblws_tc00 tblws_tc00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_tc00
    ADD CONSTRAINT tblws_tc00_pk PRIMARY KEY (id);


--
-- TOC entry 3818 (class 2606 OID 53879)
-- Name: tblws_ts00 tblws_ts00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_ts00
    ADD CONSTRAINT tblws_ts00_pk PRIMARY KEY (id);


--
-- TOC entry 3824 (class 2606 OID 53881)
-- Name: tblwsds_bd00 tblwsds_bd00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_bd00
    ADD CONSTRAINT tblwsds_bd00_pk PRIMARY KEY (id);


--
-- TOC entry 3829 (class 2606 OID 53883)
-- Name: tblwsds_cd00 tblwsds_cd00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_cd00
    ADD CONSTRAINT tblwsds_cd00_pk PRIMARY KEY (id);


--
-- TOC entry 3834 (class 2606 OID 53885)
-- Name: tblwsds_ec00 tblwsds_ec00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ec00
    ADD CONSTRAINT tblwsds_ec00_pk PRIMARY KEY (id);


--
-- TOC entry 3839 (class 2606 OID 53887)
-- Name: tblwsds_ec01 tblwsds_ec01_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ec01
    ADD CONSTRAINT tblwsds_ec01_pk PRIMARY KEY (id);


--
-- TOC entry 3842 (class 2606 OID 53889)
-- Name: tblwsds_items tblwsds_items_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_items
    ADD CONSTRAINT tblwsds_items_pk PRIMARY KEY (id);


--
-- TOC entry 3847 (class 2606 OID 53891)
-- Name: tblwsds_kt00 tblwsds_kt00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_kt00
    ADD CONSTRAINT tblwsds_kt00_pk PRIMARY KEY (id);


--
-- TOC entry 3852 (class 2606 OID 53893)
-- Name: tblwsds_ml00 tblwsds_ml00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ml00
    ADD CONSTRAINT tblwsds_ml00_pk PRIMARY KEY (id);


--
-- TOC entry 3857 (class 2606 OID 53895)
-- Name: tblwsds_nn00 tblwsds_nn00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_nn00
    ADD CONSTRAINT tblwsds_nn00_pk PRIMARY KEY (id);


--
-- TOC entry 3862 (class 2606 OID 53897)
-- Name: tblwsds_np00 tblwsds_np00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_np00
    ADD CONSTRAINT tblwsds_np00_pk PRIMARY KEY (id);


--
-- TOC entry 3867 (class 2606 OID 53899)
-- Name: tblwsds_ss00 tblwsds_ss00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ss00
    ADD CONSTRAINT tblwsds_ss00_pk PRIMARY KEY (id);


--
-- TOC entry 3873 (class 2606 OID 53901)
-- Name: tblwsds_tc00 tblwsds_tc00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_tc00
    ADD CONSTRAINT tblwsds_tc00_pk PRIMARY KEY (id);


--
-- TOC entry 3877 (class 2606 OID 53903)
-- Name: tblwsds_ts00 tblwsds_ts00_pk; Type: CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ts00
    ADD CONSTRAINT tblwsds_ts00_pk PRIMARY KEY (id);


--
-- TOC entry 3879 (class 2606 OID 53905)
-- Name: tbldepartments tbldepartments_code_uq; Type: CONSTRAINT; Schema: users; Owner: gumc
--

ALTER TABLE ONLY users.tbldepartments
    ADD CONSTRAINT tbldepartments_code_uq UNIQUE (code);


--
-- TOC entry 3881 (class 2606 OID 53907)
-- Name: tbldepartments tbldepartments_pkey; Type: CONSTRAINT; Schema: users; Owner: gumc
--

ALTER TABLE ONLY users.tbldepartments
    ADD CONSTRAINT tbldepartments_pkey PRIMARY KEY (department_id);


--
-- TOC entry 3883 (class 2606 OID 53909)
-- Name: tblusers tblusers_code_uq; Type: CONSTRAINT; Schema: users; Owner: gumc
--

ALTER TABLE ONLY users.tblusers
    ADD CONSTRAINT tblusers_code_uq UNIQUE (code);


--
-- TOC entry 3885 (class 2606 OID 53911)
-- Name: tblusers tblusers_pkey; Type: CONSTRAINT; Schema: users; Owner: gumc
--

ALTER TABLE ONLY users.tblusers
    ADD CONSTRAINT tblusers_pkey PRIMARY KEY (user_id);


--
-- TOC entry 3887 (class 2606 OID 53913)
-- Name: tbllines tbllines_line_code_uq; Type: CONSTRAINT; Schema: wqm; Owner: lims
--

ALTER TABLE ONLY wqm.tbllines
    ADD CONSTRAINT tbllines_line_code_uq UNIQUE (code);


--
-- TOC entry 3889 (class 2606 OID 53915)
-- Name: tbllines tbllines_pkey; Type: CONSTRAINT; Schema: wqm; Owner: lims
--

ALTER TABLE ONLY wqm.tbllines
    ADD CONSTRAINT tbllines_pkey PRIMARY KEY (id);


--
-- TOC entry 3891 (class 2606 OID 53917)
-- Name: tblop_lines tblop_lines_line_code_op_date_key; Type: CONSTRAINT; Schema: wqm; Owner: lims
--

ALTER TABLE ONLY wqm.tblop_lines
    ADD CONSTRAINT tblop_lines_line_code_op_date_key UNIQUE (line_code, op_date);


--
-- TOC entry 3893 (class 2606 OID 53919)
-- Name: tblop_lines tblop_lines_pkey; Type: CONSTRAINT; Schema: wqm; Owner: lims
--

ALTER TABLE ONLY wqm.tblop_lines
    ADD CONSTRAINT tblop_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 3895 (class 2606 OID 53921)
-- Name: tblop_plants tblop_plants_pkey; Type: CONSTRAINT; Schema: wqm; Owner: lims
--

ALTER TABLE ONLY wqm.tblop_plants
    ADD CONSTRAINT tblop_plants_pkey PRIMARY KEY (id);


--
-- TOC entry 3897 (class 2606 OID 53923)
-- Name: tblop_plants tblop_plants_plant_code_op_date_key; Type: CONSTRAINT; Schema: wqm; Owner: lims
--

ALTER TABLE ONLY wqm.tblop_plants
    ADD CONSTRAINT tblop_plants_plant_code_op_date_key UNIQUE (plant_code, op_date);


--
-- TOC entry 3900 (class 2606 OID 53925)
-- Name: tblviews tblviews_pkey; Type: CONSTRAINT; Schema: wqm; Owner: lims
--

ALTER TABLE ONLY wqm.tblviews
    ADD CONSTRAINT tblviews_pkey PRIMARY KEY (id);


--
-- TOC entry 3673 (class 1259 OID 53926)
-- Name: tblinout_inout_id; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tblinout_inout_id ON inv.tblinout USING btree (inout_id);


--
-- TOC entry 3676 (class 1259 OID 53927)
-- Name: tblinstruments_category_id; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tblinstruments_category_id ON inv.tblinstruments USING btree (category_id);


--
-- TOC entry 3679 (class 1259 OID 53928)
-- Name: tblinstruments_instrument_code; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tblinstruments_instrument_code ON inv.tblinstruments USING btree (code);


--
-- TOC entry 3680 (class 1259 OID 53929)
-- Name: tblinstruments_location_id; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tblinstruments_location_id ON inv.tblinstruments USING btree (location_id);


--
-- TOC entry 3681 (class 1259 OID 53930)
-- Name: tblinstruments_maker_id; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tblinstruments_maker_id ON inv.tblinstruments USING btree (maker_id);


--
-- TOC entry 3684 (class 1259 OID 53931)
-- Name: tblinstruments_status_id; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tblinstruments_status_id ON inv.tblinstruments USING btree (status_id);


--
-- TOC entry 3685 (class 1259 OID 53932)
-- Name: tblinventories_category_id; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tblinventories_category_id ON inv.tblinventories USING btree (category_id);


--
-- TOC entry 3686 (class 1259 OID 53933)
-- Name: tblinventories_code; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tblinventories_code ON inv.tblinventories USING btree (code);


--
-- TOC entry 3687 (class 1259 OID 53934)
-- Name: tblinventories_maker_id; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tblinventories_maker_id ON inv.tblinventories USING btree (maker_id);


--
-- TOC entry 3690 (class 1259 OID 53935)
-- Name: tblmaintenance_instrument_id; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tblmaintenance_instrument_id ON inv.tblmaintenance USING btree (instrument_id);


--
-- TOC entry 3691 (class 1259 OID 53936)
-- Name: tblmaintenance_location_id; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tblmaintenance_location_id ON inv.tblmaintenance USING btree (location_id);


--
-- TOC entry 3692 (class 1259 OID 53937)
-- Name: tblmaintenance_performed_date; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tblmaintenance_performed_date ON inv.tblmaintenance USING btree (performed_date);


--
-- TOC entry 3695 (class 1259 OID 53938)
-- Name: tblmaintenance_service_provider_id; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tblmaintenance_service_provider_id ON inv.tblmaintenance USING btree (service_provider_id);


--
-- TOC entry 3696 (class 1259 OID 53939)
-- Name: tbltransactions_inventory_id; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tbltransactions_inventory_id ON inv.tbltransactions USING btree (inventory_id);


--
-- TOC entry 3697 (class 1259 OID 53940)
-- Name: tbltransactions_location_id; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tbltransactions_location_id ON inv.tbltransactions USING btree (location_id);


--
-- TOC entry 3700 (class 1259 OID 53941)
-- Name: tbltransactions_supplier_id; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tbltransactions_supplier_id ON inv.tbltransactions USING btree (supplier_id);


--
-- TOC entry 3703 (class 1259 OID 53942)
-- Name: tblvendors_vendor_id; Type: INDEX; Schema: inv; Owner: lims
--

CREATE INDEX tblvendors_vendor_id ON inv.tblvendors USING btree (vendor_id);


--
-- TOC entry 3708 (class 1259 OID 53943)
-- Name: idx_pr_views_user_id; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_pr_views_user_id ON lims.tblpr_views USING btree (user_id);


--
-- TOC entry 3772 (class 1259 OID 53944)
-- Name: idx_ws_bd00_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_bd00_date ON lims.tblws_bd00 USING btree (date);


--
-- TOC entry 3773 (class 1259 OID 53945)
-- Name: idx_ws_bd00_person; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_bd00_person ON lims.tblws_bd00 USING btree (person);


--
-- TOC entry 3776 (class 1259 OID 53946)
-- Name: idx_ws_cd00_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_cd00_date ON lims.tblws_cd00 USING btree (date);


--
-- TOC entry 3777 (class 1259 OID 53947)
-- Name: idx_ws_cd00_person; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_cd00_person ON lims.tblws_cd00 USING btree (person);


--
-- TOC entry 3767 (class 1259 OID 53948)
-- Name: idx_ws_code; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_code ON lims.tblws USING btree (code);


--
-- TOC entry 3780 (class 1259 OID 53949)
-- Name: idx_ws_ec00_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_ec00_date ON lims.tblws_ec00 USING btree (date);


--
-- TOC entry 3781 (class 1259 OID 53950)
-- Name: idx_ws_ec00_person; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_ec00_person ON lims.tblws_ec00 USING btree (person);


--
-- TOC entry 3784 (class 1259 OID 53951)
-- Name: idx_ws_ec01_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_ec01_date ON lims.tblws_ec01 USING btree (date);


--
-- TOC entry 3785 (class 1259 OID 53952)
-- Name: idx_ws_ec01_person; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_ec01_person ON lims.tblws_ec01 USING btree (person);


--
-- TOC entry 3788 (class 1259 OID 53953)
-- Name: idx_ws_items_code; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_items_code ON lims.tblws_items USING btree (code);


--
-- TOC entry 3791 (class 1259 OID 53954)
-- Name: idx_ws_kt00_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_kt00_date ON lims.tblws_kt00 USING btree (date);


--
-- TOC entry 3792 (class 1259 OID 53955)
-- Name: idx_ws_kt00_person; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_kt00_person ON lims.tblws_kt00 USING btree (person);


--
-- TOC entry 3795 (class 1259 OID 53956)
-- Name: idx_ws_ml00_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_ml00_date ON lims.tblws_ml00 USING btree (date);


--
-- TOC entry 3796 (class 1259 OID 53957)
-- Name: idx_ws_ml00_person; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_ml00_person ON lims.tblws_ml00 USING btree (person);


--
-- TOC entry 3799 (class 1259 OID 53958)
-- Name: idx_ws_nn00_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_nn00_date ON lims.tblws_nn00 USING btree (date);


--
-- TOC entry 3800 (class 1259 OID 53959)
-- Name: idx_ws_nn00_person; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_nn00_person ON lims.tblws_nn00 USING btree (person);


--
-- TOC entry 3803 (class 1259 OID 53960)
-- Name: idx_ws_np00_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_np00_date ON lims.tblws_np00 USING btree (date);


--
-- TOC entry 3804 (class 1259 OID 53961)
-- Name: idx_ws_np00_person; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_np00_person ON lims.tblws_np00 USING btree (person);


--
-- TOC entry 3807 (class 1259 OID 53962)
-- Name: idx_ws_ss00_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_ss00_date ON lims.tblws_ss00 USING btree (date);


--
-- TOC entry 3808 (class 1259 OID 53963)
-- Name: idx_ws_ss00_person; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_ss00_person ON lims.tblws_ss00 USING btree (person);


--
-- TOC entry 3811 (class 1259 OID 53964)
-- Name: idx_ws_tc00_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_tc00_date ON lims.tblws_tc00 USING btree (date);


--
-- TOC entry 3812 (class 1259 OID 53965)
-- Name: idx_ws_tc00_person; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_tc00_person ON lims.tblws_tc00 USING btree (person);


--
-- TOC entry 3815 (class 1259 OID 53966)
-- Name: idx_ws_ts00_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_ts00_date ON lims.tblws_ts00 USING btree (date);


--
-- TOC entry 3816 (class 1259 OID 53967)
-- Name: idx_ws_ts00_person; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_ws_ts00_person ON lims.tblws_ts00 USING btree (person);


--
-- TOC entry 3819 (class 1259 OID 53968)
-- Name: idx_wsds_bd00_sample_code; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_bd00_sample_code ON lims.tblwsds_bd00 USING btree (sample_code);


--
-- TOC entry 3820 (class 1259 OID 53969)
-- Name: idx_wsds_bd00_smp_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_bd00_smp_date ON lims.tblwsds_bd00 USING btree (smp_date);


--
-- TOC entry 3821 (class 1259 OID 53970)
-- Name: idx_wsds_bd00_ws_id; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_bd00_ws_id ON lims.tblwsds_bd00 USING btree (ws_id);


--
-- TOC entry 3825 (class 1259 OID 53971)
-- Name: idx_wsds_cd00_sample_code; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_cd00_sample_code ON lims.tblwsds_cd00 USING btree (sample_code);


--
-- TOC entry 3826 (class 1259 OID 53972)
-- Name: idx_wsds_cd00_smp_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_cd00_smp_date ON lims.tblwsds_cd00 USING btree (smp_date);


--
-- TOC entry 3827 (class 1259 OID 53973)
-- Name: idx_wsds_cd00_ws_id; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_cd00_ws_id ON lims.tblwsds_cd00 USING btree (ws_id);


--
-- TOC entry 3830 (class 1259 OID 53974)
-- Name: idx_wsds_ec00_sample_code; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_ec00_sample_code ON lims.tblwsds_ec00 USING btree (sample_code);


--
-- TOC entry 3831 (class 1259 OID 53975)
-- Name: idx_wsds_ec00_smp_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_ec00_smp_date ON lims.tblwsds_ec00 USING btree (smp_date);


--
-- TOC entry 3832 (class 1259 OID 53976)
-- Name: idx_wsds_ec00_ws_id; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_ec00_ws_id ON lims.tblwsds_ec00 USING btree (ws_id);


--
-- TOC entry 3835 (class 1259 OID 53977)
-- Name: idx_wsds_ec01_sample_code; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_ec01_sample_code ON lims.tblwsds_ec01 USING btree (sample_code);


--
-- TOC entry 3836 (class 1259 OID 53978)
-- Name: idx_wsds_ec01_smp_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_ec01_smp_date ON lims.tblwsds_ec01 USING btree (smp_date);


--
-- TOC entry 3837 (class 1259 OID 53979)
-- Name: idx_wsds_ec01_ws_id; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_ec01_ws_id ON lims.tblwsds_ec01 USING btree (ws_id);


--
-- TOC entry 3840 (class 1259 OID 53980)
-- Name: idx_wsds_items_code; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_items_code ON lims.tblwsds_items USING btree (code);


--
-- TOC entry 3843 (class 1259 OID 53981)
-- Name: idx_wsds_kt00_sample_code; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_kt00_sample_code ON lims.tblwsds_kt00 USING btree (sample_code);


--
-- TOC entry 3844 (class 1259 OID 53982)
-- Name: idx_wsds_kt00_smp_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_kt00_smp_date ON lims.tblwsds_kt00 USING btree (smp_date);


--
-- TOC entry 3845 (class 1259 OID 53983)
-- Name: idx_wsds_kt00_ws_id; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_kt00_ws_id ON lims.tblwsds_kt00 USING btree (ws_id);


--
-- TOC entry 3848 (class 1259 OID 53984)
-- Name: idx_wsds_ml00_sample_code; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_ml00_sample_code ON lims.tblwsds_ml00 USING btree (sample_code);


--
-- TOC entry 3849 (class 1259 OID 53985)
-- Name: idx_wsds_ml00_smp_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_ml00_smp_date ON lims.tblwsds_ml00 USING btree (smp_date);


--
-- TOC entry 3850 (class 1259 OID 53986)
-- Name: idx_wsds_ml00_ws_id; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_ml00_ws_id ON lims.tblwsds_ml00 USING btree (ws_id);


--
-- TOC entry 3853 (class 1259 OID 53987)
-- Name: idx_wsds_nn00_sample_code; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_nn00_sample_code ON lims.tblwsds_nn00 USING btree (sample_code);


--
-- TOC entry 3854 (class 1259 OID 53988)
-- Name: idx_wsds_nn00_smp_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_nn00_smp_date ON lims.tblwsds_nn00 USING btree (smp_date);


--
-- TOC entry 3855 (class 1259 OID 53989)
-- Name: idx_wsds_nn00_ws_id; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_nn00_ws_id ON lims.tblwsds_nn00 USING btree (ws_id);


--
-- TOC entry 3858 (class 1259 OID 53990)
-- Name: idx_wsds_np00_sample_code; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_np00_sample_code ON lims.tblwsds_np00 USING btree (sample_code);


--
-- TOC entry 3859 (class 1259 OID 53991)
-- Name: idx_wsds_np00_smp_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_np00_smp_date ON lims.tblwsds_np00 USING btree (smp_date);


--
-- TOC entry 3860 (class 1259 OID 53992)
-- Name: idx_wsds_np00_ws_id; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_np00_ws_id ON lims.tblwsds_np00 USING btree (ws_id);


--
-- TOC entry 3863 (class 1259 OID 53993)
-- Name: idx_wsds_ss00_sample_code; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_ss00_sample_code ON lims.tblwsds_ss00 USING btree (sample_code);


--
-- TOC entry 3864 (class 1259 OID 53994)
-- Name: idx_wsds_ss00_smp_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_ss00_smp_date ON lims.tblwsds_ss00 USING btree (smp_date);


--
-- TOC entry 3865 (class 1259 OID 53995)
-- Name: idx_wsds_ss00_ws_id; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_ss00_ws_id ON lims.tblwsds_ss00 USING btree (ws_id);


--
-- TOC entry 3868 (class 1259 OID 53996)
-- Name: idx_wsds_tc00_id; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_tc00_id ON lims.tblwsds_tc00 USING btree (id);


--
-- TOC entry 3869 (class 1259 OID 53997)
-- Name: idx_wsds_tc00_sample_code_idx; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_tc00_sample_code_idx ON lims.tblwsds_tc00 USING btree (sample_code);


--
-- TOC entry 3870 (class 1259 OID 53998)
-- Name: idx_wsds_tc00_smp_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_tc00_smp_date ON lims.tblwsds_tc00 USING btree (smp_date);


--
-- TOC entry 3871 (class 1259 OID 53999)
-- Name: idx_wsds_tc00_ws_id; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_tc00_ws_id ON lims.tblwsds_tc00 USING btree (ws_id);


--
-- TOC entry 3822 (class 1259 OID 54000)
-- Name: idx_wsds_ts00_sample_code; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_ts00_sample_code ON lims.tblwsds_bd00 USING btree (sample_code);


--
-- TOC entry 3874 (class 1259 OID 54001)
-- Name: idx_wsds_ts00_smp_date; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_ts00_smp_date ON lims.tblwsds_ts00 USING btree (smp_date);


--
-- TOC entry 3875 (class 1259 OID 54002)
-- Name: idx_wsds_ts00_ws_id; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX idx_wsds_ts00_ws_id ON lims.tblwsds_ts00 USING btree (ws_id);


--
-- TOC entry 3715 (class 1259 OID 54003)
-- Name: sample_containers_name_idx; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX sample_containers_name_idx ON lims.tblsample_containers USING btree (name);


--
-- TOC entry 3722 (class 1259 OID 54004)
-- Name: sample_types_name_idx; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX sample_types_name_idx ON lims.tblsample_types USING btree (name);


--
-- TOC entry 3729 (class 1259 OID 54005)
-- Name: samples_order_code_idx; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX samples_order_code_idx ON lims.tblsamples USING btree (order_code);


--
-- TOC entry 3730 (class 1259 OID 54006)
-- Name: samples_smp_code_idx; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX samples_smp_code_idx ON lims.tblsamples USING btree (smp_code);


--
-- TOC entry 3737 (class 1259 OID 54007)
-- Name: tblsite_site_code; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX tblsite_site_code ON lims.tblsite USING btree (site_code);


--
-- TOC entry 3740 (class 1259 OID 54008)
-- Name: tblsite_site_id; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX tblsite_site_id ON lims.tblsite USING btree (site_id);


--
-- TOC entry 3741 (class 1259 OID 54009)
-- Name: tblsite_site_name; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX tblsite_site_name ON lims.tblsite USING btree (site_name);


--
-- TOC entry 3744 (class 1259 OID 54010)
-- Name: tblsmp_site_id; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX tblsmp_site_id ON lims.tblsmp USING btree (site_id);


--
-- TOC entry 3745 (class 1259 OID 54011)
-- Name: tblsmp_smp_code; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX tblsmp_smp_code ON lims.tblsmp USING btree (smp_code);


--
-- TOC entry 3748 (class 1259 OID 54012)
-- Name: tblsmp_smp_id; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX tblsmp_smp_id ON lims.tblsmp USING btree (smp_id);


--
-- TOC entry 3764 (class 1259 OID 54013)
-- Name: tblweather_wx_status_idx; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX tblweather_wx_status_idx ON lims.tblweather USING btree (wx_status);


--
-- TOC entry 3753 (class 1259 OID 54014)
-- Name: test_request_templates_name_idx; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX test_request_templates_name_idx ON lims.tbltest_request_templates USING btree (name);


--
-- TOC entry 3758 (class 1259 OID 54015)
-- Name: test_requests_department_code_idx; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX test_requests_department_code_idx ON lims.tbltest_requests USING btree (department_code);


--
-- TOC entry 3759 (class 1259 OID 54016)
-- Name: test_requests_project_code_idx; Type: INDEX; Schema: lims; Owner: lims
--

CREATE INDEX test_requests_project_code_idx ON lims.tbltest_requests USING btree (project_code);


--
-- TOC entry 3898 (class 1259 OID 54017)
-- Name: idx_views_user_id; Type: INDEX; Schema: wqm; Owner: lims
--

CREATE INDEX idx_views_user_id ON wqm.tblviews USING btree (user_id);


--
-- TOC entry 3974 (class 2620 OID 54018)
-- Name: tblsamples tr_bi_sample; Type: TRIGGER; Schema: lims; Owner: lims
--

CREATE TRIGGER tr_bi_sample BEFORE INSERT ON lims.tblsamples FOR EACH ROW EXECUTE FUNCTION lims.before_insert_sample();


--
-- TOC entry 3975 (class 2620 OID 54019)
-- Name: tbltest_requests tr_bi_test_request; Type: TRIGGER; Schema: lims; Owner: lims
--

CREATE TRIGGER tr_bi_test_request BEFORE INSERT ON lims.tbltest_requests FOR EACH ROW EXECUTE FUNCTION lims.before_insert_test_request();


--
-- TOC entry 3901 (class 2606 OID 54020)
-- Name: tblinout tblinout_instrument_id_fkey; Type: FK CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblinout
    ADD CONSTRAINT tblinout_instrument_id_fkey FOREIGN KEY (instrument_id) REFERENCES inv.tblinstruments(instrument_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3902 (class 2606 OID 54025)
-- Name: tblinout tblinout_location_id_fkey; Type: FK CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblinout
    ADD CONSTRAINT tblinout_location_id_fkey FOREIGN KEY (location_id) REFERENCES users.tbldepartments(department_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3903 (class 2606 OID 54030)
-- Name: tblinstruments tblinstruments_category_id_fkey; Type: FK CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblinstruments
    ADD CONSTRAINT tblinstruments_category_id_fkey FOREIGN KEY (category_id) REFERENCES inv.tblcategories(category_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3904 (class 2606 OID 54035)
-- Name: tblinstruments tblinstruments_location_id_fkey; Type: FK CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblinstruments
    ADD CONSTRAINT tblinstruments_location_id_fkey FOREIGN KEY (location_id) REFERENCES users.tbldepartments(department_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3905 (class 2606 OID 54040)
-- Name: tblinstruments tblinstruments_maker_id_fkey; Type: FK CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblinstruments
    ADD CONSTRAINT tblinstruments_maker_id_fkey FOREIGN KEY (maker_id) REFERENCES inv.tblvendors(vendor_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3906 (class 2606 OID 54045)
-- Name: tblinventories tblinventories_category_id_fkey; Type: FK CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblinventories
    ADD CONSTRAINT tblinventories_category_id_fkey FOREIGN KEY (category_id) REFERENCES inv.tblcategories(category_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3907 (class 2606 OID 54050)
-- Name: tblinventories tblinventories_instrument_id_fkey; Type: FK CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblinventories
    ADD CONSTRAINT tblinventories_instrument_id_fkey FOREIGN KEY (instrument_id) REFERENCES inv.tblinstruments(instrument_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3908 (class 2606 OID 54055)
-- Name: tblmaintenance tblmaintenance_instrument_id_fkey; Type: FK CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblmaintenance
    ADD CONSTRAINT tblmaintenance_instrument_id_fkey FOREIGN KEY (instrument_id) REFERENCES inv.tblinstruments(instrument_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3909 (class 2606 OID 54060)
-- Name: tblmaintenance tblmaintenance_location_id_fkey; Type: FK CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblmaintenance
    ADD CONSTRAINT tblmaintenance_location_id_fkey FOREIGN KEY (location_id) REFERENCES users.tbldepartments(department_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3910 (class 2606 OID 54065)
-- Name: tblmaintenance tblmaintenance_service_provider_id_fkey; Type: FK CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tblmaintenance
    ADD CONSTRAINT tblmaintenance_service_provider_id_fkey FOREIGN KEY (service_provider_id) REFERENCES inv.tblvendors(vendor_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3911 (class 2606 OID 54070)
-- Name: tbltransactions tbltransactions_inventory_id_fkey; Type: FK CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tbltransactions
    ADD CONSTRAINT tbltransactions_inventory_id_fkey FOREIGN KEY (inventory_id) REFERENCES inv.tblinventories(inventory_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3912 (class 2606 OID 54075)
-- Name: tbltransactions tbltransactions_location_id_fkey; Type: FK CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tbltransactions
    ADD CONSTRAINT tbltransactions_location_id_fkey FOREIGN KEY (location_id) REFERENCES users.tbldepartments(department_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3913 (class 2606 OID 54080)
-- Name: tbltransactions tbltransactions_supplier_id_fkey; Type: FK CONSTRAINT; Schema: inv; Owner: lims
--

ALTER TABLE ONLY inv.tbltransactions
    ADD CONSTRAINT tbltransactions_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES inv.tblvendors(vendor_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3922 (class 2606 OID 54085)
-- Name: tblws_items code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblws_items
    ADD CONSTRAINT code_fk FOREIGN KEY (code) REFERENCES lims.tblws(code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3939 (class 2606 OID 54090)
-- Name: tblwsds_items code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_items
    ADD CONSTRAINT code_fk FOREIGN KEY (code) REFERENCES lims.tblws(code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3914 (class 2606 OID 54095)
-- Name: tblparameters instrument_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblparameters
    ADD CONSTRAINT instrument_code_fk FOREIGN KEY (instrument_code) REFERENCES inv.tblinstruments(code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3915 (class 2606 OID 54100)
-- Name: tblsamples order_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsamples
    ADD CONSTRAINT order_code_fk FOREIGN KEY (order_code) REFERENCES lims.tbltest_requests(code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3940 (class 2606 OID 54105)
-- Name: tblwsds_items pr_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_items
    ADD CONSTRAINT pr_code_fk FOREIGN KEY (pr_code) REFERENCES lims.tblparameters(code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3916 (class 2606 OID 54110)
-- Name: tblsamples smp_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsamples
    ADD CONSTRAINT smp_code_fk FOREIGN KEY (smp_code) REFERENCES lims.tblsmp(smp_code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3917 (class 2606 OID 54115)
-- Name: tblsmp tblsmp_site_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsmp
    ADD CONSTRAINT tblsmp_site_code_fk FOREIGN KEY (site_code) REFERENCES lims.tblsite(site_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3918 (class 2606 OID 54120)
-- Name: tblsmp tblsmp_site_id_fkey; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblsmp
    ADD CONSTRAINT tblsmp_site_id_fkey FOREIGN KEY (site_id) REFERENCES lims.tblsite(site_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3920 (class 2606 OID 54125)
-- Name: tbltest_requests tbltest_requests_department_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tbltest_requests
    ADD CONSTRAINT tbltest_requests_department_code_fk FOREIGN KEY (department_code) REFERENCES users.tbldepartments(code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3921 (class 2606 OID 54130)
-- Name: tbltest_requests tbltest_requests_project_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tbltest_requests
    ADD CONSTRAINT tbltest_requests_project_code_fk FOREIGN KEY (project_code) REFERENCES lims.tblprojects(code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3923 (class 2606 OID 54135)
-- Name: tblwsds_bd00 tblwsds_bd00_sample_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_bd00
    ADD CONSTRAINT tblwsds_bd00_sample_code_fk FOREIGN KEY (sample_code) REFERENCES lims.tblsamples(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3924 (class 2606 OID 54140)
-- Name: tblwsds_bd00 tblwsds_bd00_site_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_bd00
    ADD CONSTRAINT tblwsds_bd00_site_code_fk FOREIGN KEY (site_code) REFERENCES lims.tblsite(site_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3925 (class 2606 OID 54145)
-- Name: tblwsds_bd00 tblwsds_bd00_smp_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_bd00
    ADD CONSTRAINT tblwsds_bd00_smp_code_fk FOREIGN KEY (smp_code) REFERENCES lims.tblsmp(smp_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3926 (class 2606 OID 54150)
-- Name: tblwsds_bd00 tblwsds_bd00_ws_id_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_bd00
    ADD CONSTRAINT tblwsds_bd00_ws_id_fk FOREIGN KEY (ws_id) REFERENCES lims.tblws_bd00(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3927 (class 2606 OID 54155)
-- Name: tblwsds_cd00 tblwsds_cd00_sample_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_cd00
    ADD CONSTRAINT tblwsds_cd00_sample_code_fk FOREIGN KEY (sample_code) REFERENCES lims.tblsamples(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3928 (class 2606 OID 54160)
-- Name: tblwsds_cd00 tblwsds_cd00_site_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_cd00
    ADD CONSTRAINT tblwsds_cd00_site_code_fk FOREIGN KEY (site_code) REFERENCES lims.tblsite(site_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3929 (class 2606 OID 54165)
-- Name: tblwsds_cd00 tblwsds_cd00_smp_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_cd00
    ADD CONSTRAINT tblwsds_cd00_smp_code_fk FOREIGN KEY (smp_code) REFERENCES lims.tblsmp(smp_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3930 (class 2606 OID 54170)
-- Name: tblwsds_cd00 tblwsds_cd00_ws_id_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_cd00
    ADD CONSTRAINT tblwsds_cd00_ws_id_fk FOREIGN KEY (ws_id) REFERENCES lims.tblws_cd00(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3931 (class 2606 OID 54175)
-- Name: tblwsds_ec00 tblwsds_ec00_sample_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ec00
    ADD CONSTRAINT tblwsds_ec00_sample_code_fk FOREIGN KEY (sample_code) REFERENCES lims.tblsamples(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3932 (class 2606 OID 54180)
-- Name: tblwsds_ec00 tblwsds_ec00_site_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ec00
    ADD CONSTRAINT tblwsds_ec00_site_code_fk FOREIGN KEY (site_code) REFERENCES lims.tblsite(site_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3933 (class 2606 OID 54185)
-- Name: tblwsds_ec00 tblwsds_ec00_smp_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ec00
    ADD CONSTRAINT tblwsds_ec00_smp_code_fk FOREIGN KEY (smp_code) REFERENCES lims.tblsmp(smp_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3934 (class 2606 OID 54190)
-- Name: tblwsds_ec00 tblwsds_ec00_ws_id_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ec00
    ADD CONSTRAINT tblwsds_ec00_ws_id_fk FOREIGN KEY (ws_id) REFERENCES lims.tblws_ec00(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3935 (class 2606 OID 54195)
-- Name: tblwsds_ec01 tblwsds_ec01_sample_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ec01
    ADD CONSTRAINT tblwsds_ec01_sample_code_fk FOREIGN KEY (sample_code) REFERENCES lims.tblsamples(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3936 (class 2606 OID 54200)
-- Name: tblwsds_ec01 tblwsds_ec01_site_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ec01
    ADD CONSTRAINT tblwsds_ec01_site_code_fk FOREIGN KEY (site_code) REFERENCES lims.tblsite(site_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3937 (class 2606 OID 54205)
-- Name: tblwsds_ec01 tblwsds_ec01_smp_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ec01
    ADD CONSTRAINT tblwsds_ec01_smp_code_fk FOREIGN KEY (smp_code) REFERENCES lims.tblsmp(smp_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3938 (class 2606 OID 54210)
-- Name: tblwsds_ec01 tblwsds_ec01_ws_id_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ec01
    ADD CONSTRAINT tblwsds_ec01_ws_id_fk FOREIGN KEY (ws_id) REFERENCES lims.tblws_ec01(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3961 (class 2606 OID 54215)
-- Name: tblwsds_tc00 tblwsds_kt00_sample_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_tc00
    ADD CONSTRAINT tblwsds_kt00_sample_code_fk FOREIGN KEY (sample_code) REFERENCES lims.tblsamples(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3941 (class 2606 OID 54220)
-- Name: tblwsds_kt00 tblwsds_kt00_sample_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_kt00
    ADD CONSTRAINT tblwsds_kt00_sample_code_fk FOREIGN KEY (sample_code) REFERENCES lims.tblsamples(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3942 (class 2606 OID 54225)
-- Name: tblwsds_kt00 tblwsds_kt00_site_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_kt00
    ADD CONSTRAINT tblwsds_kt00_site_code_fk FOREIGN KEY (site_code) REFERENCES lims.tblsite(site_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3943 (class 2606 OID 54230)
-- Name: tblwsds_kt00 tblwsds_kt00_smp_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_kt00
    ADD CONSTRAINT tblwsds_kt00_smp_code_fk FOREIGN KEY (smp_code) REFERENCES lims.tblsmp(smp_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3944 (class 2606 OID 54235)
-- Name: tblwsds_kt00 tblwsds_kt00_ws_id_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_kt00
    ADD CONSTRAINT tblwsds_kt00_ws_id_fk FOREIGN KEY (ws_id) REFERENCES lims.tblws_kt00(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3945 (class 2606 OID 54240)
-- Name: tblwsds_ml00 tblwsds_ml00_sample_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ml00
    ADD CONSTRAINT tblwsds_ml00_sample_code_fk FOREIGN KEY (sample_code) REFERENCES lims.tblsamples(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3946 (class 2606 OID 54245)
-- Name: tblwsds_ml00 tblwsds_ml00_site_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ml00
    ADD CONSTRAINT tblwsds_ml00_site_code_fk FOREIGN KEY (site_code) REFERENCES lims.tblsite(site_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3947 (class 2606 OID 54250)
-- Name: tblwsds_ml00 tblwsds_ml00_smp_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ml00
    ADD CONSTRAINT tblwsds_ml00_smp_code_fk FOREIGN KEY (smp_code) REFERENCES lims.tblsmp(smp_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3948 (class 2606 OID 54255)
-- Name: tblwsds_ml00 tblwsds_ml00_ws_id_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ml00
    ADD CONSTRAINT tblwsds_ml00_ws_id_fk FOREIGN KEY (ws_id) REFERENCES lims.tblws_ml00(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3949 (class 2606 OID 54260)
-- Name: tblwsds_nn00 tblwsds_nn00_sample_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_nn00
    ADD CONSTRAINT tblwsds_nn00_sample_code_fk FOREIGN KEY (sample_code) REFERENCES lims.tblsamples(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3950 (class 2606 OID 54265)
-- Name: tblwsds_nn00 tblwsds_nn00_site_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_nn00
    ADD CONSTRAINT tblwsds_nn00_site_code_fk FOREIGN KEY (site_code) REFERENCES lims.tblsite(site_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3951 (class 2606 OID 54270)
-- Name: tblwsds_nn00 tblwsds_nn00_smp_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_nn00
    ADD CONSTRAINT tblwsds_nn00_smp_code_fk FOREIGN KEY (smp_code) REFERENCES lims.tblsmp(smp_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3952 (class 2606 OID 54275)
-- Name: tblwsds_nn00 tblwsds_nn00_ws_id_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_nn00
    ADD CONSTRAINT tblwsds_nn00_ws_id_fk FOREIGN KEY (ws_id) REFERENCES lims.tblws_nn00(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3953 (class 2606 OID 54280)
-- Name: tblwsds_np00 tblwsds_np00_sample_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_np00
    ADD CONSTRAINT tblwsds_np00_sample_code_fk FOREIGN KEY (sample_code) REFERENCES lims.tblsamples(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3954 (class 2606 OID 54285)
-- Name: tblwsds_np00 tblwsds_np00_site_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_np00
    ADD CONSTRAINT tblwsds_np00_site_code_fk FOREIGN KEY (site_code) REFERENCES lims.tblsite(site_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3955 (class 2606 OID 54290)
-- Name: tblwsds_np00 tblwsds_np00_smp_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_np00
    ADD CONSTRAINT tblwsds_np00_smp_code_fk FOREIGN KEY (smp_code) REFERENCES lims.tblsmp(smp_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3956 (class 2606 OID 54295)
-- Name: tblwsds_np00 tblwsds_np00_ws_id_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_np00
    ADD CONSTRAINT tblwsds_np00_ws_id_fk FOREIGN KEY (ws_id) REFERENCES lims.tblws_np00(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3957 (class 2606 OID 54300)
-- Name: tblwsds_ss00 tblwsds_ss00_sample_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ss00
    ADD CONSTRAINT tblwsds_ss00_sample_code_fk FOREIGN KEY (sample_code) REFERENCES lims.tblsamples(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3958 (class 2606 OID 54305)
-- Name: tblwsds_ss00 tblwsds_ss00_site_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ss00
    ADD CONSTRAINT tblwsds_ss00_site_code_fk FOREIGN KEY (site_code) REFERENCES lims.tblsite(site_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3959 (class 2606 OID 54310)
-- Name: tblwsds_ss00 tblwsds_ss00_smp_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ss00
    ADD CONSTRAINT tblwsds_ss00_smp_code_fk FOREIGN KEY (smp_code) REFERENCES lims.tblsmp(smp_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3960 (class 2606 OID 54315)
-- Name: tblwsds_ss00 tblwsds_ss00_ws_id_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ss00
    ADD CONSTRAINT tblwsds_ss00_ws_id_fk FOREIGN KEY (ws_id) REFERENCES lims.tblws_ss00(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3962 (class 2606 OID 54320)
-- Name: tblwsds_tc00 tblwsds_tc00_site_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_tc00
    ADD CONSTRAINT tblwsds_tc00_site_code_fk FOREIGN KEY (site_code) REFERENCES lims.tblsite(site_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3963 (class 2606 OID 54325)
-- Name: tblwsds_tc00 tblwsds_tc00_smp_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_tc00
    ADD CONSTRAINT tblwsds_tc00_smp_code_fk FOREIGN KEY (smp_code) REFERENCES lims.tblsmp(smp_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3964 (class 2606 OID 54330)
-- Name: tblwsds_tc00 tblwsds_tc00_ws_id_fkey; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_tc00
    ADD CONSTRAINT tblwsds_tc00_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES lims.tblws_tc00(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3965 (class 2606 OID 54335)
-- Name: tblwsds_ts00 tblwsds_ts00_sample_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ts00
    ADD CONSTRAINT tblwsds_ts00_sample_code_fk FOREIGN KEY (sample_code) REFERENCES lims.tblsamples(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3966 (class 2606 OID 54340)
-- Name: tblwsds_ts00 tblwsds_ts00_site_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ts00
    ADD CONSTRAINT tblwsds_ts00_site_code_fk FOREIGN KEY (site_code) REFERENCES lims.tblsite(site_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3967 (class 2606 OID 54345)
-- Name: tblwsds_ts00 tblwsds_ts00_smp_code_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ts00
    ADD CONSTRAINT tblwsds_ts00_smp_code_fk FOREIGN KEY (smp_code) REFERENCES lims.tblsmp(smp_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3968 (class 2606 OID 54350)
-- Name: tblwsds_ts00 tblwsds_ts00_ws_id_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tblwsds_ts00
    ADD CONSTRAINT tblwsds_ts00_ws_id_fk FOREIGN KEY (ws_id) REFERENCES lims.tblws_ts00(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3919 (class 2606 OID 54355)
-- Name: tbltest_request_templates user_id_fk; Type: FK CONSTRAINT; Schema: lims; Owner: lims
--

ALTER TABLE ONLY lims.tbltest_request_templates
    ADD CONSTRAINT user_id_fk FOREIGN KEY (user_id) REFERENCES users.tblusers(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3969 (class 2606 OID 54360)
-- Name: tblusers tblusers_department_id_fkey; Type: FK CONSTRAINT; Schema: users; Owner: gumc
--

ALTER TABLE ONLY users.tblusers
    ADD CONSTRAINT tblusers_department_id_fkey FOREIGN KEY (department_id) REFERENCES users.tbldepartments(department_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3970 (class 2606 OID 54365)
-- Name: tbllines tbllines_plant_code_fk; Type: FK CONSTRAINT; Schema: wqm; Owner: lims
--

ALTER TABLE ONLY wqm.tbllines
    ADD CONSTRAINT tbllines_plant_code_fk FOREIGN KEY (plant_code) REFERENCES lims.tblsite(site_code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3971 (class 2606 OID 54370)
-- Name: tblop_lines tblop_lines_line_code_fk; Type: FK CONSTRAINT; Schema: wqm; Owner: lims
--

ALTER TABLE ONLY wqm.tblop_lines
    ADD CONSTRAINT tblop_lines_line_code_fk FOREIGN KEY (line_code) REFERENCES wqm.tbllines(code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3972 (class 2606 OID 54375)
-- Name: tblop_lines tblop_lines_op_plant_id_fk; Type: FK CONSTRAINT; Schema: wqm; Owner: lims
--

ALTER TABLE ONLY wqm.tblop_lines
    ADD CONSTRAINT tblop_lines_op_plant_id_fk FOREIGN KEY (op_plant_id) REFERENCES wqm.tblop_plants(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3973 (class 2606 OID 54380)
-- Name: tblop_plants tblop_plants_plant_code_fk; Type: FK CONSTRAINT; Schema: wqm; Owner: lims
--

ALTER TABLE ONLY wqm.tblop_plants
    ADD CONSTRAINT tblop_plants_plant_code_fk FOREIGN KEY (plant_code) REFERENCES lims.tblsite(site_code) ON UPDATE CASCADE ON DELETE RESTRICT;


-- Completed on 2025-06-09 21:26:29

--
-- PostgreSQL database dump complete
--

