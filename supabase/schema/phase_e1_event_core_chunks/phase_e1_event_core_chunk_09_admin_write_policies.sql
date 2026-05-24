-- Phase E1 / Chunk 09
-- Admin write policies for private tables. Student writes come later via RPCs.

begin;

do $$
declare
  t text;
begin
  for t in select unnest(array[
    'event_registrations','event_teams','event_team_members','event_team_invites',
    'event_participants','event_payment_records','event_attendance',
    'event_attendance_members','event_results','event_certificates',
    'event_group_channels','event_group_members','event_group_messages'
  ])
  loop
    execute format('drop policy if exists p_e1_private_admin_all on public.%I', t);
    execute format(
      'create policy p_e1_private_admin_all on public.%I for all to authenticated using (public.app_event_is_admin()) with check (public.app_event_is_admin())',
      t
    );
  end loop;
end $$;

-- Direct student inserts/updates/deletes are intentionally blocked in E1.
-- Use later transaction RPCs for registration, invite, payment proof,
-- attendance, result publish, and certificate issue.

commit;
