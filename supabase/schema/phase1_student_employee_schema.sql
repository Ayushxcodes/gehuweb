-- Phase 1 foundation schema for student + employee domains
-- Project: GEHUConnect
-- Date: 2026-05-02
-- Notes:
-- 1) Student and employee domains are intentionally isolated.
-- 2) Column names are domain-prefixed (stu_* / emp_*).
-- 3) Source-of-truth IDs are immutable:
--    - student_core.stu_student_id
--    - employee_core.emp_employee_id

begin;

-- =========================================================
-- STUDENT LOOKUP TABLES (5)
-- =========================================================

create table if not exists stu_campus_master (
  stu_campus_id bigserial primary key,
  stu_campus_code text not null unique,
  stu_campus_name text not null,
  stu_campus_state text,
  stu_campus_created_at timestamptz not null default now(),
  stu_campus_updated_at timestamptz not null default now()
);

create table if not exists stu_course_master (
  stu_course_id bigserial primary key,
  stu_course_code text not null unique,
  stu_course_name text not null,
  stu_course_level text not null check (stu_course_level in ('UG', 'PG', 'PHD', 'DIPLOMA', 'OTHER')),
  stu_course_created_at timestamptz not null default now(),
  stu_course_updated_at timestamptz not null default now()
);

create table if not exists stu_branch_master (
  stu_branch_id bigserial primary key,
  stu_branch_code text not null,
  stu_branch_name text not null,
  stu_branch_course_id bigint not null references stu_course_master(stu_course_id) on update restrict on delete restrict,
  stu_branch_campus_id bigint not null references stu_campus_master(stu_campus_id) on update restrict on delete restrict,
  stu_branch_created_at timestamptz not null default now(),
  stu_branch_updated_at timestamptz not null default now(),
  unique (stu_branch_code, stu_branch_course_id, stu_branch_campus_id)
);

create table if not exists stu_section_master (
  stu_section_id bigserial primary key,
  stu_section_code text not null unique,
  stu_section_name text not null,
  stu_section_created_at timestamptz not null default now(),
  stu_section_updated_at timestamptz not null default now()
);

create table if not exists stu_specialization_master (
  stu_specialization_id bigserial primary key,
  stu_specialization_code text not null unique,
  stu_specialization_name text not null,
  stu_specialization_course_id bigint references stu_course_master(stu_course_id) on update restrict on delete set null,
  stu_specialization_created_at timestamptz not null default now(),
  stu_specialization_updated_at timestamptz not null default now()
);

-- =========================================================
-- STUDENT DOMAIN TABLES (8)
-- =========================================================

create table if not exists student_core (
  stu_student_id text primary key,
  stu_auth_user_uuid uuid unique references auth.users(id) on update restrict on delete set null,
  stu_full_name text not null,
  stu_dob date not null check (stu_dob <= current_date),
  stu_gender_code text check (stu_gender_code in ('MALE', 'FEMALE', 'OTHER', 'UNDISCLOSED')),
  stu_category_code text check (stu_category_code in ('GEN', 'OBC', 'SC', 'ST', 'EWS', 'OTHER')),
  stu_ubi_code text unique,
  stu_profile_photo_url text,
  stu_profile_photo_storage_provider text,
  stu_profile_photo_object_key text,
  stu_profile_photo_updated_at timestamptz,
  stu_account_state text not null default 'ACTIVE' check (stu_account_state in ('ACTIVE', 'INACTIVE', 'ALUMNI', 'SUSPENDED', 'BLOCKED')),
  stu_core_created_at timestamptz not null default now(),
  stu_core_updated_at timestamptz not null default now(),
  check (length(trim(stu_student_id)) > 0),
  check (length(trim(stu_full_name)) > 1)
);

create table if not exists student_contact (
  stu_contact_id bigint generated always as identity primary key,
  stu_contact_student_id text not null unique references student_core(stu_student_id) on update restrict on delete cascade,
  stu_official_email text not null unique,
  stu_personal_email text unique,
  stu_primary_phone text not null,
  stu_alternate_phone text,
  stu_contact_created_at timestamptz not null default now(),
  stu_contact_updated_at timestamptz not null default now(),
  check (position('@' in stu_official_email) > 1),
  check (stu_personal_email is null or position('@' in stu_personal_email) > 1)
);

