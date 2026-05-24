-- Phase E1 / Chunk 05
-- Indexes, grants, RLS enable.

begin;

create index if not exists idx_event_core_feed
  on public.event_core(is_live, is_cancelled, start_at desc, event_id desc);
create index if not exists idx_event_core_deadline
  on public.event_core(registration_deadline);
create index if not exists idx_event_core_courses_gin
  on public.event_core using gin(target_courses);
create index if not exists idx_event_core_semesters_gin
  on public.event_core using gin(target_semesters);

create index if not exists idx_event_competitions_event_live
  on public.event_competitions(event_id, is_live, comp_id);
create index if not exists idx_event_registrations_student
  on public.event_registrations(student_id, registered_at desc);
create index if not exists idx_event_registrations_status
  on public.event_registrations(event_id, comp_id, status);
create index if not exists idx_event_team_members_student
  on public.event_team_members(student_id, event_id, comp_id);
create index if not exists idx_event_invites_student_status
  on public.event_team_invites(student_id, status, created_at desc);
create index if not exists idx_event_payment_status
  on public.event_payment_records(event_id, comp_id, status, updated_at desc);
create index if not exists idx_event_payment_student
  on public.event_payment_records(student_id, updated_at desc);
create index if not exists idx_event_schedule_public
  on public.event_schedule_stages(event_id, is_public, stage_order);
create index if not exists idx_event_announcements_feed
  on public.event_announcements(event_id, sent_at desc);
create index if not exists idx_event_group_messages_feed
  on public.event_group_messages(event_id, comp_id, group_id, sent_at desc);
create index if not exists idx_event_results_published
  on public.event_results(event_id, comp_id, published, rank_no);
create index if not exists idx_event_certificates_student
  on public.event_certificates(student_id, issued_at desc);

do $$
declare
  t text;
begin
  for t in select unnest(array[
    'event_core','event_competitions','event_registrations','event_teams',
    'event_team_members','event_team_invites','event_participants',
    'event_payment_records','event_schedule_stages','event_attendance',
    'event_attendance_members','event_announcements','event_group_channels',
    'event_group_members','event_group_messages','event_results',
    'event_certificates'
  ])
  loop
    execute format('grant select, insert, update, delete on table public.%I to authenticated', t);
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

commit;
