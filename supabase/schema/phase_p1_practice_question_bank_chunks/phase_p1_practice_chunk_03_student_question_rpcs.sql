-- Phase P1 / Chunk 03
-- Student/web practice question fetch RPCs.

begin;

create or replace function public.api_practice_questions_random(
  p_subjects text[] default '{}'::text[], p_topics text[] default '{}'::text[],
  p_limit integer default 25, p_seed text default null
)
returns setof public.practice_question_bank
language sql volatile security definer set search_path = public as $$
  with safe as (
    select greatest(1, least(coalesce(p_limit, 25), 100)) lim,
      ((('x' || substr(md5(coalesce(p_seed, clock_timestamp()::text)), 1, 8))::bit(32)::bigint) % 1000000)::integer seed_bucket
  ), subjects as (
    select lower(trim(x)) s from unnest(coalesce(p_subjects, '{}'::text[])) x where trim(coalesce(x, '')) <> ''
  ), topics as (
    select lower(trim(x)) t from unnest(coalesce(p_topics, '{}'::text[])) x where trim(coalesce(x, '')) <> ''
  )
  select q.* from public.practice_question_bank q, safe
  where q.active = true and 'practice' = any(q.pools)
    and (not exists (select 1 from subjects) or lower(q.subject) in (select s from subjects))
    and (not exists (select 1 from topics) or lower(q.topic) in (select t from topics))
  order by case when q.shuffle_bucket >= safe.seed_bucket then 0 else 1 end,
    q.shuffle_bucket asc, q.question_id asc
  limit (select lim from safe);
$$;

create or replace function public.api_practice_questions_sequential(
  p_subject text, p_topic text, p_limit integer default 100,
  p_after_order integer default null, p_after_question_id text default null
)
returns setof public.practice_question_bank
language sql stable security definer set search_path = public as $$
  select q.* from public.practice_question_bank q
  where q.active = true and 'practice' = any(q.pools)
    and lower(q.subject) = lower(trim(coalesce(p_subject, '')))
    and lower(q.topic) = lower(trim(coalesce(p_topic, '')))
    and (p_after_order is null or (q.question_order, q.question_id) >
      (p_after_order, coalesce(p_after_question_id, '')))
  order by q.question_order asc, q.question_id asc
  limit greatest(1, least(coalesce(p_limit, 100), 200));
$$;

grant execute on function public.api_practice_questions_random(text[],text[],integer,text) to authenticated;
grant execute on function public.api_practice_questions_sequential(text,text,integer,integer,text) to authenticated;

commit;
