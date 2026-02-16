--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5 (Debian 17.5-1.pgdg120+1)
-- Dumped by pg_dump version 17.5

-- Started on 2025-06-09 21:26:01

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
-- TOC entry 2 (class 3079 OID 35328)
-- Name: dblink; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;


--
-- TOC entry 3774 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION dblink; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION dblink IS 'connect to other PostgreSQL databases from within a database';


--
-- TOC entry 312 (class 1255 OID 35374)
-- Name: cal_inv_cost(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cal_inv_cost() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF (TG_OP = 'DELETE') THEN
      UPDATE "tblAssetMaintenancies"
        SET "curInventoryCost" = (
          SELECT coalesce(SUM("intAmount" * "curPrice"), 0) 
          FROM "tblInventoryTransactions"
          WHERE "idsAssetMaintenance" = OLD."idsAssetMaintenance"
                 AND "idsTransactionType" IN(2,5)) 
        WHERE "idsAssetMaintenance" = OLD."idsAssetMaintenance";
      RETURN OLD;

    ELSIF (TG_OP = 'UPDATE') OR (TG_OP = 'INSERT') THEN
      UPDATE "tblAssetMaintenancies"
        SET "curInventoryCost" = (
          SELECT coalesce(SUM("intAmount" * "curPrice"), 0) 
          FROM "tblInventoryTransactions"
          WHERE "idsAssetMaintenance" = NEW."idsAssetMaintenance"
                  AND "idsTransactionType" IN(2,5)) 
        WHERE "idsAssetMaintenance" = NEW."idsAssetMaintenance";
      RETURN NEW;
    END IF;
    RETURN NULL; -- result is ignored since this is an AFTER trigger
  END;
$$;


ALTER FUNCTION public.cal_inv_cost() OWNER TO postgres;

--
-- TOC entry 313 (class 1255 OID 35375)
-- Name: first_agg(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.first_agg(anyelement, anyelement) RETURNS anyelement
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
        SELECT $1;
$_$;


ALTER FUNCTION public.first_agg(anyelement, anyelement) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 219 (class 1259 OID 35376)
-- Name: tblAssets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."tblAssets" (
    "idsAsset" integer NOT NULL,
    "chrAssetCode" character varying(20),
    "chrAssetDescription" character varying(255),
    "idsAssetDivision" integer,
    "idsSite" integer,
    "idsAssetInfoG2BCode" integer,
    "chrUseDescription" character varying(255),
    "idsLocation" integer,
    "dtmInstalled" timestamp without time zone,
    "idsVendor" integer,
    "chrSerialNo" character varying(50),
    "dtmManufacture" timestamp without time zone,
    "chrBuyers" character varying(50),
    "chrPurchaseType" character varying(50),
    "curPurchasePrice" numeric(19,4),
    "idsContractor" integer,
    "dtmCompletion" timestamp without time zone,
    "idsStatus" integer,
    "intDepreciableLife" integer,
    "dtmNextSchedMaint" timestamp without time zone,
    "dtmDisposed" timestamp without time zone,
    "chrUnit" character varying(255),
    "intQuantity" integer,
    "chrDepreciationMethod" character varying(50),
    "curSalvageValue" numeric(19,4),
    "curCurrentValue" numeric(19,4),
    "memAssetNote" text,
    "chrProperty01" character varying(128) DEFAULT ''::character varying,
    "chrProperty02" character varying(128) DEFAULT ''::character varying,
    "chrProperty03" character varying(128) DEFAULT ''::character varying,
    "chrProperty04" character varying(128) DEFAULT ''::character varying,
    "chrProperty05" character varying(128) DEFAULT ''::character varying,
    "chrProperty06" character varying(128) DEFAULT ''::character varying,
    "chrProperty07" character varying(128) DEFAULT ''::character varying,
    "chrProperty08" character varying(128) DEFAULT ''::character varying,
    "chrProperty09" character varying(128) DEFAULT ''::character varying,
    "chrProperty10" character varying(128) DEFAULT ''::character varying,
    "chrProperty11" character varying(128) DEFAULT ''::character varying,
    "chrProperty12" character varying(128) DEFAULT ''::character varying,
    "chrProperty13" character varying(128) DEFAULT ''::character varying,
    "chrProperty14" character varying(128) DEFAULT ''::character varying,
    "chrProperty15" character varying(128) DEFAULT ''::character varying,
    "chrProperty16" character varying(128) DEFAULT ''::character varying,
    "chrImageSavedPath" character varying(255),
    "idsParentAsset" integer,
    "chrAssetQRCode" character varying(30),
    "dtmRegistered" timestamp without time zone DEFAULT now(),
    "dtmImageUpdate" timestamp without time zone,
    "chrImageSavedPath1" character varying(255),
    "chrImageSavedPath2" character varying(255),
    "chrImageSavedPath3" character varying(255),
    "chrImageSavedPath4" character varying(255),
    "chrImageSavedPath5" character varying(255),
    "chrImageTitle1" character varying(255),
    "chrImageTitle2" character varying(255),
    "chrImageTitle3" character varying(255),
    "chrImageTitle4" character varying(255),
    "chrImageTitle5" character varying(255),
    "dtmImageUpdate1" timestamp without time zone,
    "dtmImageUpdate2" timestamp without time zone,
    "dtmImageUpdate3" timestamp without time zone,
    "dtmImageUpdate4" timestamp without time zone,
    "dtmImageUpdate5" timestamp without time zone,
    "chrImageSavedPath0" character varying(255),
    "chrImageTitle0" character varying(255),
    "dtmImageUpdate0" timestamp without time zone,
    "idsMaker" integer
);


ALTER TABLE public."tblAssets" OWNER TO postgres;

--
-- TOC entry 314 (class 1255 OID 35398)
-- Name: fn_asset_duplicate(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_asset_duplicate(p_asset_id integer) RETURNS SETOF public."tblAssets"
    LANGUAGE plpgsql
    AS $_$
DECLARE
  cols text;
  insert_statement text;
BEGIN

  -- build list of columns
  SELECT array_to_string(array_agg( '"'|| column_name::name || '"'), ',') INTO cols
    FROM information_schema.columns 
    WHERE (table_schema, table_name) = ('public', 'tblAssets')
    AND column_name <> 'idsAsset';

  -- build insert statement
  insert_statement := 'INSERT INTO "tblAssets" (' || cols || ') SELECT ' || cols || ' FROM "tblAssets" WHERE "idsAsset" = $1 RETURNING *';

  -- execute statement
  RETURN QUERY EXECUTE insert_statement USING p_asset_id;

  RETURN;

END;
$_$;


ALTER FUNCTION public.fn_asset_duplicate(p_asset_id integer) OWNER TO postgres;

--
-- TOC entry 315 (class 1255 OID 35399)
-- Name: last_agg(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.last_agg(anyelement, anyelement) RETURNS anyelement
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
        SELECT $2;
$_$;


ALTER FUNCTION public.last_agg(anyelement, anyelement) OWNER TO postgres;

--
-- TOC entry 1025 (class 1255 OID 35400)
-- Name: first(anyelement); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE public.first(anyelement) (
    SFUNC = public.first_agg,
    STYPE = anyelement
);


ALTER AGGREGATE public.first(anyelement) OWNER TO postgres;

--
-- TOC entry 1026 (class 1255 OID 35401)
-- Name: last(anyelement); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE public.last(anyelement) (
    SFUNC = public.last_agg,
    STYPE = anyelement
);


ALTER AGGREGATE public.last(anyelement) OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 35402)
-- Name: msysconf; Type: TABLE; Schema: public; Owner: mes_usr
--

CREATE TABLE public.msysconf (
    config smallint NOT NULL,
    chvalue character varying,
    nvalue integer,
    comments character varying
);


ALTER TABLE public.msysconf OWNER TO mes_usr;

--
-- TOC entry 221 (class 1259 OID 35407)
-- Name: pklstAssetStatus; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."pklstAssetStatus" (
    "idsAssetStatus" integer NOT NULL,
    "chrAssetStatus" character varying(20),
    "memAssetStatusNote" text,
    "dtmRegistered" timestamp without time zone DEFAULT now()
);


ALTER TABLE public."pklstAssetStatus" OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 35413)
-- Name: pklstAssetStatus_idsAssetStatus_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."pklstAssetStatus_idsAssetStatus_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."pklstAssetStatus_idsAssetStatus_seq" OWNER TO postgres;

--
-- TOC entry 3775 (class 0 OID 0)
-- Dependencies: 222
-- Name: pklstAssetStatus_idsAssetStatus_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."pklstAssetStatus_idsAssetStatus_seq" OWNED BY public."pklstAssetStatus"."idsAssetStatus";


--
-- TOC entry 223 (class 1259 OID 35414)
-- Name: pklstDepartments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."pklstDepartments" (
    "idsDepartment" integer NOT NULL,
    "chrDepartmentName" character varying(50) NOT NULL,
    "chrDepartmentNote" text,
    "chrDepartmentCode" character varying(2) NOT NULL,
    "dtmRegistered" timestamp without time zone DEFAULT now(),
    "intSortOrder" integer
);


ALTER TABLE public."pklstDepartments" OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 35420)
-- Name: pklstG2BInfos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."pklstG2BInfos" (
    "idsAssetsInfoG2B" integer NOT NULL,
    "chrAssetsInfoG2BCode" character varying(255),
    "chrItemName" character varying(255),
    "chrItemSpec" character varying(255),
    "chrDepreciableLife" integer,
    "memAssetsInfoG2BNote" text,
    "dtmRegistered" timestamp without time zone DEFAULT now()
);


ALTER TABLE public."pklstG2BInfos" OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 35426)
-- Name: pklstG2BInfos_idsAssetsInfoG2B_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."pklstG2BInfos_idsAssetsInfoG2B_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."pklstG2BInfos_idsAssetsInfoG2B_seq" OWNER TO postgres;

