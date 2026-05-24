-- Phase M3 / Chunk 12 (Mock System Contract Repair)
-- Purpose:
-- 1) Make the mock DB contract match the current web/app runtime payloads.
-- 2) Replace debug/incomplete feed RPCs with cohort-safe production RPCs.
-- 3) Add the missing student hardware-readiness persistence used by proctored mock tests.
--
-- Safe properties:
-- - No pg_terminate_backend.
-- - No destructive table drops.
-- - Additive columns use IF NOT EXISTS.
-- - Feed RPCs are intentionally dropped/recreated because their return shape changes.

begin;

create schema if not exists ops;

-- -------------------------------------------------------------------------
-- 0. Public legacy compatibility tables used by web create/delete flows
-- -------------------------------------------------------------------------
create table if not exists public.app_mock_tests (
  test_id text primary key
);

alter table public.app_mock_tests
  add column if not exists title text,
  add column if not exists duration_minutes integer not null default 60,
  add column if not exists requires_web_proctoring boolean not null default false,
  add column if not exists payload_cdn_url text,
  add column if not exists start_at timestamptz,
  add column if not exists published boolean not null default true,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update public.app_mock_tests
set
  title = coalesce(nullif(trim(title), ''), 'Untitled Mock Test'),
  duration_minutes = greatest(coalesce(duration_minutes, 60), 1),
  requires_web_proctoring = coalesce(requires_web_proctoring, false),
  published = coalesce(published, true),
  created_at = coalesce(created_at, now()),
  updated_at = coalesce(updated_at, now());

alter table public.app_mock_tests
  alter column title set not null,
  alter column duration_minutes set not null,
  alter column requires_web_proctoring set not null,
  alter column published set not null,
  alter column created_at set not null,
  alter column updated_at set not null;

create table if not exists public.app_mock_questions (
  question_id text primary key,
  test_id text not null references public.app_mock_tests(test_id) on update restrict on delete cascade,
  subject text,
  topic text,
  question text not null,
  option_a text,
  option_b text,
  option_c text,
  option_d text,
  answer text,
  difficulty text,
  solution text,
  created_at timestamptz not null default now()
);

alter table public.app_mock_questions
  add column if not exists test_id text,
  add column if not exists subject text,
  add column if not exists topic text,
  add column if not exists question text,
  add column if not exists option_a text,
  add column if not exists option_b text,
  add column if not exists option_c text,
  add column if not exists option_d text,
  add column if not exists answer text,
  add column if not exists difficulty text,
  add column if not exists solution text,
  add column if not exists created_at timestamptz not null default now();

create table if not exists public.app_mock_results (
  result_id bigint generated always as identity primary key,
  test_id text,
  auth_user_id uuid,
  student_id text,
  score numeric,
  percentage numeric,
  created_at timestamptz not null default now()
);

alter table public.app_mock_results
  add column if not exists test_id text,
  add column if not exists auth_user_id uuid,
  add column if not exists student_id text,
  add column if not exists score numeric,
  add column if not exists percentage numeric,
  add column if not exists created_at timestamptz not null default now();

grant select, insert, update, delete on public.app_mock_tests to authenticated;
grant select, insert, update, delete on public.app_mock_questions to authenticated;
grant select, insert, update, delete on public.app_mock_results to authenticated;

alter table public.app_mock_tests enable row level security;
alter table public.app_mock_questions enable row level security;
alter table public.app_mock_results enable row level security;

drop policy if exists p_mock_legacy_tests_select on public.app_mock_tests;
create policy p_mock_legacy_tests_select
on public.app_mock_tests
for select
to authenticated
using (true);

drop policy if exists p_mock_legacy_tests_admin_write on public.app_mock_tests;
create policy p_mock_legacy_tests_admin_write
on public.app_mock_tests
for all
to authenticated
using (mocks.is_admin())
with check (mocks.is_admin());

drop policy if exists p_mock_legacy_questions_select on public.app_mock_questions;
create policy p_mock_legacy_questions_select
on public.app_mock_questions
for select
to authenticated
using (true);

