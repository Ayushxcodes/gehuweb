-- Phase 4 Login Step 02
-- Safe hydrate: fills blank app_profile_state fields from student_* tables for mapped students.
-- No deletes. No inserts into app_profile_state.

with mapped as (
  select
    ai.auth_user_id,
    ai.student_id,
    au.email as login_email
  from public.app_user_identity ai
  join auth.users au on au.id = ai.auth_user_id
  where ai.is_active = true
    and ai.account_type = 'STUDENT'
    and ai.student_id is not null
)
update public.app_profile_state p
set
  auth_user_id = coalesce(p.auth_user_id, m.auth_user_id),
  name = case when btrim(coalesce(p.name, '')) = '' then coalesce(sc.stu_full_name, p.name) else p.name end,
  official_email = case when btrim(coalesce(p.official_email, '')) = '' then coalesce(sct.stu_official_email, m.login_email, p.official_email) else p.official_email end,
  official_email_key = case when btrim(coalesce(p.official_email_key, '')) = '' then lower(trim(coalesce(sct.stu_official_email, m.login_email, p.official_email, ''))) else p.official_email_key end,
  personal_email = case when p.personal_email is null or btrim(p.personal_email) = '' then sct.stu_personal_email else p.personal_email end,
  personal_email_key = case when btrim(coalesce(p.personal_email_key, '')) = '' then lower(trim(coalesce(sct.stu_personal_email, p.personal_email, ''))) else p.personal_email_key end,
  student_id_label = case when btrim(coalesce(p.student_id_label, '')) = '' then p.student_id else p.student_id_label end,
  roll_no = case when btrim(coalesce(p.roll_no, '')) = '' and se.stu_class_roll_no is not null then se.stu_class_roll_no::text else p.roll_no end,
  roll_number_legacy = case when btrim(coalesce(p.roll_number_legacy, '')) = '' and se.stu_class_roll_no is not null then se.stu_class_roll_no::text else p.roll_number_legacy end,
  university_roll = case when btrim(coalesce(p.university_roll, '')) = '' then coalesce(se.stu_university_roll_no, p.university_roll) else p.university_roll end,
  enrollment_no = case when btrim(coalesce(p.enrollment_no, '')) = '' then coalesce(se.stu_enroll_no, p.enrollment_no) else p.enrollment_no end,
  course = case when btrim(coalesce(p.course, '')) = '' then coalesce(cm.stu_course_name, p.course) else p.course end,
  branch = case when btrim(coalesce(p.branch, '')) = '' then coalesce(bm.stu_branch_name, p.branch) else p.branch end,
  semester = coalesce(p.semester, se.stu_year_sem_no),
  dob_text = case when btrim(coalesce(p.dob_text, '')) = '' and sc.stu_dob is not null then to_char(sc.stu_dob, 'YYYY-MM-DD') else p.dob_text end,
  gender = case when btrim(coalesce(p.gender, '')) = '' then coalesce(sc.stu_gender_code, p.gender) else p.gender end,
  category = case when btrim(coalesce(p.category, '')) = '' then coalesce(sc.stu_category_code, p.category) else p.category end,
  father_name = case when btrim(coalesce(p.father_name, '')) = '' then coalesce(sp.stu_father_name, p.father_name) else p.father_name end,
  father_mobile = case when btrim(coalesce(p.father_mobile, '')) = '' then coalesce(sp.stu_father_phone, p.father_mobile) else p.father_mobile end,
  father_occupation = case when btrim(coalesce(p.father_occupation, '')) = '' then coalesce(sp.stu_father_occupation, p.father_occupation) else p.father_occupation end,
  mother_name = case when btrim(coalesce(p.mother_name, '')) = '' then coalesce(sp.stu_mother_name, p.mother_name) else p.mother_name end,
  mother_mobile = case when btrim(coalesce(p.mother_mobile, '')) = '' then coalesce(sp.stu_mother_phone, p.mother_mobile) else p.mother_mobile end,
  mother_occupation = case when btrim(coalesce(p.mother_occupation, '')) = '' then coalesce(sp.stu_mother_occupation, p.mother_occupation) else p.mother_occupation end,
  student_mobile = case when btrim(coalesce(p.student_mobile, '')) = '' then coalesce(sct.stu_primary_phone, p.student_mobile) else p.student_mobile end,
  phone = case when btrim(coalesce(p.phone, '')) = '' then coalesce(sct.stu_primary_phone, p.phone) else p.phone end
from mapped m
left join public.student_core sc on sc.stu_student_id = m.student_id
left join public.student_contact sct on sct.stu_contact_student_id = m.student_id
left join public.student_parent sp on sp.stu_parent_student_id = m.student_id
left join public.student_enrollment_current se on se.stu_enroll_student_id = m.student_id
left join public.stu_course_master cm on cm.stu_course_id = se.stu_course_id
left join public.stu_branch_master bm on bm.stu_branch_id = se.stu_branch_id
where p.student_id = m.student_id;

-- Quick count of mapped students still missing profile row
select count(*) as mapped_students_missing_profile_row
from public.app_user_identity ai
left join public.app_profile_state p on p.student_id = ai.student_id
where ai.is_active = true
  and ai.account_type = 'STUDENT'
  and ai.student_id is not null
  and p.uid is null;

