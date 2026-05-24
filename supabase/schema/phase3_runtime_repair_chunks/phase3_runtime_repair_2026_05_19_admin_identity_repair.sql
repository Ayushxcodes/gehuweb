-- Phase 3 runtime repair / Admin identity repair / 2026-05-19
-- Purpose: make admin@test.gehu resolve as ADMIN for RLS helpers used by notices and appeals.
-- Safe scope: only touches the pilot admin account and EMP000001 domain row.

begin;

with target_admin as (
  select id as auth_user_id, lower(email) as email_key, email
  from auth.users
  where lower(email) = 'admin@test.gehu'
  limit 1
), upsert_employee as (
  insert into public.employee_core (
    emp_employee_id,
    emp_auth_user_uuid,
    emp_full_name,
    emp_dob,
    emp_gender_code,
    emp_account_state
  )
  select
    'EMP000001',
    auth_user_id,
    'Admin User',
    date '1990-01-01',
    'UNDISCLOSED',
    'ACTIVE'
  from target_admin
  on conflict (emp_employee_id) do update set
    emp_auth_user_uuid = excluded.emp_auth_user_uuid,
    emp_full_name = excluded.emp_full_name,
    emp_account_state = 'ACTIVE'
  returning emp_employee_id
), repair_existing_identity_for_employee as (
  update public.app_user_identity ai
  set auth_user_id = ta.auth_user_id,
      account_type = 'ADMIN',
      student_id = null,
      employee_id = 'EMP000001',
      is_active = true,
      updated_at = now()
  from target_admin ta
  where ai.employee_id = 'EMP000001'
  returning ai.auth_user_id
)
insert into public.app_user_identity (
  auth_user_id,
  account_type,
  student_id,
  employee_id,
  is_active
)
select
  auth_user_id,
  'ADMIN',
  null::text,
  'EMP000001',
  true
from target_admin
on conflict (auth_user_id) do update set
  account_type = 'ADMIN',
  student_id = null,
  employee_id = 'EMP000001',
  is_active = true;

with target_admin as (
  select id as auth_user_id, email
  from auth.users
  where lower(email) = 'admin@test.gehu'
  limit 1
)
insert into public.app_profile_state (
  uid,
  auth_user_id,
  student_id,
  employee_id,
  account_role,
  name,
  official_email,
  official_email_key,
  profile_completed,
  verification_status,
  verified
)
select
  auth_user_id::text,
  auth_user_id,
  null::text,
  'EMP000001',
  'ADMIN',
  'Admin User',
  email,
  lower(trim(email)),
  true,
  'VERIFIED',
  true
from target_admin
on conflict (uid) do update set
  auth_user_id = excluded.auth_user_id,
  student_id = excluded.student_id,
  employee_id = excluded.employee_id,
  account_role = excluded.account_role,
  name = excluded.name,
  official_email = excluded.official_email,
  official_email_key = excluded.official_email_key,
  profile_completed = excluded.profile_completed,
  verification_status = excluded.verification_status,
  verified = excluded.verified;

commit;

-- Post-repair data check. This does not simulate an app JWT yet.
select
  au.id as auth_user_id,
  au.email,
  ai.account_type,
  ai.employee_id,
  ai.student_id,
  ai.is_active,
  ps.uid as profile_uid,
  ps.profile_completed,
  ps.verification_status,
  ps.verified
from auth.users au
left join public.app_user_identity ai on ai.auth_user_id = au.id
left join public.app_profile_state ps on ps.auth_user_id = au.id
where lower(au.email) = 'admin@test.gehu';