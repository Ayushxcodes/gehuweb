-- Phase E4 / Chunk 05
-- Admin pending payment list RPC.

begin;

create or replace function public.api_event_admin_pending_payments(
  p_event_id text, p_comp_id text
)
returns table(
  payment_record_id text, student_id text, student_name text, proof_url text,
  amount numeric, submitted_at timestamptz, status text
)
language sql stable security definer set search_path = public as $$
  select pr.payment_record_id, pr.student_id, coalesce(ps.name, pr.student_id) as student_name,
         pr.proof_url, pr.amount, pr.submitted_at, pr.status
  from public.event_payment_records pr
  left join public.app_profile_state ps on ps.student_id = pr.student_id
  where public.app_event_is_admin()
    and pr.event_id = p_event_id
    and pr.comp_id = p_comp_id
    and pr.status = 'PAYMENT_SUBMITTED'
  order by pr.submitted_at asc nulls last, pr.created_at asc;
$$;

grant execute on function public.api_event_admin_pending_payments(text,text) to authenticated;
commit;