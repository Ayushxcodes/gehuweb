-- Phase 3 / Chunk 04
-- Normalization triggers and final support indexes

create or replace function public.app_profile_state_normalize_keys()
returns trigger
language plpgsql
as $$
begin
  new.official_email := coalesce(trim(new.official_email), '');
  new.official_email_key := lower(new.official_email);
  new.personal_email := nullif(trim(coalesce(new.personal_email, '')), '');
  new.personal_email_key := case
    when new.personal_email is null then ''
    else lower(new.personal_email)
  end;
  return new;
end;
$$;

drop trigger if exists trg_app_profile_state_normalize_keys on public.app_profile_state;
create trigger trg_app_profile_state_normalize_keys
before insert or update on public.app_profile_state
for each row execute function public.app_profile_state_normalize_keys();

create or replace function public.app_directory_index_normalize_keys()
returns trigger
language plpgsql
as $$
begin
  new.email := coalesce(trim(new.email), '');
  new.roll_no := coalesce(trim(new.roll_no), '');
  new.university_roll := coalesce(trim(new.university_roll), '');
  new.email_key := lower(new.email);
  new.roll_no_key := upper(new.roll_no);
  new.university_roll_key := upper(new.university_roll);
  return new;
end;
$$;

drop trigger if exists trg_app_directory_index_normalize_keys on public.app_directory_index;
create trigger trg_app_directory_index_normalize_keys
before insert or update on public.app_directory_index
for each row execute function public.app_directory_index_normalize_keys();

create index if not exists idx_app_feedback_uid_source_ts
  on public.app_official_feedback(uid, source_timestamp desc);
create index if not exists idx_app_notification_meta_last_seen
  on public.app_notification_meta(last_seen_at desc nulls last);
create index if not exists idx_app_notices_event
  on public.app_notices(event_id);
create index if not exists idx_app_appeals_created
  on public.app_appeals(created_at desc);
create index if not exists idx_app_notifications_type_created
  on public.app_notifications(type, created_at desc);

