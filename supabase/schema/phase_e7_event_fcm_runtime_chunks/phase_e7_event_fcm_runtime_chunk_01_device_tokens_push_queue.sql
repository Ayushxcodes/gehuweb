-- Phase E7 / Chunk 01
-- Supabase-native FCM device-token registry + trusted push queue.

begin;

create table if not exists public.app_fcm_tokens (
  token text primary key,
  uid text not null,
  auth_user_id uuid references auth.users(id) on delete cascade,
  student_id text,
  platform text not null check (platform in ('ANDROID','WEB')),
  device_id text not null default '',
  app_version text not null default '',
  user_agent text not null default '',
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (length(trim(token)) > 0)
);

create index if not exists idx_app_fcm_tokens_uid_active
  on public.app_fcm_tokens(uid, is_active, last_seen_at desc);

create index if not exists idx_app_fcm_tokens_student_active
  on public.app_fcm_tokens(student_id, is_active, last_seen_at desc)
  where student_id is not null;

create table if not exists public.app_push_queue (
  push_id text primary key,
  target_type text not null check (target_type in ('USER','EVENT','SEGMENT','ALL')),
  target_key text not null default '',
  uid text,
  event_id text,
  comp_id text,
  notification_id text,
  title text not null,
  body text not null,
  route text not null default '',
  payload_json jsonb not null default '{}'::jsonb,
  status text not null default 'PENDING'
    check (status in ('PENDING','SENT','FAILED','SKIPPED')),
  attempts integer not null default 0 check (attempts >= 0),
  last_error text not null default '',
  claimed_at timestamptz,
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (length(trim(push_id)) > 0),
  check (length(trim(title)) > 0),
  check (length(trim(body)) > 0)
);

create index if not exists idx_app_push_queue_pending
  on public.app_push_queue(status, created_at asc)
  where status = 'PENDING';

create or replace function public.app_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_app_fcm_tokens_touch on public.app_fcm_tokens;
create trigger trg_app_fcm_tokens_touch
before update on public.app_fcm_tokens
for each row execute function public.app_touch_updated_at();

drop trigger if exists trg_app_push_queue_touch on public.app_push_queue;
create trigger trg_app_push_queue_touch
before update on public.app_push_queue
for each row execute function public.app_touch_updated_at();

alter table public.app_fcm_tokens enable row level security;
alter table public.app_push_queue enable row level security;

grant select, insert, update, delete on table public.app_fcm_tokens to authenticated;
grant select, insert, update, delete on table public.app_push_queue to authenticated;

drop policy if exists p_e7_fcm_select_own on public.app_fcm_tokens;
create policy p_e7_fcm_select_own on public.app_fcm_tokens
for select to authenticated
using (auth_user_id = auth.uid() or uid = auth.uid()::text or public.app_phase3_is_admin());

drop policy if exists p_e7_fcm_delete_own on public.app_fcm_tokens;
create policy p_e7_fcm_delete_own on public.app_fcm_tokens
for delete to authenticated
using (auth_user_id = auth.uid() or uid = auth.uid()::text or public.app_phase3_is_admin());

-- Direct client writes are intentionally denied. Clients write via RPC so uid/student mapping
-- is derived server-side and cannot be spoofed.
drop policy if exists p_e7_fcm_insert_none on public.app_fcm_tokens;
create policy p_e7_fcm_insert_none on public.app_fcm_tokens
for insert to authenticated
with check (false);

drop policy if exists p_e7_fcm_update_own on public.app_fcm_tokens;
create policy p_e7_fcm_update_own on public.app_fcm_tokens
for update to authenticated
using (auth_user_id = auth.uid() or uid = auth.uid()::text)
with check (auth_user_id = auth.uid() or uid = auth.uid()::text);

drop policy if exists p_e7_push_queue_admin_read on public.app_push_queue;
create policy p_e7_push_queue_admin_read on public.app_push_queue
for select to authenticated
using (public.app_phase3_is_admin());

