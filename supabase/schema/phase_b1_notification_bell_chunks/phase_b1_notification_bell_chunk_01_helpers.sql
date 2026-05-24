-- Phase B1 / Chunk 01
-- Notification bell helper functions.

begin;

create or replace function public.app_normalize_target_key(p_raw text)
returns text
language sql
immutable
as $$
  select replace(replace(lower(trim(coalesce(p_raw, ''))), ' ', '_'), '.', '');
$$;

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

create or replace function public.app_current_notification_target_keys()
returns text[]
language sql
stable
security invoker
set search_path = public
as $$
  with me as (
    select ps.branch, ps.course, ps.semester
    from public.app_profile_state ps
    where ps.uid = public.app_current_profile_uid()
    limit 1
  ),
  keys as (
    select unnest(array[
      'all_students',
      public.app_normalize_target_key(branch),
      public.app_normalize_target_key(course),
      case when semester is not null and semester > 0 then 'sem' || semester::text else '' end,
      case
        when public.app_normalize_target_key(course) <> ''
         and semester is not null and semester > 0
        then public.app_normalize_target_key(course) || '_sem' || semester::text
        else ''
      end
    ]) as key
    from me
  )
  select coalesce(array_agg(distinct key) filter (where key <> ''), array['all_students']::text[])
  from keys;
$$;

grant execute on function public.app_normalize_target_key(text) to authenticated;
grant execute on function public.app_current_profile_uid() to authenticated;
grant execute on function public.app_current_notification_target_keys() to authenticated;

commit;