--
-- TOC entry 3776 (class 0 OID 0)
-- Dependencies: 225
-- Name: pklstG2BInfos_idsAssetsInfoG2B_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."pklstG2BInfos_idsAssetsInfoG2B_seq" OWNED BY public."pklstG2BInfos"."idsAssetsInfoG2B";


--
-- TOC entry 226 (class 1259 OID 35427)
-- Name: pklstInventoryTransactionTypes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."pklstInventoryTransactionTypes" (
    "idsInventoryTansactionType" integer NOT NULL,
    "chrInventoryTansactionDescription" character varying(50),
    "chrInventoryTansactionAddRemove" character varying(50),
    "memInventoryTansactionNote" text,
    "dtmRegistered" timestamp without time zone DEFAULT now(),
    "intInventoryTransactionType" integer DEFAULT 0 NOT NULL
);


ALTER TABLE public."pklstInventoryTransactionTypes" OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 35434)
-- Name: pklstInventoryTransactionTypes_idsInventoryTansactionType_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."pklstInventoryTransactionTypes_idsInventoryTansactionType_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."pklstInventoryTransactionTypes_idsInventoryTansactionType_seq" OWNER TO postgres;

--
-- TOC entry 3777 (class 0 OID 0)
-- Dependencies: 227
-- Name: pklstInventoryTransactionTypes_idsInventoryTansactionType_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."pklstInventoryTransactionTypes_idsInventoryTansactionType_seq" OWNED BY public."pklstInventoryTransactionTypes"."idsInventoryTansactionType";


--
-- TOC entry 228 (class 1259 OID 35435)
-- Name: pklstLocationCategories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."pklstLocationCategories" (
    "idsLocationCategory" integer NOT NULL,
    "chrLocationCategory" character varying(20),
    "chrLocationCategoryCode" character varying(255),
    "memLocationCategoryNote" text,
    "dtmRegistered" timestamp without time zone DEFAULT now()
);


ALTER TABLE public."pklstLocationCategories" OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 35441)
-- Name: pklstLocationCategories_idsLocationCategory_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."pklstLocationCategories_idsLocationCategory_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."pklstLocationCategories_idsLocationCategory_seq" OWNER TO postgres;

--
-- TOC entry 3778 (class 0 OID 0)
-- Dependencies: 229
-- Name: pklstLocationCategories_idsLocationCategory_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."pklstLocationCategories_idsLocationCategory_seq" OWNED BY public."pklstLocationCategories"."idsLocationCategory";


--
-- TOC entry 230 (class 1259 OID 35442)
-- Name: pklstMaintenaceStatus; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."pklstMaintenaceStatus" (
    "idsMaintenaceStatus" integer NOT NULL,
    "chrMaintenaceStatus" character varying(20) NOT NULL,
    "memMaintenaceNote" character varying(255),
    "dtmRegistered" timestamp without time zone DEFAULT now(),
    "intInventoryTransactionType" integer
);


ALTER TABLE public."pklstMaintenaceStatus" OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 35446)
-- Name: pklstMaintenaceStatus_idsMaintenaceStatus_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."pklstMaintenaceStatus_idsMaintenaceStatus_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."pklstMaintenaceStatus_idsMaintenaceStatus_seq" OWNER TO postgres;

--
-- TOC entry 3779 (class 0 OID 0)
-- Dependencies: 231
-- Name: pklstMaintenaceStatus_idsMaintenaceStatus_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."pklstMaintenaceStatus_idsMaintenaceStatus_seq" OWNED BY public."pklstMaintenaceStatus"."idsMaintenaceStatus";


--
-- TOC entry 232 (class 1259 OID 35447)
-- Name: pklstPurchaseType; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."pklstPurchaseType" (
    "idsPurchaseType" integer NOT NULL,
    "chrPurchaseType" character varying(255),
    "memPunchaseNote" text,
    "dtmRegistered" timestamp without time zone DEFAULT now()
);


ALTER TABLE public."pklstPurchaseType" OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 35453)
-- Name: pklstPurchaseType_idsPurchaseType_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."pklstPurchaseType_idsPurchaseType_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."pklstPurchaseType_idsPurchaseType_seq" OWNER TO postgres;

--
-- TOC entry 3780 (class 0 OID 0)
-- Dependencies: 233
-- Name: pklstPurchaseType_idsPurchaseType_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."pklstPurchaseType_idsPurchaseType_seq" OWNED BY public."pklstPurchaseType"."idsPurchaseType";


--
-- TOC entry 234 (class 1259 OID 35454)
-- Name: pklstSites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."pklstSites" (
    "idsSite" integer NOT NULL,
    "chrSiteName" character varying(50) NOT NULL,
    "chrSiteNote" text,
    "chrSiteCode" character varying(2),
    "dtmRegistered" timestamp without time zone DEFAULT now(),
    "idsDepartment" integer,
    "intRepresentative" integer DEFAULT 100 NOT NULL,
    "intSortOrder" integer
);


ALTER TABLE public."pklstSites" OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 35461)
-- Name: pklstSites_idsSits_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."pklstSites_idsSits_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."pklstSites_idsSits_seq" OWNER TO postgres;

--
-- TOC entry 3781 (class 0 OID 0)
-- Dependencies: 235
-- Name: pklstSites_idsSits_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."pklstSites_idsSits_seq" OWNED BY public."pklstSites"."idsSite";


--
-- TOC entry 236 (class 1259 OID 35462)
-- Name: tblAssetBOMs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."tblAssetBOMs" (
    "idsAssetBOM" integer NOT NULL,
    "idsAsset" integer DEFAULT 0 NOT NULL,
    "idsInventory" integer DEFAULT 0 NOT NULL,
    "intAmount" integer DEFAULT 0 NOT NULL,
    "memAssetBOMNote" text,
    "dtmRegistered" timestamp without time zone DEFAULT now()
);


ALTER TABLE public."tblAssetBOMs" OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 35471)
-- Name: tblAssetBOMs_idsAssetBOM_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblAssetBOMs_idsAssetBOM_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblAssetBOMs_idsAssetBOM_seq" OWNER TO postgres;

--
-- TOC entry 3782 (class 0 OID 0)
-- Dependencies: 237
-- Name: tblAssetBOMs_idsAssetBOM_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblAssetBOMs_idsAssetBOM_seq" OWNED BY public."tblAssetBOMs"."idsAssetBOM";


--
-- TOC entry 238 (class 1259 OID 35472)
-- Name: tblAssetCategories_idsAssetCategory_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblAssetCategories_idsAssetCategory_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblAssetCategories_idsAssetCategory_seq" OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 35473)
-- Name: tblAssetCategories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."tblAssetCategories" (
    "idsAssetCategory" integer DEFAULT nextval('public."tblAssetCategories_idsAssetCategory_seq"'::regclass) NOT NULL,
    "chrAssetCategory" character varying(50),
    "memAssetCategoryNote" text,
    "chrAssetCategoryCode" character varying(3),
    "dtmRegistered" timestamp without time zone DEFAULT now()
);


