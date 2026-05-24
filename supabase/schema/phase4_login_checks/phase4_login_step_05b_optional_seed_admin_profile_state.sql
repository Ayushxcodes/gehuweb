-- Phase 4 Login Step 05B (optional)
-- Use only if admin UI expects app_profile_state fields and fails without them.

with admin_map as (
  select
    ai.auth_user_id,
    au.email,
    ai.employee_id
  from public.app_user_identity ai
  join auth.users au on au.id = ai.auth_user_id
  where ai.is_active = true
    and ai.account_type = 'ADMIN'
  limit 1
)
insert into public.app_profile_state (
  uid,
  auth_user_id,
  student_id,
  employee_id,
  account_role,
  name,
  official_email,
  official_email_key,
  profile_completed,
  verification_status,
  verified
)
select
  am.auth_user_id::text as uid,
  am.auth_user_id,
  null::text as student_id,
  am.employee_id,
  'ADMIN' as account_role,
  'Admin User' as name,
  am.email as official_email,
  lower(trim(am.email)) as official_email_key,
  true as profile_completed,
  'VERIFIED' as verification_status,
  true as verified
from admin_map am
on conflict (uid) do update set
  auth_user_id = excluded.auth_user_id,
  employee_id = excluded.employee_id,
  account_role = excluded.account_role,
  name = excluded.name,
  official_email = excluded.official_email,
  official_email_key = excluded.official_email_key,
  profile_completed = excluded.profile_completed,
  verification_status = excluded.verification_status,
  verified = excluded.verified;

