-- Phase N1 / Chunk 01
-- Student notice feed RPC for Android + future web.

begin;

create or replace function public.app_current_profile_uid()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select ps.uid
  from public.app_profile_state ps
  left join public.app_user_identity ai
    on ai.auth_user_id = (select auth.uid())
   and ai.is_active = true
  where ps.auth_user_id = (select auth.uid())
     or (ai.student_id is not null and ai.student_id = ps.student_id)
     or (ai.employee_id is not null and ai.employee_id = ps.employee_id)
  order by case when ps.auth_user_id = (select auth.uid()) then 0 else 1 end
  limit 1;
$$;

create or replace function public.api_student_notice_feed(
  p_branch text default 'ALL',
  p_course text default 'ALL',
  p_semester integer default null,
  p_limit integer default 50,
  p_before_created_at timestamptz default null,
  p_before_notice_id text default null
)
returns table (
  notice_id text,
  title text,
  body text,
  type text,
  event_id text,
  cta_label text,
  created_at timestamptz,
  expires_at timestamptz,
  is_read boolean
)
language sql
stable
security invoker
set search_path = public
as $$
  with me as (select public.app_current_profile_uid() as uid),
  safe_limit as (select greatest(1, least(coalesce(p_limit, 50), 100)) as lim)
  select n.notice_id, n.title, n.body, n.type, n.event_id, n.cta_label,
         n.created_at, n.expires_at,
         coalesce(r.read_at is not null, false) as is_read
  from public.app_notices n
  cross join safe_limit
  left join me on true
  left join public.app_notice_reads r
    on r.uid = me.uid and r.notice_id = n.notice_id
  where n.active = true
    and (n.expires_at is null or n.expires_at > now())
    and (coalesce(trim(p_branch), '') = ''
      or n.branch = 'ALL'
      or lower(n.branch) = lower(trim(p_branch)))
    and (coalesce(trim(p_course), '') = ''
      or 'ALL' = any(n.courses)
      or exists (
        select 1 from unnest(n.courses) c
        where lower(c) = lower(trim(p_course))
      ))
    and (p_semester is null
      or -1 = any(n.semesters)
      or p_semester = any(n.semesters))
    and (
      p_before_created_at is null
      or n.created_at < p_before_created_at
      or (n.created_at = p_before_created_at and n.notice_id < coalesce(p_before_notice_id, ''))
    )
  order by n.created_at desc, n.notice_id desc
  limit (select lim from safe_limit);
$$;

grant execute on function public.app_current_profile_uid() to authenticated;
grant execute on function public.api_student_notice_feed(text, text, integer, integer, timestamptz, text) to authenticated;

commit;
