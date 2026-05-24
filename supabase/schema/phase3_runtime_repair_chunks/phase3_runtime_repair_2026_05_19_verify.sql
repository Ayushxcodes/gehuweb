-- Phase 3 runtime repair verify / 2026-05-19

select
  n.nspname as schema_name,
  p.proname as function_name,
  p.prosecdef as security_definer
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('app_phase3_is_admin', 'app_phase3_uid_is_self')
order by p.proname;

select
  schemaname,
  tablename,
  policyname,
  cmd,
  roles,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename in (
    'app_appeals',
    'app_official_feedback',
    'app_notices',
    'app_notice_attachments'
  )
order by tablename, policyname;