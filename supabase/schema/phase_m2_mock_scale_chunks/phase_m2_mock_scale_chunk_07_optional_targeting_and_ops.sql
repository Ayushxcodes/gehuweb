-- Phase M2 / Chunk 07 (optional)
-- Purpose:
-- 1) Make mock targeting independent from profile-completion state.
-- 2) Add campus targeting for future admin filters (non-breaking default ALL).
-- 3) Create small ops views so dashboard tracking is simple.

alter table mocks.mock_tests
  add column if not exists campus text not null default 'ALL';

create index if not exists idx_m2_mock_tests_posted_campus_segment_start
  on mocks.mock_tests (lower(campus), lower(branch), lower(course), lower(semester), start_at desc, test_id desc)
  where status = 'POSTED';

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
    coalesce(nullif(trim(sb.stu_branch_name), ''), nullif(trim(ps.branch), ''), 'ALL') as branch,
    coalesce(nullif(trim(sc.stu_course_name), ''), nullif(trim(ps.course), ''), 'ALL') as course,
    coalesce(nullif(trim(sec.stu_year_sem_no::text), ''), nullif(trim(ps.semester::text), ''), 'ALL') as semester
  from public.app_user_identity ai
  left join public.student_enrollment_current sec
    on sec.stu_enroll_student_id = ai.student_id
  left join public.stu_branch_master sb
    on sb.stu_branch_id = sec.stu_branch_id
  left join public.stu_course_master sc
    on sc.stu_course_id = sec.stu_course_id
  left join public.app_profile_state ps
    on ps.auth_user_id = ai.auth_user_id
  where ai.auth_user_id = (select auth.uid())
    and ai.is_active = true
    and ai.account_type = 'STUDENT'
  limit 1;
$$;

create schema if not exists ops;

create or replace view ops.v_identity_student_readiness as
select
  ai.auth_user_id,
  ai.student_id,
  sec.stu_year_sem_no as semester_no,
  sc.stu_course_name as course_name,
  sb.stu_branch_name as branch_name,
  cp.stu_campus_name as campus_name,
  (ps.uid is not null) as has_profile_state
from public.app_user_identity ai
left join public.student_enrollment_current sec
  on sec.stu_enroll_student_id = ai.student_id
left join public.stu_course_master sc
  on sc.stu_course_id = sec.stu_course_id
left join public.stu_branch_master sb
  on sb.stu_branch_id = sec.stu_branch_id
left join public.stu_campus_master cp
  on cp.stu_campus_id = sec.stu_college_campus_id
left join public.app_profile_state ps
  on ps.auth_user_id = ai.auth_user_id
where ai.account_type = 'STUDENT'
  and ai.is_active = true;

create or replace view ops.v_mock_tests_status as
select
  mt.test_id,
  mt.title,
  mt.status,
  mt.campus,
  mt.branch,
  mt.course,
  mt.semester,
  mt.start_at,
  mt.results_published,
  count(mr.result_id) as result_rows,
  count(*) filter (where coalesce(mr.locked, false)) as locked_rows,
  count(*) filter (where coalesce(mr.published, false) or coalesce(mr.results_published, false)) as published_rows
from mocks.mock_tests mt
left join mocks.mock_results mr
  on mr.test_id = mt.test_id
group by mt.test_id, mt.title, mt.status, mt.campus, mt.branch, mt.course, mt.semester, mt.start_at, mt.results_published;
