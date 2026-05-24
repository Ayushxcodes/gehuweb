-- Phase R1 / Chunk 04
-- Student resume upsert RPC. JSON payload mirrors Android CVData.

begin;

create or replace function public.api_resume_upsert(
  p_resume_id text default null,
  p_payload jsonb default '{}'::jsonb,
  p_make_default boolean default false
)
returns table (resume_id text, is_default boolean, payload_json jsonb)
language plpgsql security definer
set search_path = public
as $$
declare
  v_uid text := public.app_current_profile_uid();
  v_auth uuid := auth.uid();
  v_student_id text;
  v_resume_id text;
  v_default boolean;
begin
  if v_uid is null then raise exception 'PROFILE_REQUIRED'; end if;
  select ai.student_id into v_student_id from public.app_user_identity ai
  where ai.auth_user_id = v_auth and ai.is_active = true limit 1;

  v_resume_id := coalesce(nullif(p_resume_id, ''),
    nullif(p_payload->>'id', ''), gen_random_uuid()::text);

  v_default := coalesce(p_make_default, false) or not exists (
    select 1 from public.student_resumes
    where uid = v_uid and deleted_at is null
  ) or exists (
    select 1 from public.student_resumes
    where uid = v_uid and resume_id = v_resume_id
      and is_default = true and deleted_at is null
  );

  insert into public.student_resume_profile(uid, auth_user_id, student_id, default_resume_id)
  values (v_uid, v_auth, v_student_id, case when v_default then v_resume_id else '' end)
  on conflict (uid) do update set
    auth_user_id = excluded.auth_user_id,
    student_id = excluded.student_id,
    default_resume_id = case when v_default then v_resume_id
      else public.student_resume_profile.default_resume_id end;

  if v_default then
    update public.student_resumes
    set is_default = false
    where uid = v_uid and deleted_at is null;
  end if;

  insert into public.student_resumes (
    uid, resume_id, auth_user_id, student_id, resume_name, template_id,
    is_default, last_updated_ms, domain, target_role, experience_level,
    strictness_mode, full_name, email, phone, payload_json
  ) values (
    v_uid, v_resume_id, v_auth, v_student_id,
    coalesce(nullif(p_payload->>'resumeName', ''), 'My Resume'),
    coalesce(nullif(p_payload->>'templateId', ''), 'classic'),
    v_default, coalesce(nullif(p_payload->>'lastUpdated', '')::bigint, 0),
    coalesce(nullif(p_payload->>'domain', ''), 'Tech'),
    coalesce(p_payload->>'targetRole', ''),
    coalesce(nullif(p_payload->>'experienceLevel', ''), 'Fresher'),
    coalesce(nullif(p_payload->>'strictnessMode', ''), 'Product'),
    coalesce(p_payload->>'fullName', ''),
    coalesce(p_payload->>'email', ''),
    coalesce(p_payload->>'phone', ''),
    coalesce(p_payload, '{}'::jsonb) || jsonb_build_object('id', v_resume_id)
  )
  on conflict (uid, resume_id) do update set
    resume_name = excluded.resume_name,
    template_id = excluded.template_id,
    is_default = excluded.is_default,
    last_updated_ms = excluded.last_updated_ms,
    domain = excluded.domain,
    target_role = excluded.target_role,
    experience_level = excluded.experience_level,
    strictness_mode = excluded.strictness_mode,
    full_name = excluded.full_name,
    email = excluded.email,
    phone = excluded.phone,
    payload_json = excluded.payload_json,
    deleted_at = null;

  return query select r.resume_id, r.is_default, r.payload_json
  from public.student_resumes r where r.uid = v_uid and r.resume_id = v_resume_id;
end;
$$;

grant execute on function public.api_resume_upsert(text, jsonb, boolean) to authenticated;

commit;
