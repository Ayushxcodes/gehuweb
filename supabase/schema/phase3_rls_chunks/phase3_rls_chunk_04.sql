-- Phase 3 RLS / Chunk 04
-- Notices + attachments + broadcast + directory

drop policy if exists p3_notices_select on public.app_notices;
create policy p3_notices_select
on public.app_notices
for select to authenticated
using (true);

drop policy if exists p3_notices_write_admin on public.app_notices;
create policy p3_notices_write_admin
on public.app_notices
for all to authenticated
using (public.app_phase3_is_admin())
with check (public.app_phase3_is_admin());

drop policy if exists p3_notice_attachments_select on public.app_notice_attachments;
create policy p3_notice_attachments_select
on public.app_notice_attachments
for select to authenticated
using (true);

drop policy if exists p3_notice_attachments_write_admin on public.app_notice_attachments;
create policy p3_notice_attachments_write_admin
on public.app_notice_attachments
for all to authenticated
using (public.app_phase3_is_admin())
with check (public.app_phase3_is_admin());

drop policy if exists p3_notifications_select on public.app_notifications;
create policy p3_notifications_select
on public.app_notifications
for select to authenticated
using (true);

drop policy if exists p3_notifications_write_admin on public.app_notifications;
create policy p3_notifications_write_admin
on public.app_notifications
for all to authenticated
using (public.app_phase3_is_admin())
with check (public.app_phase3_is_admin());

drop policy if exists p3_directory_select on public.app_directory_index;
create policy p3_directory_select
on public.app_directory_index
for select to authenticated
using (true);

drop policy if exists p3_directory_insert on public.app_directory_index;
create policy p3_directory_insert
on public.app_directory_index
for insert to authenticated
with check (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid));

drop policy if exists p3_directory_update on public.app_directory_index;
create policy p3_directory_update
on public.app_directory_index
for update to authenticated
using (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid))
with check (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid));

drop policy if exists p3_directory_delete_admin on public.app_directory_index;
create policy p3_directory_delete_admin
on public.app_directory_index
for delete to authenticated
using (public.app_phase3_is_admin());

