-- Verify RLS status for all phase-1 tables

select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'r'
  and (
    c.relname like 'stu\_%' escape '\'
    or c.relname like 'emp\_%' escape '\'
    or c.relname like 'student\_%' escape '\'
    or c.relname like 'employee\_%' escape '\'
  )
order by c.relname;

-- Optional quick summary:
-- select
--   count(*) filter (where c.relrowsecurity) as rls_enabled_count,
--   count(*) as total_count
-- from pg_class c
-- join pg_namespace n on n.oid = c.relnamespace
-- where n.nspname = 'public'
--   and c.relkind = 'r'
--   and (
--     c.relname like 'stu\_%' escape '\'
--     or c.relname like 'emp\_%' escape '\'
--     or c.relname like 'student\_%' escape '\'
--     or c.relname like 'employee\_%' escape '\'
--   );
