-- Phase E5 / Chunk 01
-- Event outcome support columns, indexes, and helper.

begin;

alter table public.event_competitions
  add column if not exists attendance_open boolean not null default false,
  add column if not exists attendance_locked boolean not null default false,
  add column if not exists results_locked_at timestamptz;

alter table public.event_attendance
  add column if not exists team_name text not null default '',
  add column if not exists present_student_ids text[] not null default '{}'::text[],
  add column if not exists absent_student_ids text[] not null default '{}'::text[];

alter table public.event_certificates
  add column if not exists auth_user_id uuid references auth.users(id) on delete set null,
  add column if not exists event_title text not null default '',
  add column if not exists competition_name text not null default '';

create index if not exists idx_event_attendance_comp_status
  on public.event_attendance(event_id, comp_id, status);

create index if not exists idx_event_results_comp_rank
  on public.event_results(event_id, comp_id, published, rank_no, team_id);

create or replace function public.app_event_rank_from_status(p_status text)
returns integer language sql immutable as $$
  select case upper(coalesce(p_status, ''))
    when 'WINNER' then 1
    when 'RUNNER_UP' then 2
    when 'SECOND_RUNNER_UP' then 3
    else 0
  end;
$$;

grant execute on function public.app_event_rank_from_status(text) to authenticated;

commit;
