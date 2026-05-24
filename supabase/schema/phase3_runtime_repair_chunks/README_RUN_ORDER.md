# Phase 3 Runtime Repair Run Order

Date: 2026-05-19

Run when Supabase-only profile appeals or admin notice compose show `permission denied` even though the user is signed in and has the correct role.

1. `phase3_runtime_repair_2026_05_19_rls_helpers.sql`
2. If `public.app_phase3_is_admin()` is false for `admin@test.gehu`, run `phase3_runtime_repair_2026_05_19_admin_identity_repair.sql`.
3. `phase3_runtime_repair_2026_05_19_verify.sql`
4. In SQL Editor, run `phase3_runtime_repair_2026_05_19_simulate_admin_policy_check.sql` to test the app JWT context for `admin@test.gehu`.
5. If admin result filters or profile display still show `MCA` as branch or long MCA course labels, run `../phase_profile_runtime_chunks/phase_profile_runtime_chunk_02_repair_test_student_course_branch.sql`.
6. If the app still reports permission/session errors, run `phase3_runtime_repair_2026_05_19_auth_policy_diagnostics.sql` while authenticated as the affected admin/student.

Expected verification:

- `app_phase3_is_admin` has `security_definer = true`.
- `app_phase3_uid_is_self` has `security_definer = true`.
- Policies exist for `app_appeals`, `app_official_feedback`, `app_notices`, and `app_notice_attachments`.
- Simulated admin check shows `helper_says_admin = true`, `identity_row_says_admin = true`, no permission denied on appeal/notice counts, and all rollback-only write smoke booleans are `true`.
- Diagnostic output shows `helper_says_admin = true` for admin accounts and `helper_says_self = true` for the affected student profile row.
- Profile/runtime repair changes only known test accounts and sets course/branch labels to `MCA` / `Haldwani` in both `public.app_profile_state` and `mocks.mock_results`.

Do not disable RLS and do not add Firebase fallback for these flows.
