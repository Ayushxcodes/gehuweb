-- Phase F1 / Chunk 02
-- Feedback cycles and immutable published entry snapshots.

begin;

create table if not exists public.feedback_cycles (
  cycle_id text primary key,
  cycle_name text not null default '',
  header_label text not null default '',
  course text not null default 'ALL',
  course_key text not null default 'all',
  branch text not null default 'ALL',
  branch_key text not null default 'all',
  semester text not null default 'ALL',
  semester_key text not null default 'all',
  target_key text not null default 'all_students',
  audience_type text not null default 'STUDENT',
  status text not null default 'DRAFT' check (status in ('DRAFT', 'PUBLISHED', 'CLOSED')),
  active boolean not null default true,
  entry_count integer not null default 0 check (entry_count >= 0),
  created_by_auth_user_id uuid references auth.users(id) on update restrict on delete set null,
  published_at timestamptz,
  expires_at timestamptz,
  payload_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_feedback_cycles_status_active
  on public.feedback_cycles(status, active, published_at desc);
create index if not exists idx_feedback_cycles_target
  on public.feedback_cycles(target_key, published_at desc);

drop trigger if exists trg_feedback_cycles_touch on public.feedback_cycles;
create trigger trg_feedback_cycles_touch
before update on public.feedback_cycles
for each row execute function public.app_touch_updated_at();

create table if not exists public.feedback_cycle_entries (
  cycle_id text not null references public.feedback_cycles(cycle_id) on delete cascade,
  entry_id text not null,
  position integer not null default 0,
  teacher_id text not null default '',
  teacher_name text not null default '',
  teacher_subject text not null default '',
  teacher_photo_url text not null default '',
  subject_type text not null default 'THEORY' check (subject_type in ('THEORY', 'PRACTICAL')),
  template_id text not null default '',
  template_name text not null default '',
  rating_scale integer not null default 5 check (rating_scale in (5, 10)),
  created_at timestamptz not null default now(),
  primary key (cycle_id, entry_id)
);

create index if not exists idx_feedback_cycle_entries_order
  on public.feedback_cycle_entries(cycle_id, position);

create table if not exists public.feedback_cycle_entry_questions (
  cycle_id text not null,
  entry_id text not null,
  question_id text not null,
  position integer not null default 0,
  question_text text not null default '',
  rating_scale integer not null default 5 check (rating_scale in (5, 10)),
  created_at timestamptz not null default now(),
  primary key (cycle_id, entry_id, question_id),
  foreign key (cycle_id, entry_id)
    references public.feedback_cycle_entries(cycle_id, entry_id) on delete cascade
);

create index if not exists idx_feedback_cycle_entry_questions_order
  on public.feedback_cycle_entry_questions(cycle_id, entry_id, position);

commit;
