-- Phase 3 quick verification (schema + RLS)

-- 1) expected app_* tables
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'app_profile_state',
    'app_appeals',
    'app_official_feedback',
    'app_inbox',
    'app_notice_reads',
    'app_notification_meta',
    'app_notices',
    'app_notice_attachments',
    'app_notifications',
    'app_directory_index'
  )
order by table_name;

-- 2) RLS enabled check
select tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename like 'app_%'
order by tablename;

-- 3) policy coverage
select tablename, policyname, cmd, roles
from pg_policies
where schemaname = 'public'
  and tablename like 'app_%'
order by tablename, policyname;

