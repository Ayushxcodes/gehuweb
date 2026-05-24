-- Phase 2: Read-access baseline policies (static version)
-- No dynamic DO blocks. Explicit statements only.
-- Target: mobile + web shared secure read model.

begin;

-- =========================================================
-- Explicit table grants (Data API)
-- =========================================================

revoke all on table app_user_identity from anon, authenticated;
grant select on table app_user_identity to authenticated;

revoke all on table stu_campus_master from anon, authenticated;
grant select on table stu_campus_master to authenticated;
revoke all on table stu_course_master from anon, authenticated;
grant select on table stu_course_master to authenticated;
revoke all on table stu_branch_master from anon, authenticated;
grant select on table stu_branch_master to authenticated;
revoke all on table stu_section_master from anon, authenticated;
grant select on table stu_section_master to authenticated;
revoke all on table stu_specialization_master from anon, authenticated;
grant select on table stu_specialization_master to authenticated;

revoke all on table student_core from anon, authenticated;
grant select on table student_core to authenticated;
revoke all on table student_contact from anon, authenticated;
grant select on table student_contact to authenticated;
revoke all on table student_parent from anon, authenticated;
grant select on table student_parent to authenticated;
revoke all on table student_address from anon, authenticated;
grant select on table student_address to authenticated;
revoke all on table student_enrollment_current from anon, authenticated;
grant select on table student_enrollment_current to authenticated;
revoke all on table student_academic_record from anon, authenticated;
grant select on table student_academic_record to authenticated;
revoke all on table student_status_log from anon, authenticated;
grant select on table student_status_log to authenticated;
revoke all on table student_attendance_daily from anon, authenticated;
grant select on table student_attendance_daily to authenticated;

revoke all on table emp_campus_master from anon, authenticated;
grant select on table emp_campus_master to authenticated;
revoke all on table emp_department_master from anon, authenticated;
grant select on table emp_department_master to authenticated;
revoke all on table emp_designation_master from anon, authenticated;
grant select on table emp_designation_master to authenticated;
revoke all on table emp_role_master from anon, authenticated;
grant select on table emp_role_master to authenticated;

revoke all on table employee_core from anon, authenticated;
grant select on table employee_core to authenticated;
revoke all on table employee_contact from anon, authenticated;
grant select on table employee_contact to authenticated;
revoke all on table employee_family from anon, authenticated;
grant select on table employee_family to authenticated;
revoke all on table employee_address from anon, authenticated;
grant select on table employee_address to authenticated;
revoke all on table employee_job_current from anon, authenticated;
grant select on table employee_job_current to authenticated;
revoke all on table employee_qualification_record from anon, authenticated;
grant select on table employee_qualification_record to authenticated;
revoke all on table employee_leave_balance from anon, authenticated;
grant select on table employee_leave_balance to authenticated;
revoke all on table employee_status_log from anon, authenticated;
grant select on table employee_status_log to authenticated;
revoke all on table employee_attendance_daily from anon, authenticated;
grant select on table employee_attendance_daily to authenticated;

-- =========================================================
-- app_user_identity policy
-- =========================================================

drop policy if exists p_probe_student_core_select on student_core;
drop policy if exists p_app_user_identity_select_own on app_user_identity;
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

-- =========================================================
-- Lookup policies
-- =========================================================

drop policy if exists p_stu_campus_master_select_auth on stu_campus_master;
drop policy if exists p_stu_campus_sel_auth on stu_campus_master;
create policy p_stu_campus_sel_auth on stu_campus_master for select to authenticated using (true);

drop policy if exists p_stu_course_master_select_auth on stu_course_master;
drop policy if exists p_stu_course_sel_auth on stu_course_master;
create policy p_stu_course_sel_auth on stu_course_master for select to authenticated using (true);

drop policy if exists p_stu_branch_master_select_auth on stu_branch_master;
drop policy if exists p_stu_branch_sel_auth on stu_branch_master;
create policy p_stu_branch_sel_auth on stu_branch_master for select to authenticated using (true);

drop policy if exists p_stu_section_master_select_auth on stu_section_master;
drop policy if exists p_stu_section_sel_auth on stu_section_master;
create policy p_stu_section_sel_auth on stu_section_master for select to authenticated using (true);

drop policy if exists p_stu_specialization_master_select_auth on stu_specialization_master;
drop policy if exists p_stu_specialization_sel_auth on stu_specialization_master;
create policy p_stu_specialization_sel_auth on stu_specialization_master for select to authenticated using (true);