ALTER TABLE public."tblAssetCategories" OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 35480)
-- Name: tblAssetDivisions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."tblAssetDivisions" (
    "idsAssetDivision" integer NOT NULL,
    "chrAssetDivision" character varying(50),
    "chrAssetDivisionPropertyTitle01" character varying(50) DEFAULT ''::character varying,
    "chrAssetDivisionPropertyTitle02" character varying(50) DEFAULT ''::character varying,
    "chrAssetDivisionPropertyTitle03" character varying(50) DEFAULT ''::character varying,
    "chrAssetDivisionPropertyTitle04" character varying(50) DEFAULT ''::character varying,
    "chrAssetDivisionPropertyTitle05" character varying(50) DEFAULT ''::character varying,
    "chrAssetDivisionPropertyTitle06" character varying(50) DEFAULT ''::character varying,
    "chrAssetDivisionPropertyTitle07" character varying(50) DEFAULT ''::character varying,
    "chrAssetDivisionPropertyTitle08" character varying(50) DEFAULT ''::character varying,
    "chrAssetDivisionPropertyTitle09" character varying(50) DEFAULT ''::character varying,
    "chrAssetDivisionPropertyTitle10" character varying(50) DEFAULT ''::character varying,
    "chrAssetDivisionPropertyTitle11" character varying(50) DEFAULT ''::character varying,
    "chrAssetDivisionPropertyTitle12" character varying(50) DEFAULT ''::character varying,
    "chrAssetDivisionPropertyTitle13" character varying(50) DEFAULT ''::character varying,
    "chrAssetDivisionPropertyTitle14" character varying(50) DEFAULT ''::character varying,
    "chrAssetDivisionPropertyTitle15" character varying(50) DEFAULT ''::character varying,
    "chrAssetDivisionPropertyTitle16" character varying(50) DEFAULT ''::character varying,
    "memAssetDivisionNote" text,
    "chrAssetDivisionCode" character varying(3),
    "dtmRegistered" timestamp without time zone DEFAULT now() NOT NULL,
    "idsAssetCategory" integer
);


ALTER TABLE public."tblAssetDivisions" OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 35502)
-- Name: tblAssetDivisions_idsAssetDivision_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblAssetDivisions_idsAssetDivision_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblAssetDivisions_idsAssetDivision_seq" OWNER TO postgres;

--
-- TOC entry 3783 (class 0 OID 0)
-- Dependencies: 241
-- Name: tblAssetDivisions_idsAssetDivision_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblAssetDivisions_idsAssetDivision_seq" OWNED BY public."tblAssetDivisions"."idsAssetDivision";


--
-- TOC entry 242 (class 1259 OID 35503)
-- Name: tblAssetImages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."tblAssetImages" (
    "idsAssetImage" integer NOT NULL,
    "idsAsset" integer,
    "oldImage" bytea,
    "intImageId" integer DEFAULT 0
);


ALTER TABLE public."tblAssetImages" OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 35509)
-- Name: tblAssetImages_lngAssetImage_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblAssetImages_lngAssetImage_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblAssetImages_lngAssetImage_seq" OWNER TO postgres;

--
-- TOC entry 3784 (class 0 OID 0)
-- Dependencies: 243
-- Name: tblAssetImages_lngAssetImage_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblAssetImages_lngAssetImage_seq" OWNED BY public."tblAssetImages"."idsAssetImage";


--
-- TOC entry 244 (class 1259 OID 35510)
-- Name: tblAssetMaintenancies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."tblAssetMaintenancies" (
    "idsAssetMaintenance" integer NOT NULL,
    "idsAsset" integer NOT NULL,
    "idsMaintenanceStatus" integer DEFAULT 0 NOT NULL,
    "dtmMaintenance" timestamp without time zone,
    "chrMaintenanceDescription" character varying(255),
    "chrMaintenancePerformedBy" character varying(50),
    "curMaintenanceCost" numeric(19,4),
    "memMaintenanceNote" text,
    "dtmRegistered" timestamp without time zone DEFAULT now(),
    "idsSupplier" integer,
    "intAmount" integer DEFAULT 0 NOT NULL,
    "idsDepartment" integer,
    "ysnOutsourcing" boolean DEFAULT false NOT NULL,
    "curInventoryCost" numeric(19,4) DEFAULT 0 NOT NULL
);


ALTER TABLE public."tblAssetMaintenancies" OWNER TO postgres;

--
-- TOC entry 3785 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN "tblAssetMaintenancies"."ysnOutsourcing"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public."tblAssetMaintenancies"."ysnOutsourcing" IS '작업구분 : 자체(T)/외주(F)';


--
-- TOC entry 245 (class 1259 OID 35520)
-- Name: tblAssetMaintenancies_idsAssetMaintenance_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblAssetMaintenancies_idsAssetMaintenance_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblAssetMaintenancies_idsAssetMaintenance_seq" OWNER TO postgres;

--
-- TOC entry 3786 (class 0 OID 0)
-- Dependencies: 245
-- Name: tblAssetMaintenancies_idsAssetMaintenance_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblAssetMaintenancies_idsAssetMaintenance_seq" OWNED BY public."tblAssetMaintenancies"."idsAssetMaintenance";


--
-- TOC entry 246 (class 1259 OID 35521)
-- Name: tblAssets_idsAsset_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblAssets_idsAsset_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblAssets_idsAsset_seq" OWNER TO postgres;

--
-- TOC entry 3787 (class 0 OID 0)
-- Dependencies: 246
-- Name: tblAssets_idsAsset_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblAssets_idsAsset_seq" OWNED BY public."tblAssets"."idsAsset";


--
-- TOC entry 247 (class 1259 OID 35522)
-- Name: tblDepartments_idsDepartment_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblDepartments_idsDepartment_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblDepartments_idsDepartment_seq" OWNER TO postgres;

--
-- TOC entry 3788 (class 0 OID 0)
-- Dependencies: 247
-- Name: tblDepartments_idsDepartment_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblDepartments_idsDepartment_seq" OWNED BY public."pklstDepartments"."idsDepartment";


--
-- TOC entry 248 (class 1259 OID 35523)
-- Name: tblInventories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."tblInventories" (
    "idsInventory" integer NOT NULL,
    "idsInventoryDivision" integer,
    "idsDepartment" integer,
    "chrItem" character varying(63),
    "chrSpec" character varying(255),
    "chrManufacturer" character varying(50),
    "chrUnit" character varying(10),
    "ysnDiscontinued" boolean DEFAULT false,
    "intReorderLevel" integer,
    "intTargetStockLevel" integer,
    "intReplacementCycleCount" double precision DEFAULT 0,
    "chrReplacementCycleUnit" character varying(255) DEFAULT '시간'::character varying,
    "memInventoryNote" text,
    "chrImageSavedPath" character varying(50),
    "chrInventoryCode" character varying(20),
    "dtmRegistered" timestamp without time zone DEFAULT now(),
    "dtmImageUpdate" timestamp without time zone
);


ALTER TABLE public."tblInventories" OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 35532)
-- Name: tblInventories_idsInventory_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblInventories_idsInventory_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblInventories_idsInventory_seq" OWNER TO postgres;

--
-- TOC entry 3789 (class 0 OID 0)
-- Dependencies: 249
-- Name: tblInventories_idsInventory_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblInventories_idsInventory_seq" OWNED BY public."tblInventories"."idsInventory";


--
-- TOC entry 250 (class 1259 OID 35533)
-- Name: tblInventoryCategories_idsInventoryCategory_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblInventoryCategories_idsInventoryCategory_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblInventoryCategories_idsInventoryCategory_seq" OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 35534)
-- Name: tblInventoryDivisions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."tblInventoryDivisions" (
    "idsInventoryDivision" integer NOT NULL,
    "chrInventoryDivision" character varying(50),
    "memInventoryDivisionNote" text,
    "chrInventoryDivisionCode" character varying(3),
    "dtmRegistered" timestamp without time zone DEFAULT now(),
    "idsInventoryCategory" integer
);


ALTER TABLE public."tblInventoryDivisions" OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 35540)
-- Name: tblInventoryDivisions_idsInventoryDivision_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblInventoryDivisions_idsInventoryDivision_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblInventoryDivisions_idsInventoryDivision_seq" OWNER TO postgres;

--
-- TOC entry 3790 (class 0 OID 0)
-- Dependencies: 252
-- Name: tblInventoryDivisions_idsInventoryDivision_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblInventoryDivisions_idsInventoryDivision_seq" OWNED BY public."tblInventoryDivisions"."idsInventoryDivision";


