-- Phase M3 / Chunk 02 (QET Type & Custom Alphanumeric Code)
-- Purpose: Adds test_type ('MET' / 'QET') and unique custom_code (e.g. 'MET-0001' or 'QET-0002') to mocks.mock_tests.
-- Backfills all existing records using a foolproof temporary sequence.
-- Drops NOT NULL constraints temporarily to ensure 100% success on any subsequent re-runs.

begin;

-- 1. Ensure columns exist
alter table mocks.mock_tests 
  add column if not exists test_type text
  check (test_type in ('MET', 'QET'));

alter table mocks.mock_tests 
  add column if not exists custom_code text;

-- 2. Drop NOT NULL constraints temporarily (Crucial for successful re-runs!)
alter table mocks.mock_tests alter column test_type drop not null;
alter table mocks.mock_tests alter column custom_code drop not null;

-- 3. Create a temporary sequence to assign sequential codes safely
create temporary sequence if not exists seq_temp_mock_codes start 1;

-- 4. Foolproof update: Direct assignment on every row (Zero Joins!)
update mocks.mock_tests
set test_type = case when coalesce(requires_web_proctoring, false) then 'MET' else 'QET' end,
    custom_code = case when coalesce(requires_web_proctoring, false) then 'MET-' else 'QET-' end || lpad(nextval('seq_temp_mock_codes')::text, 4, '0');

-- 5. Drop the temporary sequence immediately
drop sequence if exists seq_temp_mock_codes;

-- 6. Enforce NOT NULL constraints now that every single row is guaranteed to be filled
alter table mocks.mock_tests
  alter column test_type set default 'MET',
  alter column test_type set not null,
  alter column custom_code set not null;

-- Drop constraints if already present to prevent errors on multiple runs
alter table mocks.mock_tests drop constraint if exists uq_mock_tests_custom_code;
alter table mocks.mock_tests add constraint uq_mock_tests_custom_code unique (custom_code);

-- 7. Add index on custom_code
create index if not exists idx_mock_tests_custom_code 
  on mocks.mock_tests(custom_code);

commit;
