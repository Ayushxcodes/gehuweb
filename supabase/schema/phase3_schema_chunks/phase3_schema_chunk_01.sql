-- Phase 3 / Chunk 01
-- Core helper + app_profile_state
-- Run this before other Phase-3 schema chunks.

create or replace function public.app_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create table if not exists public.app_profile_state (
  uid text primary key,
  auth_user_id uuid unique references auth.users(id) on update restrict on delete set null,
  student_id text unique references student_core(stu_student_id) on update restrict on delete set null,
  employee_id text unique references employee_core(emp_employee_id) on update restrict on delete set null,
  account_role text not null default 'STUDENT'
    check (account_role in ('STUDENT', 'ADMIN', 'COORDINATOR', 'EMPLOYEE')),
  name text not null default '',
  official_email text not null default '',
  official_email_key text not null default '',
  personal_email text,
  personal_email_key text not null default '',
  student_id_label text not null default '',
  roll_no text not null default '',
  roll_number_legacy text not null default '',
  university_roll text not null default '',
  enrollment_no text not null default '',
  course text not null default '',
  branch text not null default '',
  semester integer check (semester is null or (semester >= 1 and semester <= 20)),
  dob_text text not null default '',
  gender text not null default '',
  category text not null default '',
  father_name text not null default '',
  father_occupation text not null default '',
  father_mobile text not null default '',
  mother_name text not null default '',
  mother_occupation text not null default '',
  mother_mobile text not null default '',
  student_mobile text not null default '',
  phone text not null default '',
  address_json jsonb not null default '{}'::jsonb,
  academic_record_json jsonb not null default '{}'::jsonb,
  photo_url text not null default '',
  photo_path text not null default '',
  profile_completed boolean not null default false,
  verification_status text not null default 'PENDING'
    check (verification_status in ('PENDING', 'VERIFIED', 'REJECTED', 'LOCKED', 'DRAFT')),
  verified boolean not null default false,
  edit_unlocked_until timestamptz,
  lock_reason text not null default '',
  fcm_token text not null default '',
  source_created_at timestamptz,
  source_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (official_email_key = lower(trim(official_email_key))),
  check (personal_email_key = '' or personal_email_key = lower(trim(personal_email_key)))
);

create index if not exists idx_app_profile_state_student_id
  on public.app_profile_state(student_id);
create index if not exists idx_app_profile_state_email_key
  on public.app_profile_state(official_email_key);
create index if not exists idx_app_profile_state_branch_course_sem
  on public.app_profile_state(branch, course, semester);
create index if not exists idx_app_profile_state_role
  on public.app_profile_state(account_role);

drop trigger if exists trg_app_profile_state_touch on public.app_profile_state;
create trigger trg_app_profile_state_touch
before update on public.app_profile_state
for each row execute function public.app_touch_updated_at();
