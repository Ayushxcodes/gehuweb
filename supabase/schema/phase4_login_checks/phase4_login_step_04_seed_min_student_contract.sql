-- Phase 4 Login Step 04
-- Seed minimal student-domain rows for mapped pilot students only.
-- Purpose: clear login/profile blockers without touching notice/bell/mock.

-- A) Ensure student category exists for mapped students
update public.student_core sc
set stu_category_code = 'GEN'
from public.app_user_identity ai
where ai.is_active = true
  and ai.account_type = 'STUDENT'
  and ai.student_id = sc.stu_student_id
  and (sc.stu_category_code is null or btrim(sc.stu_category_code) = '');

-- B) Seed missing student_contact rows
with mapped as (
  select ai.student_id, au.email
  from public.app_user_identity ai
  join auth.users au on au.id = ai.auth_user_id
  where ai.is_active = true
    and ai.account_type = 'STUDENT'
    and ai.student_id is not null
)
insert into public.student_contact (
  stu_contact_student_id,
  stu_official_email,
  stu_personal_email,
  stu_primary_phone,
  stu_alternate_phone
)
select
  m.student_id,
  lower(m.email),
  null,
  ('9' || lpad(right(regexp_replace(m.student_id, '\D', '', 'g'), 9), 9, '0')),
  null
from mapped m
left join public.student_contact c on c.stu_contact_student_id = m.student_id
where c.stu_contact_student_id is null;

-- C) Seed missing student_parent rows (safe placeholders)
with mapped as (
  select ai.student_id
  from public.app_user_identity ai
  where ai.is_active = true
    and ai.account_type = 'STUDENT'
    and ai.student_id is not null
)
insert into public.student_parent (
  stu_parent_student_id,
  stu_father_name,
  stu_mother_name,
  stu_father_phone,
  stu_mother_phone,
  stu_father_occupation,
  stu_mother_occupation
)
select
  m.student_id,
  'Father of ' || m.student_id,
  'Mother of ' || m.student_id,
  null,
  null,
  'Not Provided',
  'Not Provided'
from mapped m
left join public.student_parent p on p.stu_parent_student_id = m.student_id
where p.stu_parent_student_id is null;

-- D) Seed missing student_enrollment_current rows
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

