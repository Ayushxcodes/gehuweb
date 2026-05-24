-- Web Identity Fix / Chunk 01B
-- Creates/repairs app_profile_state rows for student web routing.

with matched as (
  select u.id as auth_user_id, lower(u.email) as email_key, u.email,
         case lower(u.email)
           when 'student@test.gehu' then 'STU000001'
           when 'test1@gehu.ac.in' then 'STU000002'
           when 'test2@gehu.ac.in' then 'STU000003'
         end as student_id,
         case lower(u.email)
           when 'student@test.gehu' then 'Student One'
           when 'test1@gehu.ac.in' then 'Student Two'
           when 'test2@gehu.ac.in' then 'Student Three'
         end as full_name,
         row_number() over (order by lower(u.email)) as rn
  from auth.users u
  where lower(u.email) in (
    'student@test.gehu',
    'test1@gehu.ac.in',
    'test2@gehu.ac.in'
  )
)
insert into public.app_profile_state (
  uid, auth_user_id, student_id, account_role, name, official_email,
  official_email_key, student_id_label, roll_no, university_roll,
  enrollment_no, course, branch, semester, dob_text, gender, category,
  father_name, mother_name, student_mobile, phone,
  profile_completed, verification_status, verified
)
select auth_user_id::text, auth_user_id, student_id, 'STUDENT', full_name, email,
       email_key, student_id, rn::text, 'UR-' || student_id,
       'ENR-' || student_id, 'MCA',
       'Haldwani', 4, '2003-01-01',
       'UNDISCLOSED', 'GEN', 'Father of ' || student_id,
       'Mother of ' || student_id, '900000000' || rn,
       '900000000' || rn, true, 'VERIFIED', true
from matched
on conflict (student_id) do update set
  uid = excluded.uid,
  auth_user_id = excluded.auth_user_id,
  account_role = excluded.account_role,
  name = excluded.name,
  official_email = excluded.official_email,
  official_email_key = excluded.official_email_key,
  student_id_label = excluded.student_id_label,
  roll_no = excluded.roll_no,
  university_roll = excluded.university_roll,
  enrollment_no = excluded.enrollment_no,
  course = excluded.course,
  branch = excluded.branch,
  semester = excluded.semester,
  profile_completed = true,
  verification_status = 'VERIFIED',
  verified = true;

with admin_map as (
  select u.id as auth_user_id, u.email, lower(u.email) as email_key
  from auth.users u
  where lower(u.email) = 'admin@test.gehu'
)
insert into public.app_profile_state (
  uid, auth_user_id, employee_id, account_role, name,
  official_email, official_email_key,
  profile_completed, verification_status, verified
)
select auth_user_id::text, auth_user_id, 'EMP000001', 'ADMIN', 'Admin User',
       email, email_key, true, 'VERIFIED', true
from admin_map
on conflict (employee_id) do update set
  uid = excluded.uid,
  auth_user_id = excluded.auth_user_id,
  account_role = excluded.account_role,
  name = excluded.name,
  official_email = excluded.official_email,
  official_email_key = excluded.official_email_key,
  profile_completed = true,
  verification_status = 'VERIFIED',
  verified = true;
