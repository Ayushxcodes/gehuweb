-- Phase E5 / Chunk 05
-- Admin certificate record write + student certificate feed.

begin;

create or replace function public.api_event_issue_certificate_record(
  p_certificate_id text, p_verify_code text, p_event_id text, p_comp_id text,
  p_team_id text, p_student_id text, p_student_name text, p_status text,
  p_certificate_position text, p_storage_url text, p_storage_object_key text,
  p_certificate_version text default '', p_payload_json jsonb default '{}'::jsonb
)
returns table (certificate_id text, verify_code text, issued_at timestamptz)
language plpgsql security definer set search_path = public as $$
declare
  v_auth uuid := auth.uid(); v_now timestamptz := now(); v_event_title text; v_comp_name text; v_student_auth uuid;
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not public.app_event_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  if coalesce(trim(p_certificate_id),'') = '' then raise exception 'CERTIFICATE_ID_REQUIRED'; end if;
  if coalesce(trim(p_verify_code),'') = '' then raise exception 'VERIFY_CODE_REQUIRED'; end if;
  if not exists (select 1 from public.event_results r where r.event_id=p_event_id
    and r.comp_id=p_comp_id and r.team_id=p_team_id and r.published=true)
  then raise exception 'PUBLISHED_RESULT_REQUIRED'; end if;

  select e.title, c.competition_name into v_event_title, v_comp_name
  from public.event_core e join public.event_competitions c on c.event_id=e.event_id
  where e.event_id=p_event_id and c.comp_id=p_comp_id;
  select ai.auth_user_id into v_student_auth from public.app_user_identity ai
  where ai.student_id=p_student_id and ai.is_active=true limit 1;

  insert into public.event_certificates(certificate_id, verify_code, event_id, comp_id, team_id,
    student_id, auth_user_id, student_name, status, certificate_position, storage_url,
    storage_object_key, certificate_version, event_title, competition_name, issued_at, payload_json)
  values (trim(p_certificate_id), trim(p_verify_code), p_event_id, p_comp_id, p_team_id,
    p_student_id, v_student_auth, coalesce(p_student_name,''), upper(coalesce(p_status,'PARTICIPANT')),
    coalesce(p_certificate_position,''), coalesce(p_storage_url,''), coalesce(p_storage_object_key,''),
    coalesce(p_certificate_version,''), coalesce(v_event_title,''), coalesce(v_comp_name,''), v_now,
    coalesce(p_payload_json,'{}'::jsonb))
  on conflict (certificate_id) do update set
    storage_url=excluded.storage_url, storage_object_key=excluded.storage_object_key,
    certificate_version=excluded.certificate_version, payload_json=excluded.payload_json;

  return query select trim(p_certificate_id), trim(p_verify_code), v_now;
end;
$$;

create or replace function public.api_event_my_certificates(p_limit integer default 50)
returns setof public.event_certificates
language sql stable security definer set search_path = public as $$
  select c.* from public.event_certificates c
  where c.student_id = public.app_event_current_student_id()
  order by c.issued_at desc limit greatest(1, least(coalesce(p_limit, 50), 100));
$$;

grant execute on function public.api_event_issue_certificate_record(text,text,text,text,text,text,text,text,text,text,text,text,jsonb) to authenticated;
grant execute on function public.api_event_my_certificates(integer) to authenticated;

commit;
