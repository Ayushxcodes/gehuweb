# Phase B1: Notification Bell/Inbox Run Order

Run these files in Supabase SQL Editor in this exact order:

1. `phase_b1_notification_bell_chunk_01_helpers.sql`
2. `phase_b1_notification_bell_chunk_02_student_feed_rpc.sql`
3. `phase_b1_notification_bell_chunk_03_badge_count_rpc.sql`
4. `phase_b1_notification_bell_chunk_04_state_write_rpc.sql`
5. `phase_b1_notification_bell_chunk_05_verify.sql`

This phase is additive:
- It does not delete tables.
- It does not change Android notification runtime.
- It does not touch FCM.
- It builds a clean Supabase contract for the bell and notification hub.

Expected verification:
- Six public functions are listed.
- `app_inbox`, `app_notifications`, and `app_notification_meta` have RLS enabled.
- Row counts can be `0`; that is valid before Firebase backfill/mirror is active.
