-- Phase 3 runtime repair / Simulate admin policy check / 2026-05-19
-- Run in Supabase SQL Editor after the helper + admin identity repair.
-- This explicitly sets the local JWT claims to admin@test.gehu so auth.uid() is meaningful.
-- All writes happen inside this transaction and are rolled back.

begin;

select set_config(
  'request.jwt.claim.sub',
  (select id::text from auth.users where lower(email) = 'admin@test.gehu' limit 1),
  true
);

select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub', (select id::text from auth.users where lower(email) = 'admin@test.gehu' limit 1),
    'role', 'authenticated',
    'email', 'admin@test.gehu'
  )::text,
  true
);

set local role authenticated;

select
  auth.uid() as simulated_auth_uid,
  public.app_phase3_is_admin() as helper_says_admin,
  exists (
    select 1
    from public.app_user_identity ai
    where ai.auth_user_id = auth.uid()
      and ai.is_active = true
      and upper(ai.account_type) = 'ADMIN'
  ) as identity_row_says_admin;

-- Reads should not throw permission denied when helper_says_admin is true.
select count(*) as visible_pending_appeals
from public.app_appeals
where status = 'PENDING';

select count(*) as visible_notices
from public.app_notices;

-- Notice compose smoke test: insert, attachment insert, and upsert/update path.
insert into public.app_notices (
  notice_id,
  title,
  body,
  type,
  branch,
  courses,
  semesters,
  created_by_uid,
  active,
  event_config_json,
  event_id,
  cta_label,
  participation_enabled,
  payload_json,
  source_created_at
) values (
  '__rls_smoke_notice__',
  'RLS smoke notice',
  'Rollback-only admin notice write test',
  'holiday',
  'ALL',
  array['ALL']::text[],
  array[-1]::integer[],
  auth.uid()::text,
  true,
  '{}'::jsonb,
  '',
  '',
  false,
  '{}'::jsonb,
  now()
);

insert into public.app_notice_attachments (
  notice_id,
  sort_order,
  name,
  url,
  mime,
  size_bytes
) values (
  '__rls_smoke_notice__',
  0,
  'smoke.txt',
  'https://example.invalid/smoke.txt',
  'text/plain',
  1
);

insert into public.app_notices (
  notice_id,
  title,
  body,
  type,
  branch,
  courses,
  semesters,
  created_by_uid,
  active,
  event_config_json,
  payload_json,
  source_created_at
) values (
  '__rls_smoke_notice__',
  'RLS smoke notice updated',
  'Rollback-only admin notice upsert test',
  'holiday',
  'ALL',
  array['ALL']::text[],
  array[-1]::integer[],
  auth.uid()::text,
  true,
  '{}'::jsonb,
  '{}'::jsonb,
  now()
)
on conflict (notice_id) do update set
  title = excluded.title,
  body = excluded.body,
  updated_at = now();

-- Appeal admin smoke test: insert and resolve/update path.
insert into public.app_appeals (
  appeal_id,
  uid,
  name,
  email,
  type,
  message,
  status,
  profile_path,
  roll_no,
  course,
  semester,
  profile_data_json,
  source_created_at
) values (
  '__rls_smoke_appeal__',
  auth.uid()::text,
  'RLS Smoke Student',
  'admin@test.gehu',
  'PROFILE_CHANGE',
  'Rollback-only admin appeal write test',
  'PENDING',
  'app_profile_state/' || auth.uid()::text,
  '',
  'MCA',
  1,
  '{}'::jsonb,
  now()
);

update public.app_appeals
set status = 'RESOLVED',
    admin_note = 'Rollback-only admin appeal update test',
    resolved_at = now()
where appeal_id = '__rls_smoke_appeal__';

select
  true as admin_notice_write_smoke_passed,
  true as admin_attachment_write_smoke_passed,
  true as admin_appeal_write_smoke_passed;

rollback;