--
-- TOC entry 253 (class 1259 OID 35541)
-- Name: tblInventoryImages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."tblInventoryImages" (
    "idsInventoryImage" integer NOT NULL,
    "idsInventory" integer,
    "oldImage" bytea
);


ALTER TABLE public."tblInventoryImages" OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 35546)
-- Name: tblInventoryImages_lngInventoryImage_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblInventoryImages_lngInventoryImage_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblInventoryImages_lngInventoryImage_seq" OWNER TO postgres;

--
-- TOC entry 3791 (class 0 OID 0)
-- Dependencies: 254
-- Name: tblInventoryImages_lngInventoryImage_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblInventoryImages_lngInventoryImage_seq" OWNED BY public."tblInventoryImages"."idsInventoryImage";


--
-- TOC entry 255 (class 1259 OID 35547)
-- Name: tblInventoryTransactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."tblInventoryTransactions" (
    "idsInventoryTransaction" integer NOT NULL,
    "idsInventory" integer NOT NULL,
    "idsSupplier" integer,
    "idsTransactionType" integer DEFAULT 1,
    "idsDepartment" integer NOT NULL,
    "intAmount" integer DEFAULT 0,
    "curPrice" numeric(19,4) DEFAULT 0,
    "dtmCreatedDate" timestamp without time zone,
    "chrPoNo" character varying(50),
    "memNote" character varying(255),
    "dtmRegistered" timestamp without time zone DEFAULT now(),
    "idsAssetMaintenance" integer
);


ALTER TABLE public."tblInventoryTransactions" OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 35554)
-- Name: tblInventoryTransactions_idsInventoryTransaction_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblInventoryTransactions_idsInventoryTransaction_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblInventoryTransactions_idsInventoryTransaction_seq" OWNER TO postgres;

--
-- TOC entry 3792 (class 0 OID 0)
-- Dependencies: 256
-- Name: tblInventoryTransactions_idsInventoryTransaction_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblInventoryTransactions_idsInventoryTransaction_seq" OWNED BY public."tblInventoryTransactions"."idsInventoryTransaction";


--
-- TOC entry 257 (class 1259 OID 35555)
-- Name: tblLocation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."tblLocation" (
    "idsLocation" integer NOT NULL,
    "chrLocationName" character varying(20),
    "idsSite" integer NOT NULL,
    "idsLocationCategory" integer,
    "memLocationNote" text,
    "chrLocationCode" character varying(3),
    "dtmRegistered" timestamp without time zone DEFAULT now()
);


ALTER TABLE public."tblLocation" OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 35561)
-- Name: tblLocation_idsLocation_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblLocation_idsLocation_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblLocation_idsLocation_seq" OWNER TO postgres;

--
-- TOC entry 3793 (class 0 OID 0)
-- Dependencies: 258
-- Name: tblLocation_idsLocation_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblLocation_idsLocation_seq" OWNED BY public."tblLocation"."idsLocation";


--
-- TOC entry 259 (class 1259 OID 35562)
-- Name: tblUsers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."tblUsers" (
    "idsUser" integer NOT NULL,
    "chrUserName" character varying(25),
    "chrPassword" character varying(25),
    "idsDepartment" integer,
    "intRol" integer DEFAULT 100 NOT NULL
);


ALTER TABLE public."tblUsers" OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 35566)
-- Name: tblUsers_idsUser_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblUsers_idsUser_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblUsers_idsUser_seq" OWNER TO postgres;

--
-- TOC entry 3794 (class 0 OID 0)
-- Dependencies: 260
-- Name: tblUsers_idsUser_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblUsers_idsUser_seq" OWNED BY public."tblUsers"."idsUser";


--
-- TOC entry 261 (class 1259 OID 35567)
-- Name: tblVendorCategories; Type: TABLE; Schema: public; Owner: mes_usr
--

CREATE TABLE public."tblVendorCategories" (
    "idsVendorCategories" integer NOT NULL,
    "idsAssetCategory" integer,
    "idsVendor" integer
);


ALTER TABLE public."tblVendorCategories" OWNER TO mes_usr;

--
-- TOC entry 262 (class 1259 OID 35570)
-- Name: tblVendorCategories_idsVendorCategories_seq; Type: SEQUENCE; Schema: public; Owner: mes_usr
--

CREATE SEQUENCE public."tblVendorCategories_idsVendorCategories_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblVendorCategories_idsVendorCategories_seq" OWNER TO mes_usr;

--
-- TOC entry 3795 (class 0 OID 0)
-- Dependencies: 262
-- Name: tblVendorCategories_idsVendorCategories_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mes_usr
--

ALTER SEQUENCE public."tblVendorCategories_idsVendorCategories_seq" OWNED BY public."tblVendorCategories"."idsVendorCategories";


--
-- TOC entry 263 (class 1259 OID 35571)
-- Name: tblVendors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."tblVendors" (
    "idsVendor" integer NOT NULL,
    "chrVendorName" character varying(50),
    "chrContactName" character varying(50),
    "chrContactTitle" character varying(50),
    "chrContactHp" character varying(50),
    "chrContactEmail" character varying(255),
    "chrWebPage" text,
    "chrPostalCode" character varying(255),
    "chrAddress" character varying(255),
    "chrCity" character varying(50),
    "chrStateOrProvince" character varying(50),
    "chrTelephone" character varying(255),
    "chrFax" character varying(255),
    "memNote" text,
    "attAttachments" text,
    "chrVendorCode" character varying(4),
    "dtmRegistered" timestamp without time zone DEFAULT now()
);


ALTER TABLE public."tblVendors" OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 35577)
-- Name: tblVendors_idsVendor_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblVendors_idsVendor_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblVendors_idsVendor_seq" OWNER TO postgres;

--
-- TOC entry 3796 (class 0 OID 0)
-- Dependencies: 264
-- Name: tblVendors_idsVendor_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblVendors_idsVendor_seq" OWNED BY public."tblVendors"."idsVendor";


--
-- TOC entry 265 (class 1259 OID 35578)
-- Name: tblappversion; Type: TABLE; Schema: public; Owner: mes_usr
--

CREATE TABLE public.tblappversion (
    idsappversion integer NOT NULL,
    chrappversion character varying(50),
    dtmmake date,
    memnote text
);


ALTER TABLE public.tblappversion OWNER TO mes_usr;

--
-- TOC entry 266 (class 1259 OID 35583)
-- Name: tblappversion_idsappversion_seq; Type: SEQUENCE; Schema: public; Owner: mes_usr
--

CREATE SEQUENCE public.tblappversion_idsappversion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tblappversion_idsappversion_seq OWNER TO mes_usr;

--
-- TOC entry 3797 (class 0 OID 0)
-- Dependencies: 266
-- Name: tblappversion_idsappversion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mes_usr
--

ALTER SEQUENCE public.tblappversion_idsappversion_seq OWNED BY public.tblappversion.idsappversion;


--
-- TOC entry 267 (class 1259 OID 35584)
-- Name: tblcalibration_record; Type: TABLE; Schema: public; Owner: mes_usr
--

CREATE TABLE public.tblcalibration_record (
    idscalibration integer NOT NULL,
    idsasset integer NOT NULL,
    calibration_date timestamp without time zone NOT NULL,
    before_expected real DEFAULT 0.0,
    before_measured real DEFAULT 0.0,
    after_expected real DEFAULT 0.0,
    after_measured real DEFAULT 0.0,
    comment text,
    performed_by text,
    registered_date timestamp without time zone DEFAULT now() NOT NULL,
    "ysnOutsourcing" boolean DEFAULT false NOT NULL
);


ALTER TABLE public.tblcalibration_record OWNER TO mes_usr;

--
-- TOC entry 3798 (class 0 OID 0)
-- Dependencies: 267
-- Name: TABLE tblcalibration_record; Type: COMMENT; Schema: public; Owner: mes_usr
--

COMMENT ON TABLE public.tblcalibration_record IS 'Calibration Record';


--
-- TOC entry 3799 (class 0 OID 0)
-- Dependencies: 267
-- Name: COLUMN tblcalibration_record."ysnOutsourcing"; Type: COMMENT; Schema: public; Owner: mes_usr
--

COMMENT ON COLUMN public.tblcalibration_record."ysnOutsourcing" IS '작업구분 : 자체(T)/외주(F)';


--
-- TOC entry 268 (class 1259 OID 35595)
-- Name: tblcalibration_record_idscalibration_seq; Type: SEQUENCE; Schema: public; Owner: mes_usr
--

