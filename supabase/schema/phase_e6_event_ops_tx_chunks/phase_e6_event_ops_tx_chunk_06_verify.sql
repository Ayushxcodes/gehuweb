-- Phase E6 / Chunk 06
-- Verification for event ops RPCs.

select routine_schema, routine_name
from information_schema.routines
where routine_schema = 'public'
  and routine_name in (
    'api_event_replace_schedule',
    'api_event_schedule_feed',
    'api_event_sync_group_members',
    'api_event_send_group_message',
    'api_event_set_interaction_locked',
    'api_event_finalize',
    'api_event_cancel',
    'api_event_add_scanner',
    'api_event_remove_scanner',
    'api_event_scanner_page'
  )
order by routine_name;

select
  (select count(*) from public.event_schedule_stages) as schedule_rows,
  (select count(*) from public.event_group_messages) as group_message_rows,
  (select count(*) from public.event_scanners) as scanner_rows;
