-- Phase M1 RLS Chunk 03
-- Run third

begin;

drop policy if exists p_m1_mock_sessions_select_scope on mocks.mock_sessions_legacy;
create policy p_m1_mock_sessions_select_scope
on mocks.mock_sessions_legacy
for select
to authenticated
using (
  mocks.is_admin()
  or (auth_user_id is not null and auth_user_id = mocks.current_auth_uid())
);

drop policy if exists p_m1_mock_sessions_insert_scope on mocks.mock_sessions_legacy;
create policy p_m1_mock_sessions_insert_scope
on mocks.mock_sessions_legacy
for insert
to authenticated
with check (
  mocks.is_admin()
  or (
    auth_user_id is not null
    and auth_user_id = mocks.current_auth_uid()
    and coalesce(locked, false) = false
  )
);

drop policy if exists p_m1_mock_sessions_update_scope on mocks.mock_sessions_legacy;
create policy p_m1_mock_sessions_update_scope
on mocks.mock_sessions_legacy
for update
to authenticated
using (
  mocks.is_admin()
  or (
    auth_user_id is not null
    and auth_user_id = mocks.current_auth_uid()
    and coalesce(locked, false) = false
  )
)
with check (
  mocks.is_admin()
  or (
    auth_user_id is not null
    and auth_user_id = mocks.current_auth_uid()
  )
);

drop policy if exists p_m1_mock_sessions_delete_admin on mocks.mock_sessions_legacy;
create policy p_m1_mock_sessions_delete_admin
on mocks.mock_sessions_legacy
for delete
to authenticated
using (mocks.is_admin());

drop policy if exists p_m1_mock_results_legacy_select_scope on mocks.mock_results_legacy;
create policy p_m1_mock_results_legacy_select_scope
on mocks.mock_results_legacy
for select
to authenticated
using (mocks.is_admin());

drop policy if exists p_m1_mock_results_legacy_admin_write on mocks.mock_results_legacy;
create policy p_m1_mock_results_legacy_admin_write
on mocks.mock_results_legacy
for all
to authenticated
using (mocks.is_admin())
with check (mocks.is_admin());

commit;
