-- Phase 3 / Chunk 02
-- Appeals + feedback + inbox + read/meta

create table if not exists public.app_appeals (
  appeal_id text primary key,
  uid text not null,
  name text not null default '',
  email text not null default '',
  type text not null default 'PROFILE_CHANGE',
  message text not null,
  status text not null default 'PENDING'
    check (status in ('PENDING', 'RESOLVED', 'REJECTED', 'CANCELLED')),
  profile_path text not null default '',
  roll_no text not null default '',
  course text not null default '',
  semester integer,
  profile_data_json jsonb not null default '{}'::jsonb,
  admin_note text not null default '',
  resolved_by_auth_user_id uuid references auth.users(id) on update restrict on delete set null,
  resolved_at timestamptz,
  source_created_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_app_appeals_status_created
  on public.app_appeals(status, created_at desc);
create index if not exists idx_app_appeals_uid_status
  on public.app_appeals(uid, status);

drop trigger if exists trg_app_appeals_touch on public.app_appeals;
create trigger trg_app_appeals_touch
before update on public.app_appeals
for each row execute function public.app_touch_updated_at();

create table if not exists public.app_official_feedback (
  uid text not null,
  feedback_id text not null,
  message text not null,
  admin_name text not null default '',
  type text not null default '',
  source_timestamp timestamptz,
  meta_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (uid, feedback_id)
);

create index if not exists idx_app_official_feedback_uid_created
  on public.app_official_feedback(uid, created_at desc);

drop trigger if exists trg_app_official_feedback_touch on public.app_official_feedback;
create trigger trg_app_official_feedback_touch
before update on public.app_official_feedback
for each row execute function public.app_touch_updated_at();

create table if not exists public.app_inbox (
  uid text not null,
  inbox_id text not null,
  type text not null default 'GENERAL',
  title text not null default '',
  body text not null default '',
  status text not null default 'UNREAD'
    check (status in ('UNREAD', 'READ', 'ARCHIVED', 'DISMISSED')),
  event_id text not null default '',
  comp_id text not null default '',
  team_id text not null default '',
  notice_id text not null default '',
  from_uid text not null default '',
  target_id text not null default '',
  payload_json jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  source_created_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (uid, inbox_id)
);

create index if not exists idx_app_inbox_uid_status_created
  on public.app_inbox(uid, status, created_at desc);
create index if not exists idx_app_inbox_notice
  on public.app_inbox(notice_id);
create index if not exists idx_app_inbox_event_comp
  on public.app_inbox(event_id, comp_id);

drop trigger if exists trg_app_inbox_touch on public.app_inbox;
create trigger trg_app_inbox_touch
before update on public.app_inbox
for each row execute function public.app_touch_updated_at();

create table if not exists public.app_notice_reads (
  uid text not null,
  notice_id text not null,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (uid, notice_id)
);

create index if not exists idx_app_notice_reads_uid_read
  on public.app_notice_reads(uid, read_at desc);

drop trigger if exists trg_app_notice_reads_touch on public.app_notice_reads;
create trigger trg_app_notice_reads_touch
before update on public.app_notice_reads
for each row execute function public.app_touch_updated_at();

create table if not exists public.app_notification_meta (
  uid text primary key,
  last_seen_at timestamptz,
  dismissed_ids text[] not null default '{}'::text[],
  muted boolean not null default false,
  meta_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_app_notification_meta_touch on public.app_notification_meta;
create trigger trg_app_notification_meta_touch
before update on public.app_notification_meta
for each row execute function public.app_touch_updated_at();

