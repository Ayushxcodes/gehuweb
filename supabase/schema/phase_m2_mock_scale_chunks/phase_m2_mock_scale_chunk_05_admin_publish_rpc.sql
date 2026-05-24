-- Phase M2 / Chunk 05
-- Admin publish helper (bulk publish for filtered result rows)

create or replace function mocks.api_admin_publish_results(
  p_test_id text,
  p_branch text default null,
  p_course text default null,
  p_semester text default null
)
returns integer
language plpgsql
security invoker
as $$
declare
  v_count integer := 0;
begin
  if not mocks.is_admin() then
    raise exception 'forbidden: admin role required';
  end if;

  update mocks.mock_results r
  set published = true, results_published = true, published_at = now()
  where r.test_id = p_test_id
    and coalesce(r.locked, false)
    and (p_branch is null or p_branch = '' or lower(r.branch) = lower(p_branch))
    and (p_course is null or p_course = '' or lower(r.course) = lower(p_course))
    and (p_semester is null or p_semester = '' or lower(r.semester) = lower(p_semester))
    and (coalesce(r.published, false) = false or coalesce(r.results_published, false) = false);

  get diagnostics v_count = row_count;

  update mocks.mock_tests t
  set results_published = true
  where t.test_id = p_test_id;

  return v_count;
end;
$$;

grant execute on function mocks.api_admin_publish_results(text, text, text, text) to authenticated;
