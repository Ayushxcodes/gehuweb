-- Phase F1 / Chunk 07
-- Student feedback cycle detail as nested JSON.

begin;

create or replace function public.api_student_feedback_cycle_detail(p_cycle_id text)
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
  select case
    when not public.app_feedback_cycle_visible_to_current_user(p_cycle_id) then null
    else jsonb_build_object(
      'cycle', to_jsonb(c),
      'entries', coalesce((
        select jsonb_agg(
          to_jsonb(e) || jsonb_build_object('questions', coalesce((
            select jsonb_agg(to_jsonb(q) order by q.position)
            from public.feedback_cycle_entry_questions q
            where q.cycle_id = e.cycle_id and q.entry_id = e.entry_id
          ), '[]'::jsonb))
          order by e.position
        )
        from public.feedback_cycle_entries e
        where e.cycle_id = c.cycle_id
      ), '[]'::jsonb)
    )
  end
  from public.feedback_cycles c
  where c.cycle_id = p_cycle_id;
$$;

grant execute on function public.api_student_feedback_cycle_detail(text) to authenticated;

commit;
