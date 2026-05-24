-- Phase E1 / Chunk 11
-- Verification for event foundation.

select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name like 'event_%'
order by table_name;

select
  count(*) filter (where c.relrowsecurity) as rls_enabled_tables,
  count(*) as event_tables
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'r'
  and c.relname like 'event_%';

select routine_name, data_type
from information_schema.routines
where routine_schema = 'public'
  and routine_name in (
    'app_event_is_admin',
    'app_event_current_student_id',
    'app_event_is_team_member',
    'app_event_is_group_member',
    'app_event_visible',
    'api_student_event_feed',
    'api_student_event_detail',
    'api_verify_event_certificate'
  )
order by routine_name;

select tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename like 'event_%'
order by tablename, policyname;
