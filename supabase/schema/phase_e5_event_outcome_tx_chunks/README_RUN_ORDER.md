# Phase E5: Event Attendance, Results, Certificate Transaction RPCs

Run these files in Supabase SQL Editor in this exact order.

1. `phase_e5_event_outcome_tx_chunk_01_columns_helpers.sql`
2. `phase_e5_event_outcome_tx_chunk_02_mark_attendance_rpc.sql`
3. `phase_e5_event_outcome_tx_chunk_03_attendance_page_rpc.sql`
4. `phase_e5_event_outcome_tx_chunk_04_publish_results_rpc.sql`
5. `phase_e5_event_outcome_tx_chunk_05_certificate_rpcs.sql`
6. `phase_e5_event_outcome_tx_chunk_06_verify.sql`

Stop immediately if any file errors.

This phase only installs database contracts.
It does not switch Android runtime from Firebase.
It does not touch FCM, bell notification, or mail flow.
