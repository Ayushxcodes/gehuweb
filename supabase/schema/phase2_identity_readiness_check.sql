-- Phase 2 readiness check (read-only)
-- Purpose: verify data presence before identity mapping inserts.

select
  (select count(*) from auth.users) as auth_users_rows,
  (select count(*) from public.student_core) as student_core_rows,
  (select count(*) from public.student_contact) as student_contact_rows,
  (select count(*) from public.employee_core) as employee_core_rows,
  (select count(*) from public.employee_contact) as employee_contact_rows,
  (select count(*) from public.app_user_identity) as identity_rows;

-- Student official emails available for matching
select stu_contact_student_id as student_id, stu_official_email as official_email
from public.student_contact
where stu_official_email is not null and trim(stu_official_email) <> ''
order by stu_contact_student_id
limit 20;

-- Employee official emails available for matching
select emp_contact_employee_id as employee_id, emp_official_email as official_email
from public.employee_contact
where emp_official_email is not null and trim(emp_official_email) <> ''
order by emp_contact_employee_id
limit 20;
