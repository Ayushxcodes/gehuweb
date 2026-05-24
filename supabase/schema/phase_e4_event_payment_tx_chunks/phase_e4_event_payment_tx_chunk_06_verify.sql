-- Phase E4 / Chunk 06
-- Verification for event payment transaction RPCs.

select n.nspname as schema_name, p.proname as function_name,
       pg_get_function_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'api_event_submit_payment_proof',
    'api_event_record_gateway_success',
    'api_event_admin_set_payment_status',
    'api_event_admin_pending_payments'
  )
order by p.proname;

select
  (select count(*) from public.event_payment_records) as payment_rows,
  (select count(*) from public.event_payment_records where status = 'PAYMENT_SUBMITTED') as pending_manual_rows,
  (select count(*) from public.app_inbox where type = 'PAYMENT_STATUS') as payment_inbox_rows;