-- Phase M3 / Chunk 16 (Publication State Sync)
-- Purpose:
-- 1) Keep old published result rows compatible with the new student result feed.
-- 2) Repair admin publish so selected-test publication always flips the test-level release gate.
-- 3) Do not add tables, columns, policies, or views.
--
-- Important contract:
-- - mocks.mock_tests.results_published is the student-visible release switch.
-- - mocks.mock_results.published/results_published are row-level audit flags for submitted rows.
-- - Absent students do not need mock_results rows; the student results RPC creates absent cards from the published test header.

begin;

create or replace function mocks.normalize_course(p_course text)
returns text
language sql
immutable
as $$
  select case
    when p_course is null or trim(p_course) = '' then 'ALL'
    when lower(trim(p_course)) in (
      'mca',
      'master of computer application',
      'master of computer applications',
      'masters of computer application',
      'masters of computer applications'
    ) then 'MCA'
    when lower(trim(p_course)) in (
      'bca',
      'bachelor of computer application',
      'bachelor of computer applications'
    ) then 'BCA'
    when lower(trim(p_course)) in (
      'b.tech cse',
      'btech cse',
      'bachelor of technology cse',
      'bachelor of technology in computer science'
    ) then 'B.Tech CSE'
    when lower(trim(p_course)) in ('b.tech', 'btech', 'bachelor of technology') then 'B.Tech'
    when lower(trim(p_course)) in ('m.tech', 'mtech', 'master of technology') then 'M.Tech'
    when lower(trim(p_course)) in ('mba', 'master of business administration') then 'MBA'
    else trim(p_course)
  end;
$$;

grant execute on function mocks.normalize_course(text) to authenticated;

create or replace function mocks.api_admin_publish_results(
  p_test_id text,
  p_branch text default null,
  p_course text default null,
  p_semester text default null
)
returns integer
language plpgsql
security definer
set search_path = public, mocks, pg_temp
as $$
declare
  v_count integer := 0;
  v_exists boolean := false;
begin
  if not mocks.is_admin() then
    raise exception 'forbidden: admin role required';
  end if;

  select exists (
    select 1
    from mocks.mock_tests mt
    where mt.test_id = p_test_id
  ) into v_exists;

  if not v_exists then
    raise exception 'mock test not found: %', p_test_id;
  end if;

  -- The header is the release gate used by student result feed, including absent cards.
  update mocks.mock_tests mt
  set results_published = true,
      updated_at = now()
  where mt.test_id = p_test_id
    and coalesce(mt.results_published, false) = false;

  -- Existing submitted/locked rows get row-level audit flags. Absentees are represented synthetically.
  update mocks.mock_results r
  set published = true,
      results_published = true,
      published_at = coalesce(r.published_at, now()),
      updated_at = now()
  where r.test_id = p_test_id
    and (p_branch is null or p_branch = '' or lower(coalesce(r.branch, '')) = lower(p_branch))
    and (p_course is null or p_course = '' or mocks.normalize_course(r.course) = mocks.normalize_course(p_course))
    and (p_semester is null or p_semester = '' or lower(coalesce(r.semester, '')) = lower(p_semester))
    and (
      coalesce(r.locked, false) = true
      or r.submitted_at is not null
      or coalesce(r.answered_count, 0) > 0
      or coalesce(r.published, false) = true
      or coalesce(r.results_published, false) = true
    )
    and (
      coalesce(r.published, false) = false
      or coalesce(r.results_published, false) = false
    );

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

grant execute on function mocks.api_admin_publish_results(text, text, text, text) to authenticated;

-- Backfill old data: if any row was previously published, mark that test as released.
update mocks.mock_tests mt
set results_published = true,
    updated_at = now()
where coalesce(mt.results_published, false) = false
  and exists (
    select 1
    from mocks.mock_results r
    where r.test_id = mt.test_id
      and (
        coalesce(r.published, false) = true
        or coalesce(r.results_published, false) = true
      )
  );

-- Keep existing submitted/locked rows consistent when their test is released.
update mocks.mock_results r
set published = true,
    results_published = true,
    published_at = coalesce(r.published_at, now()),
    updated_at = now()
where exists (
    select 1
    from mocks.mock_tests mt
    where mt.test_id = r.test_id
      and coalesce(mt.results_published, false) = true
  )
  and (
    coalesce(r.locked, false) = true
    or r.submitted_at is not null
    or coalesce(r.answered_count, 0) > 0
    or coalesce(r.published, false) = true
    or coalesce(r.results_published, false) = true
  )
  and (
    coalesce(r.published, false) = false
    or coalesce(r.results_published, false) = false
  );

commit;

notify pgrst, 'reload schema';

select
  true as publication_state_sync_done,
  count(*) filter (where coalesce(mt.results_published, false) = true)::integer as released_tests,
  count(*) filter (where coalesce(mt.results_published, false) = false)::integer as unreleased_tests,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'mocks'
      and p.proname = 'api_admin_publish_results'
  ) as has_admin_publish_rpc
from mocks.mock_tests mt;