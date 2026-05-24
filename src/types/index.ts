// GEHU Connect: Central TypeScript Type Declarations
// Enforces strict type-safety contracts across all pages and providers.

export type AccountType = "STUDENT" | "ADMIN" | "EMPLOYEE";

export interface AppUserIdentity {
  identity_id: string;
  auth_user_id: string;
  student_id: string | null;
  employee_id: string | null;
  account_type: AccountType;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// =========================================================
// STUDENT DOMAIN TYPES
// =========================================================

export interface StudentProfile {
  stu_student_id: string;
  stu_auth_user_uuid: string | null;
  stu_full_name: string;
  stu_dob: string;
  stu_gender_code: "MALE" | "FEMALE" | "OTHER" | "UNDISCLOSED";
  stu_category_code: "GEN" | "OBC" | "SC" | "ST" | "EWS" | "OTHER";
  stu_ubi_code: string | null;
  stu_profile_photo_url: string | null;
  stu_account_state: "ACTIVE" | "INACTIVE" | "ALUMNI" | "SUSPENDED" | "BLOCKED";
  stu_core_created_at: string;
  stu_core_updated_at: string;
  
  // Flattened contact / enrollment properties commonly mapped together
  stu_official_email?: string;
  stu_primary_phone?: string;
  stu_campus_name?: string;
  stu_course_name?: string;
  stu_branch_name?: string;
  stu_year_sem_no?: number;
  stu_university_roll_no?: string;
}

export interface StudentContact {
  stu_contact_id: number;
  stu_contact_student_id: string;
  stu_official_email: string;
  stu_personal_email: string | null;
  stu_primary_phone: string;
  stu_alternate_phone: string | null;
}

export interface StudentEnrollment {
  stu_enroll_id: number;
  stu_enroll_student_id: string;
  stu_college_campus_id: number;
  stu_course_id: number;
  stu_specialization_id: number | null;
  stu_branch_id: number | null;
  stu_section_id: number | null;
  stu_year_sem_no: number;
  stu_class_roll_no: number | null;
  stu_enroll_no: string | null;
  stu_university_roll_no: string | null;
  stu_enroll_state: "ACTIVE" | "INACTIVE" | "SUSPENDED" | "PASSED_OUT";
}

// =========================================================
// EMPLOYEE DOMAIN TYPES
// =========================================================

export interface EmployeeProfile {
  emp_employee_id: string;
  emp_auth_user_uuid: string | null;
  emp_full_name: string;
  emp_dob: string | null;
  emp_gender_code: "MALE" | "FEMALE" | "OTHER" | "UNDISCLOSED" | null;
  emp_profile_photo_url: string | null;
  emp_account_state: "ACTIVE" | "ON_LEAVE" | "INACTIVE" | "EXITED" | "SUSPENDED" | "BLOCKED";
  emp_core_created_at: string;
  emp_core_updated_at: string;

  // Flattened job details commonly mapped
  emp_official_email?: string;
  emp_primary_phone?: string;
  emp_campus_name?: string;
  emp_department_name?: string;
  emp_designation_name?: string;
  emp_role_code?: string;
}

export interface EmployeeJobCurrent {
  emp_job_id: number;
  emp_job_employee_id: string;
  emp_campus_id: number;
  emp_department_id: number;
  emp_designation_id: number;
  emp_role_id: number;
  emp_joining_date: string;
  emp_employment_type_code: "FULL_TIME" | "PART_TIME" | "CONTRACT" | "VISITING" | "TEMPORARY" | "OTHER";
}

// =========================================================
// MOCK TEST DOMAIN TYPES
// =========================================================

export type MockTestStatus = "DRAFT" | "POSTED" | "ARCHIVED";

export interface MockTest {
  test_id: string;
  title: string;
  branch: string;
  course: string;
  semester: string;
  total_questions: number;
  duration_minutes: number;
  start_at: string;
  scheduled_start_at?: string | null;
  exam_end_at?: string | null;
  expires_at?: string | null;
  status: MockTestStatus;
  source?: "manual" | "csv" | null;
  marking_aptitude_per_q: number;
  marking_english_per_q: number;
  negative_enabled: boolean;
  negative_value: number;
  negative_apply_to: string[];
  frozen_ids: string[];
  published: boolean;
  results_published: boolean;
  created_by_auth_user_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface MockQuestion {
  test_id: string;
  qid: string;
  q_index: number | null;
  subject: string;
  subject_type: "APTITUDE" | "ENGLISH";
  question: string;
  option_a: string;
  option_b: string;
  option_c: string;
  option_d: string;
  answer_letter: "A" | "B" | "C" | "D";
  solution_mode?: string | null;
  solution?: string | null;
  difficulty?: string | null;
  active: boolean;
  source?: string | null;
  uploaded_at?: string | null;
}

export interface MockResult {
  result_id: number;
  test_id: string;
  student_id: string | null;
  auth_user_id: string | null;
  firebase_uid?: string | null;
  q_order: string[];
  opt_map: Record<string, "A" | "B" | "C" | "D">;
  warn_count: number;
  locked: boolean;
  started_at: string | null;
  session_end_time: string | null;
  submitted_at: string | null;
  total_questions: number;
  answered_count: number;
  score: number;
  correct: number;
  wrong: number;
  unattempted: number;
  max_marks: number;
  percentage: number;
  published: boolean;
  results_published: boolean;
  branch: string;
  course: string;
  semester: string;
  created_at: string;
  updated_at: string;
}

// =========================================================
// EVENT & NOTICE DOMAIN TYPES
// =========================================================

export interface EventCore {
  event_id: string;
  title: string;
  description: string;
  branch: string;
  course: string;
  semester: string;
  start_date: string;
  end_date: string;
  status: "DRAFT" | "ACTIVE" | "COMPLETED" | "CANCELLED";
  created_by: string;
  created_at: string;
}

export interface NoticeCore {
  notice_id: string;
  title: string;
  content: string;
  branch: string;
  course: string;
  semester: string;
  published_by: string;
  created_at: string;
  updated_at: string;
}
