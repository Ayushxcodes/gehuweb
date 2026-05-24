-- Phase M2 / Chunk 06
-- Verification queries

-- 1) New indexes
select schemaname, tablename, indexname
from pg_indexes
where schemaname = 'mocks'
  and indexname like 'idx_m2_mock_%'
order by tablename, indexname;

-- 2) New RPC/functions
select n.nspname as schema_name, p.proname as function_name
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'mocks'
  and p.proname in (
    'current_student_context',
    'api_student_mock_feed',
    'api_student_results_feed',
    'api_admin_mock_results_page',
    'api_admin_publish_results'
  )
order by p.proname;

-- 3) Smoke checks (zero/empty is okay in SQL editor if auth.uid() is null)
select count(*) as student_feed_rows
from mocks.api_student_mock_feed(10, null::timestamptz, null::text);

select count(*) as student_result_rows
from mocks.api_student_results_feed(10, null::timestamptz, null::bigint);
