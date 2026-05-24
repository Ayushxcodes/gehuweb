-- Phase E6 / Chunk 05
-- Event scanner admin RPCs.

begin;

create or replace function public.api_event_add_scanner(p_event_id text, p_student_id text)
returns table (event_id text, student_id text, added_at timestamptz)
language plpgsql security definer set search_path = public as $$
declare v_auth uuid := auth.uid(); v_student_auth uuid; v_now timestamptz := now();
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not public.app_event_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  if not exists (select 1 from public.event_core e where e.event_id = p_event_id) then raise exception 'EVENT_NOT_FOUND'; end if;
  select ai.auth_user_id into v_student_auth from public.app_user_identity ai
  where ai.student_id = p_student_id and ai.is_active = true limit 1;
  if v_student_auth is null then raise exception 'STUDENT_NOT_FOUND'; end if;
  insert into public.event_scanners(event_id, student_id, auth_user_id, added_by_auth_user_id, added_at)
  values (p_event_id, p_student_id, v_student_auth, v_auth, v_now)
  on conflict (event_id, student_id) do update set auth_user_id = excluded.auth_user_id,
    added_by_auth_user_id = excluded.added_by_auth_user_id, added_at = excluded.added_at;
  return query select p_event_id, p_student_id, v_now;
end;
$$;

create or replace function public.api_event_remove_scanner(p_event_id text, p_student_id text)
returns table (event_id text, student_id text, removed boolean)
language plpgsql security definer set search_path = public as $$
declare v_auth uuid := auth.uid();
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not public.app_event_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  delete from public.event_scanners s where s.event_id = p_event_id and s.student_id = p_student_id;
  return query select p_event_id, p_student_id, found;
end;
$$;

create or replace function public.api_event_scanner_page(p_event_id text)
returns table (student_id text, auth_user_id uuid, added_at timestamptz)
language sql stable security definer set search_path = public as $$
  select s.student_id, s.auth_user_id, s.added_at from public.event_scanners s
  where s.event_id = p_event_id and public.app_event_is_admin()
  order by s.added_at desc, s.student_id asc;
$$;

grant execute on function public.api_event_add_scanner(text,text) to authenticated;
grant execute on function public.api_event_remove_scanner(text,text) to authenticated;
grant execute on function public.api_event_scanner_page(text) to authenticated;

commit;
