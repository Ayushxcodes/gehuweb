begin;

      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_attendance_student_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_core_sel_scope on employee_core;
create policy p_employee_core_sel_scope
on employee_core
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_contact_sel_scope on employee_contact;
create policy p_employee_contact_sel_scope
on employee_contact
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_contact_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_family_sel_scope on employee_family;
create policy p_employee_family_sel_scope
on employee_family
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_family_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_address_sel_scope on employee_address;
create policy p_employee_address_sel_scope
on employee_address
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_address_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

commit;
