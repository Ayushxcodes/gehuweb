# Checkpoint: Phase M2 Mock Dual-Write Runtime

Date: 2026-05-03

## Scope Completed Today
1. Fixed Supabase custom schema API access for `mocks` using SQL route (no UI dependency):
   - `supabase/schema/phase_m2_mock_scale_chunks/phase_m2_mock_api_access_fix.sql`
   - `supabase/schema/phase_m2_mock_scale_chunks/phase_m2_mock_api_access_verify.sql`
2. Added Android runtime mirror writer (Firebase primary, Supabase best-effort mirror):
   - `app/src/main/java/com/gehu/connect/data/remote/mock/SupabaseMockMirrorHelper.java`
3. Wired manual mock flow mirror after Firebase commit:
   - `app/src/main/java/com/gehu/connect/data/repo/FirestoreAdminRepo.java`
   - Includes snapshot fallback from committed Firestore question subcollection.
4. Wired CSV mock flow mirror after all Firebase batches succeed:
   - `app/src/main/java/com/gehu/connect/ui/admin/CsvMockActivity.java`
5. Updated repo creation context so session token is available:
   - `app/src/main/java/com/gehu/connect/ui/admin/MockAdminPanelActivity.java`

## Verified Facts
1. Authenticator role config contains:
   - `pgrst.db_schemas=public,graphql_public,mocks`
2. `mocks` schema grants verified for `authenticated`.
3. RLS enabled with policies on mock tables.
4. Runtime mirror success confirmed in logcat:
   - `SupabaseMockMirror ... PASS | testId=YlLyhhbkUMiabrJtzJpr, qRows=10`
5. Database confirmation for same test ID:
   - `mocks.mock_tests` row exists for `YlLyhhbkUMiabrJtzJpr`
   - `mocks.mock_test_questions` count = `10`

## Important Clarification
1. Old test `54AQBRxk9BPMVyNiCcEe` remains as historical failed mirror attempt:
   - `frozen_count=0`, `question_rows=0`
2. This is expected and does not invalidate new successful runtime path.

## Current Mock Migration Status
1. Admin create mock to Supabase mirror: Done.
2. Question snapshot mirror to Supabase: Done (verified).
3. Student attempt + result write/read cutover to Supabase runtime: Pending.
4. Admin publish/result runtime cutover to Supabase: Pending.

## First Step Tomorrow
1. Run one controlled student attempt for a mirrored test ID.
2. Verify corresponding rows in `mocks.mock_results` (and session table if used).
3. Then decide cutover sequence for student mock read/result screens behind feature flag.
