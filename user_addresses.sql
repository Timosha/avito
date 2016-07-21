--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

--
-- Name: add_address(character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION add_address(p_address character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
  insert into addresses (address) values(p_address);
exception
  when others then
    raise notice 'Address already exists %', p_address;
end;
$$;


ALTER FUNCTION public.add_address(p_address character varying) OWNER TO admin;

--
-- Name: get_addresses(); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION get_addresses() RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
  ret_val json;
begin
  select row_to_json(t)
    into ret_val
    from (
      select array_agg(address) as addresses from addresses
    ) t;
  return ret_val;
end;
$$;


ALTER FUNCTION public.get_addresses() OWNER TO admin;

--
-- Name: get_lock(); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION get_lock() RETURNS void
    LANGUAGE plpgsql
    AS $$
  begin    
     lock table addresses;
  end;
  $$;


ALTER FUNCTION public.get_lock() OWNER TO admin;

--
-- Name: remove_address(character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION remove_address(p_address character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin  
  delete from addresses where address = p_address;
end;
$$;


ALTER FUNCTION public.remove_address(p_address character varying) OWNER TO admin;

--
-- Name: try_update_address(character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION try_update_address(p_old_address character varying, p_new_address character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin  
  perform pgq.insert_event('AddressesToUsers', 'U', p_old_address, p_new_address, '', '', '');
end;
$$;


ALTER FUNCTION public.try_update_address(p_old_address character varying, p_new_address character varying) OWNER TO admin;

--
-- Name: update_address(character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION update_address(p_old_address character varying, p_new_address character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
  begin        
    update addresses set address = p_new_address where address = p_old_address;  
  exception
    when others then
      raise notice 'Address already exists %', p_new_address;
      delete from addresses where address = p_old_address;
      return;
  end;  
end;
$$;


ALTER FUNCTION public.update_address(p_old_address character varying, p_new_address character varying) OWNER TO admin;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: addresses; Type: TABLE; Schema: public; Owner: admin; Tablespace: 
--

CREATE TABLE addresses (
    id bigint NOT NULL,
    address character varying(1024)
);


ALTER TABLE addresses OWNER TO admin;

--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE addresses_id_seq OWNER TO admin;

--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE addresses_id_seq OWNED BY addresses.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY addresses ALTER COLUMN id SET DEFAULT nextval('addresses_id_seq'::regclass);


--
-- Name: addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: admin; Tablespace: 
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: address_idx; Type: INDEX; Schema: public; Owner: admin; Tablespace: 
--

CREATE UNIQUE INDEX address_idx ON addresses USING btree (address);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

