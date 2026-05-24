-- Mock Schema Chunk 05
-- Run fifth

begin;

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
