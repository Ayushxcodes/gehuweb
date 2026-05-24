-- Phase 3 RLS / Chunk 02
-- Profile + appeals + feedback + inbox + read/meta

drop policy if exists p3_profile_select on public.app_profile_state;
create policy p3_profile_select
on public.app_profile_state
for select to authenticated
using (
  public.app_phase3_is_admin()
  or auth_user_id = (select auth.uid())
  or public.app_phase3_uid_is_self(uid)
);

drop policy if exists p3_profile_insert on public.app_profile_state;
create policy p3_profile_insert
on public.app_profile_state
for insert to authenticated
with check (
  public.app_phase3_is_admin()
  or auth_user_id = (select auth.uid())
);

drop policy if exists p3_profile_update on public.app_profile_state;
create policy p3_profile_update
on public.app_profile_state
for update to authenticated
using (
  public.app_phase3_is_admin()
  or auth_user_id = (select auth.uid())
  or public.app_phase3_uid_is_self(uid)
)
with check (
  public.app_phase3_is_admin()
  or auth_user_id = (select auth.uid())
);

drop policy if exists p3_profile_delete on public.app_profile_state;
create policy p3_profile_delete
on public.app_profile_state
for delete to authenticated
using (public.app_phase3_is_admin());

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

