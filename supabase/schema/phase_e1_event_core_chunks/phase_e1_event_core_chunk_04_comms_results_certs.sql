-- Phase E1 / Chunk 04
-- Announcements, group chat metadata, results, certificates.

begin;

create table if not exists public.event_announcements (
  event_id text not null references public.event_core(event_id) on delete cascade,
  announcement_id text not null,
  message text not null,
  sender_name text not null default '',
  sender_auth_user_id uuid references auth.users(id) on delete set null,
  type text not null default 'GENERAL',
  topics jsonb not null default '[]'::jsonb,
  sent_at timestamptz not null default now(),
  payload_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (event_id, announcement_id)
);

create table if not exists public.event_group_channels (
  event_id text not null,
  comp_id text not null,
  group_id text not null default 'main',
  active boolean not null default true,
  member_student_ids text[] not null default '{}'::text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (event_id, comp_id, group_id),
  foreign key (event_id, comp_id)
    references public.event_competitions(event_id, comp_id) on delete cascade
);

create table if not exists public.event_group_members (
  event_id text not null,
  comp_id text not null,
  group_id text not null default 'main',
  student_id text not null references public.student_core(stu_student_id) on delete restrict,
  role text not null default 'MEMBER',
  status text not null default 'ACTIVE',
  joined_at timestamptz not null default now(),
  primary key (event_id, comp_id, group_id, student_id),
  foreign key (event_id, comp_id, group_id)
    references public.event_group_channels(event_id, comp_id, group_id) on delete cascade
);

create table if not exists public.event_group_messages (
  event_id text not null,
  comp_id text not null,
  group_id text not null default 'main',
  message_id text not null,
  sender_student_id text references public.student_core(stu_student_id) on delete set null,
  sender_name text not null default '',
  sender_role text not null default '',
  text text not null default '',
  type text not null default 'TEXT',
  sent_at timestamptz not null default now(),
  payload_json jsonb not null default '{}'::jsonb,
  primary key (event_id, comp_id, group_id, message_id),
  foreign key (event_id, comp_id, group_id)
    references public.event_group_channels(event_id, comp_id, group_id) on delete cascade
);

create table if not exists public.event_results (
  event_id text not null,
  comp_id text not null,
  team_id text not null,
  status text not null default 'PARTICIPANT'
    check (status in ('WINNER','RUNNER_UP','SECOND_RUNNER_UP','PARTICIPANT')),
  rank_no integer not null default 0 check (rank_no >= 0),
  score numeric(12,2),
  max_score numeric(12,2),
  members_json jsonb not null default '[]'::jsonb,
  published boolean not null default false,
  published_at timestamptz,
  payload_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (event_id, comp_id, team_id),
  foreign key (event_id, comp_id, team_id)
    references public.event_teams(event_id, comp_id, team_id) on delete cascade
);

create table if not exists public.event_certificates (
  certificate_id text primary key,
  verify_code text not null unique,
  event_id text not null,
  comp_id text not null,
  team_id text not null default '',
  student_id text not null references public.student_core(stu_student_id) on delete restrict,
  student_name text not null default '',
  status text not null default 'PARTICIPANT',
  certificate_position text not null default '',
  storage_url text not null default '',
  storage_object_key text not null default '',
  certificate_version text not null default '',
  issued_at timestamptz not null default now(),
  payload_json jsonb not null default '{}'::jsonb
);

commit;
