-- Phase M3 / Chunk 05 (Unlock Feeds for Testing)
-- Purpose: Temporarily disables the strict Branch/Course/Semester cohort matching
-- so that ALL students can see ALL tests. This will prove whether the tests were 
-- hidden because of course mismatch (e.g. MCA student vs B.Tech CSE test).

begin;

-- 1. Unlock Results Feed
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
begin
  select auth_user_id, student_id
  into v_auth_user_id, v_student_id
  from mocks.current_student_context()
  limit 1;

  if v_auth_user_id is null and v_student_id is null then
    return;
  end if;

  return query
  with vt as (
    select mt.*
    from mocks.mock_tests mt
    where mt.results_published = true
  )
  select
    coalesce(mr.result_id, ('-1' || lpad(abs(hashtext(vt.test_id))::text, 10, '0'))::bigint) as result_id,
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
  left join mocks.mock_results mr
    on mr.test_id = vt.test_id
    and (
      (v_auth_user_id is not null and mr.auth_user_id = v_auth_user_id)
      or (v_auth_user_id is null and v_student_id is not null and mr.student_id = v_student_id)
    )
  where (
    p_before_submitted_at is null
    or coalesce(mr.submitted_at, vt.start_at) < p_before_submitted_at
    or (
      coalesce(mr.submitted_at, vt.start_at) = p_before_submitted_at
      and p_before_result_id is not null
      and coalesce(mr.result_id, ('-1' || lpad(abs(hashtext(vt.test_id))::text, 10, '0'))::bigint) < p_before_result_id
    )
  )
  order by coalesce(mr.submitted_at, vt.start_at) desc, coalesce(mr.result_id, ('-1' || lpad(abs(hashtext(vt.test_id))::text, 10, '0'))::bigint) desc
  limit greatest(1, least(coalesce(p_limit, 25), 100));
end;
$$;

-- 2. Unlock Mock Feed
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
begin
  select auth_user_id, student_id
  into v_auth_user_id, v_student_id
  from mocks.current_student_context()
  limit 1;

  if v_auth_user_id is null and v_student_id is null then
    return;
  end if;

  return query
  with vt as (
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
  left join lateral (
    select r.locked, r.published, r.results_published, r.started_at, r.submitted_at, r.score, r.percentage
    from mocks.mock_results r
    where r.test_id = vt.test_id
      and (
        (v_auth_user_id is not null and r.auth_user_id = v_auth_user_id)
        or (v_auth_user_id is null and v_student_id is not null and r.student_id = v_student_id)
      )
    order by r.updated_at desc nulls last, r.result_id desc
    limit 1
  ) mr on true
  order by vt.start_at desc, vt.test_id desc;
end;
$$;

commit;

notify pgrst, 'reload schema';
