-- Phase E7 / Chunk 02
-- Shared event announcement RPC: announcement row + inbox rows + push queue.

begin;

create or replace function public.api_event_admin_send_announcement(
  p_event_id text,
  p_title text,
  p_body text,
  p_comp_id text default '',
  p_route text default 'EVENT_DETAIL'
)
returns table(announcement_id text, push_id text, inbox_rows integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth uuid := auth.uid();
  v_event public.event_core%rowtype;
  v_title text := coalesce(nullif(trim(p_title), ''), 'Event Announcement');
  v_body text := trim(coalesce(p_body, ''));
  v_announcement_id text;
  v_push_id text;
  v_rows integer := 0;
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not public.app_event_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  if v_body = '' then raise exception 'MESSAGE_REQUIRED'; end if;

  select * into v_event
  from public.event_core
  where event_id = p_event_id
  for update;
  if not found then raise exception 'EVENT_NOT_FOUND'; end if;
  if v_event.is_cancelled then raise exception 'EVENT_CANCELLED'; end if;

  v_announcement_id := 'ann_' || replace(gen_random_uuid()::text, '-', '');
  v_push_id := 'push_' || replace(gen_random_uuid()::text, '-', '');

  insert into public.event_announcements(
    event_id, announcement_id, message, sender_name, sender_auth_user_id,
    type, topics, sent_at, payload_json
  )
  values (
    p_event_id, v_announcement_id, v_body, 'Admin', v_auth,
    'BROADCAST', '[]'::jsonb, now(),
    jsonb_build_object('title', v_title, 'body', v_body, 'comp_id', coalesce(p_comp_id, ''))
  );

  insert into public.app_inbox(uid, inbox_id, type, title, body, status, event_id, comp_id, target_id, payload_json)
  select ps.uid,
         'event_ann_' || v_announcement_id,
         'BROADCAST',
         v_title,
         v_body,
         'UNREAD',
         p_event_id,
         coalesce(p_comp_id, ''),
         v_announcement_id,
         jsonb_build_object('event_id', p_event_id, 'comp_id', coalesce(p_comp_id, ''), 'route', p_route)
  from public.event_participants ep
  join public.app_profile_state ps on ps.student_id = ep.student_id
  where ep.event_id = p_event_id
  on conflict (uid, inbox_id) do update
    set status = 'UNREAD',
        title = excluded.title,
        body = excluded.body,
        updated_at = now();
  get diagnostics v_rows = row_count;

  insert into public.app_push_queue(
    push_id, target_type, target_key, event_id, comp_id,
    notification_id, title, body, route, payload_json
  )
  values (
    v_push_id, 'EVENT', 'event_' || p_event_id, p_event_id, coalesce(p_comp_id, ''),
    v_announcement_id, v_title, v_body, p_route,
    jsonb_build_object('screen', 'BROADCAST', 'eventId', p_event_id, 'compId', coalesce(p_comp_id, ''))
  );

  return query select v_announcement_id, v_push_id, v_rows;
end;
$$;

grant execute on function public.api_event_admin_send_announcement(text,text,text,text,text) to authenticated;

commit;

