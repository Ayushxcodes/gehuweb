-- Phase F1 / Chunk 06B Repair
-- Student feedback cycle feed without GROUP BY ambiguity.

begin;

create or replace function public.api_student_feedback_cycle_feed()
returns table (
  cycle_id text,
  cycle_name text,
  header_label text,
  entry_count integer,
  completed_count integer,
  incomplete_count integer,
  published_at timestamptz,
  expires_at timestamptz
)
language sql
stable
security invoker
set search_path = public
as $$
  with me as (select public.app_current_profile_uid() as uid),
  visible as (
    select c.*
    from public.feedback_cycles c
    where public.app_feedback_cycle_visible_to_current_user(c.cycle_id)
  )
  select
    c.cycle_id,
    c.cycle_name,
    c.header_label,
    c.entry_count,
    p.completed_count,
    greatest(c.entry_count - p.completed_count, 0) as incomplete_count,
    c.published_at,
    c.expires_at
  from visible c
  cross join me
  cross join lateral (
    select count(distinct s.entry_id)::integer as completed_count
    from public.feedback_submissions s
    where s.cycle_id = c.cycle_id
      and s.uid = me.uid
      and s.submitted = true
  ) p
  order by c.published_at desc nulls last, c.updated_at desc;
$$;

grant execute on function public.api_student_feedback_cycle_feed() to authenticated;

commit;
