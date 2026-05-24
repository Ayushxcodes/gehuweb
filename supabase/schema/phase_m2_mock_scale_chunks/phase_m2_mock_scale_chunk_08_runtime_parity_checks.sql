-- Phase M2 / Chunk 08 (Runtime Parity Checks)
-- Purpose:
-- 1) Quick health check after admin creates a mock.
-- 2) Quick health check after student submissions.
-- 3) Quick health check after admin publishes results.
--
-- Usage:
-- Replace REPLACE_TEST_ID once, then run whole file.

with params as (
  select 'REPLACE_TEST_ID'::text as test_id
)
select
  t.test_id,
  t.title,
  t.status,
  t.start_at,
  t.exam_end_at,
  t.results_published,
  t.created_at
from mocks.mock_tests t
join params p on p.test_id = t.test_id;

with params as (
  select 'REPLACE_TEST_ID'::text as test_id
)
select
  p.test_id,
  count(q.*)::bigint as question_rows
from params p
left join mocks.mock_test_questions q
  on q.test_id = p.test_id
group by p.test_id;

with params as (
  select 'REPLACE_TEST_ID'::text as test_id
)
select
  p.test_id,
  count(r.*)::bigint as results_total,
  count(*) filter (where r.locked) as locked_rows,
  count(*) filter (where r.published) as published_rows,
  count(*) filter (where r.results_published) as results_published_rows
from params p
left join mocks.mock_results r
  on r.test_id = p.test_id
group by p.test_id;

with params as (
  select 'REPLACE_TEST_ID'::text as test_id
)
select
  r.result_id,
  r.student_id,
  r.auth_user_id,
  r.locked,
  r.published,
  r.results_published,
  r.score,
  r.max_marks,
  r.percentage,
  r.submitted_at,
  r.updated_at
from mocks.mock_results r
join params p on p.test_id = r.test_id
order by r.submitted_at desc nulls last, r.result_id desc
limit 50;

-- Optional API smoke checks (works only with authenticated session):
-- select count(*) as student_feed_rows
-- from mocks.api_student_mock_feed(10, null::timestamptz, null::text);
--
-- select count(*) as student_result_rows
-- from mocks.api_student_results_feed(10, null::timestamptz, null::bigint);