drop policy if exists p_mock_legacy_questions_admin_write on public.app_mock_questions;
create policy p_mock_legacy_questions_admin_write
on public.app_mock_questions
for all
to authenticated
using (mocks.is_admin())
with check (mocks.is_admin());

drop policy if exists p_mock_legacy_results_admin_write on public.app_mock_results;
create policy p_mock_legacy_results_admin_write
on public.app_mock_results
for all
to authenticated
using (mocks.is_admin())
with check (mocks.is_admin());

-- -------------------------------------------------------------------------
-- 1. Contract columns expected by the current frontend and submit RPC
-- -------------------------------------------------------------------------
alter table mocks.mock_tests
  add column if not exists requires_web_proctoring boolean;

alter table mocks.mock_tests
  add column if not exists negative_value_aptitude numeric(10,2);

alter table mocks.mock_tests
  add column if not exists negative_value_english numeric(10,2);

alter table mocks.mock_tests
  add column if not exists test_type text;

alter table mocks.mock_tests
  add column if not exists custom_code text;

update mocks.mock_tests
set
  branch = coalesce(nullif(trim(branch), ''), 'ALL'),
  course = coalesce(nullif(trim(course), ''), 'ALL'),
  semester = coalesce(nullif(trim(semester), ''), 'ALL'),
  requires_web_proctoring = coalesce(requires_web_proctoring, false),
  negative_value_aptitude = coalesce(negative_value_aptitude, negative_value, 0),
  negative_value_english = coalesce(negative_value_english, negative_value, 0),
  test_type = coalesce(test_type, case when coalesce(requires_web_proctoring, false) then 'MET' else 'QET' end);

alter table mocks.mock_tests
  alter column requires_web_proctoring set default false,
  alter column requires_web_proctoring set not null,
  alter column negative_value_aptitude set default 0,
  alter column negative_value_aptitude set not null,
  alter column negative_value_english set default 0,
  alter column negative_value_english set not null,
  alter column test_type set default 'MET';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'mocks.mock_tests'::regclass
      and conname = 'mock_tests_test_type_contract_check'
  ) then
    alter table mocks.mock_tests
      add constraint mock_tests_test_type_contract_check
      check (test_type in ('MET', 'QET'));
  end if;
end $$;

with numbered as (
  select
    mt.test_id,
    coalesce(mt.test_type, case when mt.requires_web_proctoring then 'MET' else 'QET' end) as prefix,
    row_number() over (order by mt.created_at, mt.test_id)
      + (select count(*) from mocks.mock_tests where nullif(trim(custom_code), '') is not null) as rn
  from mocks.mock_tests mt
  where nullif(trim(mt.custom_code), '') is null
)
update mocks.mock_tests mt
set custom_code = numbered.prefix || '-' || lpad(numbered.rn::text, 4, '0')
from numbered
where mt.test_id = numbered.test_id;

create unique index if not exists uq_mock_tests_custom_code_present
  on mocks.mock_tests(custom_code)
  where custom_code is not null;

create index if not exists idx_mock_tests_contract_feed
  on mocks.mock_tests(status, results_published, start_at desc, test_id desc);

create index if not exists idx_mock_tests_contract_target
  on mocks.mock_tests(branch, course, semester, status, start_at desc);

-- -------------------------------------------------------------------------
-- 2. Shared normalization helpers
-- -------------------------------------------------------------------------
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
    mocks.normalize_course(ps.course) as course,
    coalesce(nullif(trim(ps.semester::text), ''), 'ALL') as semester
  from public.app_user_identity ai
  left join public.app_profile_state ps
    on ps.auth_user_id = ai.auth_user_id
  where ai.auth_user_id = (select auth.uid())
    and ai.is_active = true
    and ai.account_type = 'STUDENT'
  limit 1;
$$;

grant execute on function mocks.current_student_context() to authenticated;

