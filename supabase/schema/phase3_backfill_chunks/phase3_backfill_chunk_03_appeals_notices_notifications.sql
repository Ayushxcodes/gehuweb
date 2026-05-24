-- Phase 3 Backfill / Chunk 03
-- Appeals + notices + attachments + notifications

insert into public.app_appeals (
  appeal_id, uid, name, email, type, message, status, profile_path, roll_no, course, semester,
  profile_data_json, source_created_at
)
select
  a.appeal_id,
  coalesce(trim(a.data->>'uid'), ''),
  coalesce(trim(a.data->>'name'), ''),
  coalesce(trim(a.data->>'email'), ''),
  coalesce(nullif(trim(a.data->>'type'), ''), 'PROFILE_CHANGE'),
  coalesce(trim(a.data->>'message'), ''),
  case upper(coalesce(trim(a.data->>'status'), 'PENDING'))
    when 'RESOLVED' then 'RESOLVED'
    when 'REJECTED' then 'REJECTED'
    when 'CANCELLED' then 'CANCELLED'
    else 'PENDING'
  end,
  coalesce(trim(a.data->>'profilePath'), ''),
  coalesce(trim(a.data->>'rollNo'), ''),
  coalesce(trim(a.data->>'course'), ''),
  stage_import.jsonb_to_int(a.data->'semester'),
  case when jsonb_typeof(a.data->'profileData') = 'object' then a.data->'profileData' else '{}'::jsonb end,
  stage_import.jsonb_to_timestamptz(a.data->'createdAt')
from stage_import.fb_appeals a
where coalesce(trim(a.data->>'uid'), '') <> ''
on conflict (appeal_id) do update set
  uid = excluded.uid,
  name = excluded.name,
  email = excluded.email,
  type = excluded.type,
  message = excluded.message,
  status = excluded.status,
  profile_path = excluded.profile_path,
  roll_no = excluded.roll_no,
  course = excluded.course,
  semester = excluded.semester,
  profile_data_json = excluded.profile_data_json,
  source_created_at = excluded.source_created_at;

insert into public.app_notices (
  notice_id, title, body, type, branch, courses, semesters, created_by_uid, active,
  expires_at, registration_deadline, event_template, event_config_json, event_id, cta_label,
  participation_enabled, payload_json, source_created_at
)
select
  n.notice_id,
  coalesce(trim(n.data->>'title'), ''),
  coalesce(trim(n.data->>'body'), ''),
  case lower(coalesce(trim(n.data->>'type'), 'holiday'))
    when 'event' then 'event'
    when 'job' then 'job'
    else 'holiday'
  end,
  coalesce(nullif(trim(n.data->>'branch'), ''), 'ALL'),
  coalesce(stage_import.jsonb_to_text_array(n.data->'courses'), array['ALL']::text[]),
  coalesce(stage_import.jsonb_to_int_array(n.data->'semesters'), array[-1]::integer[]),
  coalesce(trim(n.data->>'createdBy'), ''),
  coalesce(stage_import.jsonb_to_bool(n.data->'active'), true),
  stage_import.jsonb_to_timestamptz(n.data->'expiresAt'),
  stage_import.jsonb_to_timestamptz(n.data->'registrationDeadline'),
  nullif(trim(n.data->>'eventTemplate'), ''),
  case when jsonb_typeof(n.data->'eventConfig') = 'object' then n.data->'eventConfig' else '{}'::jsonb end,
  coalesce(trim(n.data->>'eventId'), ''),
  coalesce(trim(n.data->>'ctaLabel'), ''),
  coalesce(stage_import.jsonb_to_bool(n.data->'participationEnabled'), false),
  n.data,
  stage_import.jsonb_to_timestamptz(n.data->'createdAt')
from stage_import.fb_notices n
on conflict (notice_id) do update set
  title = excluded.title,
  body = excluded.body,
  type = excluded.type,
  branch = excluded.branch,
  courses = excluded.courses,
  semesters = excluded.semesters,
  created_by_uid = excluded.created_by_uid,
  active = excluded.active,
  expires_at = excluded.expires_at,
  registration_deadline = excluded.registration_deadline,
  event_template = excluded.event_template,
  event_config_json = excluded.event_config_json,
  event_id = excluded.event_id,
  cta_label = excluded.cta_label,
  participation_enabled = excluded.participation_enabled,
  payload_json = excluded.payload_json,
  source_created_at = excluded.source_created_at;

insert into public.app_notice_attachments (notice_id, sort_order, name, url, mime, size_bytes)
select
  n.notice_id,
  (att.ord - 1)::integer,
  coalesce(trim(att.item->>'name'), ''),
  coalesce(trim(att.item->>'url'), ''),
  coalesce(trim(att.item->>'mime'), ''),
  coalesce(stage_import.jsonb_to_int(att.item->'size'), 0)::bigint
from stage_import.fb_notices n
cross join lateral jsonb_array_elements(
  case when jsonb_typeof(n.data->'attachments') = 'array' then n.data->'attachments' else '[]'::jsonb end
) with ordinality as att(item, ord)
where coalesce(trim(att.item->>'url'), '') <> ''
on conflict (notice_id, sort_order, url) do update set
  name = excluded.name,
  mime = excluded.mime,
  size_bytes = excluded.size_bytes;

insert into public.app_notifications (
  notif_id, type, title, message, target_type, target_key, target_id, priority, payload_json, source_created_at
)
select
  b.notif_id,
  coalesce(nullif(upper(trim(b.data->>'type')), ''), 'NOTICE'),
  coalesce(trim(b.data->>'title'), ''),
  coalesce(trim(b.data->>'message'), ''),
  case upper(coalesce(trim(b.data->>'targetType'), 'ALL'))
    when 'SEGMENT' then 'SEGMENT'
    when 'UID' then 'UID'
    when 'EVENT' then 'EVENT'
    when 'CUSTOM' then 'CUSTOM'
    else 'ALL'
  end,
  coalesce(nullif(trim(b.data->>'targetKey'), ''), 'all_students'),
  coalesce(trim(b.data->>'targetId'), ''),
  case upper(coalesce(trim(b.data->>'priority'), 'NORMAL'))
    when 'LOW' then 'LOW'
    when 'HIGH' then 'HIGH'
    when 'URGENT' then 'URGENT'
    else 'NORMAL'
  end,
  b.data,
  stage_import.jsonb_to_timestamptz(b.data->'createdAt')
from stage_import.fb_notifications b
on conflict (notif_id) do update set
  type = excluded.type,
  title = excluded.title,
  message = excluded.message,
  target_type = excluded.target_type,
  target_key = excluded.target_key,
  target_id = excluded.target_id,
  priority = excluded.priority,
  payload_json = excluded.payload_json,
  source_created_at = excluded.source_created_at;
