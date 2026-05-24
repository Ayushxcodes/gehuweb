# Checkpoint: 2026-05-03 Phase 3 Prep

## Completed
- Phase 3 schema chunks created for current live app contract:
  - `app_profile_state`
  - `app_appeals`
  - `app_official_feedback`
  - `app_inbox`
  - `app_notice_reads`
  - `app_notification_meta`
  - `app_notices`
  - `app_notice_attachments`
  - `app_notifications`
  - `app_directory_index`
- Strict RLS chunks created:
  - student self-scope
  - admin-scope writes
- Backfill pipeline chunks created:
  - read-only staging tables
  - upsert scripts
  - reconciliation checks
- Feature switch runbook added:
  - `docs/migration/09_phase3_feature_switch_runbook.md`

## Pending (Run by operator in Supabase SQL Editor)
1. Run files in `supabase/schema/phase3_chunks/README_RUN_ORDER.md`.
2. Load Firebase export data into `stage_import.*` tables.
3. Execute backfill chunks and verify hard checks.
4. Start feature-by-feature app switch only after parity passes.