create table if not exists student_parent (
  stu_parent_id bigint generated always as identity primary key,
  stu_parent_student_id text not null unique references student_core(stu_student_id) on update restrict on delete cascade,
  stu_father_name text,
  stu_mother_name text,
  stu_father_phone text,
  stu_mother_phone text,
  stu_father_occupation text,
  stu_mother_occupation text,
  stu_parent_created_at timestamptz not null default now(),
  stu_parent_updated_at timestamptz not null default now()
);

create table if not exists student_address (
  stu_address_id bigint generated always as identity primary key,
  stu_address_student_id text not null unique references student_core(stu_student_id) on update restrict on delete cascade,
  stu_permanent_line1 text,
  stu_permanent_line2 text,
  stu_city_name text,
  stu_state_name text,
  stu_pin_code text,
  stu_country_name text,
  stu_address_created_at timestamptz not null default now(),
  stu_address_updated_at timestamptz not null default now()
);

create table if not exists student_enrollment_current (
  stu_enroll_id bigint generated always as identity primary key,
  stu_enroll_student_id text not null unique references student_core(stu_student_id) on update restrict on delete cascade,
  stu_college_campus_id bigint not null references stu_campus_master(stu_campus_id) on update restrict on delete restrict,
  stu_course_id bigint not null references stu_course_master(stu_course_id) on update restrict on delete restrict,
  stu_specialization_id bigint references stu_specialization_master(stu_specialization_id) on update restrict on delete set null,
  stu_branch_id bigint references stu_branch_master(stu_branch_id) on update restrict on delete set null,
  stu_section_id bigint references stu_section_master(stu_section_id) on update restrict on delete set null,
  stu_year_sem_no integer not null check (stu_year_sem_no between 1 and 12),
  stu_class_roll_no integer,
  stu_enroll_no text unique,
  stu_university_roll_no text unique,
  stu_enroll_state text not null default 'ACTIVE' check (stu_enroll_state in ('ACTIVE', 'INACTIVE', 'SUSPENDED', 'PASSED_OUT')),
  stu_enroll_created_at timestamptz not null default now(),
  stu_enroll_updated_at timestamptz not null default now()
);

create table if not exists student_academic_record (
  stu_academic_id bigint generated always as identity primary key,
  stu_academic_student_id text not null references student_core(stu_student_id) on update restrict on delete cascade,
  stu_level_code text not null check (stu_level_code in ('HIGH_SCHOOL', 'INTERMEDIATE', 'BACHELOR')),
  stu_board_or_university_name text,
  stu_institute_name text,
  stu_passing_year integer check (stu_passing_year between 1950 and 2100),
  stu_score_type text check (stu_score_type in ('PERCENT', 'CGPA')),
  stu_score_value numeric(6,2) check (stu_score_value >= 0 and stu_score_value <= 100),
  stu_subject_major text,
  stu_academic_created_at timestamptz not null default now(),
  stu_academic_updated_at timestamptz not null default now(),
  unique (stu_academic_student_id, stu_level_code)
);

create table if not exists student_status_log (
  stu_status_log_id bigint generated always as identity primary key,
  stu_status_student_id text not null references student_core(stu_student_id) on update restrict on delete restrict,
  stu_prev_state text,
  stu_next_state text not null,
  stu_state_reason text,
  stu_state_changed_by text,
  stu_state_changed_at timestamptz not null default now()
);

create table if not exists student_attendance_daily (
  stu_attendance_id bigint generated always as identity primary key,
  stu_attendance_student_id text not null references student_core(stu_student_id) on update restrict on delete cascade,
  stu_attendance_date date not null,
  stu_attendance_mark text not null check (stu_attendance_mark in ('P', 'A', 'L', 'OD')),
  stu_attendance_marked_by text,
  stu_attendance_created_at timestamptz not null default now(),
  unique (stu_attendance_student_id, stu_attendance_date)
);

-- =========================================================
-- EMPLOYEE LOOKUP TABLES (4)
-- =========================================================

