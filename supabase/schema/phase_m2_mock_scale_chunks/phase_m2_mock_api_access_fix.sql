-- Phase M2: Mock API access fix (custom schema = mocks)
-- Run this first.
-- Goal: fix PGRST106 + grant API roles + ensure RLS is not policy-empty.

begin;

-- 1) Schema + table existence sanity
create schema if not exists mocks;

-- 2) Permissions required by Data API roles
grant usage on schema mocks to anon, authenticated;
grant all on all tables in schema mocks to anon, authenticated;
grant usage, select on all sequences in schema mocks to anon, authenticated;

alter default privileges in schema mocks
grant all on tables to anon, authenticated;

alter default privileges in schema mocks
grant usage, select on sequences to anon, authenticated;

-- 3) PostgREST schema exposure via role config (SQL path, no UI dependency)
alter role authenticator set pgrst.db_schemas = 'public,graphql_public,mocks';
notify pgrst, 'reload config';
notify pgrst, 'reload schema';

-- 4) RLS safety: enable RLS on mocks tables, and if a table has zero policies,
-- create temporary authenticated allow-all policy (so API is not hard-blocked).
do $$
declare
  t record;
  v_policy_count integer;
begin
  for t in
    select c.relname as tablename
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'mocks'
      and c.relkind = 'r'
  loop
    execute format('alter table mocks.%I enable row level security', t.tablename);

    select count(*)
      into v_policy_count
    from pg_policies
    where schemaname = 'mocks'
      and tablename = t.tablename;

    if v_policy_count = 0 then
      execute format(
        'create policy p_tmp_allow_authenticated_all on mocks.%I for all to authenticated using (true) with check (true)',
        t.tablename
      );
    end if;
  end loop;
end $$;

commit;

-- Force one more schema refresh after policy/grant updates.
notify pgrst, 'reload schema';
