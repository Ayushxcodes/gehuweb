-- Phase P1 / Chunk 02
-- Student/web topic discovery RPC.

begin;

create or replace function public.api_practice_topics(
  p_subjects text[] default array['Aptitude','English']::text[]
)
returns table (subject text, topic text, question_count bigint)
language sql stable security definer set search_path = public as $$
  with subjects as (
    select lower(trim(x)) s from unnest(coalesce(p_subjects, '{}'::text[])) x
    where trim(coalesce(x, '')) <> ''
  )
  select q.subject, q.topic, count(*)::bigint as question_count
  from public.practice_question_bank q
  where q.active = true and 'practice' = any(q.pools)
    and (not exists (select 1 from subjects)
      or lower(q.subject) in (select s from subjects))
  group by q.subject, q.topic
  order by q.subject asc, q.topic asc;
$$;

grant execute on function public.api_practice_topics(text[]) to authenticated;

commit;
