-- Phase Profile Runtime / Chunk 01
-- Purpose:
-- Fast profile read for Android/Web runtime.
-- Avoids repeated direct table REST reads and keeps the auth user scoped by auth.uid().

create or replace function public.api_my_profile_state()
returns table (
  name text,
  official_email text,
  student_id_label text,
  father_name text,
  father_occupation text,
  father_mobile text,
  mother_name text,
  mother_occupation text,
  mother_mobile text,
  dob_text text,
  gender text,
  category text,
  roll_no text,
  roll_number_legacy text,
  course text,
  branch text,
  phone text,
  student_mobile text,
  semester integer,
  photo_url text,
  photo_path text,
  address_json jsonb,
  academic_record_json jsonb,
  profile_completed boolean,
  verification_status text,
  verified boolean,
  edit_unlocked_until timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    ps.name,
    ps.official_email,
    ps.student_id_label,
    ps.father_name,
    ps.father_occupation,
    ps.father_mobile,
    ps.mother_name,
    ps.mother_occupation,
    ps.mother_mobile,
    ps.dob_text,
    ps.gender,
    ps.category,
    ps.roll_no,
    ps.roll_number_legacy,
    ps.course,
    ps.branch,
    ps.phone,
    ps.student_mobile,
    ps.semester,
    ps.photo_url,
    ps.photo_path,
    ps.address_json,
    ps.academic_record_json,
    ps.profile_completed,
    ps.verification_status,
    ps.verified,
    ps.edit_unlocked_until
  from public.app_profile_state ps
  where ps.auth_user_id = auth.uid()
  limit 1;
$$;

revoke all on function public.api_my_profile_state() from public;
grant execute on function public.api_my_profile_state() to authenticated;

select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'api_my_profile_state';
