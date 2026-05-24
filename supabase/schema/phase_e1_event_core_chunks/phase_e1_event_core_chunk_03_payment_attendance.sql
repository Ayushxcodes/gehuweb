-- Phase E1 / Chunk 03
-- Event participant, payment ledger, schedule, attendance.

begin;

create table if not exists public.event_participants (
  event_id text not null references public.event_core(event_id) on delete cascade,
  student_id text not null references public.student_core(stu_student_id) on delete restrict,
  auth_user_id uuid references auth.users(id) on delete set null,
  legacy_firebase_uid text not null default '',
  status text not null default 'REGISTERED',
  comp_ids text[] not null default '{}'::text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (event_id, student_id)
);

create table if not exists public.event_payment_records (
  payment_record_id text primary key,
  event_id text not null,
  comp_id text not null,
  student_id text not null references public.student_core(stu_student_id) on delete restrict,
  auth_user_id uuid references auth.users(id) on delete set null,
  legacy_firebase_uid text not null default '',
  status text not null default 'PAYMENT_PENDING'
    check (status in ('PAYMENT_PENDING','PAYMENT_SUBMITTED','PAYMENT_REJECTED',
      'VERIFIED','REGISTERED','REFUND_PENDING','REFUND_COMPLETE')),
  method text not null default 'MANUAL' check (method in ('MANUAL','RAZORPAY','ERP_GATEWAY')),
  amount numeric(12,2) not null default 0 check (amount >= 0),
  proof_url text not null default '',
  proof_object_key text not null default '',
  razorpay_payment_id text not null default '',
  refund_status text not null default 'NONE' check (refund_status in ('NONE','PENDING','COMPLETE')),
  rejection_reason text not null default '',
  verified_by_auth_user_id uuid references auth.users(id) on delete set null,
  source_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (event_id, comp_id, student_id),
  foreign key (event_id, comp_id)
    references public.event_competitions(event_id, comp_id) on delete cascade
);

create table if not exists public.event_schedule_stages (
  event_id text not null references public.event_core(event_id) on delete cascade,
  stage_id text not null,
  title text not null,
  type text not null default 'CUSTOM',
  status text not null default 'UPCOMING'
    check (status in ('UPCOMING','ACTIVE','COMPLETED','CANCELLED')),
  stage_order integer not null default 0,
  is_public boolean not null default true,
  starts_at timestamptz,
  ends_at timestamptz,
  payload_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (event_id, stage_id)
);

create table if not exists public.event_attendance (
  event_id text not null,
  comp_id text not null,
  team_id text not null,
  status text not null default 'PARTIAL' check (status in ('FULL','PARTIAL','ABSENT')),
  present_count integer not null default 0 check (present_count >= 0),
  total_members integer not null default 0 check (total_members >= 0),
  marked_by_auth_user_id uuid references auth.users(id) on delete set null,
  marked_at timestamptz not null default now(),
  payload_json jsonb not null default '{}'::jsonb,
  primary key (event_id, comp_id, team_id),
  foreign key (event_id, comp_id, team_id)
    references public.event_teams(event_id, comp_id, team_id) on delete cascade
);

create table if not exists public.event_attendance_members (
  event_id text not null,
  comp_id text not null,
  team_id text not null,
  student_id text not null references public.student_core(stu_student_id) on delete restrict,
  present boolean not null default false,
  marked_at timestamptz not null default now(),
  primary key (event_id, comp_id, team_id, student_id),
  foreign key (event_id, comp_id, team_id)
    references public.event_attendance(event_id, comp_id, team_id) on delete cascade
);

commit;
