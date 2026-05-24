-- Phase E1 / Chunk 06B
-- Event audience visibility helper.

begin;

create or replace function public.app_event_visible(p_event_id text)
returns boolean
language sql stable security definer
set search_path = public
as $$
  with me as (
    select p.course, p.branch, p.semester,
           cm.stu_campus_name as campus_name,
           cm.stu_campus_code as campus_code
    from public.app_profile_state p
    left join public.student_enrollment_current se
      on se.stu_enroll_student_id = p.student_id
    left join public.stu_campus_master cm
      on cm.stu_campus_id = se.stu_college_campus_id
    where p.student_id = public.app_event_current_student_id()
    limit 1
  )
  select public.app_event_is_admin()
    or exists (
      select 1
      from public.event_core e
      left join me on true
      where e.event_id = p_event_id
        and e.is_live = true
        and e.is_cancelled = false
        and (
          coalesce(cardinality(e.target_campuses), 0) = 0
          or 'ALL' = any(e.target_campuses)
          or exists (
            select 1 from unnest(e.target_campuses) c
            where lower(c) = lower(coalesce(me.campus_name, ''))
               or lower(c) = lower(coalesce(me.campus_code, ''))
          )
        )
        and (
          coalesce(cardinality(e.target_courses), 0) = 0
          or
          'ALL' = any(e.target_courses)
          or exists (
            select 1 from unnest(e.target_courses) c
            where lower(c) = lower(coalesce(me.course, ''))
               or lower(c) = lower(coalesce(me.branch, ''))
          )
        )
        and (
          coalesce(cardinality(e.target_semesters), 0) = 0
          or
          -1 = any(e.target_semesters)
          or me.semester = any(e.target_semesters)
        )
    );
$$;

grant execute on function public.app_event_visible(text) to authenticated;

commit;
