-- Phase 2 foundation: auth identity mapping
-- Purpose:
-- 1) Keep student_id and employee_id as domain source-of-truth.
-- 2) Map one Supabase auth user to exactly one domain identity.
-- 3) Enforce "admin is also employee".
-- Safe: additive only (new table + trigger), no data deletion.

begin;

create table if not exists app_user_identity (
  app_identity_id bigint generated always as identity primary key,
  auth_user_id uuid not null unique references auth.users(id) on update restrict on delete cascade,
  account_type text not null check (account_type in ('STUDENT', 'EMPLOYEE', 'ADMIN')),
  student_id text unique references student_core(stu_student_id) on update restrict on delete cascade,
  employee_id text unique references employee_core(emp_employee_id) on update restrict on delete cascade,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (
      account_type = 'STUDENT'
      and student_id is not null
      and employee_id is null
    )
    or
    (
      account_type in ('EMPLOYEE', 'ADMIN')
      and employee_id is not null
      and student_id is null
    )
  )
);

create index if not exists idx_app_identity_account_type
  on app_user_identity(account_type);

create index if not exists idx_app_identity_active
  on app_user_identity(is_active);

create or replace function app_user_identity_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_app_identity_touch') then
    create trigger trg_app_identity_touch
      before update on app_user_identity
      for each row execute function app_user_identity_touch_updated_at();
  end if;
end $$;

alter table app_user_identity enable row level security;

commit;
