-- Web Runtime Debug / Chunk 02
-- Shows possible lock waits or idle transactions. Read-only.

select
  pid,
  usename,
  state,
  wait_event_type,
  wait_event,
  now() - xact_start as xact_age,
  left(query, 240) as query_preview
from pg_stat_activity
where datname = current_database()
  and pid <> pg_backend_pid()
  and (
    wait_event_type = 'Lock'
    or state = 'idle in transaction'
    or query ilike '%auth.users%'
    or query ilike '%app_user_identity%'
  )
order by xact_start nulls last, query_start nulls last;

