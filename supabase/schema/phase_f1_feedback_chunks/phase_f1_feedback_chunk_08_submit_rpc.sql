-- Phase F1 / Chunk 08
-- Anonymous student entry response submit.

begin;

create or replace function public.api_submit_feedback_entry_response(
  p_cycle_id text,
  p_entry_id text,
  p_response jsonb
)
returns boolean
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_uid text;
  v_entry public.feedback_cycle_entries%rowtype;
  v_answers jsonb;
  v_prompt_count integer;
  v_expected_count integer;
begin
  v_uid := public.app_current_profile_uid();
  if v_uid is null or trim(v_uid) = '' then
    raise exception 'No profile mapping for current user' using errcode = '42501';
  end if;
  if not public.app_feedback_cycle_visible_to_current_user(p_cycle_id) then
    raise exception 'Feedback cycle is not available' using errcode = '42501';
  end if;
  select * into v_entry
  from public.feedback_cycle_entries
  where cycle_id = p_cycle_id and entry_id = p_entry_id;
  if not found then
    raise exception 'Feedback entry not found' using errcode = '22023';
  end if;
  if exists (
    select 1 from public.feedback_submissions
    where cycle_id = p_cycle_id and entry_id = p_entry_id and uid = v_uid
  ) then
    raise exception 'Feedback already submitted' using errcode = '23505';
  end if;

  v_answers := coalesce(p_response->'answers', '[]'::jsonb);
  v_prompt_count := jsonb_array_length(v_answers);
  select count(*)::integer into v_expected_count
  from public.feedback_cycle_entry_questions
  where cycle_id = p_cycle_id and entry_id = p_entry_id;
  if v_prompt_count <= 0 or v_prompt_count > 60 then
    raise exception 'Invalid answer count' using errcode = '22023';
  end if;
  if v_prompt_count <> v_expected_count then
    raise exception 'Answer count does not match feedback form' using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(v_answers) a(answer)
    left join public.feedback_cycle_entry_questions q
      on q.cycle_id = p_cycle_id
     and q.entry_id = p_entry_id
     and q.question_id = a.answer->>'questionId'
    where q.question_id is null
       or coalesce(a.answer->>'rating', '') !~ '^[0-9]+$'
       or (a.answer->>'rating')::integer < 1
       or (a.answer->>'rating')::integer > q.rating_scale
  ) then
    raise exception 'Invalid feedback answer payload' using errcode = '22023';
  end if;

  insert into public.feedback_responses (
    cycle_id, entry_id, teacher_id, subject_type, rating_scale,
    prompt_count, optional_comment, answers_jsonb, submitted_at
  ) values (
    p_cycle_id, p_entry_id, v_entry.teacher_id, v_entry.subject_type, v_entry.rating_scale,
    v_prompt_count, left(coalesce(p_response->>'optionalComment', ''), 500), v_answers, now()
  );

  insert into public.feedback_submissions (cycle_id, entry_id, uid, auth_user_id, submitted, submitted_at)
  values (p_cycle_id, p_entry_id, v_uid, auth.uid(), true, now());

  return true;
end;
$$;

grant execute on function public.api_submit_feedback_entry_response(text, text, jsonb) to authenticated;

commit;
