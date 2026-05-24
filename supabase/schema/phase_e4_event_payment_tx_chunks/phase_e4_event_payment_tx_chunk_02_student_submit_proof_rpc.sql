-- Phase E4 / Chunk 02
-- Student submits manual payment proof metadata after R2 upload.

begin;

create or replace function public.api_event_submit_payment_proof(
  p_event_id text, p_comp_id text, p_proof_url text, p_proof_object_key text default ''
)
returns table(payment_record_id text, event_id text, comp_id text, student_id text, status text)
language plpgsql security definer set search_path = public as $$
declare
  v_auth uuid := auth.uid(); v_student text; v_reg public.event_registrations%rowtype;
  v_payment_id text; v_amount numeric := 0; v_method text := 'MANUAL';
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if coalesce(trim(p_proof_url), '') = '' then raise exception 'PROOF_URL_REQUIRED'; end if;

  select ai.student_id into v_student from public.app_user_identity ai
  where ai.auth_user_id = v_auth and ai.is_active = true and ai.account_type = 'STUDENT' limit 1;
  if v_student is null then raise exception 'STUDENT_ID_NOT_MAPPED'; end if;

  select * into v_reg from public.event_registrations r
  where r.event_id = p_event_id and r.comp_id = p_comp_id and r.student_id = v_student for update;
  if not found then raise exception 'REGISTRATION_NOT_FOUND'; end if;
  if v_reg.status not in ('PAYMENT_PENDING','PAYMENT_REJECTED') then raise exception 'PAYMENT_NOT_AWAITING_PROOF'; end if;

  select c.fee_amount, c.payment_method into v_amount, v_method from public.event_competitions c
  where c.event_id = p_event_id and c.comp_id = p_comp_id for update;

  v_payment_id := coalesce(nullif(v_reg.legacy_firebase_uid, ''), v_student) || '_' || p_comp_id;
  insert into public.event_payment_records(payment_record_id, event_id, comp_id, student_id, auth_user_id,
    legacy_firebase_uid, status, method, amount, proof_url, proof_object_key, submitted_at, refund_status)
  values (v_payment_id, p_event_id, p_comp_id, v_student, v_auth, v_reg.legacy_firebase_uid,
    'PAYMENT_SUBMITTED', coalesce(v_method, 'MANUAL'), coalesce(v_amount, 0), p_proof_url, coalesce(p_proof_object_key, ''), now(), 'NONE')
  on conflict (payment_record_id) do update set status = 'PAYMENT_SUBMITTED', proof_url = excluded.proof_url,
    proof_object_key = excluded.proof_object_key, submitted_at = now(), refund_status = 'NONE', rejection_reason = '', updated_at = now();

  update public.event_registrations r set status = 'PAYMENT_SUBMITTED', payment_status = 'PAYMENT_SUBMITTED',
    payment_proof_url = p_proof_url, payment_submitted_at = now(), rejection_reason = '', updated_at = now()
  where r.event_id = p_event_id and r.comp_id = p_comp_id and r.student_id = v_student;

  return query select v_payment_id, p_event_id, p_comp_id, v_student, 'PAYMENT_SUBMITTED'::text;
end;
$$;

grant execute on function public.api_event_submit_payment_proof(text,text,text,text) to authenticated;
commit;