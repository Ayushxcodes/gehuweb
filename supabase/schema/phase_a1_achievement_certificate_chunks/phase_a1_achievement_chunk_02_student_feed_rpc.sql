-- Phase A1 / Chunk 02
-- Student achievement certificate feed across EVENT/COURSE/OTHER.

begin;

create or replace function public.api_student_achievement_certificates(
  p_category text default 'EVENT', p_limit integer default 50
)
returns table (
  tab_type text, certificate_id text, verify_code text,
  event_id text, comp_id text, team_id text, event_title text,
  certificate_type text, certificate_position text,
  storage_path text, storage_url text, certificate_version text,
  issued_at timestamptz, has_cert boolean, payload_json jsonb
)
language sql stable security definer set search_path = public as $$
  with me as (select public.app_event_current_student_id() student_id),
  safe as (select upper(coalesce(nullif(trim(p_category), ''), 'EVENT')) cat,
    greatest(1, least(coalesce(p_limit, 50), 100)) lim),
  rows as (
    select 'EVENT'::text tab_type, c.certificate_id, c.verify_code,
      c.event_id, c.comp_id, c.team_id,
      coalesce(nullif(c.event_title, ''), nullif(c.competition_name, ''), c.event_id) event_title,
      c.status certificate_type, c.certificate_position,
      c.storage_object_key storage_path, c.storage_url, c.certificate_version,
      c.issued_at, (coalesce(c.storage_object_key, '') <> '') has_cert, c.payload_json
    from public.event_certificates c, me, safe
    where c.student_id = me.student_id and safe.cat in ('ALL','EVENT')
    union all
    select g.category tab_type, g.certificate_id, g.verify_code,
      ''::text event_id, ''::text comp_id, ''::text team_id,
      g.title event_title, g.status certificate_type, g.certificate_position,
      g.storage_object_key storage_path, g.storage_url, g.certificate_version,
      g.issued_at, (coalesce(g.storage_object_key, '') <> '') has_cert, g.payload_json
    from public.app_achievement_certificates g, me, safe
    where g.student_id = me.student_id and safe.cat in ('ALL', g.category)
  )
  select * from rows order by issued_at desc limit (select lim from safe);
$$;

grant execute on function public.api_student_achievement_certificates(text,integer) to authenticated;

commit;
