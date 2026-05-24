-- Phase E1 / Chunk 02
-- Student registration, teams, invites, participant mirror.

begin;

create table if not exists public.event_registrations (
  event_id text not null,
  comp_id text not null,
  student_id text not null references public.student_core(stu_student_id) on delete restrict,
  auth_user_id uuid references auth.users(id) on delete set null,
  legacy_firebase_uid text not null default '',
  mode text not null check (mode in ('individual', 'team')),
  team_id text not null default '',
  role text not null default 'MEMBER' check (role in ('LEADER', 'MEMBER')),
  status text not null default 'PENDING'
    check (status in ('PENDING','ACCEPTED','REGISTERED','PAYMENT_PENDING',
      'PAYMENT_SUBMITTED','PAYMENT_REJECTED','VERIFIED','CANCELLED')),
  category text not null default '',
  payment_status text not null default '',
  selected_topic text not null default '',
  source_payload jsonb not null default '{}'::jsonb,
  registered_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (event_id, comp_id, student_id),
  foreign key (event_id, comp_id)
    references public.event_competitions(event_id, comp_id) on delete cascade
);

create table if not exists public.event_teams (
  event_id text not null,
  comp_id text not null,
  team_id text not null,
  team_name text not null default '',
  leader_student_id text references public.student_core(stu_student_id) on delete restrict,
  leader_auth_user_id uuid references auth.users(id) on delete set null,
  participant_type text not null default 'TEAM' check (participant_type in ('SOLO','TEAM')),
  team_status text not null default 'INCOMPLETE'
    check (team_status in ('OPEN','INCOMPLETE','COMPLETE','LOCKED','CANCELLED')),
  status text not null default 'OPEN',
  max_members integer not null default 1 check (max_members between 1 and 50),
  active boolean not null default true,
  team_locked boolean not null default false,
  selected_topic text not null default '',
  topic_locked boolean not null default false,
  topic_submitted_at timestamptz,
  payment_status text not null default '',
  category text not null default '',
  source_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (event_id, comp_id, team_id),
  foreign key (event_id, comp_id)
    references public.event_competitions(event_id, comp_id) on delete cascade
);

create table if not exists public.event_team_members (
  event_id text not null,
  comp_id text not null,
  team_id text not null,
  student_id text not null references public.student_core(stu_student_id) on delete restrict,
  auth_user_id uuid references auth.users(id) on delete set null,
  role text not null default 'MEMBER' check (role in ('LEADER','MEMBER')),
  status text not null default 'ACTIVE'
    check (status in ('ACTIVE','INVITED','PENDING','LEFT','REMOVED')),
  joined_at timestamptz not null default now(),
  primary key (event_id, comp_id, team_id, student_id),
  foreign key (event_id, comp_id, team_id)
    references public.event_teams(event_id, comp_id, team_id) on delete cascade
);

create table if not exists public.event_team_invites (
  event_id text not null,
  comp_id text not null,
  team_id text not null,
  student_id text not null references public.student_core(stu_student_id) on delete restrict,
  invited_by_student_id text references public.student_core(stu_student_id) on delete set null,
  status text not null default 'PENDING'
    check (status in ('PENDING','ACCEPTED','REJECTED','CANCELLED','EXPIRED')),
  inbox_id text not null default '',
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  primary key (event_id, comp_id, team_id, student_id),
  foreign key (event_id, comp_id, team_id)
    references public.event_teams(event_id, comp_id, team_id) on delete cascade
);

commit;