create table if not exists emp_campus_master (
  emp_campus_id bigserial primary key,
  emp_campus_code text not null unique,
  emp_campus_name text not null,
  emp_campus_state text,
  emp_campus_created_at timestamptz not null default now(),
  emp_campus_updated_at timestamptz not null default now()
);

create table if not exists emp_department_master (
  emp_department_id bigserial primary key,
  emp_department_code text not null unique,
  emp_department_name text not null,
  emp_department_created_at timestamptz not null default now(),
  emp_department_updated_at timestamptz not null default now()
);

create table if not exists emp_designation_master (
  emp_designation_id bigserial primary key,
  emp_designation_code text not null unique,
  emp_designation_name text not null,
  emp_designation_created_at timestamptz not null default now(),
  emp_designation_updated_at timestamptz not null default now()
);

create table if not exists emp_role_master (
  emp_role_id bigserial primary key,
  emp_role_code text not null unique,
  emp_role_name text not null,
  emp_role_created_at timestamptz not null default now(),
  emp_role_updated_at timestamptz not null default now()
);

-- =========================================================
-- EMPLOYEE DOMAIN TABLES (9)
-- =========================================================

create table if not exists employee_core (
  emp_employee_id text primary key,
  emp_auth_user_uuid uuid unique references auth.users(id) on update restrict on delete set null,
  emp_full_name text not null,
  emp_dob date check (emp_dob <= current_date),
  emp_gender_code text check (emp_gender_code in ('MALE', 'FEMALE', 'OTHER', 'UNDISCLOSED')),
  emp_blood_group_code text,
  emp_profile_photo_url text,
  emp_profile_photo_storage_provider text,
  emp_profile_photo_object_key text,
  emp_profile_photo_updated_at timestamptz,
  emp_account_state text not null default 'ACTIVE' check (emp_account_state in ('ACTIVE', 'ON_LEAVE', 'INACTIVE', 'EXITED', 'SUSPENDED', 'BLOCKED')),
  emp_core_created_at timestamptz not null default now(),
  emp_core_updated_at timestamptz not null default now(),
  check (length(trim(emp_employee_id)) > 0),
  check (length(trim(emp_full_name)) > 1)
);

create table if not exists employee_contact (
  emp_contact_id bigint generated always as identity primary key,
  emp_contact_employee_id text not null unique references employee_core(emp_employee_id) on update restrict on delete cascade,
  emp_official_email text not null unique,
  emp_personal_email text unique,
  emp_primary_phone text not null,
  emp_alternate_phone text,
  emp_contact_created_at timestamptz not null default now(),
  emp_contact_updated_at timestamptz not null default now(),
  check (position('@' in emp_official_email) > 1),
  check (emp_personal_email is null or position('@' in emp_personal_email) > 1)
);

create table if not exists employee_family (
  emp_family_id bigint generated always as identity primary key,
  emp_family_employee_id text not null unique references employee_core(emp_employee_id) on update restrict on delete cascade,
  emp_father_name text,
  emp_mother_name text,
  emp_spouse_name text,
  emp_guardian_name text,
  emp_guardian_phone text,
  emp_emergency_contact_name text,
  emp_emergency_contact_phone text,
  emp_emergency_contact_relation text,
  emp_family_created_at timestamptz not null default now(),
  emp_family_updated_at timestamptz not null default now()
);

create table if not exists employee_address (
  emp_address_id bigint generated always as identity primary key,
  emp_address_employee_id text not null unique references employee_core(emp_employee_id) on update restrict on delete cascade,
  emp_permanent_line1 text,
  emp_permanent_line2 text,
  emp_city_name text,
  emp_state_name text,
  emp_pin_code text,
  emp_country_name text,
  emp_address_created_at timestamptz not null default now(),
  emp_address_updated_at timestamptz not null default now()
);

