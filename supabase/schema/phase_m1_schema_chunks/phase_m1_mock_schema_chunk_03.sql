-- Mock Schema Chunk 03
-- Run third

begin;

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

commit;
