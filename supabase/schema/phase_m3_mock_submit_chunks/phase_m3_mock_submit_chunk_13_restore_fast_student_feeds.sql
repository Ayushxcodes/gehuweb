-- Phase M3 / Chunk 13 (Restore Fast Student Feeds)
-- Purpose: emergency restore for student mock feed/results feed after chunk 12 caused timeouts.
-- Scope: replaces only the two student feed RPCs with bounded, lightweight, security-definer functions.

begin;

create or replace function mocks.normalize_course(p_course text)
returns text
language sql
immutable
as $$
  select case
    when p_course is null or trim(p_course) = '' then 'ALL'
    when lower(trim(p_course)) in ('mca', 'master of computer application', 'master of computer applications') then 'MCA'
    when lower(trim(p_course)) in ('bca', 'bachelor of computer application', 'bachelor of computer applications') then 'BCA'
    when lower(trim(p_course)) in ('b.tech cse', 'btech cse', 'bachelor of technology cse', 'bachelor of technology in computer science') then 'B.Tech CSE'
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
    where mt.status = 'POSTED'
      and (mt.expires_at is null or mt.expires_at > now())
      and (lower(coalesce(mt.branch, 'ALL')) = 'all' or lower(mt.branch) = lower(v_branch))
      and (mocks.normalize_course(mt.course) = 'ALL' or mocks.normalize_course(mt.course) = v_course)
      and (lower(coalesce(mt.semester, 'ALL')) = 'all' or lower(coalesce(mt.semester, 'ALL')) = lower(v_semester))
      and (
        p_before_start_at is null
        or mt.start_at < p_before_start_at
        or (mt.start_at = p_before_start_at and p_before_test_id is not null and mt.test_id < p_before_test_id)
      )
    order by mt.start_at desc, mt.test_id desc
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
    coalesce(hw.verified_at is not null, false) as my_hardware_verified,
    coalesce(hw.camera_ok, false) as my_hardware_camera_ok,
    coalesce(hw.mic_ok, false) as my_hardware_mic_ok
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
  left join lateral (
    select h.camera_ok, h.mic_ok, h.verified_at
    from mocks.mock_hardware_checks h
    where h.test_id = vt.test_id
      and h.auth_user_id = v_auth_user_id
    order by h.updated_at desc nulls last, h.check_id desc
    limit 1
  ) hw on true
  order by vt.start_at desc, vt.test_id desc;
end;
$$;

grant execute on function mocks.api_student_mock_feed(integer, timestamptz, text) to authenticated;

drop function if exists mocks.api_student_results_feed(integer, timestamptz, bigint);

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
security definer
set search_path = public, mocks, pg_temp
as $$
declare
  v_auth_user_id uuid := auth.uid();
  v_student_id text;
begin
  if v_auth_user_id is null then
    return;
  end if;

  select ai.student_id
  into v_student_id
  from public.app_user_identity ai
  where ai.auth_user_id = v_auth_user_id
    and ai.is_active = true
    and ai.account_type = 'STUDENT'
  limit 1;

  if v_student_id is null then
    return;
  end if;

  return query
  with my_results as (
    select r.*
    from mocks.mock_results r
    where r.auth_user_id = v_auth_user_id

    union all

    select r.*
    from mocks.mock_results r
    where r.student_id = v_student_id
      and not exists (
        select 1
        from mocks.mock_results rx
        where rx.test_id = r.test_id
          and rx.auth_user_id = v_auth_user_id
      )
  ),
  deduped as (
    select distinct on (mr.test_id) mr.*
    from my_results mr
    order by mr.test_id, mr.updated_at desc nulls last, mr.result_id desc
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
    mr.unattempted,
    coalesce(mt.test_type, case when coalesce(mt.requires_web_proctoring, false) then 'MET' else 'QET' end) as test_type
  from deduped mr
  join mocks.mock_tests mt
    on mt.test_id = mr.test_id
  where (
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
  limit greatest(1, least(coalesce(p_limit, 25), 50));
end;
$$;

grant execute on function mocks.api_student_results_feed(integer, timestamptz, bigint) to authenticated;

commit;

notify pgrst, 'reload schema';

select
  true as fast_student_feeds_restored,
  exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'mocks'
      and p.proname = 'api_student_mock_feed'
  ) as has_mock_feed_rpc,
  exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'mocks'
      and p.proname = 'api_student_results_feed'
  ) as has_results_feed_rpc;
