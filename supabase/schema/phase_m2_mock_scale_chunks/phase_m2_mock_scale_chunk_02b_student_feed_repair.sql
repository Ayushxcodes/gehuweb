-- Phase M2 / Chunk 02B (repair)
-- Use only if api_student_mock_feed is missing/signature mismatch

drop function if exists mocks.api_student_mock_feed(integer, timestamptz, text);
drop function if exists mocks.api_student_mock_feed(integer, timestamp, text);
drop function if exists mocks.api_student_mock_feed(integer);

create or replace function mocks.current_student_context()
returns table (
  auth_user_id uuid,
  student_id text,
  branch text,
  course text,
  semester text
)
language sql
stable
as $$
  select
    ai.auth_user_id,
    ai.student_id,
    coalesce(nullif(trim(ps.branch), ''), 'ALL') as branch,
    coalesce(nullif(trim(ps.course), ''), 'ALL') as course,
    coalesce(nullif(trim(ps.semester::text), ''), 'ALL') as semester
  from public.app_user_identity ai
  left join public.app_profile_state ps
    on ps.auth_user_id = ai.auth_user_id
  where ai.auth_user_id = (select auth.uid())
    and ai.is_active = true
    and ai.account_type = 'STUDENT'
  limit 1;
$$;

create or replace function mocks.api_student_mock_feed(
  p_limit integer default 25,
  p_before_start_at timestamptz default null,
  p_before_test_id text default null
)
returns table (
  test_id text,
  title text,
  branch text,
  course text,
  semester text,
  start_at timestamptz,
  duration_minutes integer,
  status text,
  results_published boolean,
  requires_web_proctoring boolean,
  my_locked boolean,
  my_published boolean,
  my_started_at timestamptz,
  my_submitted_at timestamptz,
  my_score numeric,
  my_percentage numeric
)
language sql
stable
as $$
  with ctx as (
    select * from mocks.current_student_context()
  ),
  vt as (
    select mt.*
    from mocks.mock_tests mt
    join ctx on true
    where mt.status = 'POSTED'
      and (mt.expires_at is null or mt.expires_at > now())
      and (lower(mt.branch) = 'all' or lower(mt.branch) = lower(ctx.branch))
      and (lower(mt.course) = 'all' or lower(mt.course) = lower(ctx.course))
      and (lower(mt.semester) = 'all' or lower(mt.semester) = lower(ctx.semester))
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
    vt.status, vt.results_published, vt.requires_web_proctoring,
    coalesce(mr.locked, false) as my_locked,
    coalesce(mr.published, false) or coalesce(mr.results_published, false) as my_published,
    mr.started_at, mr.submitted_at, mr.score, mr.percentage
  from vt
  left join ctx on true
  left join lateral (
    select r.locked, r.published, r.results_published, r.started_at, r.submitted_at, r.score, r.percentage
    from mocks.mock_results r
    where r.test_id = vt.test_id
      and (
        (ctx.auth_user_id is not null and r.auth_user_id = ctx.auth_user_id)
        or (ctx.student_id is not null and r.student_id = ctx.student_id)
      )
    order by r.updated_at desc nulls last, r.result_id desc
    limit 1
  ) mr on true
  order by vt.start_at desc, vt.test_id desc;
$$;

grant execute on function mocks.current_student_context() to authenticated;
grant execute on function mocks.api_student_mock_feed(integer, timestamptz, text) to authenticated;

select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
join pg_namespace n
  on n.oid = p.pronamespace
where n.nspname = 'mocks'
  and p.proname = 'api_student_mock_feed';
