-- Phase N1 / Chunk 03
-- Verification for notice/mail RPC contract.

select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'app_current_profile_uid',
    'api_student_notice_feed',
    'api_mark_notice_read'
  )
order by p.proname;

select
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  count(pol.polname) as policy_count
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
left join pg_policy pol on pol.polrelid = c.oid
where n.nspname = 'public'
  and c.relname in ('app_notices', 'app_notice_attachments', 'app_notice_reads')
group by c.relname, c.relrowsecurity
order by c.relname;

select *
from public.api_student_notice_feed('ALL', 'ALL', null, 5, null, null);
