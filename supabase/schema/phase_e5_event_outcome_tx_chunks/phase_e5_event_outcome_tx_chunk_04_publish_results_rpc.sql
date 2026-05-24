-- Phase E5 / Chunk 04
-- Admin RPC: publish competition results atomically.

begin;

create or replace function public.api_event_publish_results(
  p_event_id text, p_comp_id text, p_assignments jsonb default '[]'::jsonb
)
returns table (event_id text, comp_id text, result_rows integer, published_at timestamptz)
language plpgsql security definer set search_path = public as $$
declare
  v_auth uuid := auth.uid(); v_comp public.event_competitions%rowtype;
  v_w integer; v_r integer; v_s integer; v_bad integer; v_rows integer; v_now timestamptz := now();
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not public.app_event_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  if jsonb_typeof(coalesce(p_assignments, '[]'::jsonb)) <> 'array' then raise exception 'ASSIGNMENTS_MUST_BE_ARRAY'; end if;

  select * into v_comp from public.event_competitions
  where event_id = p_event_id and comp_id = p_comp_id for update;
  if not found then raise exception 'COMPETITION_NOT_FOUND'; end if;
  if v_comp.results_published then raise exception 'RESULTS_ALREADY_PUBLISHED'; end if;

  with a as (select upper(trim(x.value->>'status')) st from jsonb_array_elements(p_assignments) x)
  select count(*) filter (where st = 'WINNER'), count(*) filter (where st = 'RUNNER_UP'),
         count(*) filter (where st = 'SECOND_RUNNER_UP') into v_w, v_r, v_s from a;
  if coalesce(v_w,0) > 1 then raise exception 'ONLY_ONE_WINNER_ALLOWED'; end if;
  if coalesce(v_r,0) > 1 then raise exception 'ONLY_ONE_RUNNER_UP_ALLOWED'; end if;
  if coalesce(v_s,0) > 1 then raise exception 'ONLY_ONE_SECOND_RUNNER_UP_ALLOWED'; end if;
  if coalesce(v_w,0) + coalesce(v_r,0) + coalesce(v_s,0) = 0 then raise exception 'AT_LEAST_ONE_RANK_REQUIRED'; end if;

  with a as (select trim(x.value->>'team_id') team_id, upper(trim(x.value->>'status')) st
    from jsonb_array_elements(p_assignments) x)
  select count(*) into v_bad from a
  left join public.event_attendance ea on ea.event_id = p_event_id and ea.comp_id = p_comp_id
    and ea.team_id = a.team_id and ea.status <> 'ABSENT'
  where a.st not in ('WINNER','RUNNER_UP','SECOND_RUNNER_UP','PARTICIPANT') or ea.team_id is null;
  if v_bad > 0 then raise exception 'INVALID_RESULT_ASSIGNMENT'; end if;

  with a as (
    select trim(x.value->>'team_id') team_id, upper(trim(x.value->>'status')) st,
      nullif(x.value->>'score','')::numeric score, nullif(x.value->>'max_score','')::numeric max_score
    from jsonb_array_elements(p_assignments) x
  ), eligible as (
    select t.*, ea.status attendance_status, ea.present_count, ea.total_members,
      coalesce(a.st, 'PARTICIPANT') result_status, a.score, a.max_score
    from public.event_teams t join public.event_attendance ea
      on ea.event_id=t.event_id and ea.comp_id=t.comp_id and ea.team_id=t.team_id
    left join a on a.team_id=t.team_id
    where t.event_id=p_event_id and t.comp_id=p_comp_id and t.active=true and ea.status <> 'ABSENT'
  )
  insert into public.event_results(event_id, comp_id, team_id, status, rank_no, score, max_score,
    members_json, published, published_at, payload_json, updated_at)
  select p_event_id, p_comp_id, e.team_id, e.result_status,
    public.app_event_rank_from_status(e.result_status), e.score, e.max_score,
    (select jsonb_agg(jsonb_build_object('student_id', m.student_id, 'role', m.role) order by m.role, m.student_id)
      from public.event_team_members m where m.event_id=e.event_id and m.comp_id=e.comp_id and m.team_id=e.team_id),
    true, v_now,
    jsonb_build_object('team_name', e.team_name, 'participant_type', e.participant_type,
      'attendance_status', e.attendance_status, 'present_count', e.present_count, 'total_members', e.total_members),
    v_now
  from eligible e
  on conflict (event_id, comp_id, team_id) do update set
    status=excluded.status, rank_no=excluded.rank_no, score=excluded.score,
    max_score=excluded.max_score, members_json=excluded.members_json,
    published=true, published_at=excluded.published_at, payload_json=excluded.payload_json, updated_at=v_now;
  get diagnostics v_rows = row_count;
  if v_rows = 0 then raise exception 'NO_ATTENDED_TEAMS'; end if;

  update public.event_competitions set results_published=true, results_locked_at=v_now
  where event_id=p_event_id and comp_id=p_comp_id;
  return query select p_event_id, p_comp_id, v_rows, v_now;
end;
$$;

grant execute on function public.api_event_publish_results(text,text,jsonb) to authenticated;

commit;
