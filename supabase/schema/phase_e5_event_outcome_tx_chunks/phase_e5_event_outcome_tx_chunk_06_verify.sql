-- Phase E5 / Chunk 06
-- Verification for event attendance/result/certificate RPCs.

select routine_schema, routine_name
from information_schema.routines
where routine_schema = 'public'
  and routine_name in (
    'api_event_mark_team_attendance',
    'api_event_admin_attendance_page',
    'api_event_publish_results',
    'api_event_issue_certificate_record',
    'api_event_my_certificates',
    'app_event_rank_from_status'
  )
order by routine_name;

select
  (select count(*) from public.event_attendance) as attendance_rows,
  (select count(*) from public.event_results) as result_rows,
  (select count(*) from public.event_certificates) as certificate_rows;
