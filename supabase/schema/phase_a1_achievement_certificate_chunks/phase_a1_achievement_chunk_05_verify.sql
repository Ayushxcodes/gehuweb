-- Phase A1 / Chunk 05
-- Verification for achievement certificate contracts.

select routine_schema, routine_name
from information_schema.routines
where routine_schema = 'public'
  and routine_name in (
    'api_student_achievement_certificates',
    'api_admin_issue_achievement_certificate',
    'api_verify_certificate'
  )
order by routine_name;

select
  (select count(*) from public.event_certificates) as event_certificate_rows,
  (select count(*) from public.app_achievement_certificates) as manual_certificate_rows;
