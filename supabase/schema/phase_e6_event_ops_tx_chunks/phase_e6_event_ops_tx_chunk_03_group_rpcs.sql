-- Phase E6 / Chunk 03
-- Group channel/member sync and message RPCs.

begin;

create or replace function public.api_event_sync_group_members(p_event_id text, p_comp_id text)
returns table (event_id text, comp_id text, member_rows integer)
language plpgsql security definer set search_path = public as $$
declare v_auth uuid := auth.uid(); v_rows integer;
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not public.app_event_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;

  insert into public.event_group_channels(event_id, comp_id, group_id, active, member_student_ids)
  values (p_event_id, p_comp_id, 'main', true, '{}'::text[])
  on conflict (event_id, comp_id, group_id) do update set active = true, updated_at = now();

  insert into public.event_group_members(event_id, comp_id, group_id, student_id, role, status)
  select p_event_id, p_comp_id, 'main', r.student_id, r.role, 'ACTIVE'
  from public.event_registrations r
  where r.event_id = p_event_id and r.comp_id = p_comp_id
    and public.app_event_is_visible_registration_status(r.status)
  on conflict (event_id, comp_id, group_id, student_id) do update set status = 'ACTIVE';
  get diagnostics v_rows = row_count;

  update public.event_group_channels gc set member_student_ids = coalesce((
    select array_agg(gm.student_id order by gm.student_id)
    from public.event_group_members gm
    where gm.event_id = p_event_id and gm.comp_id = p_comp_id
      and gm.group_id = 'main' and gm.status = 'ACTIVE'), '{}'::text[]), updated_at = now()
  where gc.event_id = p_event_id and gc.comp_id = p_comp_id and gc.group_id = 'main';

  return query select p_event_id, p_comp_id, v_rows;
end;
$$;

create or replace function public.api_event_send_group_message(
  p_event_id text, p_comp_id text, p_text text, p_type text default 'TEXT'
)
returns table (message_id text, sent_at timestamptz)
language plpgsql security definer set search_path = public as $$
declare v_auth uuid := auth.uid(); v_id text; v_now timestamptz := now(); v_name text; v_role text;
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not public.app_event_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  if length(trim(coalesce(p_text, ''))) = 0 then raise exception 'MESSAGE_REQUIRED'; end if;
  v_id := 'msg_' || substr(md5(v_auth::text || clock_timestamp()::text || random()::text), 1, 24);
  select coalesce(ec.emp_full_name, ai.account_type), ai.account_type into v_name, v_role
  from public.app_user_identity ai left join public.employee_core ec on ec.emp_employee_id = ai.employee_id
  where ai.auth_user_id = v_auth and ai.is_active = true limit 1;
  insert into public.event_group_messages(event_id, comp_id, group_id, message_id,
    sender_name, sender_role, text, type, sent_at, payload_json)
  values (p_event_id, p_comp_id, 'main', v_id, coalesce(v_name, 'Admin'), coalesce(v_role, 'ADMIN'),
    trim(p_text), case when upper(p_type) = 'SYSTEM' then 'SYSTEM' else 'TEXT' end, v_now,
    jsonb_build_object('sender_auth_user_id', v_auth));
  return query select v_id, v_now;
end;
$$;

grant execute on function public.api_event_sync_group_members(text,text) to authenticated;
grant execute on function public.api_event_send_group_message(text,text,text,text) to authenticated;

commit;
