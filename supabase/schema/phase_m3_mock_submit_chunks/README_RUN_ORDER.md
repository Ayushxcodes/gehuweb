# Phase M3 Mock System Run Order

This folder contains both historical debug scripts and the current production repair script.
Do not run every file blindly.

## Current Safe Path

If Phase M1 and Phase M2 mock schema files were already applied, run only:

1. `phase_m3_mock_submit_chunk_12_contract_repair.sql`

This is the current production contract repair. It:

- Adds missing columns required by the web mock organizer and runner.
- Repairs `mocks.api_student_submit_mock_result`.
- Repairs `mocks.api_student_mock_feed`.
- Repairs `mocks.api_student_results_feed`.
- Repairs `mocks.api_admin_publish_results`.
- Adds `mocks.mock_hardware_checks`.
- Adds `mocks.api_student_mark_mock_hardware_ready`.
- Adds `ops.v_mock_readiness_summary`.

Expected final output contains:

```text
mock_contract_repair_installed | true
has_hardware_table             | true
has_proctoring_column          | true
has_hardware_rpc               | true
has_mock_feed_rpc              | true
has_results_feed_rpc           | true
has_admin_publish_rpc          | true
```

## Historical Files

Chunks `01` through `09` were incremental attempts during mock submission/feed development.

Chunk `10` is a debug script that force-removes visibility filters. Do not use it for production.

Chunk `11` includes lock-recovery commands such as `pg_terminate_backend`. Do not use it as a normal deployment migration.

## If A Fresh Database Is Being Built

Run the base mock schema first:

1. `../phase_m1_mock_schema.sql`
2. `../phase_m1_mock_rls.sql`
3. `../phase_m2_mock_scale_chunks/phase_m2_mock_scale_chunk_01_indexes.sql`
4. `../phase_m2_mock_scale_chunks/phase_m2_mock_scale_chunk_04_admin_results_page_rpc.sql`
5. `phase_m3_mock_submit_chunk_12_contract_repair.sql`

Stop immediately on any SQL error and share the exact error text.
