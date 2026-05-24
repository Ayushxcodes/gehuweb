-- Phase M1: Mock domain schema foundation
-- Purpose:
-- 1) Preserve current Firebase mock-test behavior in relational form.
-- 2) Keep room for legacy compatibility during transition.
-- 3) Add integrity checks for answer/options consistency.
--
-- This script is additive and safe to run multiple times.

begin;

create schema if not exists mocks;

create or replace function mocks.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- =========================================================
-- 1) MOCK TEST HEADER
-- =========================================================
create table if not exists mocks.mock_tests (
  test_id text primary key,
  title text not null,

  branch text not null default 'ALL',
  course text not null default 'ALL',
  semester text not null default 'ALL',

  total_questions integer not null default 0 check (total_questions >= 0),
  duration_minutes integer not null default 60 check (duration_minutes > 0),

  start_at timestamptz not null,
  scheduled_start_at timestamptz,
  exam_end_at timestamptz,
  expires_at timestamptz,

  status text not null default 'DRAFT'
    check (status in ('DRAFT', 'POSTED', 'ARCHIVED')),
  source text
    check (source in ('manual', 'csv')),

  marking_aptitude_per_q numeric(10,2) not null default 1,
  marking_english_per_q numeric(10,2) not null default 2,
  negative_enabled boolean not null default false,
  negative_value numeric(10,2) not null default 0,
  negative_apply_to text[] not null default '{}'::text[],

  frozen_ids jsonb not null default '[]'::jsonb,

  published boolean not null default false,
  results_published boolean not null default false,

  created_by_auth_user_id uuid references auth.users(id) on update restrict on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  check (marking_aptitude_per_q >= 0),
  check (marking_english_per_q >= 0),
  check (negative_value >= 0),
  check (
    not jsonb_path_exists(
      frozen_ids,
      '$[*] ? (@.type() != "string" || @ == "")'
    )
  )
);

create or replace trigger trg_mock_tests_touch_updated_at
before update on mocks.mock_tests
for each row execute function mocks.touch_updated_at();

create index if not exists idx_mock_tests_status_start
  on mocks.mock_tests(status, start_at);

create index if not exists idx_mock_tests_segment_status_start
  on mocks.mock_tests(branch, course, semester, status, start_at);

create index if not exists idx_mock_tests_results_published
  on mocks.mock_tests(results_published);

-- =========================================================
-- 2) SNAPSHOT QUESTIONS PER TEST
-- =========================================================
create table if not exists mocks.mock_test_questions (
  test_id text not null references mocks.mock_tests(test_id) on update restrict on delete cascade,
  qid text not null,
  q_index integer check (q_index is null or q_index >= 0),

  subject text not null,
  subject_type text
    check (subject_type is null or subject_type in ('APTITUDE', 'ENGLISH')),

  question text not null,
  option_a text not null,
  option_b text not null,
  option_c text not null,
  option_d text not null,
  answer_letter text not null check (answer_letter in ('A', 'B', 'C', 'D')),

  solution_mode text,
  solution text,
  difficulty text,
  active boolean not null default true,
  source text,

  uploaded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  primary key (test_id, qid),
  check (length(trim(question)) > 0)
);

create or replace trigger trg_mock_test_questions_touch_updated_at
before update on mocks.mock_test_questions
for each row execute function mocks.touch_updated_at();

create index if not exists idx_mock_test_questions_test_subject
  on mocks.mock_test_questions(test_id, subject);

create index if not exists idx_mock_test_questions_test_qindex
  on mocks.mock_test_questions(test_id, q_index);

