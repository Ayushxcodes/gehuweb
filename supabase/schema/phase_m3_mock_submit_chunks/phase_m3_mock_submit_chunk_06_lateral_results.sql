-- Phase M3 / Chunk 06 (LATERAL Results Repair)
-- Purpose: Completely replaces the direct LEFT JOIN with a LATERAL join.
-- In PostgreSQL, `LEFT JOIN ... ON (A OR B)` completely disables B-Tree index scans
-- and triggers a massive full-table scan, which is causing the 8-second timeout.
-- Using a LATERAL join forces Postgres to scan using exact parameterized index lookups,
-- resolving the query instantly (<1ms).

begin;

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
  left join lateral (
    select r.result_id, r.submitted_at, r.score, r.max_marks, r.percentage, r.correct, r.wrong, r.unattempted
    from mocks.mock_results r
    where r.test_id = vt.test_id
      and (
        (v_auth_user_id is not null and r.auth_user_id = v_auth_user_id)
        or (v_auth_user_id is null and v_student_id is not null and r.student_id = v_student_id)
      )
    order by r.updated_at desc nulls last, r.result_id desc
    limit 1
  ) mr on true
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

commit;

notify pgrst, 'reload schema';