create or replace function public.api_register_fcm_token(
  p_token text,
  p_platform text,
  p_device_id text default '',
  p_app_version text default '',
  p_user_agent text default ''
)
returns table(token text, platform text, uid text, student_id text, is_active boolean, last_seen_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth uuid := auth.uid();
  v_uid text;
  v_student_id text;
  v_platform text := upper(trim(coalesce(p_platform, '')));
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if coalesce(trim(p_token), '') = '' then raise exception 'TOKEN_REQUIRED'; end if;
  if v_platform not in ('ANDROID','WEB') then raise exception 'INVALID_PLATFORM'; end if;

  select ps.uid, ps.student_id
    into v_uid, v_student_id
  from public.app_profile_state ps
  where ps.auth_user_id = v_auth
  limit 1;

  v_uid := coalesce(nullif(v_uid, ''), v_auth::text);

  insert into public.app_fcm_tokens(token, uid, auth_user_id, student_id, platform, device_id, app_version, user_agent, is_active, last_seen_at)
  values (trim(p_token), v_uid, v_auth, v_student_id, v_platform,
          coalesce(p_device_id, ''), coalesce(p_app_version, ''),
          left(coalesce(p_user_agent, ''), 500), true, now())
  on conflict (token) do update set
    uid = excluded.uid,
    auth_user_id = excluded.auth_user_id,
    student_id = excluded.student_id,
    platform = excluded.platform,
    device_id = excluded.device_id,
    app_version = excluded.app_version,
    user_agent = excluded.user_agent,
    is_active = true,
    last_seen_at = now(),
    updated_at = now();

  return query
  select t.token, t.platform, t.uid, coalesce(t.student_id, ''), t.is_active, t.last_seen_at
  from public.app_fcm_tokens t
  where t.token = trim(p_token);
end;
$$;

create or replace function public.api_unregister_fcm_token(p_token text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth uuid := auth.uid();
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  update public.app_fcm_tokens
  set is_active = false, updated_at = now()
  where token = trim(coalesce(p_token, ''))
    and (auth_user_id = v_auth or uid = v_auth::text or public.app_phase3_is_admin());
  return found;
end;
$$;

create or replace function public.api_service_push_tokens_for_queue(p_push_id text)
returns table(token text, platform text, uid text)
language sql
stable
security definer
set search_path = public
as $$
  with q as (
    select * from public.app_push_queue
    where push_id = p_push_id
      and auth.role() = 'service_role'
  ),
  target_students as (
    select ep.student_id, ps.uid
    from q
    join public.event_participants ep on ep.event_id = q.event_id
    join public.app_profile_state ps on ps.student_id = ep.student_id
    where q.target_type = 'EVENT'
  ),
  target_segment as (
    select ps.uid
    from q
    join public.app_profile_state ps on q.target_type = 'SEGMENT'
    where (
      lower(coalesce(ps.course, '')) = lower(q.target_key)
      or lower(coalesce(ps.branch, '')) = lower(q.target_key)
      or lower(coalesce(ps.course, '') || '_sem' || coalesce(ps.semester::text, '')) = lower(q.target_key)
    )
  ),
  target_users as (
    select q.uid from q where q.target_type = 'USER' and coalesce(q.uid, '') <> ''
    union
    select q.target_key from q where q.target_type = 'USER' and coalesce(q.target_key, '') <> ''
    union
    select uid from target_students
    union
    select uid from target_segment
    union
    select t.uid from public.app_fcm_tokens t, q where q.target_type = 'ALL' and t.is_active = true
  )
  select distinct t.token, t.platform, t.uid
  from public.app_fcm_tokens t
  join target_users tu on tu.uid = t.uid
  where t.is_active = true;
$$;

create or replace function public.api_service_mark_push_sent(
  p_push_id text,
  p_sent_count integer default 0
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.role() <> 'service_role' then raise exception 'SERVICE_ROLE_ONLY'; end if;
  update public.app_push_queue
  set status = case when coalesce(p_sent_count, 0) > 0 then 'SENT' else 'SKIPPED' end,
      sent_at = now(),
      attempts = attempts + 1,
      last_error = case when coalesce(p_sent_count, 0) > 0 then '' else 'NO_ACTIVE_TOKENS' end,
      updated_at = now()
  where push_id = p_push_id and status = 'PENDING';
  return found;
end;
$$;

create or replace function public.api_service_mark_push_failed(
  p_push_id text,
  p_error text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.role() <> 'service_role' then raise exception 'SERVICE_ROLE_ONLY'; end if;
  update public.app_push_queue
  set status = case when attempts >= 4 then 'FAILED' else 'PENDING' end,
      attempts = attempts + 1,
      last_error = left(coalesce(p_error, 'UNKNOWN_ERROR'), 1000),
      updated_at = now()
  where push_id = p_push_id;
  return found;
end;
$$;

grant execute on function public.api_register_fcm_token(text,text,text,text,text) to authenticated;
grant execute on function public.api_unregister_fcm_token(text) to authenticated;
grant execute on function public.api_service_push_tokens_for_queue(text) to service_role;
grant execute on function public.api_service_mark_push_sent(text,integer) to service_role;
grant execute on function public.api_service_mark_push_failed(text,text) to service_role;

commit;

