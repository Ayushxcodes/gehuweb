-- Phase 2: Read-access baseline policies (web + mobile safe)
-- Design:
-- 1) authenticated users can read lookup masters
-- 2) student can read own student records
-- 3) employee can read own employee records
-- 4) admin can read all student/employee records
-- 5) no write policies yet (insert/update/delete blocked by default)

begin;

-- -----------------------------------------------------------------
-- Explicit grants for Data API roles (safe + explicit)
-- -----------------------------------------------------------------
do $$
declare
  t text;
begin
  for t in
    select unnest(array[
      'app_user_identity',

      'stu_campus_master',
      'stu_course_master',
      'stu_branch_master',
      'stu_section_master',
      'stu_specialization_master',
      'student_core',
      'student_contact',
      'student_parent',
      'student_address',
      'student_enrollment_current',
      'student_academic_record',
      'student_status_log',
      'student_attendance_daily',

      'emp_campus_master',
      'emp_department_master',
      'emp_designation_master',
      'emp_role_master',
      'employee_core',
      'employee_contact',
      'employee_family',
      'employee_address',
      'employee_job_current',
      'employee_qualification_record',
      'employee_leave_balance',
      'employee_status_log',
      'employee_attendance_daily'
    ])
  loop
    execute format('revoke all on table %I from anon, authenticated', t);
    execute format('grant select on table %I to authenticated', t);
  end loop;
end $$;

-- -----------------------------------------------------------------
-- app_user_identity: user can read own identity map row
-- -----------------------------------------------------------------
drop policy if exists p_app_user_identity_select_own on app_user_identity;
create policy p_app_user_identity_select_own
on app_user_identity
for select
to authenticated
using (
  (select auth.uid()) is not null
  and auth_user_id = (select auth.uid())
  and is_active = true
);

-- -----------------------------------------------------------------
-- Lookup tables: any authenticated user can read
-- -----------------------------------------------------------------
do $$
declare
  t text;
  p text;
begin
  for t in
    select unnest(array[
      'stu_campus_master',
      'stu_course_master',
      'stu_branch_master',
      'stu_section_master',
      'stu_specialization_master',
      'emp_campus_master',
      'emp_department_master',
      'emp_designation_master',
      'emp_role_master'
    ])
  loop
    p := 'p_' || t || '_select_auth';
    execute format('drop policy if exists %I on %I', p, t);
    execute format(
      'create policy %I on %I for select to authenticated using (true)',
      p, t
    );
  end loop;
end $$;

-- -----------------------------------------------------------------
-- Student domain: student self-read OR admin-read-all
-- -----------------------------------------------------------------
do $$
declare
  r record;
  p text;
begin
  for r in
    select *
    from (
      values
        ('student_core', 'stu_student_id'),
        ('student_contact', 'stu_contact_student_id'),
        ('student_parent', 'stu_parent_student_id'),
        ('student_address', 'stu_address_student_id'),
        ('student_enrollment_current', 'stu_enroll_student_id'),
        ('student_academic_record', 'stu_academic_student_id'),
        ('student_status_log', 'stu_status_student_id'),
        ('student_attendance_daily', 'stu_attendance_student_id')
    ) v(tbl, col)
  loop
    p := 'p_' || r.tbl || '_select_scope';
    execute format('drop policy if exists %I on %I', p, r.tbl);

    execute format(
      $sql$
      create policy %I
      on %I
      for select
      to authenticated
      using (
        exists (
          select 1
          from app_user_identity ai
          where ai.auth_user_id = (select auth.uid())
            and ai.is_active = true
            and ai.account_type = 'STUDENT'
            and ai.student_id = %I
        )
        or
        exists (
          select 1
          from app_user_identity ai
          where ai.auth_user_id = (select auth.uid())
            and ai.is_active = true
            and ai.account_type = 'ADMIN'
            and ai.employee_id is not null
        )
      )
      $sql$,
      p, r.tbl, r.col
    );
  end loop;
end $$;

-- -----------------------------------------------------------------
-- Employee domain: employee self-read OR admin-read-all
-- -----------------------------------------------------------------
do $$
declare
  r record;
  p text;
begin
  for r in
    select *
    from (
      values
        ('employee_core', 'emp_employee_id'),
        ('employee_contact', 'emp_contact_employee_id'),
        ('employee_family', 'emp_family_employee_id'),
        ('employee_address', 'emp_address_employee_id'),
        ('employee_job_current', 'emp_job_employee_id'),
        ('employee_qualification_record', 'emp_qualification_employee_id'),
        ('employee_leave_balance', 'emp_leave_employee_id'),
        ('employee_status_log', 'emp_status_employee_id'),
        ('employee_attendance_daily', 'emp_attendance_employee_id')
    ) v(tbl, col)
  loop
    p := 'p_' || r.tbl || '_select_scope';
    execute format('drop policy if exists %I on %I', p, r.tbl);

    execute format(
      $sql$
      create policy %I
      on %I
      for select
      to authenticated
      using (
        exists (
          select 1
          from app_user_identity ai
          where ai.auth_user_id = (select auth.uid())
            and ai.is_active = true
            and ai.account_type in ('EMPLOYEE', 'ADMIN')
            and ai.employee_id = %I
        )
        or
        exists (
          select 1
          from app_user_identity ai
          where ai.auth_user_id = (select auth.uid())
            and ai.is_active = true
            and ai.account_type = 'ADMIN'
            and ai.employee_id is not null
        )
      )
      $sql$,
      p, r.tbl, r.col
    );
  end loop;
end $$;

commit;
