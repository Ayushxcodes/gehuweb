-- Mock Schema Chunk 01
-- Run first

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

commit;
