# Phase 4 Login-First Run Order (Student + Admin)

Use this when you want to test login behavior safely before full feature cutover.

Run in this exact order:

1. `phase4_verify_identity_and_rls.sql`
2. `phase4_login_checks/phase4_login_step_01_readiness.sql`
3. `phase4_login_checks/phase4_login_step_02_hydrate_profile_from_student_domain.sql`
4. `phase4_login_checks/phase4_login_step_03_required_field_gap_report.sql`
5. `phase4_login_checks/phase4_login_step_03b_required_field_gap_details.sql` (optional deep view)
6. `phase4_login_checks/phase4_login_step_04a_seed_min_student_contact_parent.sql` (if Step 03 shows blockers)
7. `phase4_login_checks/phase4_login_step_04b_seed_min_student_enrollment.sql`
8. Re-run Step 02, then Step 03
9. `phase4_login_checks/phase4_login_step_05_post_green_verify.sql`
10. `phase4_login_checks/phase4_login_step_05b_optional_seed_admin_profile_state.sql` (only if admin UI needs profile row)
11. `phase4_login_checks/phase4_login_step_06_db_gate_before_manual_login.sql`

Notes:
- Run only `.sql` files. Do not run `.md`.
- This sequence does not touch notices/bell/mock logic.
- Step 02 is safe: it only fills blank profile fields from existing student tables and does not delete data.
- If Step 03 still shows missing fields, fill those rows manually before app login demo.
