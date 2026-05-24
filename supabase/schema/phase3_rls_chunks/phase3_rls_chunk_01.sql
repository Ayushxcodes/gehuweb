-- Phase 3 RLS / Chunk 01
-- Grants + RLS enable + helper functions

grant usage on schema public to authenticated;

do $$
declare
  t text;
begin
  for t in
    select unnest(array[
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
    ])
  loop
    execute format('revoke all on table public.%I from anon, authenticated', t);
    execute format('grant select, insert, update, delete on table public.%I to authenticated', t);
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

create or replace function public.app_phase3_is_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  );
$$;

create or replace function public.app_phase3_uid_is_self(p_uid text)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.app_profile_state ps
    where ps.uid = p_uid
      and (
        ps.auth_user_id = (select auth.uid())
        or exists (
          select 1
          from public.app_user_identity ai
          where ai.auth_user_id = (select auth.uid())
            and ai.is_active = true
            and (
              (ps.student_id is not null and ai.student_id = ps.student_id)
              or (ps.employee_id is not null and ai.employee_id = ps.employee_id)
            )
        )
      )
  );
$$;

