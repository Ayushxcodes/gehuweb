-- Phase E4 / Chunk 03
-- Student records successful gateway payment callback.

begin;

create or replace function public.api_event_record_gateway_success(
  p_event_id text, p_comp_id text, p_payment_id text, p_order_id text default '', p_gateway text default 'RAZORPAY'
)
returns table(payment_record_id text, event_id text, comp_id text, student_id text, status text)
language plpgsql security definer set search_path = public as $$
declare
  v_auth uuid := auth.uid(); v_student text; v_reg public.event_registrations%rowtype;
  v_payment_record_id text; v_prev text; v_amount numeric := 0; v_method text := 'RAZORPAY';
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if coalesce(trim(p_payment_id), '') = '' then raise exception 'PAYMENT_ID_REQUIRED'; end if;

  select ai.student_id into v_student from public.app_user_identity ai
  where ai.auth_user_id = v_auth and ai.is_active = true and ai.account_type = 'STUDENT' limit 1;
  if v_student is null then raise exception 'STUDENT_ID_NOT_MAPPED'; end if;

  select * into v_reg from public.event_registrations r
  where r.event_id = p_event_id and r.comp_id = p_comp_id and r.student_id = v_student for update;
  if not found then raise exception 'REGISTRATION_NOT_FOUND'; end if;
  if v_reg.status not in ('PAYMENT_PENDING','PAYMENT_REJECTED','PAYMENT_SUBMITTED') then raise exception 'PAYMENT_NOT_OPEN'; end if;

  select c.fee_amount, c.payment_method into v_amount, v_method from public.event_competitions c
  where c.event_id = p_event_id and c.comp_id = p_comp_id for update;

  v_prev := v_reg.status;
  v_payment_record_id := coalesce(nullif(v_reg.legacy_firebase_uid, ''), v_student) || '_' || p_comp_id;
  insert into public.event_payment_records(payment_record_id, event_id, comp_id, student_id, auth_user_id,
    legacy_firebase_uid, status, method, amount, razorpay_payment_id, razorpay_order_id, gateway_name, submitted_at, verified_at, refund_status)
  values (v_payment_record_id, p_event_id, p_comp_id, v_student, v_auth, v_reg.legacy_firebase_uid,
    'VERIFIED', coalesce(v_method, 'RAZORPAY'), coalesce(v_amount, 0), p_payment_id, coalesce(p_order_id, ''), coalesce(p_gateway, 'RAZORPAY'), now(), now(), 'NONE')
  on conflict (payment_record_id) do update set status = 'VERIFIED', razorpay_payment_id = excluded.razorpay_payment_id,
    razorpay_order_id = excluded.razorpay_order_id, gateway_name = excluded.gateway_name, submitted_at = now(), verified_at = now(), updated_at = now();

  update public.event_registrations r set previous_status = v_prev, status = 'REGISTERED', payment_status = 'VERIFIED',
    payment_verified_at = now(), updated_at = now()
  where r.event_id = p_event_id and r.comp_id = p_comp_id and r.student_id = v_student;

  if not public.app_event_is_visible_registration_status(v_prev) then
    insert into public.event_participants(event_id, student_id, auth_user_id, status, comp_ids)
    values (p_event_id, v_student, v_auth, 'REGISTERED', array[p_comp_id])
    on conflict (event_id, student_id) do update set comp_ids = (select array_agg(distinct x) from unnest(public.event_participants.comp_ids || excluded.comp_ids) u(x)), status = excluded.status, updated_at = now();
    update public.event_competitions c set reg_count = c.reg_count + 1 where c.event_id = p_event_id and c.comp_id = p_comp_id;
    update public.event_core e set total_registrations = e.total_registrations + 1 where e.event_id = p_event_id;
  end if;

  update public.event_teams t set payment_status = 'VERIFIED' where t.event_id = p_event_id and t.comp_id = p_comp_id and t.team_id = v_reg.team_id and v_reg.role = 'LEADER';
  return query select v_payment_record_id, p_event_id, p_comp_id, v_student, 'REGISTERED'::text;
end;
$$;

grant execute on function public.api_event_record_gateway_success(text,text,text,text,text) to authenticated;
commit;