-- -------------------------------------------------------------------------
-- 3. Hardware readiness state for proctored mock tests
-- -------------------------------------------------------------------------
create table if not exists mocks.mock_hardware_checks (
  check_id bigint generated always as identity primary key,
  test_id text not null references mocks.mock_tests(test_id) on update restrict on delete cascade,
  auth_user_id uuid not null references auth.users(id) on update restrict on delete cascade,
  student_id text,
  camera_ok boolean not null default false,
  mic_ok boolean not null default false,
  user_agent text,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists uq_mock_hardware_checks_test_auth
  on mocks.mock_hardware_checks(test_id, auth_user_id);

create index if not exists idx_mock_hardware_checks_test
  on mocks.mock_hardware_checks(test_id);

drop trigger if exists trg_mock_hardware_checks_touch_updated_at on mocks.mock_hardware_checks;
create trigger trg_mock_hardware_checks_touch_updated_at
before update on mocks.mock_hardware_checks
for each row execute function mocks.touch_updated_at();

grant select, insert, update on mocks.mock_hardware_checks to authenticated;

alter table mocks.mock_hardware_checks enable row level security;

drop policy if exists p_m3_mock_hardware_select_scope on mocks.mock_hardware_checks;
create policy p_m3_mock_hardware_select_scope
on mocks.mock_hardware_checks
for select
to authenticated
using (
  mocks.is_admin()
  or auth_user_id = auth.uid()
  or student_id = mocks.current_student_id()
);

drop policy if exists p_m3_mock_hardware_insert_self on mocks.mock_hardware_checks;
create policy p_m3_mock_hardware_insert_self
on mocks.mock_hardware_checks
for insert
to authenticated
with check (
  auth_user_id = auth.uid()
  and (
    student_id is null
    or student_id = mocks.current_student_id()
  )
);

drop policy if exists p_m3_mock_hardware_update_self on mocks.mock_hardware_checks;
create policy p_m3_mock_hardware_update_self
on mocks.mock_hardware_checks
for update
to authenticated
using (auth_user_id = auth.uid() or mocks.is_admin())
with check (auth_user_id = auth.uid() or mocks.is_admin());

create or replace function mocks.api_student_mark_mock_hardware_ready(
  p_test_id text,
  p_camera_ok boolean default false,
  p_mic_ok boolean default false,
  p_user_agent text default null
)
returns boolean
language plpgsql
security invoker
as $$
declare
  v_auth_user_id uuid;
  v_student_id text;
begin
  select ctx.auth_user_id, ctx.student_id
  into v_auth_user_id, v_student_id
  from mocks.current_student_context() ctx
  limit 1;

  if v_auth_user_id is null then
    raise exception 'forbidden: authenticated student required';
  end if;

  if not exists (
    select 1
    from mocks.mock_tests mt
    where mt.test_id = p_test_id
      and mt.status = 'POSTED'
  ) then
    raise exception 'mock test is not available';
  end if;

  insert into mocks.mock_hardware_checks (
    test_id, auth_user_id, student_id, camera_ok, mic_ok, user_agent, verified_at
  )
  values (
    p_test_id,
    v_auth_user_id,
    v_student_id,
    coalesce(p_camera_ok, false),
    coalesce(p_mic_ok, false),
    nullif(p_user_agent, ''),
    case when coalesce(p_camera_ok, false) and coalesce(p_mic_ok, false) then now() else null end
  )
  on conflict (test_id, auth_user_id)
  do update set
    student_id = excluded.student_id,
    camera_ok = excluded.camera_ok,
    mic_ok = excluded.mic_ok,
    user_agent = excluded.user_agent,
    verified_at = excluded.verified_at,
    updated_at = now();

  return coalesce(p_camera_ok, false) and coalesce(p_mic_ok, false);
end;
$$;

grant execute on function mocks.api_student_mark_mock_hardware_ready(text, boolean, boolean, text) to authenticated;

-- -------------------------------------------------------------------------
-- 4. Student submit RPC, repaired against the explicit schema contract
-- -------------------------------------------------------------------------
create or replace function mocks.api_student_submit_mock_result(
  p_test_id text,
  p_q_order text[] default '{}'::text[],
  p_opt_map jsonb default '{}'::jsonb,
  p_warn_count integer default 0,
  p_started_at timestamptz default null,
  p_session_end_time timestamptz default null,
  p_firebase_uid text default null
)
returns bigint
language plpgsql
security invoker
as $$
declare
  v_auth uuid := auth.uid();
  v_student text;
  v_branch text;
  v_course text;
  v_semester text;
  v_result_id bigint;
  v_total integer := 0;
  v_answered integer := 0;
  v_correct integer := 0;
  v_wrong integer := 0;
  v_unattempted integer := 0;
  v_score numeric := 0;
  v_max integer := 0;
  v_pct numeric := 0;
  v_test mocks.mock_tests%rowtype;
  v_exam_end timestamptz;
begin
  if v_auth is null then
    raise exception 'forbidden: authenticated student required';
  end if;

  select ctx.student_id, ctx.branch, ctx.course, ctx.semester
  into v_student, v_branch, v_course, v_semester
  from mocks.current_student_context() ctx
  limit 1;

  if v_student is null then
    raise exception 'forbidden: active student identity required';
  end if;

  select *
  into v_test
  from mocks.mock_tests
  where test_id = p_test_id;

  if not found or v_test.status <> 'POSTED' then
    raise exception 'mock test is not available';
  end if;

  if coalesce(v_test.results_published, false) then
    raise exception 'results already published';
  end if;

  if mocks.normalize_course(v_test.course) <> 'ALL' and mocks.normalize_course(v_test.course) <> mocks.normalize_course(v_course) then
    raise exception 'mock test is not assigned to your course';
  end if;

  if lower(coalesce(v_test.branch, 'ALL')) <> 'all' and lower(v_test.branch) <> lower(coalesce(v_branch, 'ALL')) then
    raise exception 'mock test is not assigned to your branch';
  end if;

  if lower(coalesce(v_test.semester, 'ALL')) <> 'all' and lower(v_test.semester) <> lower(coalesce(v_semester, 'ALL')) then
    raise exception 'mock test is not assigned to your semester';
  end if;

  v_exam_end := coalesce(
    v_test.exam_end_at,
    v_test.start_at + make_interval(mins => v_test.duration_minutes)
  );

  if now() < v_test.start_at then
    raise exception 'mock test has not started';
  end if;

  if now() > v_exam_end + interval '10 minutes' then
    raise exception 'mock test submission window is closed';
  end if;

  if coalesce(v_test.requires_web_proctoring, false) and not exists (
    select 1
    from mocks.mock_hardware_checks h
    where h.test_id = p_test_id
      and h.auth_user_id = v_auth
      and h.camera_ok = true
      and h.mic_ok = true
      and h.verified_at is not null
  ) then
    raise exception 'hardware readiness check is required before starting this mock test';
  end if;

  with scored as (
    select
      q.qid,
      coalesce(p_opt_map, '{}'::jsonb) ? q.qid as answered,
      upper(coalesce(p_opt_map ->> q.qid, '')) = q.answer_letter as is_correct,
      case
        when q.subject_type = 'APTITUDE' or q.subject ilike '%aptitude%'
          then v_test.marking_aptitude_per_q
        else v_test.marking_english_per_q
      end as marks,
      case
        when q.subject_type = 'APTITUDE' or q.subject ilike '%aptitude%'
          then coalesce(v_test.negative_value_aptitude, v_test.negative_value, 0)
        else coalesce(v_test.negative_value_english, v_test.negative_value, 0)
      end as neg_deduction,
      exists (
        select 1
        from unnest(v_test.negative_apply_to) n
        where lower(n) = lower(q.subject)
           or lower(n) = lower(coalesce(q.subject_type, ''))
      ) as neg_applies
    from mocks.mock_test_questions q
    where q.test_id = p_test_id
  )
  select
    count(*)::integer,
    count(*) filter (where answered)::integer,
    count(*) filter (where answered and is_correct)::integer,
    count(*) filter (where answered and not is_correct)::integer,
    greatest(0, coalesce(sum(case
      when answered and is_correct then marks
      when answered and not is_correct and v_test.negative_enabled and neg_applies then -neg_deduction
      else 0
    end), 0)),
    round(coalesce(sum(marks), 0))::integer
  into v_total, v_answered, v_correct, v_wrong, v_score, v_max
  from scored;

  if v_total <= 0 then
    raise exception 'mock has no frozen questions';
  end if;

  v_unattempted := greatest(0, v_total - v_answered);
  v_pct := case when v_max > 0 then round((v_score * 100.0 / v_max), 2) else 0 end;

  select r.result_id
  into v_result_id
  from mocks.mock_results r
  where r.test_id = p_test_id
    and (
      r.auth_user_id = v_auth
      or r.student_id = v_student
    )
  order by r.updated_at desc nulls last, r.result_id desc
  limit 1;

  if v_result_id is null then
    insert into mocks.mock_results (
      test_id, student_id, auth_user_id, firebase_uid, locked, branch, course, semester
    )
    values (
      p_test_id,
      v_student,
      v_auth,
      nullif(p_firebase_uid, ''),
      false,
      coalesce(v_branch, 'ALL'),
      mocks.normalize_course(v_course),
      coalesce(v_semester, 'ALL')
    )
    returning result_id into v_result_id;
  end if;

  update mocks.mock_results
  set q_order = coalesce(p_q_order, '{}'::text[]),
      opt_map = coalesce(p_opt_map, '{}'::jsonb),
      warn_count = greatest(coalesce(p_warn_count, 0), 0),
      locked = true,
      started_at = coalesce(p_started_at, started_at, now()),
      session_end_time = coalesce(p_session_end_time, session_end_time, now()),
      submitted_at = now(),
      total_questions = v_total,
      answered_count = v_answered,
      score = v_score,
      correct = v_correct,
      wrong = v_wrong,
      unattempted = v_unattempted,
      max_marks = v_max,
      percentage = v_pct,
      branch = coalesce(v_branch, branch, 'ALL'),
      course = mocks.normalize_course(coalesce(v_course, course, 'ALL')),
      semester = coalesce(v_semester, semester, 'ALL')
  where result_id = v_result_id
    and locked = false
  returning result_id into v_result_id;

  if v_result_id is null then
    raise exception 'mock result already submitted';
  end if;

  return v_result_id;
end;
$$;

grant execute on function mocks.api_student_submit_mock_result(
  text, text[], jsonb, integer, timestamptz, timestamptz, text
) to authenticated;

-- -------------------------------------------------------------------------
-- 5. Student feed RPCs, cohort-safe and hardware-aware
-- -------------------------------------------------------------------------
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
security invoker
as $$
declare
  v_auth_user_id uuid;
  v_student_id text;
  v_branch text;
  v_course text;
  v_semester text;
begin
  select ctx.auth_user_id, ctx.student_id, ctx.branch, ctx.course, ctx.semester
  into v_auth_user_id, v_student_id, v_branch, v_course, v_semester
  from mocks.current_student_context() ctx
  limit 1;

  if v_auth_user_id is null and v_student_id is null then
    return;
  end if;

  return query
  with my_results as (
    select r.test_id, r.locked, r.published, r.results_published, r.started_at, r.submitted_at, r.score, r.percentage, r.updated_at, r.result_id
    from mocks.mock_results r
    where v_auth_user_id is not null
      and r.auth_user_id = v_auth_user_id

    union all

    select r.test_id, r.locked, r.published, r.results_published, r.started_at, r.submitted_at, r.score, r.percentage, r.updated_at, r.result_id
    from mocks.mock_results r
    where v_student_id is not null
      and r.student_id = v_student_id
  ),
  deduped_results as (
    select distinct on (mr.test_id) mr.*
    from my_results mr
    order by mr.test_id, mr.updated_at desc nulls last, mr.result_id desc
  ),
  my_hardware as (
    select distinct on (h.test_id)
      h.test_id,
      h.camera_ok,
      h.mic_ok,
      h.verified_at,
      h.updated_at
    from mocks.mock_hardware_checks h
    where v_auth_user_id is not null
      and h.auth_user_id = v_auth_user_id
    order by h.test_id, h.updated_at desc nulls last, h.check_id desc
  ),
  vt as (
    select mt.*
    from mocks.mock_tests mt
    where mt.status = 'POSTED'
      and (mt.expires_at is null or mt.expires_at > now())
      and (lower(coalesce(mt.branch, 'ALL')) = 'all' or lower(mt.branch) = lower(coalesce(v_branch, 'ALL')))
      and (mocks.normalize_course(mt.course) = 'ALL' or mocks.normalize_course(mt.course) = mocks.normalize_course(v_course))
      and (lower(coalesce(mt.semester, 'ALL')) = 'all' or lower(mt.semester) = lower(coalesce(v_semester, 'ALL')))
      and (
        p_before_start_at is null
        or mt.start_at < p_before_start_at
        or (mt.start_at = p_before_start_at and p_before_test_id is not null and mt.test_id < p_before_test_id)
      )
    order by mt.start_at desc, mt.test_id desc
    limit greatest(1, least(coalesce(p_limit, 25), 100))
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
    coalesce(vt.requires_web_proctoring, false) as requires_web_proctoring,
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
  left join deduped_results mr on mr.test_id = vt.test_id
  left join my_hardware hw on hw.test_id = vt.test_id
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
security invoker
as $$
declare
  v_auth_user_id uuid;
  v_student_id text;
  v_branch text;
  v_course text;
  v_semester text;
begin
  select ctx.auth_user_id, ctx.student_id, ctx.branch, ctx.course, ctx.semester
  into v_auth_user_id, v_student_id, v_branch, v_course, v_semester
  from mocks.current_student_context() ctx
  limit 1;

  if v_auth_user_id is null and v_student_id is null then
    return;
  end if;

  return query
  with my_results as (
    select r.test_id, r.result_id, r.submitted_at, r.score, r.max_marks, r.percentage, r.correct, r.wrong, r.unattempted, r.updated_at
    from mocks.mock_results r
    where v_auth_user_id is not null
      and r.auth_user_id = v_auth_user_id

    union all

    select r.test_id, r.result_id, r.submitted_at, r.score, r.max_marks, r.percentage, r.correct, r.wrong, r.unattempted, r.updated_at
    from mocks.mock_results r
    where v_student_id is not null
      and r.student_id = v_student_id
  ),
  deduped_results as (
    select distinct on (mr.test_id) mr.*
    from my_results mr
    order by mr.test_id, mr.updated_at desc nulls last, mr.result_id desc
  ),
  visible_tests as (
    select mt.*
    from mocks.mock_tests mt
    where mt.status = 'POSTED'
      and mt.results_published = true
      and (lower(coalesce(mt.branch, 'ALL')) = 'all' or lower(mt.branch) = lower(coalesce(v_branch, 'ALL')))
      and (mocks.normalize_course(mt.course) = 'ALL' or mocks.normalize_course(mt.course) = mocks.normalize_course(v_course))
      and (lower(coalesce(mt.semester, 'ALL')) = 'all' or lower(mt.semester) = lower(coalesce(v_semester, 'ALL')))
  ),
  question_marks as (
    select
      vt.test_id,
      round(coalesce(sum(case
        when q.subject_type = 'APTITUDE' or q.subject ilike '%aptitude%'
          then vt.marking_aptitude_per_q
        else vt.marking_english_per_q
      end), 0))::integer as max_marks
    from visible_tests vt
    left join mocks.mock_test_questions q
      on q.test_id = vt.test_id
    group by vt.test_id
  )
  select
    coalesce(mr.result_id, ('-1' || lpad(abs(hashtext(vt.test_id)::bigint)::text, 10, '0'))::bigint) as result_id,
    vt.test_id,
    vt.title,
    vt.start_at,
    mr.submitted_at,
    coalesce(mr.score, 0::numeric) as score,
    coalesce(mr.max_marks, nullif(qm.max_marks, 0), round(vt.total_questions * greatest(vt.marking_aptitude_per_q, vt.marking_english_per_q))::integer) as max_marks,
    coalesce(mr.percentage, 0::numeric) as percentage,
    coalesce(mr.correct, 0) as correct,
    coalesce(mr.wrong, 0) as wrong,
    coalesce(mr.unattempted, vt.total_questions) as unattempted,
    coalesce(vt.test_type, case when coalesce(vt.requires_web_proctoring, false) then 'MET' else 'QET' end) as test_type
  from visible_tests vt
  left join deduped_results mr on mr.test_id = vt.test_id
  left join question_marks qm on qm.test_id = vt.test_id
  where (
    p_before_submitted_at is null
    or coalesce(mr.submitted_at, vt.start_at) < p_before_submitted_at
    or (
      coalesce(mr.submitted_at, vt.start_at) = p_before_submitted_at
      and p_before_result_id is not null
      and coalesce(mr.result_id, ('-1' || lpad(abs(hashtext(vt.test_id)::bigint)::text, 10, '0'))::bigint) < p_before_result_id
    )
  )
  order by coalesce(mr.submitted_at, vt.start_at) desc,
           coalesce(mr.result_id, ('-1' || lpad(abs(hashtext(vt.test_id)::bigint)::text, 10, '0'))::bigint) desc
  limit greatest(1, least(coalesce(p_limit, 25), 100));
end;
$$;

grant execute on function mocks.api_student_results_feed(integer, timestamptz, bigint) to authenticated;

-- -------------------------------------------------------------------------
-- 6. Admin publish RPC in the same schema used by the web client
-- -------------------------------------------------------------------------
create or replace function mocks.api_admin_publish_results(
  p_test_id text,
  p_branch text default null,
  p_course text default null,
  p_semester text default null
)
returns integer
language plpgsql
security invoker
as $$
declare
  v_count integer := 0;
begin
  if not mocks.is_admin() then
    raise exception 'forbidden: admin role required';
  end if;

  update mocks.mock_results r
  set published = true,
      results_published = true,
      published_at = now()
  where r.test_id = p_test_id
    and coalesce(r.locked, false)
    and (p_branch is null or p_branch = '' or lower(r.branch) = lower(p_branch))
    and (p_course is null or p_course = '' or mocks.normalize_course(r.course) = mocks.normalize_course(p_course))
    and (p_semester is null or p_semester = '' or lower(r.semester) = lower(p_semester))
    and (
      coalesce(r.published, false) = false
      or coalesce(r.results_published, false) = false
    );

  get diagnostics v_count = row_count;

  update mocks.mock_tests t
  set results_published = true,
      updated_at = now()
  where t.test_id = p_test_id;

  return v_count;
end;
$$;

grant execute on function mocks.api_admin_publish_results(text, text, text, text) to authenticated;

-- -------------------------------------------------------------------------
-- 7. Admin readiness summary view used by /admin/mock-tests/manage
-- -------------------------------------------------------------------------
drop view if exists ops.v_mock_readiness_summary;

create view ops.v_mock_readiness_summary
with (security_invoker = true)
as
select
  h.test_id,
  count(*)::integer as total_verified_students,
  count(*) filter (where h.camera_ok and h.mic_ok and h.verified_at is not null)::integer as fully_ready_students,
  count(*) filter (where not (h.camera_ok and h.mic_ok and h.verified_at is not null))::integer as students_with_issues
from mocks.mock_hardware_checks h
group by h.test_id;

grant usage on schema ops to authenticated;
grant select on ops.v_mock_readiness_summary to authenticated;

commit;

notify pgrst, 'reload schema';

select
  true as mock_contract_repair_installed,
  to_regclass('mocks.mock_hardware_checks') is not null as has_hardware_table,
  exists (
    select 1 from information_schema.columns
    where table_schema = 'mocks'
      and table_name = 'mock_tests'
      and column_name = 'requires_web_proctoring'
  ) as has_proctoring_column,
  exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'mocks'
      and p.proname = 'api_student_mark_mock_hardware_ready'
  ) as has_hardware_rpc,
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
  ) as has_results_feed_rpc,
  exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'mocks'
      and p.proname = 'api_admin_publish_results'
  ) as has_admin_publish_rpc;
