-- Phase F1 / Chunk 06
-- Student feedback cycle feed.

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
    count(distinct s.entry_id)::integer as completed_count,
    greatest(c.entry_count - count(distinct s.entry_id)::integer, 0) as incomplete_count,
    c.published_at,
    c.expires_at
  from visible c
  cross join me
  left join public.feedback_submissions s
    on s.cycle_id = c.cycle_id and s.uid = me.uid and s.submitted = true
  group by c.cycle_id, c.cycle_name, c.header_label, c.entry_count,
           c.published_at, c.expires_at, c.updated_at
  order by c.published_at desc nulls last, c.updated_at desc;
$$;

grant execute on function public.api_student_feedback_cycle_feed() to authenticated;

commit;
