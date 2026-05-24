-- Phase F1 / Chunk 09
-- Admin aggregate result RPCs. Raw responses remain hidden from direct client reads.

begin;

create or replace function public.api_feedback_admin_entry_summary(p_cycle_id text)
returns table (
  entry_id text,
  teacher_id text,
  teacher_name text,
  teacher_subject text,
  response_count bigint,
  average_rating numeric
)
language sql
stable
security definer
set search_path = public
as $$
  select e.entry_id, e.teacher_id, e.teacher_name, e.teacher_subject,
         count(distinct r.response_id) as response_count,
         round(avg((a.answer->>'rating')::numeric), 2) as average_rating
  from public.feedback_cycle_entries e
  left join public.feedback_responses r
    on r.cycle_id = e.cycle_id and r.entry_id = e.entry_id
  left join lateral jsonb_array_elements(coalesce(r.answers_jsonb, '[]'::jsonb)) a(answer) on true
  where e.cycle_id = p_cycle_id and public.app_phase3_is_admin()
  group by e.entry_id, e.teacher_id, e.teacher_name, e.teacher_subject, e.position
  order by e.position;
$$;

create or replace function public.api_feedback_admin_question_summary(p_cycle_id text, p_entry_id text)
returns table (
  question_id text,
  question_text text,
  response_count bigint,
  average_rating numeric
)
language sql
stable
security definer
set search_path = public
as $$
  select q.question_id, q.question_text,
         count(a.answer) as response_count,
         round(avg((a.answer->>'rating')::numeric), 2) as average_rating
  from public.feedback_cycle_entry_questions q
  left join public.feedback_responses r
    on r.cycle_id = q.cycle_id and r.entry_id = q.entry_id
  left join lateral jsonb_array_elements(coalesce(r.answers_jsonb, '[]'::jsonb)) a(answer)
    on a.answer->>'questionId' = q.question_id
  where q.cycle_id = p_cycle_id
    and q.entry_id = p_entry_id
    and public.app_phase3_is_admin()
  group by q.question_id, q.question_text, q.position
  order by q.position;
$$;

grant execute on function public.api_feedback_admin_entry_summary(text) to authenticated;
grant execute on function public.api_feedback_admin_question_summary(text, text) to authenticated;

commit;
