-- Phase 1 seed data for lookup/master tables
-- Safe to run multiple times (idempotent inserts)

begin;

-- =========================================================
-- STUDENT LOOKUP SEED
-- =========================================================

insert into stu_campus_master (stu_campus_code, stu_campus_name, stu_campus_state)
values
  ('GEHU_HLD', 'GEHU Haldwani Campus', 'Uttarakhand'),
  ('GEHU_DDN', 'GEHU Dehradun Campus', 'Uttarakhand')
on conflict do nothing;

insert into stu_course_master (stu_course_code, stu_course_name, stu_course_level)
values
  ('BTECH', 'Bachelor of Technology', 'UG'),
  ('BCA', 'Bachelor of Computer Applications', 'UG'),
  ('MCA', 'Master of Computer Applications', 'PG'),
  ('MBA', 'Master of Business Administration', 'PG'),
  ('MTECH', 'Master of Technology', 'PG')
on conflict do nothing;

insert into stu_section_master (stu_section_code, stu_section_name)
values
  ('A', 'Section A'),
  ('B', 'Section B'),
  ('C', 'Section C'),
  ('NA', 'Not Assigned')
on conflict do nothing;

insert into stu_specialization_master (
  stu_specialization_code,
  stu_specialization_name,
  stu_specialization_course_id
)
select
  v.specialization_code,
  v.specialization_name,
  c.stu_course_id
from (
  values
    ('MCA_GEN', 'General', 'MCA'),
    ('MCA_AI', 'Artificial Intelligence', 'MCA'),
    ('BTECH_CSE_CORE', 'Computer Science and Engineering', 'BTECH'),
    ('BTECH_CSE_AI', 'CSE (AI/ML)', 'BTECH')
) as v(specialization_code, specialization_name, course_code)
join stu_course_master c
  on c.stu_course_code = v.course_code
on conflict do nothing;

insert into stu_branch_master (
  stu_branch_code,
  stu_branch_name,
  stu_branch_course_id,
  stu_branch_campus_id
)
select
  v.branch_code,
  v.branch_name,
  c.stu_course_id,
  m.stu_campus_id
from (
  values
    ('CSE', 'Computer Science and Engineering', 'BTECH', 'GEHU_HLD'),
    ('CSE', 'Computer Science and Engineering', 'BTECH', 'GEHU_DDN'),
    ('MCA', 'Master of Computer Applications', 'MCA', 'GEHU_HLD'),
    ('MCA', 'Master of Computer Applications', 'MCA', 'GEHU_DDN')
) as v(branch_code, branch_name, course_code, campus_code)
join stu_course_master c
  on c.stu_course_code = v.course_code
join stu_campus_master m
  on m.stu_campus_code = v.campus_code
on conflict do nothing;

-- =========================================================
-- EMPLOYEE LOOKUP SEED
-- =========================================================

insert into emp_campus_master (emp_campus_code, emp_campus_name, emp_campus_state)
values
  ('GEHU_HLD', 'GEHU Haldwani Campus', 'Uttarakhand'),
  ('GEHU_DDN', 'GEHU Dehradun Campus', 'Uttarakhand')
on conflict do nothing;

insert into emp_department_master (emp_department_code, emp_department_name)
values
  ('SOC', 'School of Computing'),
  ('HR', 'Human Resources'),
  ('ADMIN', 'Administration'),
  ('EXAM_CELL', 'Examination Cell'),
  ('PLACEMENT', 'Placement Cell'),
  ('TRANSPORT', 'Transport'),
  ('LIBRARY', 'Library'),
  ('HOSTEL', 'Hostel'),
  ('CANTEEN', 'Canteen'),
  ('SECURITY', 'Security'),
  ('IT_CELL', 'IT Cell')
on conflict do nothing;

insert into emp_designation_master (emp_designation_code, emp_designation_name)
values
  ('PROFESSOR', 'Professor'),
  ('ASSOC_PROF', 'Associate Professor'),
  ('ASST_PROF', 'Assistant Professor'),
  ('HOD', 'Head of Department'),
  ('LAB_ASSISTANT', 'Lab Assistant'),
  ('ADMIN_OFFICER', 'Admin Officer'),
  ('BUS_DRIVER', 'Bus Driver'),
  ('CONDUCTOR', 'Conductor'),
  ('GARDENER', 'Gardener'),
  ('LIBRARIAN', 'Librarian')
on conflict do nothing;

insert into emp_role_master (emp_role_code, emp_role_name)
values
  ('ADMIN', 'Admin'),
  ('FACULTY', 'Faculty'),
  ('ACADEMIC_COORD', 'Academic Coordinator'),
  ('SUPPORT_STAFF', 'Support Staff'),
  ('TRANSPORT_STAFF', 'Transport Staff'),
  ('LIBRARY_STAFF', 'Library Staff'),
  ('CANTEEN_STAFF', 'Canteen Staff'),
  ('SECURITY_STAFF', 'Security Staff')
on conflict do nothing;

commit;
