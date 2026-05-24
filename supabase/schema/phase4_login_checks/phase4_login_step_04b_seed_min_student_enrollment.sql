-- Phase 4 Login Step 04B
-- Seed minimal student_enrollment_current for mapped pilot students.

with mapped as (
  select ai.student_id
  from public.app_user_identity ai
  where ai.is_active = true
    and ai.account_type = 'STUDENT'
    and ai.student_id is not null
),
pref as (
  select
    b.stu_branch_id,
    b.stu_branch_course_id as stu_course_id,
    b.stu_branch_campus_id as stu_campus_id,
    s.stu_section_id
  from public.stu_branch_master b
  join public.stu_course_master c on c.stu_course_id = b.stu_branch_course_id
  join public.stu_campus_master cm on cm.stu_campus_id = b.stu_branch_campus_id
  join public.stu_section_master s on s.stu_section_code = 'A'
  where c.stu_course_code = 'MCA'
    and cm.stu_campus_code = 'GEHU_HLD'
    and b.stu_branch_code = 'MCA'
  limit 1
),
fb as (
  select
    b.stu_branch_id,
    b.stu_branch_course_id as stu_course_id,
    b.stu_branch_campus_id as stu_campus_id,
    (select stu_section_id from public.stu_section_master order by stu_section_id limit 1) as stu_section_id
  from public.stu_branch_master b
  order by b.stu_branch_id
  limit 1
),
chosen as (
  select * from pref
  union all
  select * from fb where not exists (select 1 from pref)
)
insert into public.student_enrollment_current (
  stu_enroll_student_id,
  stu_college_campus_id,
  stu_course_id,
  stu_specialization_id,
  stu_branch_id,
  stu_section_id,
  stu_year_sem_no,
  stu_class_roll_no,
  stu_enroll_no,
  stu_university_roll_no,
  stu_enroll_state
)
select
  m.student_id,
  c.stu_campus_id,
  c.stu_course_id,
  null,
  c.stu_branch_id,
  c.stu_section_id,
  4,
  coalesce(nullif(right(regexp_replace(m.student_id, '\D', '', 'g'), 3), ''), '0')::integer,
  'ENR-' || m.student_id,
  'UR-' || m.student_id,
  'ACTIVE'
from mapped m
cross join chosen c
left join public.student_enrollment_current e on e.stu_enroll_student_id = m.student_id
where e.stu_enroll_student_id is null;

