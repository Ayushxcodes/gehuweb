-- Phase F1 / Chunk 04
-- RLS for feedback tables.

begin;

do $$
declare
  t text;
begin
  for t in select unnest(array[
    'feedback_templates','feedback_template_questions','feedback_teachers',
    'feedback_cycles','feedback_cycle_entries','feedback_cycle_entry_questions',
    'feedback_submissions','feedback_responses'
  ])
  loop
    execute format('grant select, insert, update, delete on table public.%I to authenticated', t);
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

create or replace function public.app_feedback_cycle_visible_to_current_user(p_cycle_id text)
returns boolean
language sql
stable
set search_path = public
as $$
  with ps as (
    select p.course, p.branch, p.semester
    from public.app_profile_state p
    where p.uid = public.app_current_profile_uid()
    limit 1
  ),
  keys as (
    select public.app_normalize_target_key(k) as key
    from ps, unnest(array[
      'all_students',
      ps.course,
      ps.branch,
      case when ps.semester is not null then 'sem' || ps.semester::text else '' end,
      case when coalesce(ps.course,'') <> '' and ps.semester is not null
        then ps.course || '_sem' || ps.semester::text else '' end
    ]) as u(k)
  )
  select exists (
    select 1
    from public.feedback_cycles c
    where c.cycle_id = p_cycle_id
      and c.status = 'PUBLISHED'
      and c.active = true
      and (c.expires_at is null or c.expires_at > now())
      and public.app_normalize_target_key(c.target_key) in (select key from keys where key <> '')
  );
$$;

grant execute on function public.app_feedback_cycle_visible_to_current_user(text) to authenticated;

commit;
