# Phase E1: Events Foundation Run Order

Run these files in Supabase SQL Editor in this exact order.

1. `phase_e1_event_core_chunk_01_core_competitions.sql`
2. `phase_e1_event_core_chunk_02_registration_team.sql`
3. `phase_e1_event_core_chunk_03_payment_attendance.sql`
4. `phase_e1_event_core_chunk_04_comms_results_certs.sql`
5. `phase_e1_event_core_chunk_04b_certificate_position_repair.sql`
6. `phase_e1_event_core_chunk_05_indexes_grants.sql`
7. `phase_e1_event_core_chunk_06a_identity_helpers.sql`
8. `phase_e1_event_core_chunk_06b_visibility_helper.sql`
9. `phase_e1_event_core_chunk_07_rls_catalog.sql`
10. `phase_e1_event_core_chunk_08_rls_private.sql`
11. `phase_e1_event_core_chunk_09_admin_write_policies.sql`
12. `phase_e1_event_core_chunk_10a_student_feed_verify_rpcs.sql`
13. `phase_e1_event_core_chunk_10b_student_detail_rpc.sql`
14. `phase_e1_event_core_chunk_11_verify.sql`

Open a fresh SQL tab for each file.

Clear the editor before pasting the next file.

Stop immediately if any step errors and share the exact error text.

This phase creates the Supabase event contract only.

It does not switch Android event runtime away from Firebase.

Student event writes are intentionally blocked until the transaction RPC phase.

Certificate public verification is available through:

- `api_verify_event_certificate(p_verify_code text)`
