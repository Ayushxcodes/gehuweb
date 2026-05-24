-- Phase E1 / Chunk 01
-- Event catalog + competition contract.

begin;

create or replace function public.app_event_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create table if not exists public.event_core (
  event_id text primary key,
  title text not null,
  subtitle text not null default '',
  description text not null default '',
  organized_by text not null default '',
  whatsapp_link text not null default '',
  banner_url text not null default '',
  banner_object_key text not null default '',
  event_type text not null default 'MAIN'
    check (event_type in ('MAIN', 'STANDALONE')),
  is_live boolean not null default false,
  finalized boolean not null default false,
  is_cancelled boolean not null default false,
  event_interaction_locked boolean not null default false,
  start_at timestamptz,
  end_at timestamptz,
  registration_deadline timestamptz,
  venue text not null default '',
  target_campuses text[] not null default array['ALL']::text[],
  target_courses text[] not null default array['ALL']::text[],
  target_semesters integer[] not null default array[-1]::integer[],
  audience_json jsonb not null default '{}'::jsonb,
  total_registrations integer not null default 0 check (total_registrations >= 0),
  competitions_count integer not null default 0 check (competitions_count >= 0),
  created_by_uid text not null default '',
  created_by_auth_user_id uuid references auth.users(id) on delete set null,
  source text not null default 'supabase',
  source_payload jsonb not null default '{}'::jsonb,
  source_created_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (length(trim(event_id)) > 0),
  check (length(trim(title)) > 0)
);

create table if not exists public.event_competitions (
  event_id text not null references public.event_core(event_id) on delete cascade,
  comp_id text not null,
  competition_name text not null,
  subtitle text not null default '',
  is_default boolean not null default false,
  is_live boolean not null default false,
  participation_mode text not null default 'BOTH'
    check (participation_mode in ('SOLO', 'TEAM', 'BOTH')),
  max_members integer not null default 1 check (max_members between 1 and 50),
  team_config jsonb not null default '{}'::jsonb,
  solo_config jsonb not null default '{}'::jsonb,
  qr_enabled boolean not null default true,
  venue text not null default '',
  whatsapp_group_link text not null default '',
  organized_by text not null default '',
  coordinator_uids text[] not null default '{}'::text[],
  scanner_uids text[] not null default '{}'::text[],
  is_free boolean not null default true,
  fee_amount numeric(12,2) not null default 0 check (fee_amount >= 0),
  fee_instructions text not null default '',
  payment_method text not null default 'MANUAL'
    check (payment_method in ('MANUAL', 'RAZORPAY', 'ERP_GATEWAY')),
  registration_deadline timestamptz,
  results_published boolean not null default false,
  source_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (event_id, comp_id),
  check (length(trim(comp_id)) > 0),
  check (length(trim(competition_name)) > 0)
);

drop trigger if exists trg_event_core_touch on public.event_core;
create trigger trg_event_core_touch
before update on public.event_core
for each row execute function public.app_event_touch_updated_at();

drop trigger if exists trg_event_competitions_touch on public.event_competitions;
create trigger trg_event_competitions_touch
before update on public.event_competitions
for each row execute function public.app_event_touch_updated_at();

commit;
