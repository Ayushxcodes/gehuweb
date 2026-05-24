-- Phase E5 / Chunk 03
-- Admin RPC: paged attendance view for a competition.

begin;

create or replace function public.api_event_admin_attendance_page(
  p_event_id text, p_comp_id text
)
returns table (
  team_id text, team_name text, participant_type text, team_status text,
  attendance_status text, present_count integer, total_members integer,
  present_student_ids text[], absent_student_ids text[], marked_at timestamptz
)
language sql stable security definer set search_path = public as $$
  select t.team_id, t.team_name, t.participant_type, t.team_status,
         coalesce(a.status, '') as attendance_status,
         coalesce(a.present_count, 0) as present_count,
         coalesce(a.total_members, 0) as total_members,
         coalesce(a.present_student_ids, '{}'::text[]) as present_student_ids,
         coalesce(a.absent_student_ids, '{}'::text[]) as absent_student_ids,
         a.marked_at
  from public.event_teams t
  left join public.event_attendance a
    on a.event_id = t.event_id and a.comp_id = t.comp_id and a.team_id = t.team_id
  where public.app_event_is_admin()
    and t.event_id = p_event_id and t.comp_id = p_comp_id
    and t.active = true
  order by coalesce(a.marked_at, t.created_at) desc, t.team_name asc, t.team_id asc;
$$;

grant execute on function public.api_event_admin_attendance_page(text,text) to authenticated;

commit;
