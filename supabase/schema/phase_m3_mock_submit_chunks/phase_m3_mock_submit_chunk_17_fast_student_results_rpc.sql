-- Phase M3 / Chunk 17 (Fast Student Results RPC)
-- Purpose:
-- 1) Replace the student results feed with a bounded, index-friendly query.
-- 2) Show only tests released by mocks.mock_tests.results_published = true.
-- 3) Show an ABSENT synthetic card when the released test has no student result row.
-- 4) No sync/backfill. No table/column/policy changes.

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
    select
      mt.test_id,
      mt.title,
      mt.start_at,
      mt.total_questions,
      mt.marking_aptitude_per_q,
      mt.marking_english_per_q,
      coalesce(mt.test_type, case when coalesce(mt.requires_web_proctoring, false) then 'MET' else 'QET' end) as test_type,
      (-(abs(hashtext(mt.test_id))::bigint + 1)) as absent_result_id
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
      and (
        p_before_submitted_at is null
        or mt.start_at < p_before_submitted_at
        or (
          mt.start_at = p_before_submitted_at
          and p_before_result_id is not null
          and (-(abs(hashtext(mt.test_id))::bigint + 1)) < p_before_result_id
        )
      )
    order by mt.start_at desc nulls last, mt.test_id desc
    limit greatest(1, least(coalesce(p_limit, 25), 50))
  )
  select
    coalesce(mr.result_id, vt.absent_result_id) as result_id,
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
    vt.test_type
  from visible_tests vt
  left join lateral (
    select candidate.*
    from (
      select
        r.result_id,
        r.submitted_at,
        r.score,
        r.max_marks,
        r.percentage,
        r.correct,
        r.wrong,
        r.unattempted,
        r.updated_at,
        0 as priority
      from mocks.mock_results r
      where r.test_id = vt.test_id
        and r.auth_user_id = v_auth_user_id

      union all

      select
        r.result_id,
        r.submitted_at,
        r.score,
        r.max_marks,
        r.percentage,
        r.correct,
        r.wrong,
        r.unattempted,
        r.updated_at,
        1 as priority
      from mocks.mock_results r
      where r.test_id = vt.test_id
        and r.student_id = v_student_id
        and not exists (
          select 1
          from mocks.mock_results rx
          where rx.test_id = vt.test_id
            and rx.auth_user_id = v_auth_user_id
        )
    ) candidate
    order by candidate.priority, candidate.updated_at desc nulls last, candidate.result_id desc
    limit 1
  ) mr on true
  order by coalesce(mr.submitted_at, vt.start_at) desc nulls last,
           coalesce(mr.result_id, vt.absent_result_id) desc;
end;
$$;

grant execute on function mocks.api_student_results_feed(integer, timestamptz, bigint) to authenticated;

commit;

notify pgrst, 'reload schema';

select
  true as fast_student_results_rpc_installed,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'mocks'
      and p.proname = 'api_student_results_feed'
  ) as has_student_results_rpc;