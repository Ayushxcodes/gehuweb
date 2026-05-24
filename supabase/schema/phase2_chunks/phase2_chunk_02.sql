begin;

      and ai.employee_id is not null
  )
);

drop policy if exists p_student_address_sel_scope on student_address;
create policy p_student_address_sel_scope
on student_address
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_address_student_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_enrollment_current_sel_scope on student_enrollment_current;
create policy p_student_enrollment_current_sel_scope
on student_enrollment_current
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_enroll_student_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_academic_record_sel_scope on student_academic_record;
create policy p_student_academic_record_sel_scope
on student_academic_record
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_academic_student_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_status_log_sel_scope on student_status_log;
create policy p_student_status_log_sel_scope
on student_status_log
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'STUDENT'
      and ai.student_id = stu_status_student_id
  )
  or exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
      and ai.employee_id is not null
  )
);

drop policy if exists p_student_attendance_daily_sel_scope on student_attendance_daily;
create policy p_student_attendance_daily_sel_scope
on student_attendance_daily
for select to authenticated
using (
  exists (
    select 1 from app_user_identity ai
    where ai.auth_user_id = (select auth.uid())

commit;
