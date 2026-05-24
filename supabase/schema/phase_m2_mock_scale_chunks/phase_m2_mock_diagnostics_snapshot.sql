-- Mock diagnostics snapshot
-- Run this single file and share outputs.

-- 1) Mock and ops tables present
select table_schema, table_name
from information_schema.tables
where table_schema in ('mocks', 'ops')
order by table_schema, table_name;

-- 2) Required columns for mock creation in mocks.mock_tests
with required(col) as (
  values
    ('test_id'), ('title'), ('campus'), ('branch'), ('course'), ('semester'),
    ('total_questions'), ('duration_minutes'), ('start_at'),
    ('status'), ('source'), ('marking_aptitude_per_q'),
    ('marking_english_per_q'), ('negative_enabled'),
    ('negative_value'), ('negative_apply_to'), ('frozen_ids'),
    ('published'), ('results_published')
)
select r.col as required_column,
       (c.column_name is not null) as exists_in_db
from required r
left join information_schema.columns c
  on c.table_schema = 'mocks'
 and c.table_name = 'mock_tests'
 and c.column_name = r.col
order by r.col;

-- 3) Required columns for frozen question snapshot
with required(col) as (
  values
    ('test_id'), ('qid'), ('subject'), ('question'),
    ('option_a'), ('option_b'), ('option_c'), ('option_d'),
    ('answer_letter')
)
select r.col as required_column,
       (c.column_name is not null) as exists_in_db
from required r
left join information_schema.columns c
  on c.table_schema = 'mocks'
 and c.table_name = 'mock_test_questions'
 and c.column_name = r.col
order by r.col;

-- 4) API function signatures
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
join pg_namespace n
  on n.oid = p.pronamespace
where n.nspname = 'mocks'
  and p.proname like 'api_%'
order by p.proname;

-- 5) RLS + policy count in mocks schema
select
  t.tablename,
  t.rowsecurity as rls_enabled,
  count(pol.policyname) as policy_count
from pg_tables t
left join pg_policies pol
  on pol.schemaname = t.schemaname
 and pol.tablename = t.tablename
where t.schemaname = 'mocks'
group by t.tablename, t.rowsecurity
order by t.tablename;

-- 6) Row counts in core mock tables
select 'mock_tests' as table_name, count(*) as row_count from mocks.mock_tests
union all
select 'mock_test_questions', count(*) from mocks.mock_test_questions
union all
select 'mock_results', count(*) from mocks.mock_results
union all
select 'mock_sessions_legacy', count(*) from mocks.mock_sessions_legacy
union all
select 'mock_results_legacy', count(*) from mocks.mock_results_legacy
order by table_name;
