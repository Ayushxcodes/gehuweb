-- Phase B1 / Chunk 02
-- Student notification hub feed for Android + web.

begin;

create or replace function public.api_student_notification_feed(
  p_limit integer default 80,
  p_before_created_at timestamptz default null,
  p_before_item_id text default null
)
returns table (
  item_source text, item_id text, type text, title text, body text,
  priority text, is_invite boolean, is_broadcast boolean, is_read boolean,
  event_id text, comp_id text, team_id text, notice_id text, target_id text,
  payload_json jsonb, created_at timestamptz,
  source_created_at timestamptz
)
language sql
stable
security invoker
set search_path = public
as $$
  with me as (select public.app_current_profile_uid() as uid),
  meta as (
    select m.last_seen_at, m.dismissed_ids
    from public.app_notification_meta m, me
    where m.uid = me.uid
  ),
  keys as (select public.app_current_notification_target_keys() as target_keys),
  safe_limit as (select greatest(1, least(coalesce(p_limit, 80), 100)) as lim),
  rows as (
    select
      'INBOX'::text as item_source,
      i.inbox_id as item_id,
      i.type,
      i.title,
      i.body,
      coalesce(i.payload_json->>'priority', case when i.type = 'TEAM_INVITE' then 'HIGH' else 'NORMAL' end) as priority,
      (i.type = 'TEAM_INVITE') as is_invite,
      false as is_broadcast,
      (i.status = 'READ') as is_read,
      i.event_id, i.comp_id, i.team_id, i.notice_id, i.target_id, i.payload_json,
      coalesce(i.source_created_at, i.created_at) as created_at,
      i.source_created_at
    from public.app_inbox i, me
    where i.uid = me.uid
      and i.status <> 'READ'
    union all
    select
      'BROADCAST'::text,
      n.notif_id,
      n.type,
      n.title,
      n.message,
      n.priority,
      false,
      true,
      (meta.last_seen_at is not null and coalesce(n.source_created_at, n.created_at) <= meta.last_seen_at),
      coalesce(n.payload_json->>'eventId', ''),
      coalesce(n.payload_json->>'compId', ''),
      coalesce(n.payload_json->>'teamId', ''),
      coalesce(n.payload_json->>'noticeId', n.target_id),
      n.target_id,
      n.payload_json,
      coalesce(n.source_created_at, n.created_at),
      n.source_created_at
    from public.app_notifications n
    cross join keys
    left join meta on true
    where n.is_active = true
      and n.target_key = any(keys.target_keys)
      and not (n.notif_id = any(coalesce(meta.dismissed_ids, '{}'::text[])))
  )
  select item_source, item_id, type, title, body, priority, is_invite, is_broadcast,
         is_read, event_id, comp_id, team_id, notice_id, target_id, payload_json,
         created_at, source_created_at
  from rows
  where p_before_created_at is null
     or created_at < p_before_created_at
     or (created_at = p_before_created_at and item_id < coalesce(p_before_item_id, ''))
  order by case when is_invite then 0 when priority in ('URGENT', 'HIGH') then 1 else 2 end,
           created_at desc,
           item_id desc
  limit (select lim from safe_limit);
$$;

grant execute on function public.api_student_notification_feed(integer, timestamptz, text) to authenticated;

commit;
