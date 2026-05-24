-- Phase B1 / Chunk 03
-- Student notification bell unread count.

begin;

create or replace function public.api_student_notification_badge_count()
returns integer
language sql
stable
security invoker
set search_path = public
as $$
  with me as (
    select public.app_current_profile_uid() as uid
  ),
  meta as (
    select m.last_seen_at, m.dismissed_ids
    from public.app_notification_meta m, me
    where m.uid = me.uid
  ),
  keys as (
    select public.app_current_notification_target_keys() as target_keys
  ),
  inbox_count as (
    select count(*)::integer as c
    from public.app_inbox i, me
    where i.uid = me.uid
      and i.status = 'UNREAD'
  ),
  broadcast_count as (
    select count(*)::integer as c
    from public.app_notifications n
    cross join keys
    left join meta on true
    where n.is_active = true
      and n.target_key = any(keys.target_keys)
      and not (n.notif_id = any(coalesce(meta.dismissed_ids, '{}'::text[])))
      and (
        meta.last_seen_at is null
        or coalesce(n.source_created_at, n.created_at) > meta.last_seen_at
      )
  )
  select coalesce((select c from inbox_count), 0)
       + coalesce((select c from broadcast_count), 0);
$$;

grant execute on function public.api_student_notification_badge_count() to authenticated;

commit;
