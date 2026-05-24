# Web Runtime Debug Run Order

Use only when web login/auth routing behaves incorrectly.

1. `web_runtime_debug_chunk_01_identity_schema_check.sql`
2. `web_runtime_debug_chunk_02_lock_diagnostics.sql`
3. `web_runtime_debug_chunk_03_terminate_idle_transactions.sql` only if chunk 02 shows old idle blockers.

Do not run chunk 03 unless you have confirmed a stuck/idle transaction is present.

