-- Phase 3 runtime auth/policy diagnostics / 2026-05-19
-- Run while signed in through Supabase SQL editor/API context where auth.uid() is available.
-- Purpose: distinguish policy shape, helper security, identity mapping, and current-user role issues.

-- 1) Helper functions must both be security definer.
select
  n.nspname as schema_name,
  p.proname as function_name,
  p.prosecdef as security_definer,
  pg_get_functiondef(p.oid) as function_def
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('app_phase3_is_admin', 'app_phase3_uid_is_self')
order by p.proname;

-- 2) Current JWT identity and app identity mapping.
select
  auth.uid() as current_auth_uid,
  ai.auth_user_id,
  ai.account_type,
  ai.student_id,
  ai.employee_id,
  ai.is_active,
  public.app_phase3_is_admin() as helper_says_admin
from public.app_user_identity ai
where ai.auth_user_id = auth.uid();

-- 3) Current profile linkage for student appeal self-checks.
select
  ps.uid,
  ps.auth_user_id,
  ps.student_id,
  ps.employee_id,
  ps.name,
  ps.course,
  ps.branch,
  public.app_phase3_uid_is_self(ps.uid) as helper_says_self
from public.app_profile_state ps
where ps.auth_user_id = auth.uid()
   or exists (
     select 1
     from public.app_user_identity ai
     where ai.auth_user_id = auth.uid()
       and ai.is_active = true
       and (
         (ps.student_id is not null and ai.student_id = ps.student_id)
         or (ps.employee_id is not null and ai.employee_id = ps.employee_id)
       )
   )
order by ps.updated_at desc nulls last
limit 10;

-- 4) Admin write predicates should be true for admin accounts.
select
  public.app_phase3_is_admin() as can_admin_write_notices_and_appeals;

-- 5) Existing pending appeals visible to the current session.
select appeal_id, uid, name, email, type, status, created_at
from public.app_appeals
where status = 'PENDING'
order by created_at desc
limit 20;