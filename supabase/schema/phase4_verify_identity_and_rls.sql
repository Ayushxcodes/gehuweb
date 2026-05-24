-- Phase 4 verify: identity + RLS readiness

-- A) Identity coverage
select
  (select count(*) from auth.users) as auth_users_total,
  (select count(*) from public.app_user_identity where is_active = true) as identity_active_rows,
  (select count(*) from public.app_profile_state where auth_user_id is not null) as profile_linked_rows;

-- B) Coverage by type
select account_type, count(*) as rows
from public.app_user_identity
group by account_type
order by account_type;

-- C) Missing link diagnostics (students mapped but no profile row)
select ai.auth_user_id, ai.student_id
from public.app_user_identity ai
left join public.app_profile_state p on p.student_id = ai.student_id
where ai.account_type = 'STUDENT'
  and ai.student_id is not null
  and p.uid is null
limit 50;

-- D) Policy existence sanity
select tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename in (
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
order by tablename, policyname;

