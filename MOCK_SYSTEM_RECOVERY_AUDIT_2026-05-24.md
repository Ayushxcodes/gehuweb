# Mock System Recovery Audit - 2026-05-24

Repository audited: `E:\Major Project\gehuweb`

## Current Verified State

- Production build now passes with `npm.cmd run build`.
- The previous M3 README was stale and listed only early chunks while the folder contained debug/recovery scripts through chunk 11.
- The current production SQL entry point is now `supabase/schema/phase_m3_mock_submit_chunks/phase_m3_mock_submit_chunk_12_contract_repair.sql`.

## Concrete Faults Found

1. `src/app/admin/reports/page.tsx` called `api_admin_publish_results` without `.schema('mocks')`.
   - Effect: Supabase searched `public.api_admin_publish_results`, causing publish failures or blank RPC errors.
   - Fix: admin publishing now calls `supabase.schema('mocks').rpc(...)`.

2. `src/app/admin/mock-tests/manual/page.tsx` and `src/app/admin/mock-tests/csv/page.tsx` inserted `null` for `branch/course/semester` when UI selected `ALL`.
   - Effect: base `mocks.mock_tests` has non-null coordinate columns, so hosting could fail depending on selected filters.
   - Fix: UI now stores `"ALL"` explicitly.

3. The same create pages sent a `campus` column to `mocks.mock_tests`, but the checked-in schema did not guarantee that column.
   - Effect: PostgREST can reject the insert with a schema-cache/unknown-column error.
   - Fix: removed `campus` from the web insert payload. `branch` remains the source of campus targeting.

4. The web mock create flow used `negative_value_aptitude`, `negative_value_english`, and `requires_web_proctoring`, but the base schema did not define them.
   - Effect: create/submit/feed RPCs could fail depending on the live DB state.
   - Fix: chunk 12 adds these columns safely and repairs the submit/feed RPCs.

5. Proctored mock cards linked to `/student/mock-tests/readiness-check`, but no page existed there.
   - Effect: proctored tests could send students to 404, and `my_hardware_verified` was never persisted.
   - Fix: added the readiness page and matching hardware-check table/RPC in chunk 12.

6. The old chunk 11 included `pg_terminate_backend`.
   - Effect: unsafe as a normal production migration because it can terminate other active sessions for the same DB role.
   - Fix: chunk 12 does not terminate connections.

## Files Changed By This Pass

- `src/app/admin/mock-tests/manual/page.tsx`
- `src/app/admin/mock-tests/csv/page.tsx`
- `src/app/admin/reports/page.tsx`
- `src/app/student/dashboard/page.tsx`
- `src/app/student/mock-tests/readiness-check/page.tsx`
- `supabase/schema/phase_m3_mock_submit_chunks/phase_m3_mock_submit_chunk_12_contract_repair.sql`
- `supabase/schema/phase_m3_mock_submit_chunks/README_RUN_ORDER.md`

## SQL Step To Run

Run this file in Supabase SQL Editor:

```text
E:\Major Project\gehuweb\supabase\schema\phase_m3_mock_submit_chunks\phase_m3_mock_submit_chunk_12_contract_repair.sql
```

Expected final output:

```text
mock_contract_repair_installed | true
has_hardware_table             | true
has_proctoring_column          | true
has_hardware_rpc               | true
has_mock_feed_rpc              | true
has_results_feed_rpc           | true
has_admin_publish_rpc          | true
```

If any value is false or SQL errors, stop and paste the exact SQL output back to Codex/Antigravity.

## Manual Verification After SQL

1. Open web as admin.
2. Create a manual or CSV mock test using:
   - Branch: `Haldwani`
   - Course: `MCA`
   - Semester: `4`
   - Start date/time: a future time for upcoming test, or very near future for live test.
3. Confirm `/admin/mock-tests/manage` lists the mock.
4. Log in as the matching student.
5. Confirm `/student/mock-tests` shows the mock in Upcoming/Ongoing.
6. If proctored, open readiness check, allow camera/microphone, and confirm it reports verified.
7. Enter runner, answer at least one question, submit.
8. Open admin reports, fetch the test, publish results.
9. Confirm `/student/results` shows:
   - submitted scorecard for submitted student,
   - absent card only for cohort tests after results are published.

## Important Do Not Run Notes

- Do not run chunk 10 in production. It strips visibility filters for debugging.
- Do not run chunk 11 as a normal deploy migration. It contains lock/session termination logic.
- Use chunk 12 as the current repair layer unless a fresh DB rebuild is being performed.

## Residual Risks

- I did not execute SQL against Supabase from this machine, so the live DB still needs the chunk 12 output verified.
- The repo has many Antigravity changes outside this pass. I did not revert them.
- If Vercel has different environment variables than local `.env`, public deployment can still fail even when local build passes.
