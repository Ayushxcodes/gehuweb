-- Phase E1 / Chunk 06A
-- Event identity and membership helpers.

begin;

create or replace function public.app_event_is_admin()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.app_user_identity ai
    where ai.auth_user_id = (select auth.uid())
      and ai.is_active = true
      and ai.account_type = 'ADMIN'
  );
$$;

create or replace function public.app_event_current_student_id()
returns text
language sql stable security definer
set search_path = public
as $$
  select ai.student_id
  from public.app_user_identity ai
  where ai.auth_user_id = (select auth.uid())
    and ai.is_active = true
    and ai.account_type = 'STUDENT'
  limit 1;
$$;

create or replace function public.app_event_is_team_member(
  p_event_id text, p_comp_id text, p_team_id text
)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.event_team_members m
    where m.event_id = p_event_id
      and m.comp_id = p_comp_id
      and m.team_id = p_team_id
      and m.student_id = public.app_event_current_student_id()
      and m.status in ('ACTIVE','INVITED','PENDING')
  );
$$;

create or replace function public.app_event_is_group_member(
  p_event_id text, p_comp_id text, p_group_id text
)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.event_group_members gm
    where gm.event_id = p_event_id
      and gm.comp_id = p_comp_id
      and gm.group_id = p_group_id
      and gm.student_id = public.app_event_current_student_id()
      and gm.status = 'ACTIVE'
  );
$$;

grant execute on function public.app_event_is_admin() to authenticated;
grant execute on function public.app_event_current_student_id() to authenticated;
grant execute on function public.app_event_is_team_member(text,text,text) to authenticated;
grant execute on function public.app_event_is_group_member(text,text,text) to authenticated;

commit;
