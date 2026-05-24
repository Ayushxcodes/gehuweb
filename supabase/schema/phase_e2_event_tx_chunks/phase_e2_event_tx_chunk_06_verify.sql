-- Phase E2 / Chunk 06
-- Verify event transaction RPC installation.

select routine_name, data_type
from information_schema.routines
where routine_schema = 'public'
  and routine_name in (
    'app_event_is_visible_registration_status',
    'app_event_payment_required',
    'app_event_random_team_id',
    'api_event_my_state',
    'api_event_register_solo',
    'api_event_register_team'
  )
order by routine_name;

select table_name, column_name
from information_schema.columns
where table_schema = 'public'
  and table_name in ('event_competitions','event_registrations')
  and column_name in (
    'min_members','max_participants','max_teams','categories','reg_count',
    'invited_by_student_id','accepted_at','cancelled_at','previous_status'
  )
order by table_name, column_name;

select
  (select count(*) from public.event_core) as event_rows,
  (select count(*) from public.event_competitions) as competition_rows,
  (select count(*) from public.event_registrations) as registration_rows,
  (select count(*) from public.event_payment_records) as payment_rows;
