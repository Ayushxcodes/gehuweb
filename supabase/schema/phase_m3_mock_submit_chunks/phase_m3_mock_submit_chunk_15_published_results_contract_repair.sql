-- Phase M3 / Chunk 15 (Published Results Contract Repair)
-- Purpose:
-- 1) Student results must show ONLY tests whose results were published by admin/instructor.
-- 2) Published tests must show for the student even if the student was absent.
-- 3) Admin report test search gets a bounded RPC instead of fragile client-side table filters.
-- Scope: replaces only two RPCs. No table drops. No policy rewrites. No data deletion.

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
  with visible_tests as (
    select mt.*
    from mocks.mock_tests mt
    where coalesce(mt.results_published, false) = true
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
  ),
  my_results as (
    select
      r.test_id,
      r.result_id,
      r.submitted_at,
      r.score,
      r.max_marks,
      r.percentage,
      r.correct,
      r.wrong,
      r.unattempted,
      r.updated_at
    from mocks.mock_results r
    where r.auth_user_id = v_auth_user_id

    union all

    select
      r.test_id,
      r.result_id,
      r.submitted_at,
      r.score,
      r.max_marks,
      r.percentage,
      r.correct,
      r.wrong,
      r.unattempted,
      r.updated_at
    from mocks.mock_results r
    where r.student_id = v_student_id
      and not exists (
        select 1
        from mocks.mock_results rx
        where rx.test_id = r.test_id
          and rx.auth_user_id = v_auth_user_id
      )
  ),
  deduped_results as (
    select distinct on (mr.test_id) mr.*
    from my_results mr
    order by mr.test_id, mr.updated_at desc nulls last, mr.result_id desc
  ),
  prepared as (
    select
      coalesce(mr.result_id, ('-1' || lpad(abs(hashtext(vt.test_id)::bigint)::text, 10, '0'))::bigint) as row_result_id,
      vt.test_id,
      vt.title,
      vt.start_at,
      mr.submitted_at,
      coalesce(mr.score, 0::numeric) as score,
      coalesce(
        mr.max_marks,
        round(vt.total_questions * greatest(coalesce(vt.marking_aptitude_per_q, 1), coalesce(vt.marking_english_per_q, 1)))::integer,
        0
      ) as max_marks,
      coalesce(mr.percentage, 0::numeric) as percentage,
      coalesce(mr.correct, 0) as correct,
      coalesce(mr.wrong, 0) as wrong,
      coalesce(mr.unattempted, vt.total_questions, 0) as unattempted,
      coalesce(vt.test_type, case when coalesce(vt.requires_web_proctoring, false) then 'MET' else 'QET' end) as test_type,
      coalesce(mr.submitted_at, vt.start_at) as sort_at
    from visible_tests vt
    left join deduped_results mr
      on mr.test_id = vt.test_id
  )
  select
    p.row_result_id,
    p.test_id,
    p.title,
    p.start_at,
    p.submitted_at,
    p.score,
    p.max_marks,
    p.percentage,
    p.correct,
    p.wrong,
    p.unattempted,
    p.test_type
  from prepared p
  where (
    p_before_submitted_at is null
    or p.sort_at < p_before_submitted_at
    or (
      p.sort_at = p_before_submitted_at
      and p_before_result_id is not null
      and p.row_result_id < p_before_result_id
    )
  )
  order by p.sort_at desc nulls last, p.row_result_id desc
  limit greatest(1, least(coalesce(p_limit, 25), 50));
end;
$$;

grant execute on function mocks.api_student_results_feed(integer, timestamptz, bigint) to authenticated;

create or replace function mocks.api_admin_mock_tests_search(
  p_branch text default null,
  p_course text default null,
  p_semester text default null,
  p_search text default null,
  p_custom_code text default null,
  p_limit integer default 50
)
returns table (
  test_id text,
  title text,
  branch text,
  course text,
  semester text,
  total_questions integer,
  published boolean,
  results_published boolean,
  created_at timestamptz,
  test_type text,
  custom_code text
)
language plpgsql
stable
security definer
set search_path = public, mocks, pg_temp
as $$
declare
  v_branch text := nullif(trim(coalesce(p_branch, '')), '');
  v_course text := mocks.normalize_course(nullif(trim(coalesce(p_course, '')), ''));
  v_semester text := nullif(trim(coalesce(p_semester, '')), '');
  v_semester_digits text;
  v_search text := nullif(trim(coalesce(p_search, '')), '');
  v_custom_code text := nullif(upper(trim(coalesce(p_custom_code, ''))), '');
begin
  if not mocks.is_admin() then
    raise exception 'forbidden: admin role required';
  end if;

  if v_branch = 'ALL' then v_branch := null; end if;
  if v_course = 'ALL' then v_course := null; end if;
  if v_semester = 'ALL' then v_semester := null; end if;

  v_semester_digits := nullif(regexp_replace(coalesce(v_semester, ''), '[^0-9]+', '', 'g'), '');

  return query
  select
    mt.test_id,
    mt.title,
    coalesce(mt.branch, 'ALL') as branch,
    mocks.normalize_course(mt.course) as course,
    coalesce(mt.semester, 'ALL') as semester,
    mt.total_questions,
    coalesce(mt.published, false) as published,
    coalesce(mt.results_published, false) as results_published,
    mt.created_at,
    coalesce(mt.test_type, case when coalesce(mt.requires_web_proctoring, false) then 'MET' else 'QET' end) as test_type,
    mt.custom_code
  from mocks.mock_tests mt
  where coalesce(mt.status, 'DRAFT') <> 'ARCHIVED'
    and (v_custom_code is null or upper(coalesce(mt.custom_code, '')) = v_custom_code)
    and (v_branch is null or lower(coalesce(mt.branch, 'ALL')) = 'all' or lower(coalesce(mt.branch, '')) = lower(v_branch))
    and (v_course is null or mocks.normalize_course(mt.course) = 'ALL' or mocks.normalize_course(mt.course) = v_course)
    and (
      v_semester is null
      or lower(coalesce(mt.semester, 'ALL')) = 'all'
      or lower(coalesce(mt.semester, '')) = lower(v_semester)
      or (
        v_semester_digits is not null
        and nullif(regexp_replace(coalesce(mt.semester, ''), '[^0-9]+', '', 'g'), '') = v_semester_digits
      )
    )
    and (v_search is null or mt.title ilike ('%' || v_search || '%') or mt.test_id ilike ('%' || v_search || '%') or mt.custom_code ilike ('%' || v_search || '%'))
  order by mt.created_at desc nulls last, mt.start_at desc nulls last, mt.test_id desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

grant execute on function mocks.api_admin_mock_tests_search(text, text, text, text, text, integer) to authenticated;

commit;

notify pgrst, 'reload schema';

select
  true as published_results_contract_repaired,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'mocks'
      and p.proname = 'api_student_results_feed'
  ) as has_student_results_rpc,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'mocks'
      and p.proname = 'api_admin_mock_tests_search'
  ) as has_admin_mock_tests_search_rpc;
