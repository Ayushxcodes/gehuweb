-- Phase 2 fallback: policies only (no grant/revoke block)
-- Use this if full static script did not apply.

begin;

drop policy if exists p_probe_student_core_select on student_core;

drop policy if exists p_app_identity_sel_own on app_user_identity;
create policy p_app_identity_sel_own
on app_user_identity
for select
to authenticated
using (
  (select auth.uid()) is not null
  and auth_user_id = (select auth.uid())
  and is_active = true
);

drop policy if exists p_stu_campus_sel_auth on stu_campus_master;
create policy p_stu_campus_sel_auth on stu_campus_master for select to authenticated using (true);
drop policy if exists p_stu_course_sel_auth on stu_course_master;
create policy p_stu_course_sel_auth on stu_course_master for select to authenticated using (true);
drop policy if exists p_stu_branch_sel_auth on stu_branch_master;
create policy p_stu_branch_sel_auth on stu_branch_master for select to authenticated using (true);
drop policy if exists p_stu_section_sel_auth on stu_section_master;
create policy p_stu_section_sel_auth on stu_section_master for select to authenticated using (true);
drop policy if exists p_stu_specialization_sel_auth on stu_specialization_master;
create policy p_stu_specialization_sel_auth on stu_specialization_master for select to authenticated using (true);

drop policy if exists p_emp_campus_sel_auth on emp_campus_master;
create policy p_emp_campus_sel_auth on emp_campus_master for select to authenticated using (true);
drop policy if exists p_emp_department_sel_auth on emp_department_master;
create policy p_emp_department_sel_auth on emp_department_master for select to authenticated using (true);
drop policy if exists p_emp_designation_sel_auth on emp_designation_master;
create policy p_emp_designation_sel_auth on emp_designation_master for select to authenticated using (true);
drop policy if exists p_emp_role_sel_auth on emp_role_master;
create policy p_emp_role_sel_auth on emp_role_master for select to authenticated using (true);

drop policy if exists p_student_core_sel_scope on student_core;
create policy p_student_core_sel_scope
on student_core
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_student_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_contact_sel_scope on student_contact;
create policy p_student_contact_sel_scope
on student_contact
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_contact_student_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_parent_sel_scope on student_parent;
create policy p_student_parent_sel_scope
on student_parent
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_parent_student_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_address_sel_scope on student_address;
create policy p_student_address_sel_scope
on student_address
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_address_student_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_enrollment_current_sel_scope on student_enrollment_current;
create policy p_student_enrollment_current_sel_scope
on student_enrollment_current
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_enroll_student_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_academic_record_sel_scope on student_academic_record;
create policy p_student_academic_record_sel_scope
on student_academic_record
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_academic_student_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_status_log_sel_scope on student_status_log;
create policy p_student_status_log_sel_scope
on student_status_log
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_status_student_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_attendance_daily_sel_scope on student_attendance_daily;
create policy p_student_attendance_daily_sel_scope
on student_attendance_daily
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_attendance_student_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_core_sel_scope on employee_core;
create policy p_employee_core_sel_scope
on employee_core
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_contact_sel_scope on employee_contact;
create policy p_employee_contact_sel_scope
on employee_contact
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_contact_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_family_sel_scope on employee_family;
create policy p_employee_family_sel_scope
on employee_family
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_family_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_address_sel_scope on employee_address;
create policy p_employee_address_sel_scope
on employee_address
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_address_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_job_current_sel_scope on employee_job_current;
create policy p_employee_job_current_sel_scope
on employee_job_current
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_job_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_qualification_record_sel_scope on employee_qualification_record;
create policy p_employee_qualification_record_sel_scope
on employee_qualification_record
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_qualification_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_leave_balance_sel_scope on employee_leave_balance;
create policy p_employee_leave_balance_sel_scope
on employee_leave_balance
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_leave_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_status_log_sel_scope on employee_status_log;
create policy p_employee_status_log_sel_scope
on employee_status_log
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_status_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_attendance_daily_sel_scope on employee_attendance_daily;
create policy p_employee_attendance_daily_sel_scope
on employee_attendance_daily
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_attendance_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

commit;
