-- Phase A1 / Chunk 03
-- Admin RPC: issue COURSE/OTHER/ACHIEVEMENT certificate row after R2 upload.

begin;

create or replace function public.api_admin_issue_achievement_certificate(
  p_certificate_id text, p_verify_code text, p_student_id text,
  p_category text, p_title text, p_storage_object_key text,
  p_storage_url text default '', p_issuer_name text default '',
  p_description text default '', p_status text default 'VERIFIED',
  p_certificate_position text default '', p_certificate_version text default '',
  p_payload_json jsonb default '{}'::jsonb
)
returns table (certificate_id text, verify_code text, student_id text, issued_at timestamptz)
language plpgsql security definer set search_path = public as $$
declare
  v_auth uuid := auth.uid(); v_student_auth uuid; v_now timestamptz := now(); v_category text;
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not public.app_event_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  v_category := upper(coalesce(nullif(trim(p_category), ''), 'OTHER'));
  if v_category not in ('COURSE','OTHER','ACHIEVEMENT') then raise exception 'INVALID_CATEGORY'; end if;
  if coalesce(trim(p_storage_object_key), '') = '' then raise exception 'STORAGE_OBJECT_KEY_REQUIRED'; end if;
  select ai.auth_user_id into v_student_auth from public.app_user_identity ai
  where ai.student_id = p_student_id and ai.is_active = true limit 1;
  if v_student_auth is null then raise exception 'STUDENT_NOT_FOUND'; end if;

  insert into public.app_achievement_certificates(certificate_id, verify_code, student_id,
    auth_user_id, category, title, issuer_name, description, status, certificate_position,
    storage_url, storage_object_key, certificate_version, created_by_auth_user_id,
    issued_at, payload_json)
  values (trim(p_certificate_id), trim(p_verify_code), p_student_id, v_student_auth,
    v_category, trim(p_title), coalesce(p_issuer_name, ''), coalesce(p_description, ''),
    upper(coalesce(p_status, 'VERIFIED')), coalesce(p_certificate_position, ''),
    coalesce(p_storage_url, ''), trim(p_storage_object_key), coalesce(p_certificate_version, ''),
    v_auth, v_now, coalesce(p_payload_json, '{}'::jsonb))
  on conflict (certificate_id) do update set
    title = excluded.title, issuer_name = excluded.issuer_name,
    description = excluded.description, status = excluded.status,
    certificate_position = excluded.certificate_position,
    storage_url = excluded.storage_url, storage_object_key = excluded.storage_object_key,
    certificate_version = excluded.certificate_version, payload_json = excluded.payload_json;

  return query select trim(p_certificate_id), trim(p_verify_code), p_student_id, v_now;
end;
$$;

grant execute on function public.api_admin_issue_achievement_certificate(text,text,text,text,text,text,text,text,text,text,text,text,jsonb) to authenticated;

commit;
