-- Phase R1 / Chunk 06
-- Admin default CV lookup + official resume feedback.

begin;

create or replace function public.api_admin_student_resume_default(p_student_id text)
returns table (
  uid text,
  student_id text,
  resume_id text,
  resume_name text,
  payload_json jsonb,
  updated_at timestamptz
)
language sql stable security definer
set search_path = public
as $$
  select ps.uid, ps.student_id, r.resume_id, r.resume_name,
         r.payload_json, r.updated_at
  from public.app_profile_state ps
  join public.student_resumes r on r.uid = ps.uid
  where public.app_phase3_is_admin()
    and ps.student_id = p_student_id
    and r.deleted_at is null
  order by r.is_default desc, r.last_updated_ms desc, r.updated_at desc
  limit 1;
$$;

create or replace function public.api_resume_official_feedback_feed(p_limit integer default 50)
returns table (
  feedback_id text,
  message text,
  admin_name text,
  type text,
  source_timestamp timestamptz,
  meta_json jsonb
)
language sql stable security definer
set search_path = public
as $$
  with me as (select public.app_current_profile_uid() as uid)
  select f.feedback_id, f.message, f.admin_name, f.type,
         f.source_timestamp, f.meta_json
  from public.app_official_feedback f, me
  where f.uid = me.uid
  order by coalesce(f.source_timestamp, f.created_at) desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
$$;

create or replace function public.api_admin_send_resume_feedback(
  p_student_id text,
  p_resume_id text,
  p_message text,
  p_type text default 'RESUME'
)
returns text
language plpgsql security definer
set search_path = public
as $$
declare
  v_uid text;
  v_id text := gen_random_uuid()::text;
begin
  if not public.app_phase3_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  select ps.uid into v_uid from public.app_profile_state ps
  where ps.student_id = p_student_id limit 1;
  if v_uid is null then raise exception 'STUDENT_NOT_FOUND'; end if;

  insert into public.app_official_feedback(
    uid, feedback_id, message, admin_name, type, source_timestamp, meta_json
  ) values (
    v_uid, v_id, p_message, 'Admin', coalesce(nullif(p_type, ''), 'RESUME'),
    now(), jsonb_build_object('resume_id', coalesce(p_resume_id, ''))
  );
  return v_id;
end;
$$;

grant execute on function public.api_admin_student_resume_default(text) to authenticated;
grant execute on function public.api_resume_official_feedback_feed(integer) to authenticated;
grant execute on function public.api_admin_send_resume_feedback(text, text, text, text) to authenticated;

commit;
