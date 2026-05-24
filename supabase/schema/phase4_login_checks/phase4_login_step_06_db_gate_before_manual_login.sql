-- Phase 4 Login Step 06
-- DB gate check before manual app login test.
-- This does NOT prove app UI behavior; it only proves DB readiness.

with expected(email, account_type) as (
  values
    ('admin@test.gehu',   'ADMIN'),
    ('student@test.gehu', 'STUDENT'),
    ('test1@gehu.ac.in',  'STUDENT'),
    ('test2@gehu.ac.in',  'STUDENT')
),
rows as (
  select
    e.email,
    e.account_type,
    au.id as auth_user_id,
    ai.is_active as identity_active,
    ai.student_id,
    p.uid as profile_uid,
    p.name,
    p.official_email,
    p.roll_no,
    p.roll_number_legacy,
    p.course,
    p.branch,
    p.semester,
    p.phone,
    p.student_mobile
  from expected e
  left join auth.users au
    on lower(au.email) = lower(e.email)
  left join public.app_user_identity ai
    on ai.auth_user_id = au.id
  left join public.app_profile_state p
    on p.student_id = ai.student_id
)
select
  email,
  account_type,
  (auth_user_id is not null) as has_auth_user,
  (coalesce(identity_active, false)) as has_active_identity,
  case
    when account_type = 'STUDENT' then (profile_uid is not null)
    else true
  end as has_profile_row_if_student,
  case
    when account_type = 'STUDENT' then
      (
        btrim(coalesce(name, '')) <> ''
        and btrim(coalesce(official_email, '')) <> ''
        and (btrim(coalesce(roll_no, '')) <> '' or btrim(coalesce(roll_number_legacy, '')) <> '')
        and btrim(coalesce(course, '')) <> ''
        and btrim(coalesce(branch, '')) <> ''
        and semester is not null
        and (btrim(coalesce(phone, '')) <> '' or btrim(coalesce(student_mobile, '')) <> '')
      )
    else true
  end as student_required_fields_ok,
  case
    when account_type = 'STUDENT'
         and auth_user_id is not null
         and coalesce(identity_active, false)
         and profile_uid is not null
         and btrim(coalesce(name, '')) <> ''
         and btrim(coalesce(official_email, '')) <> ''
         and (btrim(coalesce(roll_no, '')) <> '' or btrim(coalesce(roll_number_legacy, '')) <> '')
         and btrim(coalesce(course, '')) <> ''
         and btrim(coalesce(branch, '')) <> ''
         and semester is not null
         and (btrim(coalesce(phone, '')) <> '' or btrim(coalesce(student_mobile, '')) <> '')
      then 'DB_READY_FOR_MANUAL_LOGIN_TEST'
    when account_type = 'ADMIN'
         and auth_user_id is not null
         and coalesce(identity_active, false)
      then 'DB_READY_FOR_MANUAL_LOGIN_TEST'
    else 'BLOCKED'
  end as db_gate_status
from rows
order by account_type, email;

