-- Phase E2 / Chunk 01
-- Registration transaction support columns.

begin;

alter table public.event_competitions
  add column if not exists min_members integer not null default 1
    check (min_members between 1 and 50);

alter table public.event_competitions
  add column if not exists max_participants integer
    check (max_participants is null or max_participants >= 0);

alter table public.event_competitions
  add column if not exists max_teams integer
    check (max_teams is null or max_teams >= 0);

alter table public.event_competitions
  add column if not exists categories text[] not null default '{}'::text[];

alter table public.event_competitions
  add column if not exists reg_count integer not null default 0
    check (reg_count >= 0);

alter table public.event_registrations
  add column if not exists invited_by_student_id text
    references public.student_core(stu_student_id) on delete set null;

alter table public.event_registrations
  add column if not exists accepted_at timestamptz;

alter table public.event_registrations
  add column if not exists cancelled_at timestamptz;

alter table public.event_registrations
  add column if not exists previous_status text not null default '';

create index if not exists idx_event_competitions_reg_count
  on public.event_competitions(event_id, comp_id, reg_count);

create index if not exists idx_event_registrations_auth_user
  on public.event_registrations(auth_user_id);

commit;
