-- Phase 3 Backfill / Chunk 02
-- Helper array parsers + users/directory upsert

create or replace function stage_import.jsonb_to_text_array(j jsonb)
returns text[]
language sql
stable
as $$
  select case
    when j is null or jsonb_typeof(j) <> 'array' then null
    else array(
      select trim(value)
      from jsonb_array_elements_text(j) as value
      where trim(value) <> ''
    )
  end;
$$;

create or replace function stage_import.jsonb_to_int_array(j jsonb)
returns integer[]
language sql
stable
as $$
  select case
    when j is null or jsonb_typeof(j) <> 'array' then null
    else array(
      select (value)::integer
      from jsonb_array_elements_text(j) as value
      where value ~ '^-?[0-9]+$'
    )
  end;
$$;

insert into public.app_profile_state (
  uid, account_role, name, official_email, official_email_key, student_id, student_id_label,
  roll_no, roll_number_legacy, university_roll, course, branch, semester, dob_text, gender,
  category, father_name, father_occupation, father_mobile, mother_name, mother_occupation,
  mother_mobile, student_mobile, phone, address_json, academic_record_json, photo_url, photo_path,
  profile_completed, verification_status, verified, edit_unlocked_until, fcm_token,
  source_created_at, source_updated_at
)
select
  u.uid,
  case upper(coalesce(trim(u.data->>'role'), 'STUDENT'))
    when 'ADMIN' then 'ADMIN'
    when 'COORDINATOR' then 'COORDINATOR'
    when 'EMPLOYEE' then 'EMPLOYEE'
    else 'STUDENT'
  end,
  coalesce(trim(u.data->>'name'), ''),
  coalesce(lower(trim(u.data->>'email')), ''),
  coalesce(lower(trim(u.data->>'email')), ''),
  nullif(trim(u.data->>'studentId'), ''),
  coalesce(trim(u.data->>'studentId'), ''),
  coalesce(nullif(trim(u.data->>'rollNo'), ''), coalesce(trim(u.data->>'rollNumber'), '')),
  coalesce(trim(u.data->>'rollNumber'), ''),
  coalesce(trim(u.data->>'universityRoll'), ''),
  coalesce(trim(u.data->>'course'), ''),
  coalesce(trim(u.data->>'branch'), ''),
  stage_import.jsonb_to_int(u.data->'semester'),
  coalesce(trim(u.data->>'dob'), ''),
  coalesce(trim(u.data->>'gender'), ''),
  coalesce(trim(u.data->>'category'), ''),
  coalesce(trim(u.data->>'fatherName'), ''),
  coalesce(trim(u.data->>'fatherOccupation'), ''),
  coalesce(trim(u.data->>'fatherMobile'), ''),
  coalesce(trim(u.data->>'motherName'), ''),
  coalesce(trim(u.data->>'motherOccupation'), ''),
  coalesce(trim(u.data->>'motherMobile'), ''),
  coalesce(trim(u.data->>'studentMobile'), ''),
  coalesce(nullif(trim(u.data->>'studentMobile'), ''), coalesce(trim(u.data->>'phone'), '')),
  case when jsonb_typeof(u.data->'address') = 'object' then u.data->'address' else '{}'::jsonb end,
  case when jsonb_typeof(u.data->'academicRecord') = 'object' then u.data->'academicRecord' else '{}'::jsonb end,
  coalesce(trim(u.data->>'photoUrl'), ''),
  coalesce(trim(u.data->>'photoPath'), ''),
  coalesce(stage_import.jsonb_to_bool(u.data->'profileCompleted'), false),
  case upper(coalesce(trim(u.data->>'verificationStatus'), 'PENDING'))
    when 'VERIFIED' then 'VERIFIED'
    when 'REJECTED' then 'REJECTED'
    when 'LOCKED' then 'LOCKED'
    when 'DRAFT' then 'DRAFT'
    else 'PENDING'
  end,
  coalesce(stage_import.jsonb_to_bool(u.data->'verified'), false),
  stage_import.jsonb_to_timestamptz(u.data->'editUnlockedUntil'),
  coalesce(trim(u.data->>'fcmToken'), ''),
  stage_import.jsonb_to_timestamptz(u.data->'createdAt'),
  stage_import.jsonb_to_timestamptz(u.data->'updatedAt')
from stage_import.fb_users u
on conflict (uid) do update set
  account_role = excluded.account_role,
  name = excluded.name,
  official_email = excluded.official_email,
  official_email_key = excluded.official_email_key,
  student_id = excluded.student_id,
  student_id_label = excluded.student_id_label,
  roll_no = excluded.roll_no,
  roll_number_legacy = excluded.roll_number_legacy,
  university_roll = excluded.university_roll,
  course = excluded.course,
  branch = excluded.branch,
  semester = excluded.semester,
  dob_text = excluded.dob_text,
  gender = excluded.gender,
  category = excluded.category,
  father_name = excluded.father_name,
  father_occupation = excluded.father_occupation,
  father_mobile = excluded.father_mobile,
  mother_name = excluded.mother_name,
  mother_occupation = excluded.mother_occupation,
  mother_mobile = excluded.mother_mobile,
  student_mobile = excluded.student_mobile,
  phone = excluded.phone,
  address_json = excluded.address_json,
  academic_record_json = excluded.academic_record_json,
  photo_url = excluded.photo_url,
  photo_path = excluded.photo_path,
  profile_completed = excluded.profile_completed,
  verification_status = excluded.verification_status,
  verified = excluded.verified,
  edit_unlocked_until = excluded.edit_unlocked_until,
  fcm_token = excluded.fcm_token,
  source_created_at = excluded.source_created_at,
  source_updated_at = excluded.source_updated_at;

insert into public.app_directory_index (
  uid, name, email, roll_no, university_roll, role, email_key, roll_no_key, university_roll_key, source_updated_at
)
select
  d.uid,
  coalesce(trim(d.data->>'name'), ''),
  coalesce(trim(d.data->>'email'), ''),
  coalesce(trim(d.data->>'rollNo'), ''),
  coalesce(trim(d.data->>'universityRoll'), ''),
  coalesce(trim(d.data->>'role'), ''),
  lower(coalesce(trim(d.data->>'email'), '')),
  upper(coalesce(trim(d.data->>'rollNo'), '')),
  upper(coalesce(trim(d.data->>'universityRoll'), '')),
  stage_import.jsonb_to_timestamptz(d.data->'updatedAt')
from stage_import.fb_directory d
on conflict (uid) do update set
  name = excluded.name,
  email = excluded.email,
  roll_no = excluded.roll_no,
  university_roll = excluded.university_roll,
  role = excluded.role,
  email_key = excluded.email_key,
  roll_no_key = excluded.roll_no_key,
  university_roll_key = excluded.university_roll_key,
  source_updated_at = excluded.source_updated_at;

insert into public.app_directory_index (
  uid, name, email, roll_no, university_roll, role, email_key, roll_no_key, university_roll_key, student_id, source_updated_at
)
select
  p.uid, p.name, p.official_email, p.roll_no, p.university_roll, p.account_role,
  lower(p.official_email), upper(p.roll_no), upper(p.university_roll),
  coalesce(p.student_id, ''), p.source_updated_at
from public.app_profile_state p
where not exists (
  select 1 from public.app_directory_index d where d.uid = p.uid
);
