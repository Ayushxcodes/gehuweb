# Stage Import Format (Firebase -> `stage_import.*`)

Use JSON payload as-is from Firebase export.

## Required staging tables
- `stage_import.fb_users`
- `stage_import.fb_directory`
- `stage_import.fb_appeals`
- `stage_import.fb_notices`
- `stage_import.fb_notifications`
- `stage_import.fb_user_inbox`
- `stage_import.fb_user_read_notices`
- `stage_import.fb_user_notification_meta`
- `stage_import.fb_user_official_feedback`

## Example inserts
```sql
insert into stage_import.fb_users(uid, data)
values ('UID_001', '{"name":"Test","email":"a@b.com"}'::jsonb);

insert into stage_import.fb_user_inbox(uid, inbox_id, data)
values ('UID_001', 'INBOX_001', '{"type":"NOTICE","status":"UNREAD"}'::jsonb);
```

## Replace mode (recommended for reruns)
```sql
truncate table
  stage_import.fb_users,
  stage_import.fb_directory,
  stage_import.fb_appeals,
  stage_import.fb_notices,
  stage_import.fb_notifications,
  stage_import.fb_user_inbox,
  stage_import.fb_user_read_notices,
  stage_import.fb_user_notification_meta,
  stage_import.fb_user_official_feedback;
```

