-- Phase F1 / Chunk 01
-- Feedback setup templates, questions, and teacher records.

begin;

create extension if not exists pgcrypto;

create table if not exists public.feedback_templates (
  template_id text primary key,
  template_name text not null default '',
  department_name text not null default '',
  department_key text not null default '',
  branch text not null default 'ALL',
  branch_key text not null default 'all',
  status text not null default 'DRAFT' check (status in ('DRAFT', 'ACTIVE')),
  rating_scale integer not null default 5 check (rating_scale in (5, 10)),
  created_by_auth_user_id uuid references auth.users(id) on update restrict on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_feedback_templates_status_updated
  on public.feedback_templates(status, updated_at desc);

drop trigger if exists trg_feedback_templates_touch on public.feedback_templates;
create trigger trg_feedback_templates_touch
before update on public.feedback_templates
for each row execute function public.app_touch_updated_at();

create table if not exists public.feedback_template_questions (
  template_id text not null references public.feedback_templates(template_id) on delete cascade,
  question_id text not null,
  position integer not null default 0,
  question_text text not null default '',
  rating_scale integer not null default 5 check (rating_scale in (5, 10)),
  created_at timestamptz not null default now(),
  primary key (template_id, question_id)
);

create index if not exists idx_feedback_template_questions_order
  on public.feedback_template_questions(template_id, position);

create table if not exists public.feedback_teachers (
  teacher_id text primary key,
  name text not null default '',
  name_key text not null default '',
  subject text not null default '',
  subject_key text not null default '',
  photo_url text not null default '',
  photo_path text not null default '',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_feedback_teachers_active_name
  on public.feedback_teachers(active, name_key);

drop trigger if exists trg_feedback_teachers_touch on public.feedback_teachers;
create trigger trg_feedback_teachers_touch
before update on public.feedback_teachers
for each row execute function public.app_touch_updated_at();

commit;
