-- Phase M3 / Chunk 03 (Student Results Feed Absent Support & Type Mapping)
-- Purpose: Overhauls mocks.api_student_results_feed RPC to:
-- 1) Correctly return all published tests matching student's cohort, even if the student was ABSENT.
-- 2) Use synthetic unique negative bigint IDs for absent tests.
-- 3) Return test_type ('MET' / 'QET') column derived directly from requires_web_proctoring.
-- 4) Dynamically purges all overloaded signatures to guarantee zero PostgREST candidate ambiguities.
-- 5) Uses high-performance PL/pgSQL local variables to completely avoid OR join traps and prevent connection pool starvation.

begin;

-- 1. Dynamically scan and drop EVERY overloaded signature of api_student_results_feed
do $$
declare
  r record;
begin
  for r in 
    select 
      n.nspname as schema_name,
      p.proname as function_name,
      oidvectortypes(p.proargtypes) as args
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where p.proname = 'api_student_results_feed'
  loop
    execute 'drop function if exists ' || r.schema_name || '.' || r.function_name || '(' || r.args || ') cascade;';
  end loop;
end;
$$;

-- 2. Recreate function using ultra-high-performance PL/pgSQL
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
  -- Fetch current student context once to avoid query planner OR traps
  select 
    auth_user_id, student_id, branch, course, semester
  into 
    v_auth_user_id, v_student_id, v_branch, v_course, v_semester
  from mocks.current_student_context()
  limit 1;

  -- Exit immediately if no authenticated user session is active
  if v_auth_user_id is null and v_student_id is null then
    return;
  end if;

  return query
  with vt as (
    select mt.*
    from mocks.mock_tests mt
    where mt.results_published = true
      and (lower(mt.branch) = 'all' or lower(mt.branch) = lower(coalesce(v_branch, 'ALL')))
      and (lower(mt.course) = 'all' or lower(mt.course) = lower(coalesce(v_course, 'ALL')))
      and (lower(mt.semester) = 'all' or lower(mt.semester) = lower(coalesce(v_semester, 'ALL')))
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

-- 3. Grant execution permissions
grant execute on function mocks.api_student_results_feed(integer, timestamptz, bigint) to authenticated;

commit;

-- 4. Notify PostgREST to reload schema cache immediately
notify pgrst, 'reload schema';
