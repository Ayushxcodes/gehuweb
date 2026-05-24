-- Phase F1 / Chunk 03
-- Feedback submission tracker and anonymous response storage.

begin;

create table if not exists public.feedback_submissions (
  cycle_id text not null,
  entry_id text not null,
  uid text not null,
  auth_user_id uuid not null references auth.users(id) on update restrict on delete cascade,
  submitted boolean not null default true,
  submitted_at timestamptz not null default now(),
  primary key (cycle_id, entry_id, uid),
  foreign key (cycle_id, entry_id)
    references public.feedback_cycle_entries(cycle_id, entry_id) on delete cascade
);

create index if not exists idx_feedback_submissions_uid_cycle
  on public.feedback_submissions(uid, cycle_id);

create table if not exists public.feedback_responses (
  response_id uuid primary key default gen_random_uuid(),
  cycle_id text not null,
  entry_id text not null,
  teacher_id text not null default '',
  subject_type text not null default 'THEORY' check (subject_type in ('THEORY', 'PRACTICAL')),
  rating_scale integer not null default 5 check (rating_scale in (5, 10)),
  prompt_count integer not null default 0 check (prompt_count >= 0 and prompt_count <= 60),
  optional_comment text not null default '' check (char_length(optional_comment) <= 500),
  answers_jsonb jsonb not null default '[]'::jsonb,
  submitted_at timestamptz not null default now(),
  foreign key (cycle_id, entry_id)
    references public.feedback_cycle_entries(cycle_id, entry_id) on delete cascade,
  check (jsonb_typeof(answers_jsonb) = 'array')
);

create index if not exists idx_feedback_responses_cycle_entry
  on public.feedback_responses(cycle_id, entry_id);
create index if not exists idx_feedback_responses_submitted
  on public.feedback_responses(submitted_at desc);

commit;
