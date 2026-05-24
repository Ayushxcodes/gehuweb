-- Phase 4 Login Step 05
-- Post-green verification snapshot before app login testing.

-- A) Summary
select
  (select count(*) from auth.users) as auth_users_total,
  (select count(*) from public.app_user_identity where is_active = true) as identity_active_rows,
  (select count(*) from public.app_user_identity where is_active = true and account_type = 'ADMIN') as admin_identity_rows,
  (select count(*) from public.app_user_identity where is_active = true and account_type = 'STUDENT') as student_identity_rows,
  (select count(*) from public.app_profile_state where auth_user_id is not null) as profile_linked_rows;

-- B) Pilot identity/profile matrix
select
  au.email,
  ai.account_type,
  ai.student_id,
  ai.employee_id,
  p.uid as profile_uid,
  p.name,
  p.course,
  p.branch,
  p.semester,
  p.phone,
  p.verification_status,
  p.profile_completed
from public.app_user_identity ai
join auth.users au on au.id = ai.auth_user_id
left join public.app_profile_state p on p.student_id = ai.student_id
where ai.is_active = true
order by ai.account_type, au.email;

-- C) Any remaining student blockers? (should return 0 rows)
select
  au.email,
  ai.student_id
from public.app_user_identity ai
join auth.users au on au.id = ai.auth_user_id
join public.app_profile_state p on p.student_id = ai.student_id
where ai.is_active = true
  and ai.account_type = 'STUDENT'
  and (
    btrim(coalesce(p.name, '')) = ''
    or btrim(coalesce(p.official_email, '')) = ''
    or (btrim(coalesce(p.roll_no, '')) = '' and btrim(coalesce(p.roll_number_legacy, '')) = '')
    or btrim(coalesce(p.course, '')) = ''
    or btrim(coalesce(p.branch, '')) = ''
    or p.semester is null
    or (btrim(coalesce(p.phone, '')) = '' and btrim(coalesce(p.student_mobile, '')) = '')
  );

