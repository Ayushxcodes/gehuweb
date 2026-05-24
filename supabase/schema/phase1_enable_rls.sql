-- Phase 1 security baseline
-- Enable RLS on all student/employee foundation tables.
-- Keep policies empty for now (secure by default: anon/authenticated cannot read/write rows).

begin;

-- Student lookup
alter table if exists stu_campus_master enable row level security;
alter table if exists stu_course_master enable row level security;
alter table if exists stu_branch_master enable row level security;
alter table if exists stu_section_master enable row level security;
alter table if exists stu_specialization_master enable row level security;

-- Student domain
alter table if exists student_core enable row level security;
alter table if exists student_contact enable row level security;
alter table if exists student_parent enable row level security;
alter table if exists student_address enable row level security;
alter table if exists student_enrollment_current enable row level security;
alter table if exists student_academic_record enable row level security;
alter table if exists student_status_log enable row level security;
alter table if exists student_attendance_daily enable row level security;

-- Employee lookup
alter table if exists emp_campus_master enable row level security;
alter table if exists emp_department_master enable row level security;
alter table if exists emp_designation_master enable row level security;
alter table if exists emp_role_master enable row level security;

-- Employee domain
alter table if exists employee_core enable row level security;
alter table if exists employee_contact enable row level security;
alter table if exists employee_family enable row level security;
alter table if exists employee_address enable row level security;
alter table if exists employee_job_current enable row level security;
alter table if exists employee_qualification_record enable row level security;
alter table if exists employee_leave_balance enable row level security;
alter table if exists employee_status_log enable row level security;
alter table if exists employee_attendance_daily enable row level security;

commit;
