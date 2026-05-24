# Phase E6: Event Operations RPC Run Order

Run these files in Supabase SQL Editor in this exact order.

1. `phase_e6_event_ops_tx_chunk_01_scanner_table.sql`
2. `phase_e6_event_ops_tx_chunk_02_schedule_rpcs.sql`
3. `phase_e6_event_ops_tx_chunk_03_group_rpcs.sql`
4. `phase_e6_event_ops_tx_chunk_04_lifecycle_rpcs.sql`
5. `phase_e6_event_ops_tx_chunk_05_scanner_rpcs.sql`
6. `phase_e6_event_ops_tx_chunk_06_verify.sql`

Stop immediately if any file errors.

Database contract only. No Android/Firebase/FCM runtime cutover.
