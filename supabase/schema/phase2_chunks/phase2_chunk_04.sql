begin;


drop policy if exists p_employee_job_current_sel_scope on employee_job_current;
create policy p_employee_job_current_sel_scope
on employee_job_current
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_job_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_qualification_record_sel_scope on employee_qualification_record;
create policy p_employee_qualification_record_sel_scope
on employee_qualification_record
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_qualification_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_leave_balance_sel_scope on employee_leave_balance;
create policy p_employee_leave_balance_sel_scope
on employee_leave_balance
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_leave_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_status_log_sel_scope on employee_status_log;
create policy p_employee_status_log_sel_scope
on employee_status_log
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_status_employee_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_employee_attendance_daily_sel_scope on employee_attendance_daily;
create policy p_employee_attendance_daily_sel_scope
on employee_attendance_daily
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type in ('EMPLOYEE', 'ADMIN')
      and ai.employee_id = emp_attendance_employee_id

commit;
