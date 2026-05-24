-- Phase E1 / Chunk 10A
-- Student event feed + public certificate verification.

begin;

create or replace function public.api_student_event_feed(
  p_limit integer default 25,
  p_before_start_at timestamptz default null,
  p_before_event_id text default null
)
returns table (
  event_id text, title text, subtitle text, banner_url text,
  event_type text, start_at timestamptz, end_at timestamptz,
  registration_deadline timestamptz, venue text,
  competitions_count integer, my_status text
)
language sql
stable
security invoker
set search_path = public
as $$
  with safe_limit as (select greatest(1, least(coalesce(p_limit, 25), 50)) as lim)
  select e.event_id, e.title, e.subtitle, e.banner_url, e.event_type,
         e.start_at, e.end_at, e.registration_deadline, e.venue,
         e.competitions_count,
         coalesce(r.my_status, '') as my_status
  from public.event_core e
  cross join safe_limit
  left join lateral (
    select string_agg(distinct r.status, ',' order by r.status) as my_status
    from public.event_registrations r
    where r.event_id = e.event_id
      and r.student_id = public.app_event_current_student_id()
  ) r on true
  where public.app_event_visible(e.event_id)
    and (
      p_before_start_at is null
      or e.start_at < p_before_start_at
      or (e.start_at = p_before_start_at and e.event_id < coalesce(p_before_event_id, ''))
    )
  order by e.start_at desc nulls last, e.event_id desc
  limit (select lim from safe_limit);
$$;

create or replace function public.api_verify_event_certificate(p_verify_code text)
returns table (
  certificate_id text,
  verify_code text,
  event_id text,
  comp_id text,
  team_id text,
  student_name text,
  status text,
  certificate_position text,
  certificate_version text,
  issued_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select c.certificate_id, c.verify_code, c.event_id, c.comp_id, c.team_id,
         c.student_name, c.status, c.certificate_position,
         c.certificate_version, c.issued_at
  from public.event_certificates c
  where c.verify_code = trim(coalesce(p_verify_code, ''))
  limit 1;
$$;

grant execute on function public.api_student_event_feed(integer,timestamptz,text) to authenticated;
grant execute on function public.api_verify_event_certificate(text) to anon, authenticated;

commit;
