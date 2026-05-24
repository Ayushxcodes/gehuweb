-- Phase E2 / Chunk 03
-- Student state snapshot for one event.

begin;

create or replace function public.api_event_my_state(p_event_id text)
returns table (
  registrations_json jsonb,
  teams_json jsonb,
  invites_json jsonb,
  payments_json jsonb,
  certificates_json jsonb
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    coalesce((select jsonb_agg(to_jsonb(r) order by r.registered_at desc)
      from public.event_registrations r
      where r.event_id = p_event_id
        and r.student_id = public.app_event_current_student_id()), '[]'::jsonb),
    coalesce((select jsonb_agg(to_jsonb(t) order by t.created_at desc)
      from public.event_teams t
      where t.event_id = p_event_id
        and public.app_event_is_team_member(t.event_id, t.comp_id, t.team_id)), '[]'::jsonb),
    coalesce((select jsonb_agg(to_jsonb(i) order by i.created_at desc)
      from public.event_team_invites i
      where i.event_id = p_event_id
        and i.student_id = public.app_event_current_student_id()), '[]'::jsonb),
    coalesce((select jsonb_agg(to_jsonb(p) order by p.updated_at desc)
      from public.event_payment_records p
      where p.event_id = p_event_id
        and p.student_id = public.app_event_current_student_id()), '[]'::jsonb),
    coalesce((select jsonb_agg(to_jsonb(c) order by c.issued_at desc)
      from public.event_certificates c
      where c.event_id = p_event_id
        and c.student_id = public.app_event_current_student_id()), '[]'::jsonb);
$$;

grant execute on function public.api_event_my_state(text) to authenticated;

commit;