drop policy if exists p_emp_campus_master_select_auth on emp_campus_master;
drop policy if exists p_emp_campus_sel_auth on emp_campus_master;
create policy p_emp_campus_sel_auth on emp_campus_master for select to authenticated using (true);

drop policy if exists p_emp_department_master_select_auth on emp_department_master;
drop policy if exists p_emp_department_sel_auth on emp_department_master;
create policy p_emp_department_sel_auth on emp_department_master for select to authenticated using (true);

drop policy if exists p_emp_designation_master_select_auth on emp_designation_master;
drop policy if exists p_emp_designation_sel_auth on emp_designation_master;
create policy p_emp_designation_sel_auth on emp_designation_master for select to authenticated using (true);

drop policy if exists p_emp_role_master_select_auth on emp_role_master;
drop policy if exists p_emp_role_sel_auth on emp_role_master;
create policy p_emp_role_sel_auth on emp_role_master for select to authenticated using (true);

-- =========================================================
-- Student domain policies (self or admin)
-- =========================================================

drop policy if exists p_student_core_select_scope on student_core;
drop policy if exists p_student_core_sel_scope on student_core;
create policy p_student_core_sel_scope
on student_core
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_student_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_contact_select_scope on student_contact;
drop policy if exists p_student_contact_sel_scope on student_contact;
create policy p_student_contact_sel_scope
on student_contact
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_contact_student_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_parent_select_scope on student_parent;
drop policy if exists p_student_parent_sel_scope on student_parent;
create policy p_student_parent_sel_scope
on student_parent
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_parent_student_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_address_select_scope on student_address;
drop policy if exists p_student_address_sel_scope on student_address;
create policy p_student_address_sel_scope
on student_address
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_address_student_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_enrollment_current_select_scope on student_enrollment_current;
drop policy if exists p_student_enrollment_current_sel_scope on student_enrollment_current;
create policy p_student_enrollment_current_sel_scope
on student_enrollment_current
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_enroll_student_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_academic_record_select_scope on student_academic_record;
drop policy if exists p_student_academic_record_sel_scope on student_academic_record;
create policy p_student_academic_record_sel_scope
on student_academic_record
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_academic_student_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_status_log_select_scope on student_status_log;
drop policy if exists p_student_status_log_sel_scope on student_status_log;
create policy p_student_status_log_sel_scope
on student_status_log
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_status_student_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_attendance_daily_select_scope on student_attendance_daily;
drop policy if exists p_student_attendance_daily_sel_scope on student_attendance_daily;
create policy p_student_attendance_daily_sel_scope
on student_attendance_daily
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_attendance_student_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

-- =========================================================
-- Employee domain policies (self or admin)
-- =========================================================

drop policy if exists p_employee_core_select_scope on employee_core;
drop policy if exists p_employee_core_sel_scope on employee_core;
create policy p_employee_core_sel_scope
on employee_core
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_employee_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_contact_select_scope on employee_contact;
drop policy if exists p_employee_contact_sel_scope on employee_contact;
create policy p_employee_contact_sel_scope
on employee_contact
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_contact_employee_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_family_select_scope on employee_family;
drop policy if exists p_employee_family_sel_scope on employee_family;
create policy p_employee_family_sel_scope
on employee_family
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_family_employee_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_address_select_scope on employee_address;
drop policy if exists p_employee_address_sel_scope on employee_address;
create policy p_employee_address_sel_scope
on employee_address
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_address_employee_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_job_current_select_scope on employee_job_current;
drop policy if exists p_employee_job_current_sel_scope on employee_job_current;
create policy p_employee_job_current_sel_scope
on employee_job_current
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_job_employee_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_qualification_record_select_scope on employee_qualification_record;
drop policy if exists p_employee_qualification_record_sel_scope on employee_qualification_record;
create policy p_employee_qualification_record_sel_scope
on employee_qualification_record
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_qualification_employee_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_leave_balance_select_scope on employee_leave_balance;
drop policy if exists p_employee_leave_balance_sel_scope on employee_leave_balance;
create policy p_employee_leave_balance_sel_scope
on employee_leave_balance
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_leave_employee_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_status_log_select_scope on employee_status_log;
drop policy if exists p_employee_status_log_sel_scope on employee_status_log;
create policy p_employee_status_log_sel_scope
on employee_status_log
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_status_employee_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_attendance_daily_select_scope on employee_attendance_daily;
drop policy if exists p_employee_attendance_daily_sel_scope on employee_attendance_daily;
create policy p_employee_attendance_daily_sel_scope
on employee_attendance_daily
for select
to authenticated
using (
  exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_attendance_employee_id
  )
  or exists (
    select 1
    from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

commit;
