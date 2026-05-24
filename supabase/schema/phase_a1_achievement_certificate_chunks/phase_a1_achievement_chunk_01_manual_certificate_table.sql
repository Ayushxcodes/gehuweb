-- Phase A1 / Chunk 01
-- Generic achievement certificates for COURSE/OTHER future tabs.

begin;

create table if not exists public.app_achievement_certificates (
  certificate_id text primary key,
  verify_code text not null unique,
  student_id text not null references public.student_core(stu_student_id) on delete restrict,
  auth_user_id uuid references auth.users(id) on delete set null,
  category text not null check (category in ('COURSE','OTHER','ACHIEVEMENT')),
  title text not null,
  issuer_name text not null default '',
  description text not null default '',
  status text not null default 'VERIFIED',
  certificate_position text not null default '',
  storage_url text not null default '',
  storage_object_key text not null default '',
  certificate_version text not null default '',
  issued_at timestamptz not null default now(),
  expires_at timestamptz,
  created_by_auth_user_id uuid references auth.users(id) on delete set null,
  payload_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (length(trim(certificate_id)) > 0),
  check (length(trim(verify_code)) > 0),
  check (length(trim(title)) > 0)
);

create index if not exists idx_app_achievement_cert_student
  on public.app_achievement_certificates(student_id, issued_at desc);
create index if not exists idx_app_achievement_cert_category
  on public.app_achievement_certificates(category, issued_at desc);

alter table public.app_achievement_certificates enable row level security;

drop policy if exists p_a1_cert_select on public.app_achievement_certificates;
create policy p_a1_cert_select on public.app_achievement_certificates
for select to authenticated
using (public.app_event_is_admin() or student_id = public.app_event_current_student_id());

drop policy if exists p_a1_cert_admin_all on public.app_achievement_certificates;
create policy p_a1_cert_admin_all on public.app_achievement_certificates
for all to authenticated
using (public.app_event_is_admin())
with check (public.app_event_is_admin());

drop trigger if exists trg_app_achievement_cert_touch on public.app_achievement_certificates;
create trigger trg_app_achievement_cert_touch
before update on public.app_achievement_certificates
for each row execute function public.app_touch_updated_at();

grant select, insert, update, delete on public.app_achievement_certificates to authenticated;

commit;
