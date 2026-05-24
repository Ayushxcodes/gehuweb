-- Phase E4 / Chunk 04
-- Admin verifies or rejects manual payment submissions.

begin;

create or replace function public.api_event_admin_set_payment_status(
  p_event_id text, p_comp_id text, p_student_id text, p_action text, p_reason text default ''
)
returns table(event_id text, comp_id text, student_id text, payment_status text, registration_status text)
language plpgsql security definer set search_path = public as $$
declare
  v_auth uuid := auth.uid(); v_is_admin boolean; v_reg public.event_registrations%rowtype;
  v_payment public.event_payment_records%rowtype; v_uid text; v_inbox_id text; v_prev text; v_status text;
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  select public.app_event_is_admin() into v_is_admin;
  if not v_is_admin then raise exception 'ADMIN_ONLY'; end if;
  if upper(coalesce(p_action, '')) not in ('APPROVE','REJECT') then raise exception 'INVALID_ACTION'; end if;

  select * into v_reg from public.event_registrations r
  where r.event_id = p_event_id and r.comp_id = p_comp_id and r.student_id = p_student_id for update;
  if not found then raise exception 'REGISTRATION_NOT_FOUND'; end if;
  select * into v_payment from public.event_payment_records pr
  where pr.event_id = p_event_id and pr.comp_id = p_comp_id and pr.student_id = p_student_id for update;
  if not found then raise exception 'PAYMENT_RECORD_NOT_FOUND'; end if;
  if v_payment.status <> 'PAYMENT_SUBMITTED' then raise exception 'PAYMENT_NOT_SUBMITTED'; end if;

  v_prev := v_reg.status;
  select ps.uid into v_uid from public.app_profile_state ps where ps.student_id = p_student_id limit 1;
  if upper(p_action) = 'APPROVE' then
    v_status := 'REGISTERED';
    update public.event_payment_records pr set status = 'VERIFIED', verified_by_auth_user_id = v_auth,
      verified_at = now(), refund_status = 'NONE', rejection_reason = '', updated_at = now()
    where pr.payment_record_id = v_payment.payment_record_id;
    update public.event_registrations r set previous_status = v_prev, status = 'REGISTERED', payment_status = 'VERIFIED',
      payment_verified_by_auth_user_id = v_auth, payment_verified_at = now(), rejection_reason = '', updated_at = now()
    where r.event_id = p_event_id and r.comp_id = p_comp_id and r.student_id = p_student_id;
    if not public.app_event_is_visible_registration_status(v_prev) then
      insert into public.event_participants(event_id, student_id, auth_user_id, status, comp_ids)
      values (p_event_id, p_student_id, v_reg.auth_user_id, 'REGISTERED', array[p_comp_id])
      on conflict (event_id, student_id) do update set comp_ids = (select array_agg(distinct x) from unnest(public.event_participants.comp_ids || excluded.comp_ids) u(x)), status = excluded.status, updated_at = now();
      update public.event_competitions c set reg_count = c.reg_count + 1 where c.event_id = p_event_id and c.comp_id = p_comp_id;
      update public.event_core e set total_registrations = e.total_registrations + 1 where e.event_id = p_event_id;
    end if;
  else
    v_status := 'PAYMENT_REJECTED';
    update public.event_payment_records pr set status = 'PAYMENT_REJECTED', rejection_reason = coalesce(nullif(trim(p_reason), ''), 'Payment rejected by admin'),
      refund_status = case when coalesce(pr.proof_url, '') <> '' then 'PENDING' else 'NONE' end, updated_at = now()
    where pr.payment_record_id = v_payment.payment_record_id;
    update public.event_registrations r set previous_status = v_prev, status = 'PAYMENT_REJECTED', payment_status = 'PAYMENT_REJECTED',
      rejection_reason = coalesce(nullif(trim(p_reason), ''), 'Payment rejected by admin'), updated_at = now()
    where r.event_id = p_event_id and r.comp_id = p_comp_id and r.student_id = p_student_id;
  end if;

  if v_uid is not null then
    v_inbox_id := 'payment_' || lower(upper(p_action)) || '_' || substr(md5(p_event_id || ':' || p_comp_id || ':' || p_student_id || ':' || upper(p_action)), 1, 24);
    insert into public.app_inbox(uid, inbox_id, type, title, body, status, event_id, comp_id, target_id, payload_json)
    values (v_uid, v_inbox_id, 'PAYMENT_STATUS', case when upper(p_action)='APPROVE' then 'Payment Approved' else 'Payment Rejected' end,
      case when upper(p_action)='APPROVE' then 'Your payment has been verified. You are now registered.' else 'Your payment was rejected: ' || coalesce(nullif(trim(p_reason), ''), 'Payment rejected by admin') end,
      'UNREAD', p_event_id, p_comp_id, p_student_id, jsonb_build_object('action', upper(p_action), 'student_id', p_student_id))
    on conflict (uid, inbox_id) do update set status = 'UNREAD', body = excluded.body, updated_at = now();
  end if;
  update public.event_teams t set payment_status = case when upper(p_action)='APPROVE' then 'VERIFIED' else 'PAYMENT_REJECTED' end where t.event_id = p_event_id and t.comp_id = p_comp_id and t.team_id = v_reg.team_id and v_reg.role = 'LEADER';
  return query select p_event_id, p_comp_id, p_student_id, case when upper(p_action)='APPROVE' then 'VERIFIED' else 'PAYMENT_REJECTED' end, v_status;
end;
$$;

grant execute on function public.api_event_admin_set_payment_status(text,text,text,text,text) to authenticated;
commit;