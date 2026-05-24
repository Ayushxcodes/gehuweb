-- Phase M3 / Chunk 14 (Emergency No-Hardware Mock Feed Restore)
-- Purpose: restore /student/mock-tests immediately when mocks.mock_hardware_checks does not exist.
-- Scope: replaces ONLY mocks.api_student_mock_feed. It does not touch tables, policies, results feed, auth, or app data.
-- Why this exists: chunk 13 referenced mocks.mock_hardware_checks, but the live DB reported:
--   relation "mocks.mock_hardware_checks" does not exist

begin;

create or replace function mocks.normalize_course(p_course text)
returns text
language sql
immutable
as $$
  select case
    when p_course is null or trim(p_course) = '' then 'ALL'
    when lower(trim(p_course)) in (
      'mca',
      'master of computer application',
      'master of computer applications',
      'masters of computer application',
      'masters of computer applications'
    ) then 'MCA'
    when lower(trim(p_course)) in (
      'bca',
      'bachelor of computer application',
      'bachelor of computer applications'
    ) then 'BCA'
    when lower(trim(p_course)) in (
      'b.tech cse',
      'btech cse',
      'bachelor of technology cse',
      'bachelor of technology in computer science'
    ) then 'B.Tech CSE'
    when lower(trim(p_course)) in ('b.tech', 'btech', 'bachelor of technology') then 'B.Tech'
    when lower(trim(p_course)) in ('m.tech', 'mtech', 'master of technology') then 'M.Tech'
    when lower(trim(p_course)) in ('mba', 'master of business administration') then 'MBA'
    else trim(p_course)
  end;
$$;

grant execute on function mocks.normalize_course(text) to authenticated;

drop function if exists mocks.api_student_mock_feed(integer, timestamptz, text);

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
  my_percentage numeric,
  my_hardware_verified boolean,
  my_hardware_camera_ok boolean,
  my_hardware_mic_ok boolean
)
language plpgsql
stable
security definer
set search_path = public, mocks, pg_temp
as $$
declare
  v_auth_user_id uuid := auth.uid();
  v_student_id text;
  v_branch text;
  v_course text;
  v_semester text;
  v_semester_digits text;
begin
  if v_auth_user_id is null then
    return;
  end if;

  select
    ai.student_id,
    coalesce(nullif(trim(ps.branch), ''), 'ALL'),
    mocks.normalize_course(ps.course),
    coalesce(nullif(trim(ps.semester::text), ''), 'ALL')
  into v_student_id, v_branch, v_course, v_semester
  from public.app_user_identity ai
  left join public.app_profile_state ps
    on ps.auth_user_id = ai.auth_user_id
  where ai.auth_user_id = v_auth_user_id
    and ai.is_active = true
    and ai.account_type = 'STUDENT'
  limit 1;

  if v_student_id is null then
    return;
  end if;

  v_semester_digits := nullif(regexp_replace(coalesce(v_semester, ''), '[^0-9]+', '', 'g'), '');

  return query
  with vt as (
    select
      mt.test_id,
      mt.title,
      coalesce(mt.branch, 'ALL') as branch,
      mocks.normalize_course(mt.course) as course,
      coalesce(mt.semester, 'ALL') as semester,
      mt.start_at,
      mt.duration_minutes,
      mt.status,
      coalesce(mt.results_published, false) as results_published,
      coalesce(mt.requires_web_proctoring, false) as requires_web_proctoring
    from mocks.mock_tests mt
    where (mt.status = 'POSTED' or coalesce(mt.published, false) = true)
      and (lower(coalesce(mt.branch, 'ALL')) = 'all' or lower(coalesce(mt.branch, '')) = lower(v_branch))
      and (mocks.normalize_course(mt.course) = 'ALL' or mocks.normalize_course(mt.course) = v_course)
      and (
        lower(coalesce(mt.semester, 'ALL')) = 'all'
        or lower(coalesce(mt.semester, '')) = lower(v_semester)
        or (
          v_semester_digits is not null
          and nullif(regexp_replace(coalesce(mt.semester, ''), '[^0-9]+', '', 'g'), '') = v_semester_digits
        )
      )
      and (
        p_before_start_at is null
        or mt.start_at < p_before_start_at
        or (mt.start_at = p_before_start_at and p_before_test_id is not null and mt.test_id < p_before_test_id)
      )
    order by mt.start_at desc nulls last, mt.test_id desc
    limit greatest(1, least(coalesce(p_limit, 25), 50))
  )
  select
    vt.test_id,
    vt.title,
    vt.branch,
    vt.course,
    vt.semester,
    vt.start_at,
    vt.duration_minutes,
    vt.status,
    vt.results_published,
    vt.requires_web_proctoring,
    coalesce(mr.locked, false) as my_locked,
    coalesce(mr.published, false) or coalesce(mr.results_published, false) as my_published,
    mr.started_at as my_started_at,
    mr.submitted_at as my_submitted_at,
    mr.score as my_score,
    mr.percentage as my_percentage,
    false as my_hardware_verified,
    false as my_hardware_camera_ok,
    false as my_hardware_mic_ok
  from vt
  left join lateral (
    select r.locked, r.published, r.results_published, r.started_at, r.submitted_at, r.score, r.percentage, r.updated_at, r.result_id
    from mocks.mock_results r
    where r.test_id = vt.test_id
      and (
        r.auth_user_id = v_auth_user_id
        or r.student_id = v_student_id
      )
    order by r.updated_at desc nulls last, r.result_id desc
    limit 1
  ) mr on true
  order by vt.start_at desc nulls last, vt.test_id desc;
end;
$$;

grant execute on function mocks.api_student_mock_feed(integer, timestamptz, text) to authenticated;

commit;

notify pgrst, 'reload schema';

select
  true as mock_feed_no_hardware_dependency_restored,
  to_regclass('mocks.mock_hardware_checks') is not null as has_mock_hardware_checks_table,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'mocks'
      and p.proname = 'api_student_mock_feed'
  ) as has_mock_feed_rpc;
