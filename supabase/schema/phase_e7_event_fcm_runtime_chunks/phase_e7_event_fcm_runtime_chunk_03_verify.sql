-- Phase E7 / Chunk 03
-- Verification snapshot. Safe to run repeatedly.

select
  to_regclass('public.app_fcm_tokens') is not null as has_fcm_token_table,
  to_regclass('public.app_push_queue') is not null as has_push_queue_table,
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'api_register_fcm_token'
  ) as has_register_fcm_rpc,
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'api_event_admin_send_announcement'
  ) as has_event_announcement_rpc,
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'api_service_push_tokens_for_queue'
  ) as has_service_push_token_rpc;

