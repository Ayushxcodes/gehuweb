-- Phase 2 grants (read-only for authenticated, no access for anon)
revoke all on table
  app_user_identity,
  stu_campus_master, stu_course_master, stu_branch_master, stu_section_master, stu_specialization_master,
  student_core, student_contact, student_parent, student_address, student_enrollment_current, student_academic_record, student_status_log, student_attendance_daily,
  emp_campus_master, emp_department_master, emp_designation_master, emp_role_master,
  employee_core, employee_contact, employee_family, employee_address, employee_job_current, employee_qualification_record, employee_leave_balance, employee_status_log, employee_attendance_daily
from anon, authenticated;

grant select on table
  app_user_identity,
  stu_campus_master, stu_course_master, stu_branch_master, stu_section_master, stu_specialization_master,
  student_core, student_contact, student_parent, student_address, student_enrollment_current, student_academic_record, student_status_log, student_attendance_daily,
  emp_campus_master, emp_department_master, emp_designation_master, emp_role_master,
  employee_core, employee_contact, employee_family, employee_address, employee_job_current, employee_qualification_record, employee_leave_balance, employee_status_log, employee_attendance_daily
to authenticated;
