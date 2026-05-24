-- Phase R1 / Chunk 07
-- Resume/CV verification.

select
  (select count(*) from public.student_resume_profile) as resume_profile_rows,
  (select count(*) from public.student_resumes) as resume_rows,
  (select count(*) from public.student_resumes where deleted_at is null) as active_resume_rows,
  (select count(*) from public.student_resumes where is_default and deleted_at is null) as default_resume_rows,
  (select count(*) from public.app_official_feedback where type in ('RESUME','CV','ATS')) as resume_feedback_rows;

select p.proname as function_name,
       pg_get_function_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'api_resume_list',
    'api_resume_get',
    'api_resume_upsert',
    'api_resume_set_default',
    'api_resume_delete',
    'api_admin_student_resume_default',
    'api_resume_official_feedback_feed',
    'api_admin_send_resume_feedback'
  )
order by p.proname;
