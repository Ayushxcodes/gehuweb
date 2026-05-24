# Phase N1 Notice/Mail SQL Run Order

Run these files in Supabase SQL Editor after Phase 3 tables/RLS are already present.

1. `phase_n1_notice_mail_chunk_01_student_feed_rpc.sql`
2. `phase_n1_notice_mail_chunk_02_mark_read_rpc.sql`
3. `phase_n1_notice_mail_chunk_03_verify.sql`

Purpose:
- Give Android and future web one indexed Supabase contract for student mail feed.
- Keep read-state writes bound to the logged-in Supabase user through `app_profile_state`.
- Avoid changing Firebase notification/bell behavior during this module.

Rollback:
- Set `AUTH_PROVIDER=firebase` in `local.properties`; Android will stop using these RPCs.
