-- Phase 2: Preview identity matches (read-only)
-- Purpose: show which auth users match student/employee records by official email.
-- No data is inserted/updated in this script.

-- 1) Auth users that match student official email
select
  au.id as auth_user_id,
  au.email as auth_email,
  sc.stu_contact_student_id as student_id
from auth.users au
join public.student_contact sc
  on lower(au.email) = lower(sc.stu_official_email)
order by au.created_at desc;

-- 2) Auth users that match employee official email
select
  au.id as auth_user_id,
  au.email as auth_email,
  ec.emp_contact_employee_id as employee_id
from auth.users au
join public.employee_contact ec
  on lower(au.email) = lower(ec.emp_official_email)
order by au.created_at desc;

-- 3) Summary counts
select
  (select count(*) from auth.users) as auth_users_total,
  (select count(*)
   from auth.users au
   join public.student_contact sc
     on lower(au.email) = lower(sc.stu_official_email)
  ) as student_email_matches,
  (select count(*)
   from auth.users au
   join public.employee_contact ec
     on lower(au.email) = lower(ec.emp_official_email)
  ) as employee_email_matches,
  (select count(*) from public.app_user_identity) as existing_identity_rows;
