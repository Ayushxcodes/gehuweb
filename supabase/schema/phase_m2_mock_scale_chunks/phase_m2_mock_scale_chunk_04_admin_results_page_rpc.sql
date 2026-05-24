-- Phase M2 / Chunk 04
-- Admin paged results (keyset pagination)

create or replace function mocks.api_admin_mock_results_page(
  p_test_id text,
  p_limit integer default 100,
  p_before_submitted_at timestamptz default null,
  p_before_result_id bigint default null,
  p_branch text default null,
  p_course text default null,
  p_semester text default null,
  p_only_locked boolean default true
)
returns table (
  result_id bigint,
  test_id text,
  auth_user_id uuid,
  student_id text,
  student_name text,
  roll_no text,
  branch text,
  course text,
  semester text,
  locked boolean,
  submitted_at timestamptz,
  score numeric,
  max_marks integer,
  percentage numeric,
  published boolean
)
language plpgsql
security invoker
as $$
begin
  if not mocks.is_admin() then
    raise exception 'forbidden: admin role required';
  end if;

  return query
  select
    r.result_id, r.test_id, r.auth_user_id, r.student_id,
    coalesce(ps.name, '') as student_name,
    coalesce(ps.roll_no, '') as roll_no,
    r.branch, r.course, r.semester, r.locked, r.submitted_at,
    r.score, r.max_marks, r.percentage, r.published
  from mocks.mock_results r
  left join public.app_profile_state ps
    on (r.auth_user_id is not null and ps.auth_user_id = r.auth_user_id)
    or (r.student_id is not null and ps.student_id = r.student_id)
  where r.test_id = p_test_id
    and (not p_only_locked or coalesce(r.locked, false))
    and (p_branch is null or p_branch = '' or lower(r.branch) = lower(p_branch))
    and (p_course is null or p_course = '' or lower(r.course) = lower(p_course))
    and (p_semester is null or p_semester = '' or lower(r.semester) = lower(p_semester))
    and (
      p_before_submitted_at is null
      or coalesce(r.submitted_at, r.updated_at) < p_before_submitted_at
      or (
        coalesce(r.submitted_at, r.updated_at) = p_before_submitted_at
        and p_before_result_id is not null
        and r.result_id < p_before_result_id
      )
    )
  order by coalesce(r.submitted_at, r.updated_at) desc, r.result_id desc
  limit greatest(1, least(coalesce(p_limit, 100), 500));
end;
$$;

grant execute on function mocks.api_admin_mock_results_page(
  text, integer, timestamptz, bigint, text, text, text, boolean
) to authenticated;
