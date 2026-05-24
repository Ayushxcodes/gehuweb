-- Phase E3 / Chunk 01
-- Atomic team invite send RPC.

begin;

create or replace function public.api_event_send_team_invite(
  p_event_id text, p_comp_id text, p_team_id text, p_invitee_student_id text
)
returns table(event_id text, comp_id text, team_id text, invitee_student_id text, invite_status text, inbox_id text)
language plpgsql security definer set search_path = public as $$
declare
  v_auth uuid := auth.uid();
  v_leader text; v_leader_uid text; v_invitee_auth uuid; v_invitee_uid text;
  v_event public.event_core%rowtype; v_comp public.event_competitions%rowtype;
  v_team public.event_teams%rowtype; v_taken int; v_existing text; v_inbox text;
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  select ai.student_id, ps.uid into v_leader, v_leader_uid
  from public.app_user_identity ai left join public.app_profile_state ps on ps.student_id = ai.student_id
  where ai.auth_user_id = v_auth and ai.is_active = true and ai.account_type = 'STUDENT' limit 1;
  if v_leader is null then raise exception 'STUDENT_ID_NOT_MAPPED'; end if;
  if p_invitee_student_id = v_leader then raise exception 'CANNOT_INVITE_SELF'; end if;

  select * into v_event from public.event_core e where e.event_id = p_event_id for update;
  if not found then raise exception 'EVENT_NOT_FOUND'; end if;
  select * into v_comp from public.event_competitions c where c.event_id = p_event_id and c.comp_id = p_comp_id for update;
  if not found then raise exception 'COMPETITION_NOT_FOUND'; end if;
  select * into v_team from public.event_teams t where t.event_id = p_event_id and t.comp_id = p_comp_id and t.team_id = p_team_id for update;
  if not found then raise exception 'TEAM_NOT_FOUND'; end if;

  if v_team.leader_student_id <> v_leader then raise exception 'ONLY_LEADER_CAN_INVITE'; end if;
  if v_team.team_locked or not v_team.active or v_team.team_status in ('LOCKED','CANCELLED') then raise exception 'TEAM_LOCKED'; end if;
  if v_event.event_interaction_locked or v_event.finalized or v_event.is_cancelled or not v_event.is_live then raise exception 'EVENT_CLOSED'; end if;
  if not v_comp.is_live or v_comp.participation_mode not in ('TEAM','BOTH') then raise exception 'TEAM_NOT_ALLOWED'; end if;
  if coalesce(v_comp.registration_deadline, v_event.registration_deadline) is not null
     and coalesce(v_comp.registration_deadline, v_event.registration_deadline) <= now() then raise exception 'REGISTRATION_DEADLINE_PASSED'; end if;

  select ai.auth_user_id, ps.uid into v_invitee_auth, v_invitee_uid
  from public.app_user_identity ai join public.app_profile_state ps on ps.student_id = ai.student_id
  where ai.student_id = p_invitee_student_id and ai.is_active = true and ai.account_type = 'STUDENT' limit 1;
  if v_invitee_auth is null or v_invitee_uid is null then raise exception 'INVITEE_NOT_MAPPED'; end if;

  select status, inbox_id into v_existing, v_inbox from public.event_team_invites
  where i.event_id = p_event_id and i.comp_id = p_comp_id and i.team_id = p_team_id and i.student_id = p_invitee_student_id for update;
  if v_existing = 'PENDING' then return query select p_event_id, p_comp_id, p_team_id, p_invitee_student_id, v_existing, v_inbox; return; end if;
  if v_existing = 'ACCEPTED' then raise exception 'INVITE_ALREADY_ACCEPTED'; end if;
  if exists (select 1 from public.event_registrations r where r.event_id = p_event_id and r.comp_id = p_comp_id and r.student_id = p_invitee_student_id and r.status <> 'CANCELLED') then raise exception 'ALREADY_REGISTERED'; end if;

  select count(*)::int into v_taken from (
    select m.student_id from public.event_team_members m where m.event_id = p_event_id and m.comp_id = p_comp_id and m.team_id = p_team_id and m.status = 'ACTIVE'
    union select i.student_id from public.event_team_invites i where i.event_id = p_event_id and i.comp_id = p_comp_id and i.team_id = p_team_id and i.status = 'PENDING'
  ) s;
  if v_taken >= v_team.max_members then raise exception 'TEAM_FULL'; end if;

  v_inbox := 'event_invite_' || substr(md5(p_event_id || ':' || p_comp_id || ':' || p_team_id || ':' || p_invitee_student_id), 1, 24);
  insert into public.event_team_invites(event_id, comp_id, team_id, student_id, invited_by_student_id, status, inbox_id)
  values (p_event_id, p_comp_id, p_team_id, p_invitee_student_id, v_leader, 'PENDING', v_inbox)
  on conflict (event_id, comp_id, team_id, student_id) do update set status = 'PENDING', invited_by_student_id = excluded.invited_by_student_id, inbox_id = excluded.inbox_id, responded_at = null;
  insert into public.event_team_members(event_id, comp_id, team_id, student_id, auth_user_id, role, status)
  values (p_event_id, p_comp_id, p_team_id, p_invitee_student_id, v_invitee_auth, 'MEMBER', 'INVITED')
  on conflict (event_id, comp_id, team_id, student_id) do update set status = 'INVITED', auth_user_id = excluded.auth_user_id;
  insert into public.event_registrations(event_id, comp_id, student_id, auth_user_id, mode, team_id, role, status, invited_by_student_id, category)
  values (p_event_id, p_comp_id, p_invitee_student_id, v_invitee_auth, 'team', p_team_id, 'MEMBER', 'PENDING', v_leader, v_team.category)
  on conflict (event_id, comp_id, student_id) do update set status = 'PENDING', team_id = excluded.team_id, invited_by_student_id = excluded.invited_by_student_id where public.event_registrations.status = 'CANCELLED';
  insert into public.app_inbox(uid, inbox_id, type, title, body, status, event_id, comp_id, team_id, from_uid, target_id, payload_json)
  values (v_invitee_uid, v_inbox, 'TEAM_INVITE', 'Team Invite', 'You have been invited to join a team.', 'UNREAD', p_event_id, p_comp_id, p_team_id, coalesce(v_leader_uid,''), p_invitee_student_id, jsonb_build_object('student_id', p_invitee_student_id, 'leader_student_id', v_leader))
  on conflict (uid, inbox_id) do update set status = 'UNREAD', updated_at = now(), payload_json = excluded.payload_json;
  return query select p_event_id, p_comp_id, p_team_id, p_invitee_student_id, 'PENDING'::text, v_inbox;
end;
$$;

grant execute on function public.api_event_send_team_invite(text,text,text,text) to authenticated;
commit;
