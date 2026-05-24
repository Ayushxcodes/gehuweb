# Phase E2: Event Transaction RPC Run Order

Run these files in Supabase SQL Editor in this exact order.

1. `phase_e2_event_tx_chunk_01_contract_columns.sql`
2. `phase_e2_event_tx_chunk_02_helpers.sql`
3. `phase_e2_event_tx_chunk_03_my_state_rpc.sql`
4. `phase_e2_event_tx_chunk_04_register_solo_rpc.sql`
5. `phase_e2_event_tx_chunk_05_register_team_rpc.sql`
6. `phase_e2_event_tx_chunk_06_verify.sql`

Stop immediately if any file errors.

This phase only installs registration transaction RPCs.

It does not switch Android runtime from Firebase.

It does not install invite, payment approval, attendance, result publish, or certificate issue transactions yet.

Student direct writes remain blocked by RLS.

Web and Android should call RPCs for registration once this phase is verified:

- `api_event_register_solo`
- `api_event_register_team`
- `api_event_my_state`
