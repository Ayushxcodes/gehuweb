# Phase F1: Feedback Run Order

Run these files in Supabase SQL Editor in this exact order:

1. `phase_f1_feedback_chunk_01_templates_teachers.sql`
2. `phase_f1_feedback_chunk_02_cycles.sql`
3. `phase_f1_feedback_chunk_03_submission_response.sql`
4. `phase_f1_feedback_chunk_04_rls.sql`
5. `phase_f1_feedback_chunk_05_policies.sql`
6. `phase_f1_feedback_chunk_06_student_feed_rpc.sql`
   - If SQL editor still has the stale GROUP BY version open, run `phase_f1_feedback_chunk_06b_student_feed_rpc_repair.sql` instead.
7. `phase_f1_feedback_chunk_07_student_detail_rpc.sql`
8. `phase_f1_feedback_chunk_08_submit_rpc.sql`
9. `phase_f1_feedback_chunk_09_admin_results_rpc.sql`
10. `phase_f1_feedback_chunk_10_verify.sql`

This phase creates the Supabase contract only.

It does not:
- switch Android feedback runtime from Firebase
- change R2 upload behavior
- change mandatory popup/gate behavior
- send FCM from Supabase

Expected empty-table state is valid until feedback data is migrated or mirrored.
