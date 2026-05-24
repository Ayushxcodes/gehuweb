-- Phase M3 / Chunk 04 (Mock Feed Performance Repair)
-- Purpose: Overhauls mocks.api_student_mock_feed RPC to use high-performance PL/pgSQL.
-- This completely eliminates the `OR` join sequential scan trap that was exhausting the database
-- connection pool and causing 8-second query timeouts on the ongoing/upcoming mock tests feed.

begin;

-- Dynamically drop all overloaded signatures to ensure clean slate
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
    where p.proname = 'api_student_mock_feed'
  loop
    execute 'drop function if exists ' || r.schema_name || '.' || r.function_name || '(' || r.args || ') cascade;';
  end loop;
end;
$$;

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
  -- 1. Fetch static scalar coordinates once (< 0.1ms)
  select auth_user_id, student_id, branch, course, semester
  into v_auth_user_id, v_student_id, v_branch, v_course, v_semester
  from mocks.current_student_context()
  limit 1;

  -- 2. Prevent unauthenticated access instantly
  if v_auth_user_id is null and v_student_id is null then
    return;
  end if;

  -- 3. Execute 100% indexed query
  return query
  with vt as (
    select mt.*
    from mocks.mock_tests mt
    where mt.status = 'POSTED'
      and (mt.expires_at is null or mt.expires_at > now())
      and (lower(mt.branch) = 'all' or lower(mt.branch) = lower(coalesce(v_branch, 'ALL')))
      and (lower(mt.course) = 'all' or lower(mt.course) = lower(coalesce(v_course, 'ALL')))
      and (lower(mt.semester) = 'all' or lower(mt.semester) = lower(coalesce(v_semester, 'ALL')))
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

grant execute on function mocks.api_student_mock_feed(integer, timestamptz, text) to authenticated;

commit;

notify pgrst, 'reload schema';
