-- Web Runtime Debug / Chunk 03
-- Optional. Use only if chunk 02 shows old idle transaction blockers.

select
  pid,
  state,
  now() - xact_start as xact_age,
  pg_terminate_backend(pid) as terminated,
  left(query, 160) as query_preview
from pg_stat_activity
where datname = current_database()
  and pid <> pg_backend_pid()
  and state = 'idle in transaction'
  and xact_start < now() - interval '60 seconds';

