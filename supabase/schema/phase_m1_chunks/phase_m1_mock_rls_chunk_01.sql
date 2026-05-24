-- Phase M1 RLS Chunk 01
-- Run first

begin;

grant usage on schema mocks to authenticated;

revoke all on all tables in schema mocks from anon;
revoke all on all tables in schema mocks from authenticated;

grant select on mocks.mock_tests to authenticated;
grant select on mocks.mock_test_questions to authenticated;
grant select, insert, update on mocks.mock_results to authenticated;
grant select, insert, update on mocks.mock_sessions_legacy to authenticated;
grant select on mocks.mock_results_legacy to authenticated;

alter table mocks.mock_tests enable row level security;
alter table mocks.mock_test_questions enable row level security;
alter table mocks.mock_results enable row level security;
alter table mocks.mock_sessions_legacy enable row level security;
alter table mocks.mock_results_legacy enable row level security;

create or replace function mocks.current_auth_uid()
returns uuid
language sql
stable
as $$
  select auth.uid();
$$;

create or replace function mocks.current_student_id()
returns text
language sql
stable
as $$
  select ai.student_id
  from public.app_user_identity ai
  where ai.auth_user_id = (select auth.uid())
    and ai.is_active = true
    and ai.account_type = 'STUDENT'
  limit 1;
$$;

create or replace function mocks.is_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  );
$$;

drop policy if exists p_m1_mock_tests_select_scope on mocks.mock_tests;
create policy p_m1_mock_tests_select_scope
on mocks.mock_tests
for select
to authenticated
using (mocks.is_admin() or status = 'POSTED');

drop policy if exists p_m1_mock_tests_admin_write on mocks.mock_tests;
create policy p_m1_mock_tests_admin_write
on mocks.mock_tests
for all
to authenticated
using (mocks.is_admin())
with check (mocks.is_admin());

drop policy if exists p_m1_mock_questions_select_scope on mocks.mock_test_questions;
create policy p_m1_mock_questions_select_scope
on mocks.mock_test_questions
for select
to authenticated
using (
  mocks.is_admin()
  or exists (
    select 1
    from mocks.mock_tests mt
    where mt.test_id = mock_test_questions.test_id
      and mt.status = 'POSTED'
  )
);

drop policy if exists p_m1_mock_questions_admin_write on mocks.mock_test_questions;
create policy p_m1_mock_questions_admin_write
on mocks.mock_test_questions
for all
to authenticated
using (mocks.is_admin())
with check (mocks.is_admin());

commit;
