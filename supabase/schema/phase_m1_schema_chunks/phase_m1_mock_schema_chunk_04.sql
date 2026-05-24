-- Mock Schema Chunk 04
-- Run fourth

begin;

create table if not exists mocks.mock_sessions_legacy (
  session_id text primary key,
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

commit;
