# Phase 3 Run Order (One-by-One, No Bulk)

Run in this exact sequence:

1. `../phase3_schema_chunks/phase3_schema_chunk_01.sql`
2. `../phase3_schema_chunks/phase3_schema_chunk_02.sql`
3. `../phase3_schema_chunks/phase3_schema_chunk_03.sql`
4. `../phase3_schema_chunks/phase3_schema_chunk_04.sql`
5. `../phase3_rls_chunks/phase3_rls_chunk_01.sql`
6. `../phase3_rls_chunks/phase3_rls_chunk_02.sql`
7. `../phase3_rls_chunks/phase3_rls_chunk_03.sql`
8. `../phase3_rls_chunks/phase3_rls_chunk_04.sql`
9. `../phase3_verify_schema_rls.sql`
10. `../phase3_backfill_chunks/phase3_backfill_chunk_01_stage.sql`
11. Load Firebase export rows into `stage_import.*` tables
12. `../phase3_backfill_chunks/phase3_backfill_chunk_02_profile_directory.sql`
13. `../phase3_backfill_chunks/phase3_backfill_chunk_03_appeals_notices_notifications.sql`
14. `../phase3_backfill_chunks/phase3_backfill_chunk_04_user_subcollections.sql`
15. `../phase3_backfill_chunks/phase3_backfill_chunk_05_verify.sql`

Important:
- Open a fresh SQL tab for each file.
- Clear previous text before pasting next file.
- Do not run multiple files together.
- If one step fails, stop and share the exact error text.

