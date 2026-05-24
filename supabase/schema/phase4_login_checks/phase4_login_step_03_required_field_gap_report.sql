-- Phase 4 Login Step 03
-- Required-now gap report for pilot student login/read flows.

with mapped_students as (
  select
    ai.auth_user_id,
    au.email,
    ai.student_id
  from public.app_user_identity ai
  join auth.users au on au.id = ai.auth_user_id
  where ai.is_active = true
    and ai.account_type = 'STUDENT'
    and ai.student_id is not null
),
gaps as (
  select
    ms.email,
    ms.student_id,
    p.uid,
    (p.uid is null) as missing_profile_row,
    (btrim(coalesce(p.name, '')) = '') as missing_name,
    (btrim(coalesce(p.official_email, '')) = '') as missing_official_email,
    (btrim(coalesce(p.student_id_label, '')) = '') as missing_student_id_label,
    (btrim(coalesce(p.roll_no, '')) = '' and btrim(coalesce(p.roll_number_legacy, '')) = '') as missing_roll,
    (btrim(coalesce(p.course, '')) = '') as missing_course,
    (btrim(coalesce(p.branch, '')) = '') as missing_branch,
    (p.semester is null) as missing_semester,
    (btrim(coalesce(p.dob_text, '')) = '') as missing_dob,
    (btrim(coalesce(p.gender, '')) = '') as missing_gender,
    (btrim(coalesce(p.category, '')) = '') as missing_category,
    (btrim(coalesce(p.father_name, '')) = '') as missing_father_name,
    (btrim(coalesce(p.mother_name, '')) = '') as missing_mother_name,
    (btrim(coalesce(p.phone, '')) = '' and btrim(coalesce(p.student_mobile, '')) = '') as missing_phone
  from mapped_students ms
  left join public.app_profile_state p on p.student_id = ms.student_id
)
select
  email,
  student_id,
  (missing_profile_row::int
    + missing_name::int
    + missing_official_email::int
    + missing_student_id_label::int
    + missing_roll::int
    + missing_course::int
    + missing_branch::int
    + missing_semester::int
    + missing_dob::int
    + missing_gender::int
    + missing_category::int
    + missing_father_name::int
    + missing_mother_name::int
    + missing_phone::int) as missing_required_field_count,
  case
    when missing_profile_row then 'BLOCKER: create/migrate app_profile_state row first'
    when (missing_name or missing_official_email or missing_roll or missing_course or missing_branch or missing_semester) then 'BLOCKER: core profile gaps'
    else 'OK_FOR_LOGIN_PILOT'
  end as readiness_status
from gaps
order by missing_required_field_count desc, email;
