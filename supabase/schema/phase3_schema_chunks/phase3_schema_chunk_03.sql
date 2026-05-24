-- Phase 3 / Chunk 03
-- Notices + broadcasts + directory index

create table if not exists public.app_notices (
  notice_id text primary key,
  title text not null default '',
  body text not null default '',
  type text not null default 'holiday'
    check (type in ('holiday', 'event', 'job')),
  branch text not null default 'ALL',
  courses text[] not null default array['ALL']::text[],
  semesters integer[] not null default array[-1]::integer[],
  created_by_uid text not null default '',
  active boolean not null default true,
  expires_at timestamptz,
  registration_deadline timestamptz,
  event_template text,
  event_config_json jsonb not null default '{}'::jsonb,
  event_id text not null default '',
  cta_label text not null default '',
  participation_enabled boolean not null default false,
  payload_json jsonb not null default '{}'::jsonb,
  source_created_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_app_notices_active_created
  on public.app_notices(active, created_at desc);
create index if not exists idx_app_notices_branch_created
  on public.app_notices(branch, created_at desc);
create index if not exists idx_app_notices_courses_gin
  on public.app_notices using gin (courses);
create index if not exists idx_app_notices_semesters_gin
  on public.app_notices using gin (semesters);

drop trigger if exists trg_app_notices_touch on public.app_notices;
create trigger trg_app_notices_touch
before update on public.app_notices
for each row execute function public.app_touch_updated_at();

create table if not exists public.app_notice_attachments (
  attachment_id bigint generated always as identity primary key,
  notice_id text not null references public.app_notices(notice_id) on update restrict on delete cascade,
  sort_order integer not null default 0,
  name text not null default '',
  url text not null default '',
  mime text not null default '',
  size_bytes bigint not null default 0 check (size_bytes >= 0),
  created_at timestamptz not null default now()
);

create unique index if not exists uq_app_notice_attachments_notice_sort_url
  on public.app_notice_attachments(notice_id, sort_order, url);

create index if not exists idx_app_notice_attachments_notice
  on public.app_notice_attachments(notice_id);

create table if not exists public.app_notifications (
  notif_id text primary key,
  type text not null default 'NOTICE',
  title text not null default '',
  message text not null default '',
  target_type text not null default 'ALL'
    check (target_type in ('ALL', 'SEGMENT', 'UID', 'EVENT', 'CUSTOM')),
  target_key text not null default 'all_students',
  target_id text not null default '',
  priority text not null default 'NORMAL'
    check (priority in ('LOW', 'NORMAL', 'HIGH', 'URGENT')),
  payload_json jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  source_created_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_app_notifications_target_created
  on public.app_notifications(target_key, created_at desc);

drop trigger if exists trg_app_notifications_touch on public.app_notifications;
create trigger trg_app_notifications_touch
before update on public.app_notifications
for each row execute function public.app_touch_updated_at();

create table if not exists public.app_directory_index (
  uid text primary key,
  name text not null default '',
  email text not null default '',
  roll_no text not null default '',
  university_roll text not null default '',
  role text not null default '',
  email_key text not null default '',
  roll_no_key text not null default '',
  university_roll_key text not null default '',
  student_id text not null default '',
  source_updated_at timestamptz,
  updated_at timestamptz not null default now(),
  check (email_key = lower(trim(email_key))),
  check (roll_no_key = upper(trim(roll_no_key)) or roll_no_key = ''),
  check (university_roll_key = upper(trim(university_roll_key)) or university_roll_key = '')
);

create index if not exists idx_app_directory_email_key
  on public.app_directory_index(email_key);
create index if not exists idx_app_directory_roll_key
  on public.app_directory_index(roll_no_key);
create index if not exists idx_app_directory_university_roll_key
  on public.app_directory_index(university_roll_key);

drop trigger if exists trg_app_directory_index_touch on public.app_directory_index;
create trigger trg_app_directory_index_touch
before update on public.app_directory_index
for each row execute function public.app_touch_updated_at();

