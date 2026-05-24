-- Phase AUTH Route / Chunk 01
-- Purpose:
-- Replace two post-login REST reads with one RPC route snapshot.
-- Android still performs Supabase password auth first; this RPC resolves
-- account type + profile gate in one round trip after auth succeeds.

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
  edit_unlocked_until timestamptz
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
    ps.edit_unlocked_until
  from public.app_user_identity ai
  left join public.app_profile_state ps
    on ps.auth_user_id = ai.auth_user_id
  where ai.auth_user_id = auth.uid()
    and ai.is_active = true
  limit 1;
$$;

revoke all on function public.api_auth_route_snapshot() from public;
grant execute on function public.api_auth_route_snapshot() to authenticated;

select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'api_auth_route_snapshot';
