-- Phase 3 Backfill / Chunk 01
-- Read-only staging schema for Firebase exports

create schema if not exists stage_import;

create table if not exists stage_import.fb_users (
  uid text primary key,
  data jsonb not null
);
create table if not exists stage_import.fb_directory (
  uid text primary key,
  data jsonb not null
);
create table if not exists stage_import.fb_appeals (
  appeal_id text primary key,
  data jsonb not null
);
create table if not exists stage_import.fb_notices (
  notice_id text primary key,
  data jsonb not null
);
create table if not exists stage_import.fb_notifications (
  notif_id text primary key,
  data jsonb not null
);
create table if not exists stage_import.fb_user_inbox (
  uid text not null,
  inbox_id text not null,
  data jsonb not null,
  primary key (uid, inbox_id)
);
create table if not exists stage_import.fb_user_read_notices (
  uid text not null,
  notice_id text not null,
  data jsonb not null default '{}'::jsonb,
  primary key (uid, notice_id)
);
create table if not exists stage_import.fb_user_notification_meta (
  uid text not null,
  doc_id text not null,
  data jsonb not null,
  primary key (uid, doc_id)
);
create table if not exists stage_import.fb_user_official_feedback (
  uid text not null,
  feedback_id text not null,
  data jsonb not null,
  primary key (uid, feedback_id)
);

create or replace function stage_import.jsonb_to_timestamptz(j jsonb)
returns timestamptz
language plpgsql
as $$
declare s text;
begin
  if j is null or jsonb_typeof(j) = 'null' then return null; end if;
  if jsonb_typeof(j) = 'string' then
    begin return (j#>>'{}')::timestamptz; exception when others then return null; end;
  end if;
  if jsonb_typeof(j) = 'number' then
    s := j#>>'{}';
    if s::numeric > 100000000000 then return to_timestamp((s::numeric)/1000.0); end if;
    return to_timestamp(s::numeric);
  end if;
  if jsonb_typeof(j) = 'object' then
    if j ? '_seconds' then return to_timestamp((j->>'_seconds')::double precision); end if;
    if j ? 'seconds' then return to_timestamp((j->>'seconds')::double precision); end if;
    if j ? 'iso' then begin return (j->>'iso')::timestamptz; exception when others then return null; end; end if;
  end if;
  return null;
exception when others then
  return null;
end;
$$;

create or replace function stage_import.jsonb_to_int(j jsonb)
returns integer
language plpgsql
as $$
begin
  if j is null or jsonb_typeof(j) = 'null' then return null; end if;
  if jsonb_typeof(j) = 'number' then return (j#>>'{}')::integer; end if;
  if jsonb_typeof(j) = 'string' and (j#>>'{}') ~ '^-?[0-9]+$' then return (j#>>'{}')::integer; end if;
  return null;
exception when others then
  return null;
end;
$$;

create or replace function stage_import.jsonb_to_bool(j jsonb)
returns boolean
language plpgsql
as $$
declare s text;
begin
  if j is null or jsonb_typeof(j) = 'null' then return null; end if;
  if jsonb_typeof(j) = 'boolean' then return (j#>>'{}')::boolean; end if;
  if jsonb_typeof(j) = 'number' then return ((j#>>'{}')::numeric <> 0); end if;
  if jsonb_typeof(j) = 'string' then
    s := lower(trim(j#>>'{}'));
    if s in ('true','1','yes','y') then return true; end if;
    if s in ('false','0','no','n') then return false; end if;
  end if;
  return null;
end;
$$;

