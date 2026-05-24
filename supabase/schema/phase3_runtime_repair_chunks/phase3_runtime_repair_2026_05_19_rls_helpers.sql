-- Phase 3 runtime repair / 2026-05-19
-- Fixes Supabase-only permission denied on profile appeals and admin notice/appeal writes.
-- Security goal: keep RLS enabled, but make helper predicates reliable inside RLS policies.

begin;

grant usage on schema public to authenticated;

grant select on table public.app_user_identity to authenticated;
grant select, insert, update, delete on table public.app_profile_state to authenticated;
grant select, insert, update, delete on table public.app_appeals to authenticated;
grant select, insert, update, delete on table public.app_official_feedback to authenticated;
grant select, insert, update, delete on table public.app_notices to authenticated;
grant select, insert, update, delete on table public.app_notice_attachments to authenticated;

alter table public.app_profile_state enable row level security;
alter table public.app_appeals enable row level security;
alter table public.app_official_feedback enable row level security;
alter table public.app_notices enable row level security;
alter table public.app_notice_attachments enable row level security;

create or replace function public.app_phase3_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, auth, pg_temp
as $$
  select exists (
    select 1
    from public.app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and upper(ai.account_type) = 'ADMIN'
  );
$$;

create or replace function public.app_phase3_uid_is_self(p_uid text)
returns boolean
language sql
stable
security definer
set search_path = public, auth, pg_temp
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

grant execute on function public.app_phase3_is_admin() to authenticated;
grant execute on function public.app_phase3_uid_is_self(text) to authenticated;

-- Re-apply only the affected policies so live DBs with older helpers become deterministic.
drop policy if exists p3_appeals_select on public.app_appeals;
create policy p3_appeals_select
on public.app_appeals
for select to authenticated
using (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid));

drop policy if exists p3_appeals_insert on public.app_appeals;
create policy p3_appeals_insert
on public.app_appeals
for insert to authenticated
with check (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid));

drop policy if exists p3_appeals_update_admin on public.app_appeals;
create policy p3_appeals_update_admin
on public.app_appeals
for update to authenticated
using (public.app_phase3_is_admin())
with check (public.app_phase3_is_admin());

drop policy if exists p3_appeals_delete_admin on public.app_appeals;
create policy p3_appeals_delete_admin
on public.app_appeals
for delete to authenticated
using (public.app_phase3_is_admin());

drop policy if exists p3_feedback_select on public.app_official_feedback;
create policy p3_feedback_select
on public.app_official_feedback
for select to authenticated
using (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid));

drop policy if exists p3_feedback_write_admin on public.app_official_feedback;
create policy p3_feedback_write_admin
on public.app_official_feedback
for all to authenticated
using (public.app_phase3_is_admin())
with check (public.app_phase3_is_admin());

drop policy if exists p3_notices_select on public.app_notices;
create policy p3_notices_select
on public.app_notices
for select to authenticated
using (true);

drop policy if exists p3_notices_write_admin on public.app_notices;
create policy p3_notices_write_admin
on public.app_notices
for all to authenticated
using (public.app_phase3_is_admin())
with check (public.app_phase3_is_admin());

drop policy if exists p3_notice_attachments_select on public.app_notice_attachments;
create policy p3_notice_attachments_select
on public.app_notice_attachments
for select to authenticated
using (true);

drop policy if exists p3_notice_attachments_write_admin on public.app_notice_attachments;
create policy p3_notice_attachments_write_admin
on public.app_notice_attachments
for all to authenticated
using (public.app_phase3_is_admin())
with check (public.app_phase3_is_admin());

commit;