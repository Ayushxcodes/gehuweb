# Phase E7: Event Runtime + FCM Cutover Run Order

Run these chunks after E1-E6 and B1 notification bell chunks.

There are **4 SQL files** in this phase. The verify file is named `chunk_03_verify`
because it was created before the date+time repair, but it must still run **last**.
So the correct order is `01`, `02`, `04`, then `03_verify`.

1. `phase_e7_event_fcm_runtime_chunk_01_device_tokens_push_queue.sql`
2. `phase_e7_event_fcm_runtime_chunk_02_event_announcement_push_rpc.sql`
3. `phase_e7_event_fcm_runtime_chunk_04_schedule_datetime_rpc.sql`
4. `phase_e7_event_fcm_runtime_chunk_03_verify.sql`

Purpose:

- Stores Android and web FCM registration tokens in Supabase.
- Adds an auditable Supabase push queue.
- Adds a shared event announcement RPC that writes event announcements, student inbox rows, and push queue rows together.
- Adds service-role-only RPCs for the trusted Firebase Cloud Function sender.
- Repairs schedule replacement so event stages preserve `starts_at` and `ends_at` date+time values.

Security:

- Android/web never receive or use `service_role`.
- Android/web only call authenticated RPCs with the user's Supabase JWT.
- FCM sending is server-side only, through the Cloud Function using Supabase service-role secret plus Firebase Admin SDK.
