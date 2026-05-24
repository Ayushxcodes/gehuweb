-- Phase M3 / Chunk 02
-- Verify student submit RPC exists.

select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'mocks'
  and p.proname = 'api_student_submit_mock_result';

select
  table_name,
  row_count
from (
  select 'mock_tests' as table_name, count(*)::bigint as row_count
  from mocks.mock_tests
  union all
  select 'mock_test_questions', count(*)::bigint
  from mocks.mock_test_questions
  union all
  select 'mock_results', count(*)::bigint
  from mocks.mock_results
) s
order by table_name;

