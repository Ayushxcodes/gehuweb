-- Phase E2 / Chunk 04
-- Atomic solo event registration.

begin;

create or replace function public.api_event_register_solo(
  p_event_id text, p_comp_id text, p_display_name text default null,
  p_category text default '', p_legacy_firebase_uid text default null
)
returns table (
  event_id text, comp_id text, team_id text, status text,
  payment_required boolean, fee_amount numeric, payment_method text
)
language plpgsql security definer set search_path = public as $$
declare
  v_auth uuid := auth.uid(); v_student_id text;
  v_event public.event_core%rowtype; v_comp public.event_competitions%rowtype;
  v_team_id text; v_status text; v_payment_id text;
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  select ai.student_id into v_student_id from public.app_user_identity ai
  where ai.auth_user_id = v_auth and ai.is_active = true and ai.account_type = 'STUDENT';
  if v_student_id is null then raise exception 'STUDENT_ID_NOT_MAPPED'; end if;

  select * into v_event from public.event_core where event_id = p_event_id for update;
  if not found then raise exception 'EVENT_NOT_FOUND'; end if;
  select * into v_comp from public.event_competitions
  where event_id = p_event_id and comp_id = p_comp_id for update;
  if not found then raise exception 'COMPETITION_NOT_FOUND'; end if;

  if not public.app_event_visible(p_event_id) then raise exception 'EVENT_NOT_VISIBLE'; end if;
  if v_event.event_interaction_locked or v_event.finalized or v_event.is_cancelled or not v_event.is_live
  then raise exception 'EVENT_CLOSED'; end if;
  if v_event.end_at is not null and v_event.end_at <= now() then raise exception 'EVENT_ENDED'; end if;
  if coalesce(v_comp.registration_deadline, v_event.registration_deadline) is not null
     and coalesce(v_comp.registration_deadline, v_event.registration_deadline) <= now()
  then raise exception 'REGISTRATION_DEADLINE_PASSED'; end if;
  if not v_comp.is_live then raise exception 'COMPETITION_NOT_LIVE'; end if;
  if v_comp.participation_mode not in ('SOLO','BOTH') then raise exception 'SOLO_NOT_ALLOWED'; end if;
  if exists (select 1 from public.event_registrations r
    where r.event_id = p_event_id and r.comp_id = p_comp_id and r.student_id = v_student_id)
  then raise exception 'ALREADY_REGISTERED'; end if;

  v_team_id := coalesce(nullif(trim(p_legacy_firebase_uid), ''), v_student_id);
  v_status := case when public.app_event_payment_required(v_comp.is_free, v_comp.fee_amount)
    then 'PAYMENT_PENDING' else 'REGISTERED' end;

  insert into public.event_teams(event_id, comp_id, team_id, team_name, leader_student_id,
    leader_auth_user_id, participant_type, team_status, max_members, active, category, payment_status)
  values (p_event_id, p_comp_id, v_team_id,
    coalesce(nullif(trim(p_display_name), ''), 'Participant-' || v_student_id),
    v_student_id, v_auth, 'SOLO', 'COMPLETE', 1, true, coalesce(p_category, ''), v_status);
  insert into public.event_team_members(event_id, comp_id, team_id, student_id, auth_user_id, role, status)
  values (p_event_id, p_comp_id, v_team_id, v_student_id, v_auth, 'LEADER', 'ACTIVE');
  insert into public.event_registrations(event_id, comp_id, student_id, auth_user_id, legacy_firebase_uid,
    mode, team_id, role, status, category, payment_status)
  values (p_event_id, p_comp_id, v_student_id, v_auth, coalesce(p_legacy_firebase_uid, ''),
    'individual', v_team_id, 'LEADER', v_status, coalesce(p_category, ''), v_status);

  if public.app_event_is_visible_registration_status(v_status) then
    insert into public.event_participants(event_id, student_id, auth_user_id, legacy_firebase_uid, status, comp_ids)
    values (p_event_id, v_student_id, v_auth, coalesce(p_legacy_firebase_uid, ''), v_status, array[p_comp_id])
    on conflict (event_id, student_id) do update set
      comp_ids = (select array_agg(distinct x) from unnest(public.event_participants.comp_ids || excluded.comp_ids) u(x)),
      status = excluded.status, updated_at = now();
    update public.event_competitions set reg_count = reg_count + 1 where event_id = p_event_id and comp_id = p_comp_id;
    update public.event_core set total_registrations = total_registrations + 1 where event_id = p_event_id;
  end if;

  if public.app_event_payment_required(v_comp.is_free, v_comp.fee_amount) then
    v_payment_id := coalesce(nullif(trim(p_legacy_firebase_uid), ''), v_student_id) || '_' || p_comp_id;
    insert into public.event_payment_records(payment_record_id, event_id, comp_id, student_id,
      auth_user_id, legacy_firebase_uid, status, method, amount)
    values (v_payment_id, p_event_id, p_comp_id, v_student_id, v_auth,
      coalesce(p_legacy_firebase_uid, ''), 'PAYMENT_PENDING', v_comp.payment_method, v_comp.fee_amount);
  end if;

  return query select p_event_id, p_comp_id, v_team_id, v_status,
    public.app_event_payment_required(v_comp.is_free, v_comp.fee_amount), v_comp.fee_amount, v_comp.payment_method;
end;
$$;

grant execute on function public.api_event_register_solo(text,text,text,text,text) to authenticated;

commit;
