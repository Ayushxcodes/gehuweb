-- Phase P1 / Chunk 04
-- Admin write RPCs for practice question bank.

begin;

create or replace function public.api_admin_upsert_practice_question(
  p_question_id text, p_subject text, p_unit text, p_topic text,
  p_question_text text, p_option_a text, p_option_b text,
  p_option_c text, p_option_d text, p_answer_key text,
  p_difficulty text default '', p_solution text default '',
  p_pools text[] default array['practice']::text[], p_solution_mode text default 'full',
  p_question_order integer default 0, p_source_payload jsonb default '{}'::jsonb
)
returns table (question_id text, active boolean)
language plpgsql security definer set search_path = public as $$
declare v_auth uuid := auth.uid(); v_key text := upper(trim(coalesce(p_answer_key, '')));
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not public.app_event_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  if v_key not in ('A','B','C','D') then raise exception 'INVALID_ANSWER_KEY'; end if;
  insert into public.practice_question_bank(question_id, subject, unit, topic,
    question_text, option_a, option_b, option_c, option_d, answer_key,
    difficulty, solution, active, pools, solution_mode, question_order, source_payload)
  values (trim(p_question_id), trim(p_subject), coalesce(p_unit, ''), trim(p_topic),
    trim(p_question_text), coalesce(p_option_a, ''), coalesce(p_option_b, ''),
    coalesce(p_option_c, ''), coalesce(p_option_d, ''), v_key,
    coalesce(p_difficulty, ''), coalesce(p_solution, ''), true,
    coalesce(p_pools, array['practice']::text[]), coalesce(p_solution_mode, 'full'),
    coalesce(p_question_order, 0), coalesce(p_source_payload, '{}'::jsonb))
  on conflict (question_id) do update set
    subject = excluded.subject, unit = excluded.unit, topic = excluded.topic,
    question_text = excluded.question_text, option_a = excluded.option_a,
    option_b = excluded.option_b, option_c = excluded.option_c,
    option_d = excluded.option_d, answer_key = excluded.answer_key,
    difficulty = excluded.difficulty, solution = excluded.solution,
    pools = excluded.pools, solution_mode = excluded.solution_mode,
    question_order = excluded.question_order, source_payload = excluded.source_payload,
    active = true;
  return query select trim(p_question_id), true;
end;
$$;

create or replace function public.api_admin_set_practice_question_active(
  p_question_id text, p_active boolean
)
returns table (question_id text, active boolean)
language plpgsql security definer set search_path = public as $$
declare v_auth uuid := auth.uid();
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not public.app_event_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  update public.practice_question_bank q set active = coalesce(p_active, false)
  where q.question_id = p_question_id
  returning q.question_id, q.active into question_id, active;
  if question_id is null then raise exception 'QUESTION_NOT_FOUND'; end if;
  return next;
end;
$$;

grant execute on function public.api_admin_upsert_practice_question(text,text,text,text,text,text,text,text,text,text,text,text,text[],text,integer,jsonb) to authenticated;
grant execute on function public.api_admin_set_practice_question_active(text,boolean) to authenticated;

commit;
