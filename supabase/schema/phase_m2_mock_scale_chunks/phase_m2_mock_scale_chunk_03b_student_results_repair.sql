-- Phase M2 / Chunk 03B (repair)
-- Use only if api_student_results_feed is missing/signature mismatch

drop function if exists mocks.api_student_results_feed(integer, timestamptz, bigint);
drop function if exists mocks.api_student_results_feed(integer, timestamp, bigint);
drop function if exists mocks.api_student_results_feed(integer);

create or replace function mocks.api_student_results_feed(
  p_limit integer default 25,
  p_before_submitted_at timestamptz default null,
  p_before_result_id bigint default null
)
returns table (
  result_id bigint,
  test_id text,
  title text,
  start_at timestamptz,
  submitted_at timestamptz,
  score numeric,
  max_marks integer,
  percentage numeric,
  correct integer,
  wrong integer,
  unattempted integer
)
language sql
stable
as $$
  with ctx as (
    select * from mocks.current_student_context()
  )
  select
    mr.result_id,
    mr.test_id,
    mt.title,
    mt.start_at,
    mr.submitted_at,
    mr.score,
    mr.max_marks,
    mr.percentage,
    mr.correct,
    mr.wrong,
    mr.unattempted
  from mocks.mock_results mr
  join mocks.mock_tests mt
    on mt.test_id = mr.test_id
  join ctx on true
  where (
      (ctx.auth_user_id is not null and mr.auth_user_id = ctx.auth_user_id)
      or (ctx.student_id is not null and mr.student_id = ctx.student_id)
    )
    and (
      coalesce(mr.published, false)
      or coalesce(mr.results_published, false)
      or coalesce(mt.results_published, false)
    )
    and (
      p_before_submitted_at is null
      or coalesce(mr.submitted_at, mr.updated_at) < p_before_submitted_at
      or (
        coalesce(mr.submitted_at, mr.updated_at) = p_before_submitted_at
        and p_before_result_id is not null
        and mr.result_id < p_before_result_id
      )
    )
  order by coalesce(mr.submitted_at, mr.updated_at) desc, mr.result_id desc
  limit greatest(1, least(coalesce(p_limit, 25), 100));
$$;

grant execute on function mocks.api_student_results_feed(integer, timestamptz, bigint) to authenticated;

select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
join pg_namespace n
  on n.oid = p.pronamespace
where n.nspname = 'mocks'
  and p.proname = 'api_student_results_feed';
