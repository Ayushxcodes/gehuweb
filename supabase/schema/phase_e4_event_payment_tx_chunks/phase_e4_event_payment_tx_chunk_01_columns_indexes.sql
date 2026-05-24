-- Phase E4 / Chunk 01
-- Event payment transaction support columns and indexes.

begin;

alter table public.event_payment_records
  add column if not exists submitted_at timestamptz;

alter table public.event_payment_records
  add column if not exists verified_at timestamptz;

alter table public.event_payment_records
  add column if not exists razorpay_order_id text not null default '';

alter table public.event_payment_records
  add column if not exists gateway_name text not null default '';

alter table public.event_registrations
  add column if not exists payment_proof_url text not null default '';

alter table public.event_registrations
  add column if not exists payment_submitted_at timestamptz;

alter table public.event_registrations
  add column if not exists payment_verified_at timestamptz;

alter table public.event_registrations
  add column if not exists payment_verified_by_auth_user_id uuid references auth.users(id) on delete set null;

alter table public.event_registrations
  add column if not exists rejection_reason text not null default '';

create index if not exists idx_event_payment_records_status_comp
  on public.event_payment_records(event_id, comp_id, status, submitted_at desc nulls last);

create index if not exists idx_event_registrations_payment_status
  on public.event_registrations(event_id, comp_id, status, updated_at desc);

commit;