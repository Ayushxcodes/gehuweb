# Phase M2 Mock Scale Run Order (copy/paste friendly)

Run these files in this exact order:

1. `phase_m2_mock_scale_chunk_01_indexes.sql`
2. `phase_m2_mock_scale_chunk_02_student_feed_rpc.sql`
3. `phase_m2_mock_scale_chunk_03_student_results_rpc.sql`
4. `phase_m2_mock_scale_chunk_04_admin_results_page_rpc.sql`
5. `phase_m2_mock_scale_chunk_05_admin_publish_rpc.sql`
6. `phase_m2_mock_scale_chunk_06_verify.sql`
7. `phase_m2_mock_scale_chunk_07_optional_targeting_and_ops.sql` (optional but recommended)
8. `phase_m2_mock_scale_chunk_08_runtime_parity_checks.sql` (runtime sanity after real app actions)

Important:
- Open a fresh SQL tab for each file.
- Clear SQL editor before pasting next file.
- Stop immediately if any step errors, then share exact error text.
