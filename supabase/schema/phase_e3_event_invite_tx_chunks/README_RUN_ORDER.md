# Phase E3 Event Invite Transactions Run Order

Purpose: install safe Supabase RPCs for team invite lifecycle.

Run in Supabase SQL Editor, one by one:

1. `phase_e3_event_invite_tx_chunk_01_send_invite_rpc.sql`
2. `phase_e3_event_invite_tx_chunk_02_accept_invite_rpc.sql`
3. `phase_e3_event_invite_tx_chunk_03_reject_invite_rpc.sql`
4. `phase_e3_event_invite_tx_chunk_04_remove_invite_rpc.sql`
5. `phase_e3_event_invite_tx_chunk_05_verify.sql`

Important:
- These chunks do not delete Firebase data.
- These chunks do not switch Android runtime.
- These chunks do not touch notification bell / FCM runtime.
- Students should call these RPCs through authenticated Supabase session only.
