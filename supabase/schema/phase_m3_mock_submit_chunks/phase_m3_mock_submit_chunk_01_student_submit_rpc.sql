create or replace function mocks.api_student_submit_mock_result(
  p_test_id text, p_q_order text[] default '{}'::text[],
  p_opt_map jsonb default '{}'::jsonb, p_warn_count integer default 0,
  p_started_at timestamptz default null, p_session_end_time timestamptz default null,
  p_firebase_uid text default null)
returns bigint language plpgsql security invoker
as $$
declare
  v_auth uuid := auth.uid();
  v_student text; v_branch text; v_course text; v_semester text;
  v_result_id bigint; v_total integer := 0; v_answered integer := 0;
  v_correct integer := 0; v_wrong integer := 0; v_unattempted integer := 0;
  v_score numeric := 0; v_max integer := 0; v_pct numeric := 0;
  v_test mocks.mock_tests%rowtype;
begin
  if v_auth is null then raise exception 'forbidden: authenticated student required'; end if;

  select student_id, branch, course, semester
  into v_student, v_branch, v_course, v_semester
  from mocks.current_student_context() limit 1;

  if v_student is null then raise exception 'forbidden: active student identity required'; end if;

  select * into v_test from mocks.mock_tests where test_id = p_test_id;

  if not found or v_test.status <> 'POSTED' then raise exception 'mock test is not available'; end if;
  if coalesce(v_test.results_published, false) then raise exception 'results already published'; end if;

  with scored as (
    select
      q.qid,
      coalesce(p_opt_map, '{}'::jsonb) ? q.qid as answered,
      upper(coalesce(p_opt_map ->> q.qid, '')) = q.answer_letter as is_correct,
      case when q.subject_type = 'APTITUDE' or q.subject ilike '%aptitude%'
        then v_test.marking_aptitude_per_q else v_test.marking_english_per_q end as marks,
      case when q.subject_type = 'APTITUDE' or q.subject ilike '%aptitude%'
        then coalesce(v_test.negative_value_aptitude, v_test.negative_value) 
        else coalesce(v_test.negative_value_english, v_test.negative_value) end as neg_deduction,
      exists(
        select 1 from unnest(v_test.negative_apply_to) n
        where lower(n) = lower(q.subject) or lower(n) = lower(coalesce(q.subject_type, ''))
      ) as neg_applies
    from mocks.mock_test_questions q
    where q.test_id = p_test_id
  )
  select
    count(*)::integer, count(*) filter (where answered)::integer,
    count(*) filter (where answered and is_correct)::integer,
    count(*) filter (where answered and not is_correct)::integer,
    greatest(0, coalesce(sum(case
      when answered and is_correct then marks
      when answered and not is_correct and v_test.negative_enabled and neg_applies then -neg_deduction
      else 0 end), 0)),
    round(coalesce(sum(marks), 0))::integer
  into v_total, v_answered, v_correct, v_wrong, v_score, v_max
  from scored;

  if v_total <= 0 then raise exception 'mock has no frozen questions'; end if;
  v_unattempted := greatest(0, v_total - v_answered);
  v_pct := case when v_max > 0 then round((v_score * 100.0 / v_max), 2) else 0 end;

  select result_id into v_result_id from mocks.mock_results
  where test_id = p_test_id and (auth_user_id = v_auth or student_id = v_student)
  order by updated_at desc nulls last, result_id desc
  limit 1;

  if v_result_id is null then
    insert into mocks.mock_results
      (test_id, student_id, auth_user_id, firebase_uid, locked, branch, course, semester)
    values (p_test_id, v_student, v_auth, nullif(p_firebase_uid, ''), false,
      coalesce(v_branch, 'ALL'), coalesce(v_course, 'ALL'), coalesce(v_semester, 'ALL'))
    returning result_id into v_result_id;
  end if;

  update mocks.mock_results
  set q_order = coalesce(p_q_order, '{}'::text[]),
      opt_map = coalesce(p_opt_map, '{}'::jsonb),
      warn_count = greatest(coalesce(p_warn_count, 0), 0),
      locked = true, started_at = coalesce(p_started_at, started_at, now()),
      session_end_time = coalesce(p_session_end_time, session_end_time),
      submitted_at = now(), total_questions = v_total, answered_count = v_answered,
      score = v_score, correct = v_correct, wrong = v_wrong,
      unattempted = v_unattempted, max_marks = v_max, percentage = v_pct
  where result_id = v_result_id and locked = false
  returning result_id into v_result_id;

  if v_result_id is null then raise exception 'mock result already submitted'; end if;

  return v_result_id;
end;
$$;

grant execute on function mocks.api_student_submit_mock_result(
  text, text[], jsonb, integer, timestamptz, timestamptz, text) to authenticated;
