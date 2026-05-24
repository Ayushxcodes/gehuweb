-- Phase 2 read policies (single file, <100 lines, no transaction wrapper)
drop policy if exists p_probe_student_core_select on student_core;

create or replace function public.can_read_student(target_student_id text) returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.app_user_identity ai where ai.auth_user_id = (select auth.uid()) and ai.is_active = true and ai.account_type = 'STUDENT' and ai.student_id = target_student_id)
      or exists (select 1 from public.app_user_identity ai where ai.auth_user_id = (select auth.uid()) and ai.is_active = true and ai.account_type = 'ADMIN' and ai.employee_id is not null);
$$;

create or replace function public.can_read_employee(target_employee_id text) returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.app_user_identity ai where ai.auth_user_id = (select auth.uid()) and ai.is_active = true and ai.account_type in ('EMPLOYEE','ADMIN') and ai.employee_id = target_employee_id)
      or exists (select 1 from public.app_user_identity ai where ai.auth_user_id = (select auth.uid()) and ai.is_active = true and ai.account_type = 'ADMIN' and ai.employee_id is not null);
$$;

drop policy if exists p2_identity_self on app_user_identity; create policy p2_identity_self on app_user_identity for select to authenticated using (auth_user_id = (select auth.uid()) and is_active = true);

drop policy if exists p2_lookup_read on stu_campus_master; create policy p2_lookup_read on stu_campus_master for select to authenticated using (true);
drop policy if exists p2_lookup_read on stu_course_master; create policy p2_lookup_read on stu_course_master for select to authenticated using (true);
drop policy if exists p2_lookup_read on stu_branch_master; create policy p2_lookup_read on stu_branch_master for select to authenticated using (true);
drop policy if exists p2_lookup_read on stu_section_master; create policy p2_lookup_read on stu_section_master for select to authenticated using (true);
drop policy if exists p2_lookup_read on stu_specialization_master; create policy p2_lookup_read on stu_specialization_master for select to authenticated using (true);
drop policy if exists p2_lookup_read on emp_campus_master; create policy p2_lookup_read on emp_campus_master for select to authenticated using (true);
drop policy if exists p2_lookup_read on emp_department_master; create policy p2_lookup_read on emp_department_master for select to authenticated using (true);
drop policy if exists p2_lookup_read on emp_designation_master; create policy p2_lookup_read on emp_designation_master for select to authenticated using (true);
drop policy if exists p2_lookup_read on emp_role_master; create policy p2_lookup_read on emp_role_master for select to authenticated using (true);

drop policy if exists p2_student_scope on student_core; create policy p2_student_scope on student_core for select to authenticated using (public.can_read_student(stu_student_id));
drop policy if exists p2_student_scope on student_contact; create policy p2_student_scope on student_contact for select to authenticated using (public.can_read_student(stu_contact_student_id));
drop policy if exists p2_student_scope on student_parent; create policy p2_student_scope on student_parent for select to authenticated using (public.can_read_student(stu_parent_student_id));
drop policy if exists p2_student_scope on student_address; create policy p2_student_scope on student_address for select to authenticated using (public.can_read_student(stu_address_student_id));
drop policy if exists p2_student_scope on student_enrollment_current; create policy p2_student_scope on student_enrollment_current for select to authenticated using (public.can_read_student(stu_enroll_student_id));
drop policy if exists p2_student_scope on student_academic_record; create policy p2_student_scope on student_academic_record for select to authenticated using (public.can_read_student(stu_academic_student_id));
drop policy if exists p2_student_scope on student_status_log; create policy p2_student_scope on student_status_log for select to authenticated using (public.can_read_student(stu_status_student_id));
drop policy if exists p2_student_scope on student_attendance_daily; create policy p2_student_scope on student_attendance_daily for select to authenticated using (public.can_read_student(stu_attendance_student_id));

drop policy if exists p2_employee_scope on employee_core; create policy p2_employee_scope on employee_core for select to authenticated using (public.can_read_employee(emp_employee_id));
drop policy if exists p2_employee_scope on employee_contact; create policy p2_employee_scope on employee_contact for select to authenticated using (public.can_read_employee(emp_contact_employee_id));
drop policy if exists p2_employee_scope on employee_family; create policy p2_employee_scope on employee_family for select to authenticated using (public.can_read_employee(emp_family_employee_id));
drop policy if exists p2_employee_scope on employee_address; create policy p2_employee_scope on employee_address for select to authenticated using (public.can_read_employee(emp_address_employee_id));
drop policy if exists p2_employee_scope on employee_job_current; create policy p2_employee_scope on employee_job_current for select to authenticated using (public.can_read_employee(emp_job_employee_id));
drop policy if exists p2_employee_scope on employee_qualification_record; create policy p2_employee_scope on employee_qualification_record for select to authenticated using (public.can_read_employee(emp_qualification_employee_id));
drop policy if exists p2_employee_scope on employee_leave_balance; create policy p2_employee_scope on employee_leave_balance for select to authenticated using (public.can_read_employee(emp_leave_employee_id));
drop policy if exists p2_employee_scope on employee_status_log; create policy p2_employee_scope on employee_status_log for select to authenticated using (public.can_read_employee(emp_status_employee_id));
drop policy if exists p2_employee_scope on employee_attendance_daily; create policy p2_employee_scope on employee_attendance_daily for select to authenticated using (public.can_read_employee(emp_attendance_employee_id));
