-- Phase 4 Login Step 01
-- Read-only readiness snapshot for current pilot users.

-- A) High-level coverage
select
  (select count(*) from auth.users) as auth_users_total,
  (select count(*) from public.app_user_identity where is_active = true) as identity_active_rows,
  (select count(*) from public.app_user_identity where is_active = true and account_type = 'ADMIN') as admin_identity_rows,
  (select count(*) from public.app_user_identity where is_active = true and account_type = 'STUDENT') as student_identity_rows,
  (select count(*) from public.app_profile_state where auth_user_id is not null) as profile_linked_rows;

-- B) Pilot mapping diagnostics (student/admin + profile/table presence)
with mapped as (
  select
    ai.auth_user_id,
    au.email,
    ai.account_type,
    ai.student_id,
    ai.employee_id
  from public.app_user_identity ai
  join auth.users au on au.id = ai.auth_user_id
  where ai.is_active = true
)
select
  m.account_type,
  m.email,
  m.student_id,
  m.employee_id,
  (p.uid is not null) as has_app_profile_state,
  (sc.stu_student_id is not null) as has_student_core,
  (sct.stu_contact_student_id is not null) as has_student_contact,
  (se.stu_enroll_student_id is not null) as has_student_enrollment
from mapped m
left join public.app_profile_state p on p.student_id = m.student_id
left join public.student_core sc on sc.stu_student_id = m.student_id
left join public.student_contact sct on sct.stu_contact_student_id = m.student_id
left join public.student_enrollment_current se on se.stu_enroll_student_id = m.student_id
order by m.account_type, m.email;

