-- Phase Profile Runtime / Chunk 03
-- 1. Upgrade public.api_auth_route_snapshot() to return all missing profile fields expected by next.js AuthProvider.
-- 2. Normalize course names in mocks.current_student_context() to map longdegree names to short codes.
-- 3. Synchronize 'student@test.gehu' profile state to coordinates MCA / Haldwani / Semester 4.

begin;

-- Safe-drop old signature to prevent PostgreSQL return-type mismatch
drop function if exists public.api_auth_route_snapshot();

-- Upgrade api_auth_route_snapshot
create or replace function public.api_auth_route_snapshot()
returns table (
  auth_user_id uuid,
  email text,
  account_type text,
  is_active boolean,
  student_id text,
  employee_id text,
  profile_completed boolean,
  verification_status text,
  verified boolean,
  edit_unlocked_until timestamptz,
  uid text,
  name text,
  official_email text,
  student_id_label text,
  roll_no text,
  course text,
  branch text,
  semester integer
)
language sql
stable
security definer
set search_path = public
as $$
  select
    ai.auth_user_id,
    coalesce(auth.jwt() ->> 'email', '')::text as email,
    ai.account_type,
    ai.is_active,
    ai.student_id,
    ai.employee_id,
    case
      when ai.account_type = 'ADMIN' then true
      else coalesce(ps.profile_completed, false)
    end as profile_completed,
    case
      when ai.account_type = 'ADMIN' then 'VERIFIED'
      else coalesce(ps.verification_status, 'PENDING')
    end as verification_status,
    case
      when ai.account_type = 'ADMIN' then true
      else coalesce(ps.verified, false)
    end as verified,
    ps.edit_unlocked_until,
    ps.uid,
    ps.name,
    ps.official_email,
    ps.student_id_label,
    ps.roll_no,
    ps.course,
    ps.branch,
    ps.semester
  from public.app_user_identity ai
  left join public.app_profile_state ps
    on ps.auth_user_id = ai.auth_user_id
  where ai.auth_user_id = auth.uid()
    and ai.is_active = true
  limit 1;
$$;

grant execute on function public.api_auth_route_snapshot() to authenticated;

-- Normalize mocks.current_student_context()
create or replace function mocks.current_student_context()
returns table (
  auth_user_id uuid,
  student_id text,
  branch text,
  course text,
  semester text
)
language sql
stable
as $$
  select
    ai.auth_user_id,
    ai.student_id,
    coalesce(nullif(trim(ps.branch), ''), 'ALL') as branch,
    case 
      when lower(trim(ps.course)) in ('master of computer application', 'master of computer applications', 'mca') then 'MCA'
      when lower(trim(ps.course)) in ('bachelor of computer application', 'bachelor of computer applications', 'bca') then 'BCA'
      when lower(trim(ps.course)) in ('bachelor of technology', 'b.tech') then 'B.Tech'
      when lower(trim(ps.course)) in ('master of technology', 'm.tech') then 'M.Tech'
      when lower(trim(ps.course)) in ('master of business administration', 'mba') then 'MBA'
      else coalesce(nullif(trim(ps.course), ''), 'ALL')
    end as course,
    coalesce(nullif(trim(ps.semester::text), ''), 'ALL') as semester
  from public.app_user_identity ai
  left join public.app_profile_state ps
    on ps.auth_user_id = ai.auth_user_id
  where ai.auth_user_id = (select auth.uid())
    and ai.is_active = true
    and ai.account_type = 'STUDENT'
  limit 1;
$$;

grant execute on function mocks.current_student_context() to authenticated;

-- Sync student@test.gehu coordinates in app_profile_state
update public.app_profile_state
set course = 'Master of Computer Application',
    branch = 'Haldwani',
    semester = 4,
    profile_completed = true,
    verification_status = 'VERIFIED',
    verified = true,
    updated_at = now()
where official_email_key = 'student@test.gehu';

commit;
