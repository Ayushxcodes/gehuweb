-- Phase E3 / Chunk 05
-- Verification for event invite transaction RPCs.

select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'api_event_send_team_invite',
    'api_event_accept_team_invite',
    'api_event_reject_team_invite',
    'api_event_remove_team_invite'
  )
order by p.proname;

select
  (select count(*) from public.event_team_invites) as invite_rows,
  (select count(*) from public.event_team_members) as member_rows,
  (select count(*) from public.event_registrations) as registration_rows,
  (select count(*) from public.app_inbox where type = 'TEAM_INVITE') as invite_inbox_rows;
