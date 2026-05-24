-- Mock Schema Chunk 02
-- Run second

begin;

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

commit;
