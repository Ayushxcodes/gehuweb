-- Phase E1 / Chunk 10B
-- Rich student event detail RPC.

begin;

create or replace function public.api_student_event_detail(p_event_id text)
returns table (
  event_json jsonb,
  competitions_json jsonb,
  schedule_json jsonb,
  announcements_json jsonb,
  my_registrations_json jsonb,
  my_teams_json jsonb,
  my_invites_json jsonb,
  my_payments_json jsonb,
  my_results_json jsonb,
  my_certificates_json jsonb
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    to_jsonb(e) as event_json,
    coalesce((select jsonb_agg(to_jsonb(c) order by c.created_at, c.comp_id)
      from public.event_competitions c
      where c.event_id = e.event_id), '[]'::jsonb) as competitions_json,
    coalesce((select jsonb_agg(to_jsonb(s) order by s.stage_order, s.created_at)
      from public.event_schedule_stages s
      where s.event_id = e.event_id and s.is_public = true), '[]'::jsonb) as schedule_json,
    coalesce((select jsonb_agg(to_jsonb(a) order by a.sent_at desc)
      from public.event_announcements a
      where a.event_id = e.event_id), '[]'::jsonb) as announcements_json,
    coalesce((select jsonb_agg(to_jsonb(r) order by r.registered_at desc)
      from public.event_registrations r
      where r.event_id = e.event_id
        and r.student_id = public.app_event_current_student_id()), '[]'::jsonb) as my_registrations_json,
    coalesce((select jsonb_agg(to_jsonb(t) order by t.created_at desc)
      from public.event_teams t
      where t.event_id = e.event_id
        and public.app_event_is_team_member(t.event_id, t.comp_id, t.team_id)), '[]'::jsonb) as my_teams_json,
    coalesce((select jsonb_agg(to_jsonb(i) order by i.created_at desc)
      from public.event_team_invites i
      where i.event_id = e.event_id
        and i.student_id = public.app_event_current_student_id()), '[]'::jsonb) as my_invites_json,
    coalesce((select jsonb_agg(to_jsonb(p) order by p.updated_at desc)
      from public.event_payment_records p
      where p.event_id = e.event_id
        and p.student_id = public.app_event_current_student_id()), '[]'::jsonb) as my_payments_json,
    coalesce((select jsonb_agg(to_jsonb(res) order by res.rank_no, res.team_id)
      from public.event_results res
      where res.event_id = e.event_id
        and res.published = true
        and public.app_event_is_team_member(res.event_id, res.comp_id, res.team_id)), '[]'::jsonb) as my_results_json,
    coalesce((select jsonb_agg(to_jsonb(cert) order by cert.issued_at desc)
      from public.event_certificates cert
      where cert.event_id = e.event_id
        and cert.student_id = public.app_event_current_student_id()), '[]'::jsonb) as my_certificates_json
  from public.event_core e
  where e.event_id = p_event_id
    and public.app_event_visible(e.event_id);
$$;

grant execute on function public.api_student_event_detail(text) to authenticated;

commit;
