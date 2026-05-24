-- Phase E1 / Chunk 08
-- RLS for private student/team/payment/result tables.

begin;

drop policy if exists p_e1_reg_read on public.event_registrations;
create policy p_e1_reg_read on public.event_registrations
for select to authenticated
using (public.app_event_is_admin() or student_id = public.app_event_current_student_id());

drop policy if exists p_e1_participants_read on public.event_participants;
create policy p_e1_participants_read on public.event_participants
for select to authenticated
using (public.app_event_is_admin() or student_id = public.app_event_current_student_id());

drop policy if exists p_e1_teams_read on public.event_teams;
create policy p_e1_teams_read on public.event_teams
for select to authenticated
using (
  public.app_event_is_admin()
  or leader_student_id = public.app_event_current_student_id()
  or public.app_event_is_team_member(event_id, comp_id, team_id)
);

drop policy if exists p_e1_team_members_read on public.event_team_members;
create policy p_e1_team_members_read on public.event_team_members
for select to authenticated
using (
  public.app_event_is_admin()
  or student_id = public.app_event_current_student_id()
  or public.app_event_is_team_member(event_id, comp_id, team_id)
);

drop policy if exists p_e1_invites_read on public.event_team_invites;
create policy p_e1_invites_read on public.event_team_invites
for select to authenticated
using (
  public.app_event_is_admin()
  or student_id = public.app_event_current_student_id()
  or exists (
    select 1 from public.event_teams t
    where t.event_id = event_team_invites.event_id
      and t.comp_id = event_team_invites.comp_id
      and t.team_id = event_team_invites.team_id
      and t.leader_student_id = public.app_event_current_student_id()
  )
);

drop policy if exists p_e1_payment_read on public.event_payment_records;
create policy p_e1_payment_read on public.event_payment_records
for select to authenticated
using (public.app_event_is_admin() or student_id = public.app_event_current_student_id());

drop policy if exists p_e1_attendance_read on public.event_attendance;
create policy p_e1_attendance_read on public.event_attendance
for select to authenticated
using (public.app_event_is_admin() or public.app_event_is_team_member(event_id, comp_id, team_id));

drop policy if exists p_e1_attendance_members_read on public.event_attendance_members;
create policy p_e1_attendance_members_read on public.event_attendance_members
for select to authenticated
using (public.app_event_is_admin() or public.app_event_is_team_member(event_id, comp_id, team_id));

drop policy if exists p_e1_results_read on public.event_results;
create policy p_e1_results_read on public.event_results
for select to authenticated
using (
  public.app_event_is_admin()
  or (published = true and public.app_event_is_team_member(event_id, comp_id, team_id))
);

drop policy if exists p_e1_certs_read on public.event_certificates;
create policy p_e1_certs_read on public.event_certificates
for select to authenticated
using (public.app_event_is_admin() or student_id = public.app_event_current_student_id());

drop policy if exists p_e1_group_channels_read on public.event_group_channels;
create policy p_e1_group_channels_read on public.event_group_channels
for select to authenticated
using (
  public.app_event_is_admin()
  or public.app_event_is_group_member(event_id, comp_id, group_id)
);

drop policy if exists p_e1_group_members_read on public.event_group_members;
create policy p_e1_group_members_read on public.event_group_members
for select to authenticated
using (
  public.app_event_is_admin()
  or student_id = public.app_event_current_student_id()
  or public.app_event_is_group_member(event_id, comp_id, group_id)
);

drop policy if exists p_e1_group_messages_read on public.event_group_messages;
create policy p_e1_group_messages_read on public.event_group_messages
for select to authenticated
using (
  public.app_event_is_admin()
  or public.app_event_is_group_member(event_id, comp_id, group_id)
);

commit;
