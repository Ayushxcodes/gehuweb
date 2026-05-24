-- Phase 3 RLS / Chunk 03
-- Inbox + notice reads + notification meta

drop policy if exists p3_inbox_select on public.app_inbox;
create policy p3_inbox_select
on public.app_inbox
for select to authenticated
using (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid));

drop policy if exists p3_inbox_insert on public.app_inbox;
create policy p3_inbox_insert
on public.app_inbox
for insert to authenticated
with check (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid));

drop policy if exists p3_inbox_update on public.app_inbox;
create policy p3_inbox_update
on public.app_inbox
for update to authenticated
using (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid))
with check (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid));

drop policy if exists p3_inbox_delete on public.app_inbox;
create policy p3_inbox_delete
on public.app_inbox
for delete to authenticated
using (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid));

drop policy if exists p3_notice_reads_select on public.app_notice_reads;
create policy p3_notice_reads_select
on public.app_notice_reads
for select to authenticated
using (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid));

drop policy if exists p3_notice_reads_write on public.app_notice_reads;
create policy p3_notice_reads_write
on public.app_notice_reads
for all to authenticated
using (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid))
with check (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid));

drop policy if exists p3_notification_meta_select on public.app_notification_meta;
create policy p3_notification_meta_select
on public.app_notification_meta
for select to authenticated
using (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid));

drop policy if exists p3_notification_meta_write on public.app_notification_meta;
create policy p3_notification_meta_write
on public.app_notification_meta
for all to authenticated
using (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid))
with check (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid));

