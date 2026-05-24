-- Phase M1 RLS Chunk 02
-- Run second

begin;

drop policy if exists p_m1_mock_results_select_scope on mocks.mock_results;
create policy p_m1_mock_results_select_scope
on mocks.mock_results
for select
to authenticated
using (
  mocks.is_admin()
  or (
    (auth_user_id is not null and auth_user_id = mocks.current_auth_uid())
    or (student_id is not null and student_id = mocks.current_student_id())
  )
);

drop policy if exists p_m1_mock_results_insert_scope on mocks.mock_results;
create policy p_m1_mock_results_insert_scope
on mocks.mock_results
for insert
to authenticated
with check (
  mocks.is_admin()
  or (
    coalesce(published, false) = false
    and coalesce(results_published, false) = false
    and coalesce(locked, false) = false
    and (
      (auth_user_id is not null and auth_user_id = mocks.current_auth_uid())
      or (student_id is not null and student_id = mocks.current_student_id())
    )
  )
);

drop policy if exists p_m1_mock_results_update_scope on mocks.mock_results;
create policy p_m1_mock_results_update_scope
on mocks.mock_results
for update
to authenticated
using (
  mocks.is_admin()
  or (
    coalesce(locked, false) = false
    and (
      (auth_user_id is not null and auth_user_id = mocks.current_auth_uid())
      or (student_id is not null and student_id = mocks.current_student_id())
    )
  )
)
with check (
  mocks.is_admin()
  or (
    coalesce(published, false) = false
    and coalesce(results_published, false) = false
    and (
      (auth_user_id is not null and auth_user_id = mocks.current_auth_uid())
      or (student_id is not null and student_id = mocks.current_student_id())
    )
  )
);

drop policy if exists p_m1_mock_results_delete_admin on mocks.mock_results;
create policy p_m1_mock_results_delete_admin
on mocks.mock_results
for delete
to authenticated
using (mocks.is_admin());

commit;
