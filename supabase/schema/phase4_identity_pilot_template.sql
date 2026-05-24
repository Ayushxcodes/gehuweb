-- Phase 4 (Pilot): Auth identity mapping
-- Purpose: connect Supabase auth users to your existing app_profile_state/student_core rows.
-- Run after creating users in Supabase Auth dashboard.

-- 1) Preview auth users (copy exact emails)
select id as auth_user_id, email
from auth.users
order by created_at desc
limit 50;

-- 2) Insert identity mappings
-- Replace sample rows with your real pilot users.
with desired(email, account_type, student_id, employee_id) as (
  values
    ('admin@test.gehu',    'ADMIN',   null::text, 'EMP000001'),
    ('student@test.gehu',  'STUDENT', 'STU000001', null::text),
    ('test1@gehu.ac.in',   'STUDENT', 'STU000002', null::text),
    ('test2@gehu.ac.in',   'STUDENT', 'STU000003', null::text)
)
insert into public.app_user_identity (auth_user_id, account_type, student_id, employee_id, is_active)
select
  u.id,
  d.account_type,
  d.student_id,
  d.employee_id,
  true
from desired d
join auth.users u on lower(u.email) = lower(d.email)
on conflict (auth_user_id) do update set
  account_type = excluded.account_type,
  student_id = excluded.student_id,
  employee_id = excluded.employee_id,
  is_active = excluded.is_active;

-- 3) Link app_profile_state.auth_user_id from identity mapping
update public.app_profile_state p
set auth_user_id = ai.auth_user_id
from public.app_user_identity ai
where ai.student_id is not null
  and p.student_id = ai.student_id
  and (p.auth_user_id is distinct from ai.auth_user_id);

-- Optional admin profile link (if admin has employee profile in app_profile_state)
update public.app_profile_state p
set auth_user_id = ai.auth_user_id
from public.app_user_identity ai
where ai.employee_id is not null
  and p.employee_id = ai.employee_id
  and (p.auth_user_id is distinct from ai.auth_user_id);
