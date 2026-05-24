-- Phase M1: Verification queries for mock schema + policies
-- Run after: phase_m1_mock_schema.sql and phase_m1_mock_rls.sql

-- 1) Confirm mock tables exist
select table_schema, table_name
from information_schema.tables
where table_schema = 'mocks'
order by table_name;

-- 2) Confirm RLS is enabled
select schemaname, tablename, rowsecurity
from pg_tables
where schemaname = 'mocks'
order by tablename;

-- 3) Confirm policy coverage
select schemaname, tablename, policyname, cmd, roles
from pg_policies
where schemaname = 'mocks'
order by tablename, policyname;

-- 4) Confirm grants for authenticated
select table_schema, table_name, grantee, privilege_type
from information_schema.role_table_grants
where table_schema = 'mocks'
  and grantee = 'authenticated'
order by table_name, privilege_type;

-- 5) Confirm helper functions exist
select n.nspname as schema_name, p.proname as function_name
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'mocks'
  and p.proname in ('current_auth_uid', 'current_student_id', 'is_admin')
order by p.proname;

-- 6) Identity table sanity (expected: 0 rows initially)
select count(*) as identity_rows
from public.app_user_identity;
