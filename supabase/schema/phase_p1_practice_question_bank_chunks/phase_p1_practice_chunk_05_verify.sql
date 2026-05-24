-- Phase P1 / Chunk 05
-- Verification for practice question bank contracts.

select routine_schema, routine_name
from information_schema.routines
where routine_schema = 'public'
  and routine_name in (
    'api_practice_topics',
    'api_practice_questions_random',
    'api_practice_questions_sequential',
    'api_admin_upsert_practice_question',
    'api_admin_set_practice_question_active'
  )
order by routine_name;

select
  (select count(*) from public.practice_question_bank) as practice_question_rows,
  (select count(*) from public.practice_question_bank where active = true) as active_question_rows,
  (select count(distinct topic) from public.practice_question_bank where active = true) as active_topic_count;
