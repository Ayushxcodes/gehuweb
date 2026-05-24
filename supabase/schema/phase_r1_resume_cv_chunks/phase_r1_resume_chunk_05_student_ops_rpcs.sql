-- Phase R1 / Chunk 05
-- Student default/delete operations.

begin;

create or replace function public.api_resume_set_default(p_resume_id text)
returns boolean
language plpgsql security definer
set search_path = public
as $$
declare
  v_uid text := public.app_current_profile_uid();
begin
  if v_uid is null then raise exception 'PROFILE_REQUIRED'; end if;
  if not exists (
    select 1 from public.student_resumes
    where uid = v_uid and resume_id = p_resume_id and deleted_at is null
  ) then raise exception 'RESUME_NOT_FOUND'; end if;

  update public.student_resumes set is_default = false
  where uid = v_uid and deleted_at is null;
  update public.student_resumes set is_default = true
  where uid = v_uid and resume_id = p_resume_id and deleted_at is null;

  insert into public.student_resume_profile(uid, auth_user_id, student_id, default_resume_id)
  select v_uid, auth.uid(), ai.student_id, p_resume_id
  from public.app_user_identity ai
  where ai.auth_user_id = auth.uid() and ai.is_active = true limit 1
  on conflict (uid) do update set default_resume_id = excluded.default_resume_id;

  return true;
end;
$$;

create or replace function public.api_resume_delete(p_resume_id text)
returns boolean
language plpgsql security definer
set search_path = public
as $$
declare
  v_uid text := public.app_current_profile_uid();
  v_next text;
begin
  if v_uid is null then raise exception 'PROFILE_REQUIRED'; end if;

  update public.student_resumes
  set deleted_at = now(), is_default = false
  where uid = v_uid and resume_id = p_resume_id and deleted_at is null;

  select r.resume_id into v_next
  from public.student_resumes r
  where r.uid = v_uid and r.deleted_at is null
  order by r.last_updated_ms desc, r.updated_at desc
  limit 1;

  if v_next is not null then
    update public.student_resumes
    set is_default = (resume_id = v_next)
    where uid = v_uid and deleted_at is null;
  end if;

  update public.student_resume_profile
  set default_resume_id = coalesce(v_next, '')
  where uid = v_uid;

  return true;
end;
$$;

grant execute on function public.api_resume_set_default(text) to authenticated;
grant execute on function public.api_resume_delete(text) to authenticated;

commit;
