-- Phase E3 / Chunk 02
-- Atomic team invite accept RPC.

begin;

create or replace function public.api_event_accept_team_invite(
  p_event_id text, p_comp_id text, p_team_id text
)
returns table(event_id text, comp_id text, team_id text, student_id text, status text)
language plpgsql security definer set search_path = public as $$
declare
  v_auth uuid := auth.uid(); v_student text; v_uid text;
  v_event public.event_core%rowtype; v_comp public.event_competitions%rowtype; v_team public.event_teams%rowtype;
  v_invite public.event_team_invites%rowtype; v_prev text; v_active int; v_new_status text := 'ACCEPTED';
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  select ai.student_id, ps.uid into v_student, v_uid
  from public.app_user_identity ai left join public.app_profile_state ps on ps.student_id = ai.student_id
  where ai.auth_user_id = v_auth and ai.is_active = true and ai.account_type = 'STUDENT' limit 1;
  if v_student is null then raise exception 'STUDENT_ID_NOT_MAPPED'; end if;

  select * into v_event from public.event_core e where e.event_id = p_event_id for update;
  if not found then raise exception 'EVENT_NOT_FOUND'; end if;
  select * into v_comp from public.event_competitions c where c.event_id = p_event_id and c.comp_id = p_comp_id for update;
  if not found then raise exception 'COMPETITION_NOT_FOUND'; end if;
  select * into v_team from public.event_teams t where t.event_id = p_event_id and t.comp_id = p_comp_id and t.team_id = p_team_id for update;
  if not found then raise exception 'TEAM_NOT_FOUND'; end if;
  select * into v_invite from public.event_team_invites i where i.event_id = p_event_id and i.comp_id = p_comp_id and i.team_id = p_team_id and i.student_id = v_student for update;
  if not found then raise exception 'INVITE_NOT_FOUND'; end if;
  if v_invite.status <> 'PENDING' then raise exception 'INVITE_NOT_PENDING'; end if;

  if v_team.team_locked or not v_team.active or v_team.team_status in ('LOCKED','CANCELLED') then raise exception 'TEAM_LOCKED'; end if;
  if v_event.event_interaction_locked or v_event.finalized or v_event.is_cancelled or not v_event.is_live then raise exception 'EVENT_CLOSED'; end if;
  if coalesce(v_comp.registration_deadline, v_event.registration_deadline) is not null
     and coalesce(v_comp.registration_deadline, v_event.registration_deadline) <= now() then raise exception 'REGISTRATION_DEADLINE_PASSED'; end if;

  select count(*)::int into v_active from public.event_team_members m
  where m.event_id = p_event_id and m.comp_id = p_comp_id and m.team_id = p_team_id and m.status = 'ACTIVE';
  if v_active >= v_team.max_members then raise exception 'TEAM_FULL'; end if;

  select r.status into v_prev from public.event_registrations r where r.event_id = p_event_id and r.comp_id = p_comp_id and r.student_id = v_student for update;
  update public.event_team_invites i set status = 'ACCEPTED', responded_at = now() where i.event_id = p_event_id and i.comp_id = p_comp_id and i.team_id = p_team_id and i.student_id = v_student;
  update public.event_team_members m set status = 'ACTIVE', joined_at = now(), auth_user_id = v_auth where m.event_id = p_event_id and m.comp_id = p_comp_id and m.team_id = p_team_id and m.student_id = v_student;
  insert into public.event_registrations(event_id, comp_id, student_id, auth_user_id, mode, team_id, role, status, accepted_at, invited_by_student_id, category)
  values (p_event_id, p_comp_id, v_student, v_auth, 'team', p_team_id, 'MEMBER', v_new_status, now(), v_invite.invited_by_student_id, v_team.category)
  on conflict (event_id, comp_id, student_id) do update set previous_status = event_registrations.status, status = excluded.status, accepted_at = now(), auth_user_id = excluded.auth_user_id;

  if not public.app_event_is_visible_registration_status(coalesce(v_prev, '')) then
    insert into public.event_participants(event_id, student_id, auth_user_id, status, comp_ids)
    values (p_event_id, v_student, v_auth, v_new_status, array[p_comp_id])
    on conflict (event_id, student_id) do update set comp_ids = (select array_agg(distinct x) from unnest(public.event_participants.comp_ids || excluded.comp_ids) u(x)), status = excluded.status, updated_at = now();
    update public.event_competitions c set reg_count = c.reg_count + 1 where c.event_id = p_event_id and c.comp_id = p_comp_id;
    update public.event_core e set total_registrations = e.total_registrations + 1 where e.event_id = p_event_id;
  end if;

  select count(*)::int into v_active from public.event_team_members m where m.event_id = p_event_id and m.comp_id = p_comp_id and m.team_id = p_team_id and m.status = 'ACTIVE';
  update public.event_teams t set team_status = case when v_active >= v_comp.min_members then 'COMPLETE' else 'INCOMPLETE' end, updated_at = now() where t.event_id = p_event_id and t.comp_id = p_comp_id and t.team_id = p_team_id;
  update public.app_inbox i set status = 'READ', read_at = coalesce(i.read_at, now()) where i.uid = v_uid and i.inbox_id = v_invite.inbox_id;
  return query select p_event_id, p_comp_id, p_team_id, v_student, v_new_status;
end;
$$;

grant execute on function public.api_event_accept_team_invite(text,text,text) to authenticated;
commit;

