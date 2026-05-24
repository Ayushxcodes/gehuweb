-- Phase A1 / Chunk 04
-- Public verification across event and generic achievement certificates.

begin;

create or replace function public.api_verify_certificate(p_verify_code text)
returns table (
  source text, certificate_id text, verify_code text, student_id text,
  student_name text, title text, certificate_type text,
  certificate_position text, certificate_version text, issued_at timestamptz
)
language sql stable security definer set search_path = public as $$
  with key as (select trim(coalesce(p_verify_code, '')) code), rows as (
    select 'EVENT'::text source, c.certificate_id, c.verify_code, c.student_id,
      c.student_name, coalesce(nullif(c.event_title, ''), c.event_id) title,
      c.status certificate_type, c.certificate_position,
      c.certificate_version, c.issued_at
    from public.event_certificates c, key where c.verify_code = key.code
    union all
    select g.category source, g.certificate_id, g.verify_code, g.student_id,
      coalesce(sc.stu_full_name, '') student_name, g.title,
      g.status certificate_type, g.certificate_position,
      g.certificate_version, g.issued_at
    from public.app_achievement_certificates g
    left join public.student_core sc on sc.stu_student_id = g.student_id, key
    where g.verify_code = key.code
  )
  select * from rows limit 1;
$$;

grant execute on function public.api_verify_certificate(text) to anon, authenticated;

commit;