CREATE SEQUENCE public.tblcalibration_record_idscalibration_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tblcalibration_record_idscalibration_seq OWNER TO mes_usr;

--
-- TOC entry 3800 (class 0 OID 0)
-- Dependencies: 268
-- Name: tblcalibration_record_idscalibration_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mes_usr
--

ALTER SEQUENCE public.tblcalibration_record_idscalibration_seq OWNED BY public.tblcalibration_record.idscalibration;


--
-- TOC entry 269 (class 1259 OID 35596)
-- Name: tblimages_idsimage_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tblimages_idsimage_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tblimages_idsimage_seq OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 35597)
-- Name: tblimages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblimages (
    idsimage integer DEFAULT nextval('public.tblimages_idsimage_seq'::regclass) NOT NULL,
    idscategory integer DEFAULT 0 NOT NULL,
    oldimage bytea,
    intimageno integer DEFAULT 0 NOT NULL,
    intcategory integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.tblimages OWNER TO postgres;

--
-- TOC entry 3407 (class 2604 OID 35606)
-- Name: pklstAssetStatus idsAssetStatus; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstAssetStatus" ALTER COLUMN "idsAssetStatus" SET DEFAULT nextval('public."pklstAssetStatus_idsAssetStatus_seq"'::regclass);


--
-- TOC entry 3409 (class 2604 OID 35607)
-- Name: pklstDepartments idsDepartment; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstDepartments" ALTER COLUMN "idsDepartment" SET DEFAULT nextval('public."tblDepartments_idsDepartment_seq"'::regclass);


--
-- TOC entry 3411 (class 2604 OID 35608)
-- Name: pklstG2BInfos idsAssetsInfoG2B; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstG2BInfos" ALTER COLUMN "idsAssetsInfoG2B" SET DEFAULT nextval('public."pklstG2BInfos_idsAssetsInfoG2B_seq"'::regclass);


--
-- TOC entry 3413 (class 2604 OID 35609)
-- Name: pklstInventoryTransactionTypes idsInventoryTansactionType; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstInventoryTransactionTypes" ALTER COLUMN "idsInventoryTansactionType" SET DEFAULT nextval('public."pklstInventoryTransactionTypes_idsInventoryTansactionType_seq"'::regclass);


--
-- TOC entry 3416 (class 2604 OID 35610)
-- Name: pklstLocationCategories idsLocationCategory; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstLocationCategories" ALTER COLUMN "idsLocationCategory" SET DEFAULT nextval('public."pklstLocationCategories_idsLocationCategory_seq"'::regclass);


--
-- TOC entry 3418 (class 2604 OID 35611)
-- Name: pklstMaintenaceStatus idsMaintenaceStatus; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstMaintenaceStatus" ALTER COLUMN "idsMaintenaceStatus" SET DEFAULT nextval('public."pklstMaintenaceStatus_idsMaintenaceStatus_seq"'::regclass);


--
-- TOC entry 3420 (class 2604 OID 35612)
-- Name: pklstPurchaseType idsPurchaseType; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstPurchaseType" ALTER COLUMN "idsPurchaseType" SET DEFAULT nextval('public."pklstPurchaseType_idsPurchaseType_seq"'::regclass);


--
-- TOC entry 3422 (class 2604 OID 35613)
-- Name: pklstSites idsSite; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstSites" ALTER COLUMN "idsSite" SET DEFAULT nextval('public."pklstSites_idsSits_seq"'::regclass);


--
-- TOC entry 3425 (class 2604 OID 35614)
-- Name: tblAssetBOMs idsAssetBOM; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetBOMs" ALTER COLUMN "idsAssetBOM" SET DEFAULT nextval('public."tblAssetBOMs_idsAssetBOM_seq"'::regclass);


--
-- TOC entry 3432 (class 2604 OID 35615)
-- Name: tblAssetDivisions idsAssetDivision; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetDivisions" ALTER COLUMN "idsAssetDivision" SET DEFAULT nextval('public."tblAssetDivisions_idsAssetDivision_seq"'::regclass);


--
-- TOC entry 3450 (class 2604 OID 35616)
-- Name: tblAssetImages idsAssetImage; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetImages" ALTER COLUMN "idsAssetImage" SET DEFAULT nextval('public."tblAssetImages_lngAssetImage_seq"'::regclass);


--
-- TOC entry 3452 (class 2604 OID 35617)
-- Name: tblAssetMaintenancies idsAssetMaintenance; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetMaintenancies" ALTER COLUMN "idsAssetMaintenance" SET DEFAULT nextval('public."tblAssetMaintenancies_idsAssetMaintenance_seq"'::regclass);


--
-- TOC entry 3389 (class 2604 OID 35618)
-- Name: tblAssets idsAsset; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssets" ALTER COLUMN "idsAsset" SET DEFAULT nextval('public."tblAssets_idsAsset_seq"'::regclass);


--
-- TOC entry 3458 (class 2604 OID 35619)
-- Name: tblInventories idsInventory; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblInventories" ALTER COLUMN "idsInventory" SET DEFAULT nextval('public."tblInventories_idsInventory_seq"'::regclass);


--
-- TOC entry 3463 (class 2604 OID 35620)
-- Name: tblInventoryDivisions idsInventoryDivision; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblInventoryDivisions" ALTER COLUMN "idsInventoryDivision" SET DEFAULT nextval('public."tblInventoryDivisions_idsInventoryDivision_seq"'::regclass);


--
-- TOC entry 3465 (class 2604 OID 35621)
-- Name: tblInventoryImages idsInventoryImage; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblInventoryImages" ALTER COLUMN "idsInventoryImage" SET DEFAULT nextval('public."tblInventoryImages_lngInventoryImage_seq"'::regclass);


--
-- TOC entry 3466 (class 2604 OID 35622)
-- Name: tblInventoryTransactions idsInventoryTransaction; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblInventoryTransactions" ALTER COLUMN "idsInventoryTransaction" SET DEFAULT nextval('public."tblInventoryTransactions_idsInventoryTransaction_seq"'::regclass);


--
-- TOC entry 3471 (class 2604 OID 35623)
-- Name: tblLocation idsLocation; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblLocation" ALTER COLUMN "idsLocation" SET DEFAULT nextval('public."tblLocation_idsLocation_seq"'::regclass);


--
-- TOC entry 3473 (class 2604 OID 35624)
-- Name: tblUsers idsUser; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblUsers" ALTER COLUMN "idsUser" SET DEFAULT nextval('public."tblUsers_idsUser_seq"'::regclass);


--
-- TOC entry 3475 (class 2604 OID 35625)
-- Name: tblVendorCategories idsVendorCategories; Type: DEFAULT; Schema: public; Owner: mes_usr
--

ALTER TABLE ONLY public."tblVendorCategories" ALTER COLUMN "idsVendorCategories" SET DEFAULT nextval('public."tblVendorCategories_idsVendorCategories_seq"'::regclass);


--
-- TOC entry 3476 (class 2604 OID 35626)
-- Name: tblVendors idsVendor; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblVendors" ALTER COLUMN "idsVendor" SET DEFAULT nextval('public."tblVendors_idsVendor_seq"'::regclass);


--
-- TOC entry 3478 (class 2604 OID 35627)
-- Name: tblappversion idsappversion; Type: DEFAULT; Schema: public; Owner: mes_usr
--

ALTER TABLE ONLY public.tblappversion ALTER COLUMN idsappversion SET DEFAULT nextval('public.tblappversion_idsappversion_seq'::regclass);


--
-- TOC entry 3479 (class 2604 OID 35628)
-- Name: tblcalibration_record idscalibration; Type: DEFAULT; Schema: public; Owner: mes_usr
--

ALTER TABLE ONLY public.tblcalibration_record ALTER COLUMN idscalibration SET DEFAULT nextval('public.tblcalibration_record_idscalibration_seq'::regclass);


--
-- TOC entry 3505 (class 2606 OID 51633)
-- Name: pklstAssetStatus pklstAssetStatus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstAssetStatus"
    ADD CONSTRAINT "pklstAssetStatus_pkey" PRIMARY KEY ("idsAssetStatus");


--
-- TOC entry 3507 (class 2606 OID 51635)
-- Name: pklstDepartments pklstDepartments_chrDepartmentCode_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstDepartments"
    ADD CONSTRAINT "pklstDepartments_chrDepartmentCode_key" UNIQUE ("chrDepartmentCode");


--
-- TOC entry 3509 (class 2606 OID 51637)
-- Name: pklstDepartments pklstDepartments_chrDepartmentName_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstDepartments"
    ADD CONSTRAINT "pklstDepartments_chrDepartmentName_key" UNIQUE ("chrDepartmentName");


--
-- TOC entry 3511 (class 2606 OID 51639)
-- Name: pklstDepartments pklstDepartments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstDepartments"
    ADD CONSTRAINT "pklstDepartments_pkey" PRIMARY KEY ("idsDepartment");


--
-- TOC entry 3514 (class 2606 OID 51641)
-- Name: pklstG2BInfos pklstG2BInfos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstG2BInfos"
    ADD CONSTRAINT "pklstG2BInfos_pkey" PRIMARY KEY ("idsAssetsInfoG2B");


--
-- TOC entry 3516 (class 2606 OID 51643)
-- Name: pklstInventoryTransactionTypes pklstInventoryTransactionTypes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstInventoryTransactionTypes"
    ADD CONSTRAINT "pklstInventoryTransactionTypes_pkey" PRIMARY KEY ("idsInventoryTansactionType");


--
-- TOC entry 3519 (class 2606 OID 51645)
-- Name: pklstLocationCategories pklstLocationCategories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstLocationCategories"
    ADD CONSTRAINT "pklstLocationCategories_pkey" PRIMARY KEY ("idsLocationCategory");


--
-- TOC entry 3521 (class 2606 OID 51647)
-- Name: pklstMaintenaceStatus pklstMaintenaceStatus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstMaintenaceStatus"
    ADD CONSTRAINT "pklstMaintenaceStatus_pkey" PRIMARY KEY ("idsMaintenaceStatus");


--
-- TOC entry 3523 (class 2606 OID 51649)
-- Name: pklstPurchaseType pklstPurchaseType_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstPurchaseType"
    ADD CONSTRAINT "pklstPurchaseType_pkey" PRIMARY KEY ("idsPurchaseType");


--
-- TOC entry 3525 (class 2606 OID 51651)
-- Name: pklstSites pklstSites_chrSiteCode_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstSites"
    ADD CONSTRAINT "pklstSites_chrSiteCode_key" UNIQUE ("chrSiteCode");


--
-- TOC entry 3527 (class 2606 OID 51653)
-- Name: pklstSites pklstSites_chrSiteName_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstSites"
    ADD CONSTRAINT "pklstSites_chrSiteName_key" UNIQUE ("chrSiteName");


--
-- TOC entry 3529 (class 2606 OID 51655)
-- Name: pklstSites pklstSites_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstSites"
    ADD CONSTRAINT "pklstSites_pkey" PRIMARY KEY ("idsSite");


--
-- TOC entry 3533 (class 2606 OID 51657)
-- Name: tblAssetBOMs tblAssetBOMs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetBOMs"
    ADD CONSTRAINT "tblAssetBOMs_pkey" PRIMARY KEY ("idsAssetBOM");


--
-- TOC entry 3535 (class 2606 OID 51659)
-- Name: tblAssetCategories tblAssetCategories_chrAssetCategoryCode_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetCategories"
    ADD CONSTRAINT "tblAssetCategories_chrAssetCategoryCode_key" UNIQUE ("chrAssetCategoryCode");


--
-- TOC entry 3537 (class 2606 OID 51661)
-- Name: tblAssetCategories tblAssetCategories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetCategories"
    ADD CONSTRAINT "tblAssetCategories_pkey" PRIMARY KEY ("idsAssetCategory");


--
-- TOC entry 3539 (class 2606 OID 51663)
-- Name: tblAssetDivisions tblAssetDivisions_chrAssetDivisionCode_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetDivisions"
    ADD CONSTRAINT "tblAssetDivisions_chrAssetDivisionCode_key" UNIQUE ("chrAssetDivisionCode");


--
-- TOC entry 3541 (class 2606 OID 51665)
-- Name: tblAssetDivisions tblAssetDivisions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetDivisions"
    ADD CONSTRAINT "tblAssetDivisions_pkey" PRIMARY KEY ("idsAssetDivision");


--
-- TOC entry 3545 (class 2606 OID 51667)
-- Name: tblAssetImages tblAssetImages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetImages"
    ADD CONSTRAINT "tblAssetImages_pkey" PRIMARY KEY ("idsAssetImage");


--
-- TOC entry 3550 (class 2606 OID 51669)
-- Name: tblAssetMaintenancies tblAssetMaintenancies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetMaintenancies"
    ADD CONSTRAINT "tblAssetMaintenancies_pkey" PRIMARY KEY ("idsAssetMaintenance");


--
-- TOC entry 3503 (class 2606 OID 51671)
-- Name: tblAssets tblAssets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssets"
    ADD CONSTRAINT "tblAssets_pkey" PRIMARY KEY ("idsAsset");


--
-- TOC entry 3555 (class 2606 OID 51673)
-- Name: tblInventories tblInventories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblInventories"
    ADD CONSTRAINT "tblInventories_pkey" PRIMARY KEY ("idsInventory");


--
-- TOC entry 3558 (class 2606 OID 51675)
-- Name: tblInventoryDivisions tblInventoryCategories_chrInventoryCategory_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblInventoryDivisions"
    ADD CONSTRAINT "tblInventoryCategories_chrInventoryCategory_key" UNIQUE ("chrInventoryDivision");


--
-- TOC entry 3560 (class 2606 OID 51677)
-- Name: tblInventoryDivisions tblInventoryCategories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblInventoryDivisions"
    ADD CONSTRAINT "tblInventoryCategories_pkey" PRIMARY KEY ("idsInventoryDivision");


--
-- TOC entry 3563 (class 2606 OID 51679)
-- Name: tblInventoryImages tblInventoryImages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblInventoryImages"
    ADD CONSTRAINT "tblInventoryImages_pkey" PRIMARY KEY ("idsInventoryImage");


--
-- TOC entry 3570 (class 2606 OID 51681)
-- Name: tblInventoryTransactions tblInventoryTransactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblInventoryTransactions"
    ADD CONSTRAINT "tblInventoryTransactions_pkey" PRIMARY KEY ("idsInventoryTransaction");


--
-- TOC entry 3574 (class 2606 OID 51683)
-- Name: tblLocation tblLocation_chrLocationCode_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblLocation"
    ADD CONSTRAINT "tblLocation_chrLocationCode_key" UNIQUE ("chrLocationCode");


--
-- TOC entry 3576 (class 2606 OID 51685)
-- Name: tblLocation tblLocation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblLocation"
    ADD CONSTRAINT "tblLocation_pkey" PRIMARY KEY ("idsLocation");


--
-- TOC entry 3578 (class 2606 OID 51687)
-- Name: tblUsers tblUsers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblUsers"
    ADD CONSTRAINT "tblUsers_pkey" PRIMARY KEY ("idsUser");


--
-- TOC entry 3580 (class 2606 OID 51689)
-- Name: tblVendorCategories tblVendorCategories_pkey; Type: CONSTRAINT; Schema: public; Owner: mes_usr
--

ALTER TABLE ONLY public."tblVendorCategories"
    ADD CONSTRAINT "tblVendorCategories_pkey" PRIMARY KEY ("idsVendorCategories");


--
-- TOC entry 3584 (class 2606 OID 51691)
-- Name: tblVendors tblVendors_chrVendorName_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblVendors"
    ADD CONSTRAINT "tblVendors_chrVendorName_key" UNIQUE ("chrVendorName");


--
-- TOC entry 3586 (class 2606 OID 51693)
-- Name: tblVendors tblVendors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblVendors"
    ADD CONSTRAINT "tblVendors_pkey" PRIMARY KEY ("idsVendor");


--
-- TOC entry 3588 (class 2606 OID 51695)
-- Name: tblappversion tblappversion_pkey; Type: CONSTRAINT; Schema: public; Owner: mes_usr
--

ALTER TABLE ONLY public.tblappversion
    ADD CONSTRAINT tblappversion_pkey PRIMARY KEY (idsappversion);


--
-- TOC entry 3591 (class 2606 OID 51697)
-- Name: tblcalibration_record tblcalibration_record_pkey; Type: CONSTRAINT; Schema: public; Owner: mes_usr
--

ALTER TABLE ONLY public.tblcalibration_record
    ADD CONSTRAINT tblcalibration_record_pkey PRIMARY KEY (idscalibration);


--
-- TOC entry 3595 (class 2606 OID 51699)
-- Name: tblimages tblimage_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblimages
    ADD CONSTRAINT tblimage_pkey PRIMARY KEY (idsimage);


--
-- TOC entry 3530 (class 1259 OID 51700)
-- Name: idxAssetBOM_AssetID; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxAssetBOM_AssetID" ON public."tblAssetBOMs" USING btree ("idsAsset");


--
-- TOC entry 3531 (class 1259 OID 51701)
-- Name: idxAssetBOM_InventoryID; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxAssetBOM_InventoryID" ON public."tblAssetBOMs" USING btree ("idsInventory");


--
-- TOC entry 3490 (class 1259 OID 51702)
-- Name: idxAssetCategoryID; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxAssetCategoryID" ON public."tblAssets" USING btree ("idsAssetDivision");


--
-- TOC entry 3491 (class 1259 OID 51703)
-- Name: idxAssetCode; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxAssetCode" ON public."tblAssets" USING btree ("chrAssetCode");


--
-- TOC entry 3542 (class 1259 OID 51704)
-- Name: idxAssetImages_AssetID; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxAssetImages_AssetID" ON public."tblAssetImages" USING btree ("idsAsset");


--
-- TOC entry 3492 (class 1259 OID 51705)
-- Name: idxAssetInfoG2BCode; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxAssetInfoG2BCode" ON public."tblAssets" USING btree ("idsAssetInfoG2BCode");


--
-- TOC entry 3546 (class 1259 OID 51706)
-- Name: idxAssetMaintenance_AssetID; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxAssetMaintenance_AssetID" ON public."tblAssetMaintenancies" USING btree ("idsAsset");


--
-- TOC entry 3493 (class 1259 OID 51707)
-- Name: idxAssetQRCode; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxAssetQRCode" ON public."tblAssets" USING btree ("chrAssetQRCode");


--
-- TOC entry 3494 (class 1259 OID 51708)
-- Name: idxBuyers; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxBuyers" ON public."tblAssets" USING btree ("chrBuyers");


--
-- TOC entry 3495 (class 1259 OID 51709)
-- Name: idxContractor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxContractor" ON public."tblAssets" USING btree ("idsContractor");


--
-- TOC entry 3496 (class 1259 OID 51710)
-- Name: idxDepartmentID; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxDepartmentID" ON public."tblAssets" USING btree ("idsSite");


--
-- TOC entry 3551 (class 1259 OID 51711)
-- Name: idxInventoryCategories; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxInventoryCategories" ON public."tblInventories" USING btree ("idsInventoryDivision");


--
-- TOC entry 3556 (class 1259 OID 51712)
-- Name: idxInventoryCategoryCode; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxInventoryCategoryCode" ON public."tblInventoryDivisions" USING btree ("chrInventoryDivisionCode");


--
-- TOC entry 3552 (class 1259 OID 51713)
-- Name: idxInventoryCode; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxInventoryCode" ON public."tblInventories" USING btree ("chrInventoryCode");


--
-- TOC entry 3561 (class 1259 OID 51714)
-- Name: idxInventoryImage_InventoryID; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxInventoryImage_InventoryID" ON public."tblInventoryImages" USING btree ("idsInventory");


--
-- TOC entry 3564 (class 1259 OID 51715)
-- Name: idxInventoryTransaction_DepartmentID; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxInventoryTransaction_DepartmentID" ON public."tblInventoryTransactions" USING btree ("idsDepartment");


--
-- TOC entry 3565 (class 1259 OID 51716)
-- Name: idxInventoryTransaction_InventoryID; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxInventoryTransaction_InventoryID" ON public."tblInventoryTransactions" USING btree ("idsInventory");


--
-- TOC entry 3566 (class 1259 OID 51717)
-- Name: idxInventoryTransaction_SupplierID; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxInventoryTransaction_SupplierID" ON public."tblInventoryTransactions" USING btree ("idsSupplier");


--
-- TOC entry 3567 (class 1259 OID 51718)
-- Name: idxInventoryTransaction_TransactionTypeID; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxInventoryTransaction_TransactionTypeID" ON public."tblInventoryTransactions" USING btree ("idsTransactionType");


--
-- TOC entry 3553 (class 1259 OID 51719)
-- Name: idxInventory_DepartmentID; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxInventory_DepartmentID" ON public."tblInventories" USING btree ("idsDepartment");


--
-- TOC entry 3571 (class 1259 OID 51720)
-- Name: idxLocationCategory; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxLocationCategory" ON public."tblLocation" USING btree ("idsLocationCategory");


--
-- TOC entry 3497 (class 1259 OID 51721)
-- Name: idxLocationID; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxLocationID" ON public."tblAssets" USING btree ("idsLocation");


--
-- TOC entry 3572 (class 1259 OID 51722)
-- Name: idxLocation_Department; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxLocation_Department" ON public."tblLocation" USING btree ("idsSite");


--
-- TOC entry 3547 (class 1259 OID 51723)
-- Name: idxMaintenance; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxMaintenance" ON public."tblAssetMaintenancies" USING btree ("dtmMaintenance");


--
-- TOC entry 3548 (class 1259 OID 51724)
-- Name: idxMaintenanceStatus; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxMaintenanceStatus" ON public."tblAssetMaintenancies" USING btree ("idsMaintenanceStatus");


--
-- TOC entry 3498 (class 1259 OID 51725)
-- Name: idxParentAsset; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxParentAsset" ON public."tblAssets" USING btree ("idsParentAsset");


--
-- TOC entry 3568 (class 1259 OID 51726)
-- Name: idxPoNo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxPoNo" ON public."tblInventoryTransactions" USING btree ("chrPoNo");


--
-- TOC entry 3499 (class 1259 OID 51727)
-- Name: idxSerialNo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxSerialNo" ON public."tblAssets" USING btree ("chrSerialNo");


--
-- TOC entry 3500 (class 1259 OID 51728)
-- Name: idxStatusID; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxStatusID" ON public."tblAssets" USING btree ("idsStatus");


--
-- TOC entry 3581 (class 1259 OID 51729)
-- Name: idxVendorCode; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxVendorCode" ON public."tblVendors" USING btree ("chrVendorCode");


--
-- TOC entry 3501 (class 1259 OID 51730)
-- Name: idxVendorID; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxVendorID" ON public."tblAssets" USING btree ("idsVendor");


--
-- TOC entry 3582 (class 1259 OID 51731)
-- Name: idxZipCode; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idxZipCode" ON public."tblVendors" USING btree ("chrPostalCode");


--
-- TOC entry 3543 (class 1259 OID 51732)
-- Name: idxassetimageid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idxassetimageid ON public."tblAssetImages" USING btree ("idsAsset", "intImageId");


--
-- TOC entry 3512 (class 1259 OID 51733)
-- Name: pkls_idxAssetsInfoG2BCode; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "pkls_idxAssetsInfoG2BCode" ON public."pklstG2BInfos" USING btree ("chrAssetsInfoG2BCode");


--
-- TOC entry 3517 (class 1259 OID 51734)
-- Name: pkls_idxLocationCode; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "pkls_idxLocationCode" ON public."pklstLocationCategories" USING btree ("chrLocationCategoryCode");


--
-- TOC entry 3589 (class 1259 OID 51735)
-- Name: tblcalibration_record_idsasset; Type: INDEX; Schema: public; Owner: mes_usr
--

CREATE INDEX tblcalibration_record_idsasset ON public.tblcalibration_record USING btree (idsasset);


--
-- TOC entry 3592 (class 1259 OID 51736)
-- Name: tblimage_idsimage_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tblimage_idsimage_idx ON public.tblimages USING btree (idsimage);


--
-- TOC entry 3593 (class 1259 OID 51737)
-- Name: tblimage_intcategory_idscategory_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tblimage_intcategory_idscategory_idx ON public.tblimages USING btree (intcategory, idscategory);


--
-- TOC entry 3623 (class 2620 OID 51738)
-- Name: tblInventoryTransactions cal_inv_cost; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER cal_inv_cost AFTER INSERT OR DELETE OR UPDATE ON public."tblInventoryTransactions" FOR EACH ROW EXECUTE FUNCTION public.cal_inv_cost();


--
-- TOC entry 3604 (class 2606 OID 51739)
-- Name: pklstSites pklstSites_idsDepartment_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."pklstSites"
    ADD CONSTRAINT "pklstSites_idsDepartment_fkey" FOREIGN KEY ("idsDepartment") REFERENCES public."pklstDepartments"("idsDepartment") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3605 (class 2606 OID 51744)
-- Name: tblAssetBOMs tblAssetBOMs_idsAsset_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetBOMs"
    ADD CONSTRAINT "tblAssetBOMs_idsAsset_fkey" FOREIGN KEY ("idsAsset") REFERENCES public."tblAssets"("idsAsset") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3606 (class 2606 OID 51749)
-- Name: tblAssetBOMs tblAssetBOMs_idsInventory_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetBOMs"
    ADD CONSTRAINT "tblAssetBOMs_idsInventory_fkey" FOREIGN KEY ("idsInventory") REFERENCES public."tblInventories"("idsInventory") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3607 (class 2606 OID 51754)
-- Name: tblAssetDivisions tblAssetDivisions_idsAssetCategory_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetDivisions"
    ADD CONSTRAINT "tblAssetDivisions_idsAssetCategory_fkey" FOREIGN KEY ("idsAssetCategory") REFERENCES public."tblAssetCategories"("idsAssetCategory") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3608 (class 2606 OID 51759)
-- Name: tblAssetImages tblAssetImages_idsAsset_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetImages"
    ADD CONSTRAINT "tblAssetImages_idsAsset_fkey" FOREIGN KEY ("idsAsset") REFERENCES public."tblAssets"("idsAsset") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3609 (class 2606 OID 51764)
-- Name: tblAssetMaintenancies tblAssetMaintenancies_idsAsset_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetMaintenancies"
    ADD CONSTRAINT "tblAssetMaintenancies_idsAsset_fkey" FOREIGN KEY ("idsAsset") REFERENCES public."tblAssets"("idsAsset") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3610 (class 2606 OID 51769)
-- Name: tblAssetMaintenancies tblAssetMaintenancies_idsMaintenanceStatus_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssetMaintenancies"
    ADD CONSTRAINT "tblAssetMaintenancies_idsMaintenanceStatus_fkey" FOREIGN KEY ("idsMaintenanceStatus") REFERENCES public."pklstMaintenaceStatus"("idsMaintenaceStatus") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3596 (class 2606 OID 51774)
-- Name: tblAssets tblAssets_idsAssetDivision_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssets"
    ADD CONSTRAINT "tblAssets_idsAssetDivision_fkey" FOREIGN KEY ("idsAssetDivision") REFERENCES public."tblAssetDivisions"("idsAssetDivision") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3597 (class 2606 OID 51779)
-- Name: tblAssets tblAssets_idsAssetInfoG2BCode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssets"
    ADD CONSTRAINT "tblAssets_idsAssetInfoG2BCode_fkey" FOREIGN KEY ("idsAssetInfoG2BCode") REFERENCES public."pklstG2BInfos"("idsAssetsInfoG2B") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3598 (class 2606 OID 51784)
-- Name: tblAssets tblAssets_idsContractor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssets"
    ADD CONSTRAINT "tblAssets_idsContractor_fkey" FOREIGN KEY ("idsContractor") REFERENCES public."tblVendors"("idsVendor") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3599 (class 2606 OID 51789)
-- Name: tblAssets tblAssets_idsLocation_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssets"
    ADD CONSTRAINT "tblAssets_idsLocation_fkey" FOREIGN KEY ("idsLocation") REFERENCES public."tblLocation"("idsLocation") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3600 (class 2606 OID 51794)
-- Name: tblAssets tblAssets_idsParentAsset_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssets"
    ADD CONSTRAINT "tblAssets_idsParentAsset_fkey" FOREIGN KEY ("idsParentAsset") REFERENCES public."tblAssets"("idsAsset") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3601 (class 2606 OID 51799)
-- Name: tblAssets tblAssets_idsSite_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssets"
    ADD CONSTRAINT "tblAssets_idsSite_fkey" FOREIGN KEY ("idsSite") REFERENCES public."pklstSites"("idsSite") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3602 (class 2606 OID 51804)
-- Name: tblAssets tblAssets_idsStatus_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssets"
    ADD CONSTRAINT "tblAssets_idsStatus_fkey" FOREIGN KEY ("idsStatus") REFERENCES public."pklstAssetStatus"("idsAssetStatus") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3603 (class 2606 OID 51809)
-- Name: tblAssets tblAssets_idsVendor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblAssets"
    ADD CONSTRAINT "tblAssets_idsVendor_fkey" FOREIGN KEY ("idsVendor") REFERENCES public."tblVendors"("idsVendor") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3611 (class 2606 OID 51814)
-- Name: tblInventories tblInventories_idsInventoryDivision_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblInventories"
    ADD CONSTRAINT "tblInventories_idsInventoryDivision_fkey" FOREIGN KEY ("idsInventoryDivision") REFERENCES public."tblInventoryDivisions"("idsInventoryDivision") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3612 (class 2606 OID 51819)
-- Name: tblInventoryDivisions tblInventoryDivisions_idsInventoryCategory_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblInventoryDivisions"
    ADD CONSTRAINT "tblInventoryDivisions_idsInventoryCategory_fkey" FOREIGN KEY ("idsInventoryCategory") REFERENCES public."tblAssetCategories"("idsAssetCategory") ON DELETE RESTRICT;


--
-- TOC entry 3613 (class 2606 OID 51824)
-- Name: tblInventoryImages tblInventoryImages_idsInventory_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblInventoryImages"
    ADD CONSTRAINT "tblInventoryImages_idsInventory_fkey" FOREIGN KEY ("idsInventory") REFERENCES public."tblInventories"("idsInventory") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3614 (class 2606 OID 51829)
-- Name: tblInventoryTransactions tblInventoryTransactions_idsInventory_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblInventoryTransactions"
    ADD CONSTRAINT "tblInventoryTransactions_idsInventory_fkey" FOREIGN KEY ("idsInventory") REFERENCES public."tblInventories"("idsInventory") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3615 (class 2606 OID 51834)
-- Name: tblInventoryTransactions tblInventoryTransactions_idsSupplier_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblInventoryTransactions"
    ADD CONSTRAINT "tblInventoryTransactions_idsSupplier_fkey" FOREIGN KEY ("idsSupplier") REFERENCES public."tblVendors"("idsVendor") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3616 (class 2606 OID 51839)
-- Name: tblInventoryTransactions tblInventoryTransactions_idsTransactionType_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblInventoryTransactions"
    ADD CONSTRAINT "tblInventoryTransactions_idsTransactionType_fkey" FOREIGN KEY ("idsTransactionType") REFERENCES public."pklstInventoryTransactionTypes"("idsInventoryTansactionType") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3617 (class 2606 OID 51844)
-- Name: tblLocation tblLocation_idsLocationCategory_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblLocation"
    ADD CONSTRAINT "tblLocation_idsLocationCategory_fkey" FOREIGN KEY ("idsLocationCategory") REFERENCES public."pklstLocationCategories"("idsLocationCategory") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3618 (class 2606 OID 51849)
-- Name: tblLocation tblLocation_idsSite_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblLocation"
    ADD CONSTRAINT "tblLocation_idsSite_fkey" FOREIGN KEY ("idsSite") REFERENCES public."pklstSites"("idsSite") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3619 (class 2606 OID 51854)
-- Name: tblUsers tblUsers_idsDepartment_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblUsers"
    ADD CONSTRAINT "tblUsers_idsDepartment_fkey" FOREIGN KEY ("idsDepartment") REFERENCES public."pklstDepartments"("idsDepartment") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3620 (class 2606 OID 51859)
-- Name: tblVendorCategories tblVendorCategories_idsAssetCategory_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mes_usr
--

ALTER TABLE ONLY public."tblVendorCategories"
    ADD CONSTRAINT "tblVendorCategories_idsAssetCategory_fkey" FOREIGN KEY ("idsAssetCategory") REFERENCES public."tblAssetCategories"("idsAssetCategory") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3621 (class 2606 OID 51864)
-- Name: tblVendorCategories tblVendorCategories_idsVendor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mes_usr
--

ALTER TABLE ONLY public."tblVendorCategories"
    ADD CONSTRAINT "tblVendorCategories_idsVendor_fkey" FOREIGN KEY ("idsVendor") REFERENCES public."tblVendors"("idsVendor") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3622 (class 2606 OID 51869)
-- Name: tblcalibration_record tblcalibration_record_idsasset_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mes_usr
--

ALTER TABLE ONLY public.tblcalibration_record
    ADD CONSTRAINT tblcalibration_record_idsasset_fkey FOREIGN KEY (idsasset) REFERENCES public."tblAssets"("idsAsset") ON UPDATE CASCADE ON DELETE RESTRICT;


-- Completed on 2025-06-09 21:26:01

--
-- PostgreSQL database dump complete
--

