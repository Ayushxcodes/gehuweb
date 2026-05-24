-- Phase 4 Login Step 04A
-- Seed minimal student contact + parent + category for mapped pilot students.

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

