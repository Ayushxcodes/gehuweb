# Phase E4 Event Payment Transactions Run Order

Purpose: install safe Supabase RPCs for event payment proof and admin verification.

Run in Supabase SQL Editor, one by one:

1. `phase_e4_event_payment_tx_chunk_01_columns_indexes.sql`
2. `phase_e4_event_payment_tx_chunk_02_student_submit_proof_rpc.sql`
3. `phase_e4_event_payment_tx_chunk_03_student_gateway_success_rpc.sql`
4. `phase_e4_event_payment_tx_chunk_04_admin_verify_reject_rpc.sql`
5. `phase_e4_event_payment_tx_chunk_05_admin_pending_list_rpc.sql`
6. `phase_e4_event_payment_tx_chunk_06_verify.sql`

Important:
- These chunks do not delete Firebase data.
- These chunks do not switch Android runtime.
- R2 remains storage; Supabase stores proof metadata only.