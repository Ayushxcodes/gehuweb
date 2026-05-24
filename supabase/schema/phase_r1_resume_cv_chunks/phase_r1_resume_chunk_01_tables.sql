-- Phase R1 / Chunk 01
-- Resume/CV tables. Preserves Android CVData as JSONB.

begin;

create extension if not exists pgcrypto;

create table if not exists public.student_resume_profile (
  uid text primary key references public.app_profile_state(uid) on delete cascade,
  auth_user_id uuid references auth.users(id) on delete set null,
  student_id text references public.student_core(stu_student_id) on delete set null,
  default_resume_id text not null default '',
  source_legacy_uid text not null default '',
  source_payload_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.student_resumes (
  uid text not null references public.app_profile_state(uid) on delete cascade,
  resume_id text not null,
  auth_user_id uuid references auth.users(id) on delete set null,
  student_id text references public.student_core(stu_student_id) on delete set null,
  resume_name text not null default 'My Resume',
  template_id text not null default 'classic',
  is_default boolean not null default false,
  last_updated_ms bigint not null default 0,
  domain text not null default 'Tech',
  target_role text not null default '',
  experience_level text not null default 'Fresher',
  strictness_mode text not null default 'Product',
  full_name text not null default '',
  email text not null default '',
  phone text not null default '',
  payload_json jsonb not null default '{}'::jsonb,
  ats_snapshot_json jsonb not null default '{}'::jsonb,
  source_payload_json jsonb not null default '{}'::jsonb,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (uid, resume_id)
);

create index if not exists idx_student_resumes_uid_updated
  on public.student_resumes(uid, deleted_at, last_updated_ms desc);
create index if not exists idx_student_resumes_student
  on public.student_resumes(student_id, deleted_at);
create unique index if not exists uq_student_resumes_one_default
  on public.student_resumes(uid) where is_default = true and deleted_at is null;

drop trigger if exists trg_student_resume_profile_touch on public.student_resume_profile;
create trigger trg_student_resume_profile_touch
before update on public.student_resume_profile
for each row execute function public.app_touch_updated_at();

drop trigger if exists trg_student_resumes_touch on public.student_resumes;
create trigger trg_student_resumes_touch
before update on public.student_resumes
for each row execute function public.app_touch_updated_at();

grant select, insert, update, delete on public.student_resume_profile to authenticated;
grant select, insert, update, delete on public.student_resumes to authenticated;

alter table public.student_resume_profile enable row level security;
alter table public.student_resumes enable row level security;

commit;