create table if not exists employee_job_current (
  emp_job_id bigint generated always as identity primary key,
  emp_job_employee_id text not null unique references employee_core(emp_employee_id) on update restrict on delete cascade,
  emp_campus_id bigint not null references emp_campus_master(emp_campus_id) on update restrict on delete restrict,
  emp_department_id bigint not null references emp_department_master(emp_department_id) on update restrict on delete restrict,
  emp_designation_id bigint not null references emp_designation_master(emp_designation_id) on update restrict on delete restrict,
  emp_role_id bigint not null references emp_role_master(emp_role_id) on update restrict on delete restrict,
  emp_joining_date date not null,
  emp_experience_years numeric(5,2),
  emp_reporting_to_employee_id text references employee_core(emp_employee_id) on update restrict on delete set null,
  emp_employment_type_code text check (emp_employment_type_code in ('FULL_TIME', 'PART_TIME', 'CONTRACT', 'VISITING', 'TEMPORARY', 'OTHER')),
  emp_highest_qualification text,
  emp_specialization_text text,
  emp_is_phd_guide boolean not null default false,
  emp_job_created_at timestamptz not null default now(),
  emp_job_updated_at timestamptz not null default now()
);

create table if not exists employee_qualification_record (
  emp_qualification_id bigint generated always as identity primary key,
  emp_qualification_employee_id text not null references employee_core(emp_employee_id) on update restrict on delete cascade,
  emp_qualification_level text not null,
  emp_qualification_institute_name text,
  emp_qualification_passing_year integer check (emp_qualification_passing_year between 1950 and 2100),
  emp_qualification_score_type text check (emp_qualification_score_type in ('PERCENT', 'CGPA', 'GRADE', 'NA')),
  emp_qualification_score_value numeric(7,2),
  emp_qualification_created_at timestamptz not null default now(),
  emp_qualification_updated_at timestamptz not null default now()
);

create table if not exists employee_leave_balance (
  emp_leave_id bigint generated always as identity primary key,
  emp_leave_employee_id text not null references employee_core(emp_employee_id) on update restrict on delete cascade,
  emp_leave_type_code text not null,
  emp_leave_year_no integer not null check (emp_leave_year_no between 2000 and 2100),
  emp_leave_total_count numeric(7,2) not null default 0 check (emp_leave_total_count >= 0),
  emp_leave_used_count numeric(7,2) not null default 0 check (emp_leave_used_count >= 0),
  emp_leave_balance_count numeric(7,2) not null default 0 check (emp_leave_balance_count >= 0),
  emp_leave_updated_at timestamptz not null default now(),
  unique (emp_leave_employee_id, emp_leave_type_code, emp_leave_year_no)
);

create table if not exists employee_status_log (
  emp_status_log_id bigint generated always as identity primary key,
  emp_status_employee_id text not null references employee_core(emp_employee_id) on update restrict on delete restrict,
  emp_prev_state text,
  emp_next_state text not null,
  emp_state_reason text,
  emp_state_changed_by text,
  emp_state_changed_at timestamptz not null default now()
);

create table if not exists employee_attendance_daily (
  emp_attendance_id bigint generated always as identity primary key,
  emp_attendance_employee_id text not null references employee_core(emp_employee_id) on update restrict on delete cascade,
  emp_attendance_date date not null,
  emp_attendance_mark text not null check (emp_attendance_mark in ('P', 'A', 'L', 'OD')),
  emp_attendance_marked_by text,
  emp_attendance_created_at timestamptz not null default now(),
  unique (emp_attendance_employee_id, emp_attendance_date)
);

-- =========================================================
-- TRIGGERS: UPDATED_AT AUTO-TIMESTAMP
-- =========================================================

create or replace function stu_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.stu_core_updated_at := now();
  return new;
end;
$$;

create or replace function stu_touch_contact_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.stu_contact_updated_at := now();
  return new;
end;
$$;

create or replace function stu_touch_parent_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.stu_parent_updated_at := now();
  return new;
end;
$$;

create or replace function stu_touch_address_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.stu_address_updated_at := now();
  return new;
end;
$$;

create or replace function stu_touch_enroll_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.stu_enroll_updated_at := now();
  return new;
end;
$$;

create or replace function stu_touch_academic_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.stu_academic_updated_at := now();
  return new;
end;
$$;

create or replace function emp_touch_core_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.emp_core_updated_at := now();
  return new;
end;
$$;

create or replace function emp_touch_contact_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.emp_contact_updated_at := now();
  return new;
end;
$$;

create or replace function emp_touch_family_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.emp_family_updated_at := now();
  return new;