-- =========================================================
-- 3) MOCK RESULTS (CURRENT SSOT EQUIVALENT)
-- =========================================================
create table if not exists mocks.mock_results (
  result_id bigint generated always as identity primary key,

  test_id text not null references mocks.mock_tests(test_id) on update restrict on delete cascade,
  student_id text references student_core(stu_student_id) on update restrict on delete set null,
  auth_user_id uuid references auth.users(id) on update restrict on delete set null,
  firebase_uid text,

  q_order text[] not null default '{}'::text[],
  opt_map jsonb not null default '{}'::jsonb,

  warn_count integer not null default 0 check (warn_count >= 0),
  locked boolean not null default false,
  started_at timestamptz,
  session_end_time timestamptz,
  submitted_at timestamptz,

  total_questions integer not null default 0 check (total_questions >= 0),
  answered_count integer not null default 0 check (answered_count >= 0),

  score numeric(10,2) not null default 0,
  correct integer not null default 0 check (correct >= 0),
  wrong integer not null default 0 check (wrong >= 0),
  unattempted integer not null default 0 check (unattempted >= 0),
  max_marks integer not null default 0 check (max_marks >= 0),
  percentage numeric(6,2) not null default 0 check (percentage >= 0 and percentage <= 100),

  published boolean not null default false,
  published_at timestamptz,
  results_published boolean not null default false,

  branch text not null default 'ALL',
  course text not null default 'ALL',
  semester text not null default 'ALL',

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  check (
    student_id is not null
    or auth_user_id is not null
    or firebase_uid is not null
  ),
  check (
    total_questions = 0
    or answered_count <= total_questions
  ),
  check (
    not jsonb_path_exists(
      opt_map,
      '$.* ? (@ != "A" && @ != "B" && @ != "C" && @ != "D")'
    )
  )
);

create unique index if not exists uq_mock_results_test_student
  on mocks.mock_results(test_id, student_id)
  where student_id is not null;

create unique index if not exists uq_mock_results_test_auth
  on mocks.mock_results(test_id, auth_user_id)
  where auth_user_id is not null;

create unique index if not exists uq_mock_results_test_firebase
  on mocks.mock_results(test_id, firebase_uid)
  where firebase_uid is not null;

create or replace trigger trg_mock_results_touch_updated_at
before update on mocks.mock_results
for each row execute function mocks.touch_updated_at();

create index if not exists idx_mock_results_test_publish
  on mocks.mock_results(test_id, published, results_published);

create index if not exists idx_mock_results_auth_user
  on mocks.mock_results(auth_user_id);

create index if not exists idx_mock_results_student
  on mocks.mock_results(student_id);

create index if not exists idx_mock_results_locked
  on mocks.mock_results(test_id, locked);

create index if not exists idx_mock_results_opt_map_gin
  on mocks.mock_results using gin (opt_map jsonb_path_ops);

-- =========================================================
-- 4) LEGACY SESSION MIRROR (OPTIONAL BRIDGE)
-- =========================================================
create table if not exists mocks.mock_sessions_legacy (
  session_id text primary key, -- expected format: {testId}_{uid}
  test_id text not null references mocks.mock_tests(test_id) on update restrict on delete cascade,
  auth_user_id uuid references auth.users(id) on update restrict on delete set null,
  firebase_uid text,

  q_order text[] not null default '{}'::text[],
  answers jsonb not null default '{}'::jsonb,
  warn_count integer not null default 0 check (warn_count >= 0),
  locked boolean not null default false,
  started_at timestamptz,
  session_end_time timestamptz,
  submitted_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    auth_user_id is not null
    or firebase_uid is not null
  )
);

create or replace trigger trg_mock_sessions_legacy_touch_updated_at
before update on mocks.mock_sessions_legacy
for each row execute function mocks.touch_updated_at();

create index if not exists idx_mock_sessions_legacy_test
  on mocks.mock_sessions_legacy(test_id);

-- =========================================================
-- 5) LEGACY RESULT MIRROR (OPTIONAL BRIDGE)
-- =========================================================
create table if not exists mocks.mock_results_legacy (
  test_id text not null references mocks.mock_tests(test_id) on update restrict on delete cascade,
  firebase_uid text not null,

  student_name text,
  email text,
  branch text,
  course text,
  counts jsonb not null default '{}'::jsonb,
  marks jsonb not null default '{}'::jsonb,
  percentage numeric(6,2),
  performance text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  primary key (test_id, firebase_uid)
);

create or replace trigger trg_mock_results_legacy_touch_updated_at
before update on mocks.mock_results_legacy
for each row execute function mocks.touch_updated_at();

commit;

