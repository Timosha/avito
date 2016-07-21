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
-- Name: add_user(character varying, integer); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION add_user(p_login character varying, p_status integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  check integer;
begin
  begin
    select 1
      into check
      from user_statuses
      where status = p_status;
  exception 
    when no_data_found then
       raise exception 'Invalid status value: %', p_status;
  end;
  begin
    insert into users (login, status) values (p_login, p_status);
  exception
    when others then 
      raise exception 'Duplicate login: %', p_login;
  end;
end;
$$;


ALTER FUNCTION public.add_user(p_login character varying, p_status integer) OWNER TO admin;

--
-- Name: add_user_address(character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION add_user_address(p_login character varying, p_address character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  user_id bigint;  
begin
  begin
    select id
      into user_id
      from users
      where login = p_login;
  exception 
    when no_data_found then
       raise exception 'No user with login: %', p_login;
  end;  
  insert into addresses (user_id, address) values (user_id, p_address);             
  
end;
$$;


ALTER FUNCTION public.add_user_address(p_login character varying, p_address character varying) OWNER TO admin;

--
-- Name: get_address_count(character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION get_address_count(p_address character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
  declare
    v_count integer;
  begin
    select count(*)
	into v_count
	from addresses
	where address = p_address;
    return v_count;
  end;
  $$;


ALTER FUNCTION public.get_address_count(p_address character varying) OWNER TO admin;

--
-- Name: get_all_users_cards(); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION get_all_users_cards() RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
  ret_val json;  
begin          
  select row_to_json(tt) 
    into ret_val
    from (
    select array_agg(row_to_json(t)) as users
      from (
        select 
	  login, 
	  min(status) as status,
          array_agg(addresses.address) as addresses
          from users left join addresses  on users.id = addresses.user_id 
          group by users.login) t) tt;
        
  return ret_val;  
end;
$$;


ALTER FUNCTION public.get_all_users_cards() OWNER TO admin;

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
-- Name: get_user_card(character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION get_user_card(p_login character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
  ret_val json;  
begin    
  perform 1 from users where login = p_login;
  if not found then
    raise exception 'User % is not exists', p_login;
  end if;
    
  select row_to_json(t) 
    into ret_val
    from (
      select 
	min(login) as login, 
	min(status) as status,
        array_agg(addresses.address) as addresses
        from users left join addresses  on users.id = addresses.user_id 
        where users.login = p_login) t;      
        
  return ret_val;  
end;
$$;


ALTER FUNCTION public.get_user_card(p_login character varying) OWNER TO admin;

--
-- Name: get_users(); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION get_users() RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
  ret_val json;
begin
  select row_to_json(t)
    into ret_val
    from (
      select array_agg(login) as users from users
    ) t;
  return ret_val;
end;
$$;


ALTER FUNCTION public.get_users() OWNER TO admin;

--
-- Name: remove_address(character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION remove_address(p_login character varying, p_address character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  v_user_id bigint;
begin
  select id
    into v_user_id
    from users
    where login = p_login;
  delete from addresses where user_id = v_user_id and address = p_address;
end;
$$;


ALTER FUNCTION public.remove_address(p_login character varying, p_address character varying) OWNER TO admin;

--
-- Name: try_add_user_address(character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION try_add_user_address(p_login character varying, p_address character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  user_id bigint;  
begin
  begin
    select id
      into user_id
      from users
      where login = p_login;
  exception 
    when no_data_found then
       raise exception 'No user with login: %', p_login;
  end;      
  perform pgq.insert_event('UsersToAddresses', 'I', p_login, p_address, '', '', '');  
  
end;
$$;


ALTER FUNCTION public.try_add_user_address(p_login character varying, p_address character varying) OWNER TO admin;

--
-- Name: try_remove_address(character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION try_remove_address(p_login character varying, p_address character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  v_addr_id bigint;
begin
  begin
    select addresses.id 
      into v_addr_id
      from users join addresses on users.id = addresses.user_id
      where users.login = p_login and addresses.address = p_address;
  exception
    when no_data_found then
      raise exception 'User % does not have such address', p_login;
  end;
  perform pgq.insert_event('UsersToAddresses', 'D', p_login, p_address, '', '', '');
end;
$$;


ALTER FUNCTION public.try_remove_address(p_login character varying, p_address character varying) OWNER TO admin;

--
-- Name: try_update_user_address(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION try_update_user_address(p_login character varying, p_old_address character varying, p_new_address character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
  begin
    perform pgq.insert_event('UsersToAddresses', 'U', p_login, p_old_address, p_new_address, '', '');
  end;
  $$;


ALTER FUNCTION public.try_update_user_address(p_login character varying, p_old_address character varying, p_new_address character varying) OWNER TO admin;

--
-- Name: update_address(character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION update_address(p_old_address character varying, p_new_address character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare    
begin
  update addresses set address = p_new_address where address = p_old_address;
end;
$$;


ALTER FUNCTION public.update_address(p_old_address character varying, p_new_address character varying) OWNER TO admin;

--
-- Name: update_user_address(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION update_user_address(p_login character varying, p_old_address character varying, p_new_address character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  v_user_id bigint;
  v_status integer;  
begin    
  begin
    select id, status
      into v_user_id, v_status
      from users
      where login = p_login;
  exception 
    when no_data_found then
       raise notice 'No user with login: %', p_login;
       return;
  end;  
  
  if v_status != 3 then
    raise notice 'User have readonly status';
    return;
  end if;
    
  begin
    update addresses set address = p_new_address where user_id = v_user_id and address = p_old_address;
  exception
    when others then
	raise notice 'User % already have this address', p_login;
	return;
  end;   
end;
$$;


ALTER FUNCTION public.update_user_address(p_login character varying, p_old_address character varying, p_new_address character varying) OWNER TO admin;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: addresses; Type: TABLE; Schema: public; Owner: admin; Tablespace: 
--

CREATE TABLE addresses (
    id bigint NOT NULL,
    user_id bigint,
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
-- Name: ret_val; Type: TABLE; Schema: public; Owner: admin; Tablespace: 
--

CREATE TABLE ret_val (
    row_to_json json
);


ALTER TABLE ret_val OWNER TO admin;

--
-- Name: user_statuses; Type: TABLE; Schema: public; Owner: admin; Tablespace: 
--

CREATE TABLE user_statuses (
    status integer,
    descr character varying(256)
);


ALTER TABLE user_statuses OWNER TO admin;

--
-- Name: users; Type: TABLE; Schema: public; Owner: admin; Tablespace: 
--

CREATE TABLE users (
    id bigint NOT NULL,
    login character varying(256) NOT NULL,
    status integer DEFAULT 1 NOT NULL
);


ALTER TABLE users OWNER TO admin;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_id_seq OWNER TO admin;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY addresses ALTER COLUMN id SET DEFAULT nextval('addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: admin; Tablespace: 
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: unq_pair; Type: CONSTRAINT; Schema: public; Owner: admin; Tablespace: 
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT unq_pair UNIQUE (user_id, address);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: admin; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: addresses_user_id_idx; Type: INDEX; Schema: public; Owner: admin; Tablespace: 
--

CREATE INDEX addresses_user_id_idx ON addresses USING btree (user_id);


--
-- Name: users_login_idx; Type: INDEX; Schema: public; Owner: admin; Tablespace: 
--

CREATE UNIQUE INDEX users_login_idx ON users USING btree (login);


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

