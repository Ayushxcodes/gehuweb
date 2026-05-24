-- Phase M3 / Chunk 07 (Diagnostic Dummy Feed)
-- Purpose: This replaces the results feed with a HARDCODED instant return.
-- If this STILL times out, your Supabase Database connection pool is completely locked
-- up by ghost queries and you MUST restart your database/dev server.
-- If this returns instantly, we know the previous query was somehow still hanging.

begin;

create or replace function mocks.api_student_results_feed(
  p_limit integer default 25,
  p_before_submitted_at timestamptz default null,
  p_before_result_id bigint default null
)
returns table (
  result_id bigint,
  test_id text,
  title text,
  start_at timestamptz,
  submitted_at timestamptz,
  score numeric,
  max_marks integer,
  percentage numeric,
  correct integer,
  wrong integer,
  unattempted integer,
  test_type text
)
language sql
stable
as $$
  select 
    999999::bigint as result_id,
    'DIAGNOSTIC_TEST_ID'::text as test_id,
    'DIAGNOSTIC: If you see this, the SQL was hanging. If it still timed out, your DB is locked.'::text as title,
    now()::timestamptz as start_at,
    now()::timestamptz as submitted_at,
    100.00::numeric as score,
    100::integer as max_marks,
    100.00::numeric as percentage,
    100::integer as correct,
    0::integer as wrong,
    0::integer as unattempted,
    'MET'::text as test_type;
$$;

commit;

notify pgrst, 'reload schema';