end;
$$;

create or replace function emp_touch_address_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.emp_address_updated_at := now();
  return new;
end;
$$;

create or replace function emp_touch_job_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.emp_job_updated_at := now();
  return new;
end;
$$;

create or replace function emp_touch_qualification_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.emp_qualification_updated_at := now();
  return new;
end;
$$;

do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_stu_core_touch') then
    create trigger trg_stu_core_touch
      before update on student_core
      for each row execute function stu_touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_stu_contact_touch') then
    create trigger trg_stu_contact_touch
      before update on student_contact
      for each row execute function stu_touch_contact_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_stu_parent_touch') then
    create trigger trg_stu_parent_touch
      before update on student_parent
      for each row execute function stu_touch_parent_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_stu_address_touch') then
    create trigger trg_stu_address_touch
      before update on student_address
      for each row execute function stu_touch_address_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_stu_enroll_touch') then
    create trigger trg_stu_enroll_touch
      before update on student_enrollment_current
      for each row execute function stu_touch_enroll_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_stu_academic_touch') then
    create trigger trg_stu_academic_touch
      before update on student_academic_record
      for each row execute function stu_touch_academic_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_emp_core_touch') then
    create trigger trg_emp_core_touch
      before update on employee_core
      for each row execute function emp_touch_core_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_emp_contact_touch') then
    create trigger trg_emp_contact_touch
      before update on employee_contact
      for each row execute function emp_touch_contact_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_emp_family_touch') then
    create trigger trg_emp_family_touch
      before update on employee_family
      for each row execute function emp_touch_family_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_emp_address_touch') then
    create trigger trg_emp_address_touch
      before update on employee_address
      for each row execute function emp_touch_address_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_emp_job_touch') then
    create trigger trg_emp_job_touch
      before update on employee_job_current
      for each row execute function emp_touch_job_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_emp_qualification_touch') then
    create trigger trg_emp_qualification_touch
      before update on employee_qualification_record
      for each row execute function emp_touch_qualification_updated_at();
  end if;
end $$;

-- =========================================================
-- IMMUTABLE SOURCE OF TRUTH ID TRIGGERS
-- =========================================================

create or replace function stu_block_student_id_update()
returns trigger
language plpgsql
as $$
begin
  if new.stu_student_id is distinct from old.stu_student_id then
    raise exception 'stu_student_id is immutable and cannot be changed';
  end if;
  return new;
end;
$$;

create or replace function emp_block_employee_id_update()
returns trigger
language plpgsql
as $$
begin
  if new.emp_employee_id is distinct from old.emp_employee_id then
    raise exception 'emp_employee_id is immutable and cannot be changed';
  end if;
  return new;
end;
$$;

do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_stu_immutable_id') then
    create trigger trg_stu_immutable_id
      before update on student_core
      for each row execute function stu_block_student_id_update();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_emp_immutable_id') then
    create trigger trg_emp_immutable_id
      before update on employee_core
      for each row execute function emp_block_employee_id_update();
  end if;
end $$;

-- =========================================================
-- INDEXES FOR COMMON QUERY PATHS
-- =========================================================

create index if not exists idx_stu_enroll_course on student_enrollment_current(stu_course_id);
create index if not exists idx_stu_enroll_branch on student_enrollment_current(stu_branch_id);
create index if not exists idx_stu_enroll_section on student_enrollment_current(stu_section_id);
create index if not exists idx_stu_academic_student on student_academic_record(stu_academic_student_id);
create index if not exists idx_stu_status_student on student_status_log(stu_status_student_id);
create index if not exists idx_stu_att_student_date on student_attendance_daily(stu_attendance_student_id, stu_attendance_date);

create index if not exists idx_emp_job_dept on employee_job_current(emp_department_id);
create index if not exists idx_emp_job_role on employee_job_current(emp_role_id);
create index if not exists idx_emp_qualification_emp on employee_qualification_record(emp_qualification_employee_id);
create index if not exists idx_emp_status_emp on employee_status_log(emp_status_employee_id);
create index if not exists idx_emp_att_emp_date on employee_attendance_daily(emp_attendance_employee_id, emp_attendance_date);

commit;
