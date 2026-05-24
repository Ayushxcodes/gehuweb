-- Phase E5 / Chunk 02
-- Admin RPC: mark team attendance atomically.

begin;

create or replace function public.api_event_mark_team_attendance(
  p_event_id text, p_comp_id text, p_team_id text,
  p_present_student_ids text[] default '{}'::text[]
)
returns table (event_id text, comp_id text, team_id text, status text,
  present_count integer, total_members integer)
language plpgsql security definer set search_path = public as $$
declare
  v_auth uuid := auth.uid(); v_team public.event_teams%rowtype;
  v_all text[]; v_present text[]; v_absent text[]; v_invalid integer; v_status text;
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not public.app_event_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;

  select * into v_team from public.event_teams
  where event_id = p_event_id and comp_id = p_comp_id and team_id = p_team_id for update;
  if not found then raise exception 'TEAM_NOT_FOUND'; end if;

  select coalesce(array_agg(m.student_id order by m.student_id), '{}'::text[])
    into v_all from public.event_team_members m
  where m.event_id = p_event_id and m.comp_id = p_comp_id
    and m.team_id = p_team_id and m.status = 'ACTIVE';
  if cardinality(v_all) = 0 then raise exception 'TEAM_HAS_NO_ACTIVE_MEMBERS'; end if;

  v_present := array(select distinct x from unnest(coalesce(p_present_student_ids, '{}'::text[])) x);
  select count(*) into v_invalid from unnest(v_present) x where not (x = any(v_all));
  if v_invalid > 0 then raise exception 'ATTENDANCE_HAS_NON_MEMBER_STUDENT'; end if;
  v_absent := array(select x from unnest(v_all) x where not (x = any(v_present)));
  v_status := case when cardinality(v_present) = 0 then 'ABSENT'
                   when cardinality(v_present) = cardinality(v_all) then 'FULL'
                   else 'PARTIAL' end;

  insert into public.event_attendance(event_id, comp_id, team_id, team_name, status,
    present_count, total_members, marked_by_auth_user_id, marked_at,
    present_student_ids, absent_student_ids)
  values (p_event_id, p_comp_id, p_team_id, v_team.team_name, v_status,
    cardinality(v_present), cardinality(v_all), v_auth, now(), v_present, v_absent)
  on conflict (event_id, comp_id, team_id) do update set
    team_name = excluded.team_name, status = excluded.status,
    present_count = excluded.present_count, total_members = excluded.total_members,
    marked_by_auth_user_id = excluded.marked_by_auth_user_id, marked_at = now(),
    present_student_ids = excluded.present_student_ids,
    absent_student_ids = excluded.absent_student_ids;

  delete from public.event_attendance_members
  where event_attendance_members.event_id = p_event_id
    and event_attendance_members.comp_id = p_comp_id
    and event_attendance_members.team_id = p_team_id;
  insert into public.event_attendance_members(event_id, comp_id, team_id, student_id, present, marked_at)
  select p_event_id, p_comp_id, p_team_id, x, x = any(v_present), now() from unnest(v_all) x;

  return query select p_event_id, p_comp_id, p_team_id, v_status,
    cardinality(v_present)::integer, cardinality(v_all)::integer;
end;
$$;

grant execute on function public.api_event_mark_team_attendance(text,text,text,text[]) to authenticated;

commit;
