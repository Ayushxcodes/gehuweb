-- Phase M2 / Chunk 01
-- Mock scale indexes (additive, safe, idempotent)

create index if not exists idx_m2_mock_tests_posted_start_test
  on mocks.mock_tests (start_at desc, test_id desc)
  where status = 'POSTED';

create index if not exists idx_m2_mock_tests_posted_segment_start_test
  on mocks.mock_tests (lower(branch), lower(course), lower(semester), start_at desc, test_id desc)
  where status = 'POSTED';

create index if not exists idx_m2_mock_results_auth_test_updated
  on mocks.mock_results (auth_user_id, test_id, updated_at desc)
  where auth_user_id is not null;

create index if not exists idx_m2_mock_results_student_test_updated
  on mocks.mock_results (student_id, test_id, updated_at desc)
  where student_id is not null;

create index if not exists idx_m2_mock_results_test_locked_submitted
  on mocks.mock_results (test_id, locked, submitted_at desc, result_id desc);

create index if not exists idx_m2_mock_results_test_publish_locked
  on mocks.mock_results (test_id, published, results_published, locked);

create index if not exists idx_m2_mock_questions_test_qindex_qid
  on mocks.mock_test_questions (test_id, q_index, qid);
