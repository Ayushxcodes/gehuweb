-- Phase B1 / Chunk 04
-- Student notification read/dismiss/seen state writes.

begin;

create or replace function public.api_mark_inbox_notification_read(p_inbox_id text)
returns boolean
language plpgsql
volatile
security invoker
set search_path = public
as $$
declare
  v_uid text;
begin
  v_uid := public.app_current_profile_uid();
  if v_uid is null or trim(v_uid) = '' then
    raise exception 'No profile mapping for current user' using errcode = '42501';
  end if;

  update public.app_inbox
  set status = 'READ', read_at = now(), updated_at = now()
  where uid = v_uid and inbox_id = p_inbox_id;

  return found;
end;
$$;

create or replace function public.api_touch_notification_seen()
returns boolean
language plpgsql
volatile
security invoker
set search_path = public
as $$
declare
  v_uid text;
begin
  v_uid := public.app_current_profile_uid();
  if v_uid is null or trim(v_uid) = '' then
    raise exception 'No profile mapping for current user' using errcode = '42501';
  end if;

  insert into public.app_notification_meta (uid, last_seen_at)
  values (v_uid, now())
  on conflict (uid) do update
    set last_seen_at = excluded.last_seen_at,
        updated_at = now();

  return true;
end;
$$;

create or replace function public.api_dismiss_notifications(p_notif_ids text[])
returns integer
language plpgsql
volatile
security invoker
set search_path = public
as $$
declare
  v_uid text;
  v_ids text[];
begin
  v_uid := public.app_current_profile_uid();
  if v_uid is null or trim(v_uid) = '' then
    raise exception 'No profile mapping for current user' using errcode = '42501';
  end if;

  select coalesce(array_agg(distinct trim(x)) filter (where trim(x) <> ''), '{}'::text[])
  into v_ids
  from unnest(coalesce(p_notif_ids, '{}'::text[])) as u(x);

  if array_length(v_ids, 1) is null then
    return 0;
  end if;

  insert into public.app_notification_meta (uid, dismissed_ids, meta_json)
  values (v_uid, v_ids, jsonb_build_object('dismissedUpdatedAt', now()))
  on conflict (uid) do update
    set dismissed_ids = (
          select array_agg(distinct id)
          from unnest(public.app_notification_meta.dismissed_ids || excluded.dismissed_ids) as u(id)
        ),
        meta_json = public.app_notification_meta.meta_json || excluded.meta_json,
        updated_at = now();

  return array_length(v_ids, 1);
end;
$$;

grant execute on function public.api_mark_inbox_notification_read(text) to authenticated;
grant execute on function public.api_touch_notification_seen() to authenticated;
grant execute on function public.api_dismiss_notifications(text[]) to authenticated;

commit;
