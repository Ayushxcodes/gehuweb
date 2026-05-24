-- Phase E3 / Chunk 04
-- Atomic pending invite removal by team leader.

begin;

create or replace function public.api_event_remove_team_invite(
  p_event_id text, p_comp_id text, p_team_id text, p_invitee_student_id text
)
returns table(event_id text, comp_id text, team_id text, invitee_student_id text, status text)
language plpgsql security definer set search_path = public as $$
declare
  v_auth uuid := auth.uid(); v_leader text; v_invitee_uid text;
  v_team public.event_teams%rowtype; v_invite public.event_team_invites%rowtype; v_prev text;
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  select ai.student_id into v_leader from public.app_user_identity ai
  where ai.auth_user_id = v_auth and ai.is_active = true and ai.account_type = 'STUDENT' limit 1;
  if v_leader is null then raise exception 'STUDENT_ID_NOT_MAPPED'; end if;

  select * into v_team from public.event_teams t where t.event_id = p_event_id and t.comp_id = p_comp_id and t.team_id = p_team_id for update;
  if not found then raise exception 'TEAM_NOT_FOUND'; end if;
  if v_team.leader_student_id <> v_leader then raise exception 'ONLY_LEADER_CAN_REMOVE_INVITE'; end if;

  select * into v_invite from public.event_team_invites i
  where i.event_id = p_event_id and i.comp_id = p_comp_id and i.team_id = p_team_id and i.student_id = p_invitee_student_id for update;
  if not found then raise exception 'INVITE_NOT_FOUND'; end if;
  if v_invite.status = 'ACCEPTED' then raise exception 'INVITE_ALREADY_ACCEPTED_USE_MEMBER_REMOVE'; end if;

  select ps.uid into v_invitee_uid from public.app_profile_state ps where ps.student_id = p_invitee_student_id limit 1;
  select r.status into v_prev from public.event_registrations r where r.event_id = p_event_id and r.comp_id = p_comp_id and r.student_id = p_invitee_student_id for update;
  update public.event_team_invites i set status = 'CANCELLED', responded_at = now()
  where i.event_id = p_event_id and i.comp_id = p_comp_id and i.team_id = p_team_id and i.student_id = p_invitee_student_id;
  update public.event_team_members m set status = 'REMOVED'
  where m.event_id = p_event_id and m.comp_id = p_comp_id and m.team_id = p_team_id and m.student_id = p_invitee_student_id and m.status <> 'ACTIVE';
  update public.event_registrations r set previous_status = coalesce(v_prev, ''), status = 'CANCELLED', cancelled_at = now()
  where r.event_id = p_event_id and r.comp_id = p_comp_id and r.student_id = p_invitee_student_id and r.status not in ('ACCEPTED','REGISTERED','VERIFIED');
  if v_invitee_uid is not null then
    update public.app_inbox i set status = 'DISMISSED', read_at = coalesce(i.read_at, now())
    where i.uid = v_invitee_uid and i.inbox_id = v_invite.inbox_id;
  end if;
  return query select p_event_id, p_comp_id, p_team_id, p_invitee_student_id, 'CANCELLED'::text;
end;
$$;

grant execute on function public.api_event_remove_team_invite(text,text,text,text) to authenticated;
commit;

