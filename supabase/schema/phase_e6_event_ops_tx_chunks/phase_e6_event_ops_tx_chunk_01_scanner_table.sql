-- Phase E6 / Chunk 01
-- Event scanner assignment table and strict RLS.

begin;

create table if not exists public.event_scanners (
  event_id text not null references public.event_core(event_id) on delete cascade,
  student_id text not null references public.student_core(stu_student_id) on delete restrict,
  auth_user_id uuid references auth.users(id) on delete set null,
  legacy_firebase_uid text not null default '',
  added_by_auth_user_id uuid references auth.users(id) on delete set null,
  added_at timestamptz not null default now(),
  payload_json jsonb not null default '{}'::jsonb,
  primary key (event_id, student_id)
);

create index if not exists idx_event_scanners_student
  on public.event_scanners(student_id, event_id);

alter table public.event_scanners enable row level security;

drop policy if exists p_e6_event_scanners_read on public.event_scanners;
create policy p_e6_event_scanners_read on public.event_scanners
for select to authenticated
using (public.app_event_is_admin() or student_id = public.app_event_current_student_id());

drop policy if exists p_e6_event_scanners_admin_all on public.event_scanners;
create policy p_e6_event_scanners_admin_all on public.event_scanners
for all to authenticated
using (public.app_event_is_admin())
with check (public.app_event_is_admin());

grant select, insert, update, delete on public.event_scanners to authenticated;

commit;
