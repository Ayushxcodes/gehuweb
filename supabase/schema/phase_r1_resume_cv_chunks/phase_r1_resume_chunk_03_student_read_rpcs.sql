-- Phase R1 / Chunk 03
-- Student resume list/detail RPCs.

begin;

create or replace function public.api_resume_list()
returns table (
  resume_id text,
  resume_name text,
  template_id text,
  is_default boolean,
  last_updated_ms bigint,
  updated_at timestamptz
)
language sql stable security definer
set search_path = public
as $$
  with me as (select public.app_current_profile_uid() as uid)
  select r.resume_id, r.resume_name, r.template_id,
         r.is_default, r.last_updated_ms, r.updated_at
  from public.student_resumes r, me
  where r.uid = me.uid and r.deleted_at is null
  order by r.is_default desc, r.last_updated_ms desc, r.updated_at desc;
$$;

create or replace function public.api_resume_get(p_resume_id text default null)
returns table (
  resume_id text,
  resume_name text,
  is_default boolean,
  payload_json jsonb,
  updated_at timestamptz
)
language sql stable security definer
set search_path = public
as $$
  with me as (select public.app_current_profile_uid() as uid)
  select r.resume_id, r.resume_name, r.is_default,
         r.payload_json, r.updated_at
  from public.student_resumes r, me
  where r.uid = me.uid
    and r.deleted_at is null
    and (p_resume_id is null or p_resume_id = '' or r.resume_id = p_resume_id)
  order by
    case when p_resume_id is null or p_resume_id = '' then r.is_default else false end desc,
    r.last_updated_ms desc, r.updated_at desc
  limit 1;
$$;

grant execute on function public.api_resume_list() to authenticated;
grant execute on function public.api_resume_get(text) to authenticated;

commit;
