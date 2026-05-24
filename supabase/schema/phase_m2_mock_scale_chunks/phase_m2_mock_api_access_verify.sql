-- Phase M2: Verify mock API access
-- Run after phase_m2_mock_api_access_fix.sql

-- A) Root-cause visibility
select
  exists(select 1 from pg_namespace where nspname = 'mocks') as schema_mocks_exists,
  to_regclass('mocks.mock_tests') is not null as table_mock_tests_exists,
  current_setting('pgrst.db_schemas', true) as db_schemas_session_setting,
  (select rolconfig from pg_roles where rolname = 'authenticator') as authenticator_role_config;

-- B) Grants check
select
  has_schema_privilege('anon', 'mocks', 'USAGE') as anon_schema_usage,
  has_schema_privilege('authenticated', 'mocks', 'USAGE') as auth_schema_usage,
  has_table_privilege('anon', 'mocks.mock_tests', 'SELECT,INSERT,UPDATE,DELETE') as anon_mock_tests_all,
  has_table_privilege('authenticated', 'mocks.mock_tests', 'SELECT,INSERT,UPDATE,DELETE') as auth_mock_tests_all;

-- C) RLS + policies check
select
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  count(p.policyname) as policy_count
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
left join pg_policies p on p.schemaname = n.nspname and p.tablename = c.relname
where n.nspname = 'mocks'
  and c.relkind = 'r'
group by c.relname, c.relrowsecurity
order by c.relname;

-- D) Data API enabled hint (if Data API disabled globally, API calls still fail outside SQL scope)
select
  case
    when current_setting('pgrst.db_schemas', true) is null then 'UNKNOWN_OR_NOT_VISIBLE_IN_SESSION'
    else 'PGRST_CONFIG_VISIBLE'
  end as data_api_hint;
