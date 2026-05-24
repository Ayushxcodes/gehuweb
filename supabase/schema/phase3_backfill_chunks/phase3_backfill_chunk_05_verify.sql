-- Phase 3 Backfill / Chunk 05
-- Reconciliation checks (hard checks)

-- 1) Source vs target row counts (keyed parity)
with c as (
  select 'users->app_profile_state' as check_name,
         (select count(*) from stage_import.fb_users) as source_rows,
         (select count(*) from public.app_profile_state p join stage_import.fb_users s on s.uid = p.uid) as matched_rows
  union all
  select 'appeals->app_appeals',
         (select count(*) from stage_import.fb_appeals),
         (select count(*) from public.app_appeals t join stage_import.fb_appeals s on s.appeal_id = t.appeal_id)
  union all
  select 'notices->app_notices',
         (select count(*) from stage_import.fb_notices),
         (select count(*) from public.app_notices t join stage_import.fb_notices s on s.notice_id = t.notice_id)
  union all
  select 'notifications->app_notifications',
         (select count(*) from stage_import.fb_notifications),
         (select count(*) from public.app_notifications t join stage_import.fb_notifications s on s.notif_id = t.notif_id)
  union all
  select 'inbox->app_inbox',
         (select count(*) from stage_import.fb_user_inbox),
         (select count(*) from public.app_inbox t join stage_import.fb_user_inbox s on s.uid=t.uid and s.inbox_id=t.inbox_id)
  union all
  select 'readNotices->app_notice_reads',
         (select count(*) from stage_import.fb_user_read_notices),
         (select count(*) from public.app_notice_reads t join stage_import.fb_user_read_notices s on s.uid=t.uid and s.notice_id=t.notice_id)
)
select check_name, source_rows, matched_rows, (source_rows - matched_rows) as missing_rows
from c
order by check_name;

-- 2) Mandatory key null/blank checks
select 'app_profile_state.uid_blank' as issue, count(*) as bad_rows
from public.app_profile_state where coalesce(trim(uid), '') = ''
union all
select 'app_inbox.uid_or_inbox_blank', count(*) from public.app_inbox where coalesce(trim(uid), '') = '' or coalesce(trim(inbox_id), '') = ''
union all
select 'app_notices.notice_id_blank', count(*) from public.app_notices where coalesce(trim(notice_id), '') = ''
union all
select 'app_notifications.notif_id_blank', count(*) from public.app_notifications where coalesce(trim(notif_id), '') = ''
union all
select 'app_appeals.appeal_id_blank', count(*) from public.app_appeals where coalesce(trim(appeal_id), '') = '';

-- 3) Profile lock + verification parity check
select count(*) as lock_state_mismatch_rows
from stage_import.fb_users s
join public.app_profile_state p on p.uid = s.uid
where coalesce(stage_import.jsonb_to_bool(s.data->'profileCompleted'), false) is distinct from p.profile_completed
   or coalesce(nullif(upper(trim(s.data->>'verificationStatus')), ''), 'PENDING') is distinct from p.verification_status
   or coalesce(stage_import.jsonb_to_bool(s.data->'verified'), false) is distinct from p.verified
   or stage_import.jsonb_to_timestamptz(s.data->'editUnlockedUntil') is distinct from p.edit_unlocked_until;

-- 4) Inbox unread parity by uid
with src as (
  select uid, count(*) as unread_count
  from stage_import.fb_user_inbox
  where upper(coalesce(trim(data->>'status'), 'UNREAD')) <> 'READ'
  group by uid
),
tgt as (
  select uid, count(*) as unread_count
  from public.app_inbox
  where upper(status) <> 'READ'
  group by uid
)
select coalesce(src.uid, tgt.uid) as uid,
       coalesce(src.unread_count, 0) as source_unread,
       coalesce(tgt.unread_count, 0) as target_unread
from src
full join tgt using (uid)
where coalesce(src.unread_count, 0) <> coalesce(tgt.unread_count, 0)
order by uid
limit 200;

-- 5) Notice read-marker parity by uid
with src as (
  select uid, count(*) as read_rows
  from stage_import.fb_user_read_notices
  group by uid
),
tgt as (
  select uid, count(*) as read_rows
  from public.app_notice_reads
  group by uid
)
select coalesce(src.uid, tgt.uid) as uid,
       coalesce(src.read_rows, 0) as source_rows,
       coalesce(tgt.read_rows, 0) as target_rows
from src
full join tgt using (uid)
where coalesce(src.read_rows, 0) <> coalesce(tgt.read_rows, 0)
order by uid
limit 200;

