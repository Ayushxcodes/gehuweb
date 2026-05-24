-- GEHU Connect profile appeal + notice/mail smoke
-- Date: 2026-05-20
-- Purpose: read-only checks for the next stabilized layer after auth route.

select
  to_regclass('public.app_appeals') is not null as has_appeals_table,
  to_regclass('public.app_notices') is not null as has_notices_table,
  to_regclass('public.app_notice_reads') is not null as has_notice_reads_table,
  to_regclass('public.app_notice_attachments') is not null as has_notice_attachments_table,
  to_regprocedure('public.api_student_notice_feed(text,text,integer,integer,timestamp with time zone,text)') is not null as has_notice_feed_rpc,
  to_regprocedure('public.api_mark_notice_read(text)') is not null as has_mark_notice_read_rpc,
  exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'app_appeals' and column_name = 'resolved_by_auth_user_id'
  ) as appeals_has_resolved_by,
  exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'app_notices' and column_name = 'created_by_uid'
  ) as notices_has_created_by,
  exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'app_profile_state' and column_name = 'edit_unlocked_until'
  ) as profile_has_unlock_until;