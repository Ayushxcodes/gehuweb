-- Phase 3 Backfill / Chunk 04
-- user inbox/read/meta/officialFeedback

insert into public.app_inbox (
  uid, inbox_id, type, title, body, status, event_id, comp_id, team_id, notice_id, from_uid,
  target_id, payload_json, source_created_at, read_at
)
select
  i.uid,
  i.inbox_id,
  coalesce(nullif(upper(trim(i.data->>'type')), ''), 'GENERAL'),
  coalesce(trim(i.data->>'title'), ''),
  coalesce(trim(i.data->>'body'), ''),
  case upper(coalesce(trim(i.data->>'status'), 'UNREAD'))
    when 'READ' then 'READ'
    when 'ARCHIVED' then 'ARCHIVED'
    when 'DISMISSED' then 'DISMISSED'
    else 'UNREAD'
  end,
  coalesce(trim(i.data->>'eventId'), ''),
  coalesce(trim(i.data->>'compId'), ''),
  coalesce(trim(i.data->>'teamId'), ''),
  coalesce(trim(i.data->>'noticeId'), ''),
  coalesce(trim(i.data->>'fromUid'), ''),
  coalesce(trim(i.data->>'targetId'), ''),
  i.data,
  stage_import.jsonb_to_timestamptz(i.data->'createdAt'),
  stage_import.jsonb_to_timestamptz(i.data->'readAt')
from stage_import.fb_user_inbox i
on conflict (uid, inbox_id) do update set
  type = excluded.type,
  title = excluded.title,
  body = excluded.body,
  status = excluded.status,
  event_id = excluded.event_id,
  comp_id = excluded.comp_id,
  team_id = excluded.team_id,
  notice_id = excluded.notice_id,
  from_uid = excluded.from_uid,
  target_id = excluded.target_id,
  payload_json = excluded.payload_json,
  source_created_at = excluded.source_created_at,
  read_at = excluded.read_at;

insert into public.app_notice_reads (uid, notice_id, read_at)
select
  r.uid,
  r.notice_id,
  coalesce(
    stage_import.jsonb_to_timestamptz(r.data->'readAt'),
    stage_import.jsonb_to_timestamptz(r.data->'createdAt')
  )
from stage_import.fb_user_read_notices r
on conflict (uid, notice_id) do update set
  read_at = excluded.read_at;

insert into public.app_notification_meta (uid, last_seen_at, dismissed_ids, meta_json)
select
  m.uid,
  stage_import.jsonb_to_timestamptz(m.data->'lastSeenAt'),
  coalesce(stage_import.jsonb_to_text_array(m.data->'dismissedIds'), '{}'::text[]),
  m.data
from stage_import.fb_user_notification_meta m
where m.doc_id = 'meta'
on conflict (uid) do update set
  last_seen_at = excluded.last_seen_at,
  dismissed_ids = excluded.dismissed_ids,
  meta_json = excluded.meta_json;

insert into public.app_official_feedback (
  uid, feedback_id, message, admin_name, type, source_timestamp, meta_json
)
select
  f.uid,
  f.feedback_id,
  coalesce(trim(f.data->>'message'), ''),
  coalesce(trim(f.data->>'adminName'), ''),
  coalesce(trim(f.data->>'type'), ''),
  stage_import.jsonb_to_timestamptz(f.data->'timestamp'),
  f.data
from stage_import.fb_user_official_feedback f
on conflict (uid, feedback_id) do update set
  message = excluded.message,
  admin_name = excluded.admin_name,
  type = excluded.type,
  source_timestamp = excluded.source_timestamp,
  meta_json = excluded.meta_json;

