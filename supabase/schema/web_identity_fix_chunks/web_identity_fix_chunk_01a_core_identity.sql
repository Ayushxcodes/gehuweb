-- Web Identity Fix / Chunk 01A
-- Creates/repairs domain rows and app_user_identity for test accounts.

with desired(email, account_type, student_id, employee_id, full_name) as (
  values
    ('admin@test.gehu', 'ADMIN', null::text, 'EMP000001', 'Admin User'),
    ('student@test.gehu', 'STUDENT', 'STU000001', null::text, 'Student One'),
    ('test1@gehu.ac.in', 'STUDENT', 'STU000002', null::text, 'Student Two'),
    ('test2@gehu.ac.in', 'STUDENT', 'STU000003', null::text, 'Student Three')
),
matched as (
  select u.id as auth_user_id, d.*
  from desired d
  join auth.users u on lower(u.email) = lower(d.email)
),
upsert_students as (
  insert into public.student_core (
    stu_student_id, stu_auth_user_uuid, stu_full_name, stu_dob,
    stu_gender_code, stu_category_code, stu_account_state
  )
  select student_id, auth_user_id, full_name, date '2003-01-01',
         'UNDISCLOSED', 'GEN', 'ACTIVE'
  from matched
  where account_type = 'STUDENT'
  on conflict (stu_student_id) do update set
    stu_auth_user_uuid = excluded.stu_auth_user_uuid,
    stu_full_name = excluded.stu_full_name,
    stu_category_code = coalesce(student_core.stu_category_code, excluded.stu_category_code),
    stu_account_state = 'ACTIVE'
),
upsert_admin_employee as (
  insert into public.employee_core (
    emp_employee_id, emp_auth_user_uuid, emp_full_name,
    emp_dob, emp_gender_code, emp_account_state
  )
  select employee_id, auth_user_id, full_name,
         date '1990-01-01', 'UNDISCLOSED', 'ACTIVE'
  from matched
  where account_type = 'ADMIN'
  on conflict (emp_employee_id) do update set
    emp_auth_user_uuid = excluded.emp_auth_user_uuid,
    emp_full_name = excluded.emp_full_name,
    emp_account_state = 'ACTIVE'
),
repair_existing_identity as (
  update public.app_user_identity ai
  set auth_user_id = m.auth_user_id,
      account_type = m.account_type,
      is_active = true,
      updated_at = now()
  from matched m
  where (m.student_id is not null and ai.student_id = m.student_id)
     or (m.employee_id is not null and ai.employee_id = m.employee_id)
  returning ai.auth_user_id
)
insert into public.app_user_identity (
  auth_user_id, account_type, student_id, employee_id, is_active
)
select auth_user_id, account_type, student_id, employee_id, true
from matched
on conflict (auth_user_id) do update set
  account_type = excluded.account_type,
  student_id = excluded.student_id,
  employee_id = excluded.employee_id,
  is_active = true;

