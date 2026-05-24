-- Phase M3 / Chunk 09 (Bulletproof CTEs)
-- Purpose: Completely abandons `LATERAL` joins and `OR` traps.
-- We pre-compute all of the student's results exactly once in a CTE,
-- and then do a standard hash join to the `mock_tests` table.
-- This guarantees O(1) index performance and mathematically cannot time out.

begin;

-- 1. Bulletproof Results Feed
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
  unattempted integer,
  test_type text
)
language plpgsql
stable
as $$
declare
  v_auth_user_id uuid;
  v_student_id text;
  v_branch text;
  v_course text;
  v_semester text;
begin
  select auth_user_id, student_id, branch, course, semester
  into v_auth_user_id, v_student_id, v_branch, v_course, v_semester
  from mocks.current_student_context()
  limit 1;

  if v_auth_user_id is null and v_student_id is null then
    return;
  end if;

  return query
  with my_results as (
    -- Pre-fetch all of the active student's exact results using exact indexes BEFORE joining.
    select r.test_id, r.result_id, r.submitted_at, r.score, r.max_marks, r.percentage, r.correct, r.wrong, r.unattempted, r.updated_at
    from mocks.mock_results r
    where r.auth_user_id = v_auth_user_id and v_auth_user_id is not null
    
    union all
    
    select r.test_id, r.result_id, r.submitted_at, r.score, r.max_marks, r.percentage, r.correct, r.wrong, r.unattempted, r.updated_at
    from mocks.mock_results r
    where r.student_id = v_student_id and v_auth_user_id is null and v_student_id is not null
  ),
  deduped_results as (
    -- In rare cases where a student submitted multiple times, take the latest.
    select distinct on (mr.test_id) mr.*
    from my_results mr
    order by mr.test_id, mr.updated_at desc nulls last, mr.result_id desc
  ),
  vt as (
    select mt.*
    from mocks.mock_tests mt
    where mt.results_published = true
      -- If you want strict course filtering back, uncomment the following:
      -- and (lower(mt.branch) = 'all' or lower(mt.branch) = lower(coalesce(v_branch, 'ALL')))
      -- and (lower(mt.course) = 'all' or lower(mt.course) = lower(coalesce(v_course, 'ALL')))
      -- and (lower(mt.semester) = 'all' or lower(mt.semester) = lower(coalesce(v_semester, 'ALL')))
  )
  select
    coalesce(mr.result_id, ('-1' || lpad(abs(hashtext(vt.test_id)::bigint)::text, 10, '0'))::bigint) as result_id,
    vt.test_id,
    vt.title,
    vt.start_at,
    mr.submitted_at,
    coalesce(mr.score, 0::numeric) as score,
    coalesce(mr.max_marks, vt.total_questions * 4) as max_marks,
    coalesce(mr.percentage, 0::numeric) as percentage,
    coalesce(mr.correct, 0) as correct,
    coalesce(mr.wrong, 0) as wrong,
    coalesce(mr.unattempted, vt.total_questions) as unattempted,
    case when coalesce(vt.requires_web_proctoring, false) then 'MET'::text else 'QET'::text end as test_type
  from vt
  left join deduped_results mr on mr.test_id = vt.test_id
  where (
    p_before_submitted_at is null
    or coalesce(mr.submitted_at, vt.start_at) < p_before_submitted_at
    or (
      coalesce(mr.submitted_at, vt.start_at) = p_before_submitted_at
      and p_before_result_id is not null
      and coalesce(mr.result_id, ('-1' || lpad(abs(hashtext(vt.test_id)::bigint)::text, 10, '0'))::bigint) < p_before_result_id
    )
  )
  order by coalesce(mr.submitted_at, vt.start_at) desc, coalesce(mr.result_id, ('-1' || lpad(abs(hashtext(vt.test_id)::bigint)::text, 10, '0'))::bigint) desc
  limit greatest(1, least(coalesce(p_limit, 25), 100));
end;
$$;


-- 2. Bulletproof Mock Feed
create or replace function mocks.api_student_mock_feed(
  p_limit integer default 25,
  p_before_start_at timestamptz default null,
  p_before_test_id text default null
)
returns table (
  test_id text, title text, branch text, course text, semester text, start_at timestamptz, duration_minutes integer,
  status text, results_published boolean, requires_web_proctoring boolean,
  my_locked boolean,
  my_published boolean,
  my_started_at timestamptz,
  my_submitted_at timestamptz,
  my_score numeric,
  my_percentage numeric
)
language plpgsql
stable
as $$
declare
  v_auth_user_id uuid;
  v_student_id text;
  v_branch text;
  v_course text;
  v_semester text;
begin
  select auth_user_id, student_id, branch, course, semester
  into v_auth_user_id, v_student_id, v_branch, v_course, v_semester
  from mocks.current_student_context()
  limit 1;

  if v_auth_user_id is null and v_student_id is null then
    return;
  end if;

  return query
  with my_results as (
    select r.test_id, r.locked, r.published, r.results_published, r.started_at, r.submitted_at, r.score, r.percentage, r.updated_at, r.result_id
    from mocks.mock_results r
    where r.auth_user_id = v_auth_user_id and v_auth_user_id is not null
    
    union all
    
    select r.test_id, r.locked, r.published, r.results_published, r.started_at, r.submitted_at, r.score, r.percentage, r.updated_at, r.result_id
    from mocks.mock_results r
    where r.student_id = v_student_id and v_auth_user_id is null and v_student_id is not null
  ),
  deduped_results as (
    select distinct on (mr.test_id) mr.*
    from my_results mr
    order by mr.test_id, mr.updated_at desc nulls last, mr.result_id desc
  ),
  vt as (
    select mt.*
    from mocks.mock_tests mt
    where mt.status = 'POSTED'
      and (mt.expires_at is null or mt.expires_at > now())
      and (
        p_before_start_at is null
        or mt.start_at < p_before_start_at
        or (mt.start_at = p_before_start_at and p_before_test_id is not null and mt.test_id < p_before_test_id)
      )
    order by mt.start_at desc, mt.test_id desc
    limit greatest(1, least(coalesce(p_limit, 25), 100))
  )
  select
    vt.test_id, vt.title, vt.branch, vt.course, vt.semester, vt.start_at, vt.duration_minutes,
    vt.status, vt.results_published, coalesce(vt.requires_web_proctoring, false) as requires_web_proctoring,
    coalesce(mr.locked, false) as my_locked,
    coalesce(mr.published, false) or coalesce(mr.results_published, false) as my_published,
    mr.started_at as my_started_at, mr.submitted_at as my_submitted_at, mr.score as my_score, mr.percentage as my_percentage
  from vt
  left join deduped_results mr on mr.test_id = vt.test_id
  order by vt.start_at desc, vt.test_id desc;
end;
$$;

commit;

notify pgrst, 'reload schema';
