-- Phase B1 / Chunk 05
-- Notification bell quick verification.

select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'app_current_notification_target_keys',
    'api_student_notification_feed',
    'api_student_notification_badge_count',
    'api_mark_inbox_notification_read',
    'api_touch_notification_seen',
    'api_dismiss_notifications'
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
  and c.relname in ('app_inbox', 'app_notifications', 'app_notification_meta')
group by c.relname, c.relrowsecurity
order by c.relname;

select
  (select count(*) from public.app_inbox) as inbox_rows,
  (select count(*) from public.app_notifications) as notification_rows,
  (select count(*) from public.app_notification_meta) as notification_meta_rows;
