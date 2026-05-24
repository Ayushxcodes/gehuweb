-- Phase E1 / Chunk 07
-- RLS for catalog-like event tables.

begin;

do $$
declare
  t text;
begin
  for t in select unnest(array[
    'event_core','event_competitions','event_schedule_stages',
    'event_announcements'
  ])
  loop
    execute format('drop policy if exists p_e1_admin_all on public.%I', t);
    execute format('drop policy if exists p_e1_visible_read on public.%I', t);
    execute format(
      'create policy p_e1_admin_all on public.%I for all to authenticated using (public.app_event_is_admin()) with check (public.app_event_is_admin())',
      t
    );
    execute format(
      'create policy p_e1_visible_read on public.%I for select to authenticated using (public.app_event_visible(event_id))',
      t
    );
  end loop;
end $$;

commit;
