-- Phase F1 / Chunk 10
-- Feedback module verification.

select
  table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'feedback_templates','feedback_template_questions','feedback_teachers',
    'feedback_cycles','feedback_cycle_entries','feedback_cycle_entry_questions',
    'feedback_submissions','feedback_responses'
  )
order by table_name;

select
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  count(pol.polname) as policy_count
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
left join pg_policy pol on pol.polrelid = c.oid
where n.nspname = 'public'
  and c.relname like 'feedback_%'
group by c.relname, c.relrowsecurity
order by c.relname;

select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and (
    p.proname like 'api_feedback_%'
    or p.proname in (
     'api_student_feedback_cycle_feed',
     'api_student_feedback_cycle_detail',
     'api_submit_feedback_entry_response'
    )
  )
order by p.proname;
