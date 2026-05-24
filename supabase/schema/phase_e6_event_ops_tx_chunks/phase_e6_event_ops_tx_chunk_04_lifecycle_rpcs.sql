-- Phase E6 / Chunk 04
-- Event lifecycle close/finalize/cancel RPCs.

begin;

create or replace function public.api_event_set_interaction_locked(p_event_id text)
returns table (event_id text, event_interaction_locked boolean)
language plpgsql security definer set search_path = public as $$
declare v_auth uuid := auth.uid();
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not public.app_event_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  update public.event_core e set event_interaction_locked = true
  where e.event_id = p_event_id and e.is_cancelled = false
  returning e.event_id, e.event_interaction_locked into event_id, event_interaction_locked;
  if event_id is null then raise exception 'EVENT_NOT_FOUND_OR_CANCELLED'; end if;
  return next;
end;
$$;

create or replace function public.api_event_finalize(p_event_id text)
returns table (event_id text, finalized boolean, event_interaction_locked boolean)
language plpgsql security definer set search_path = public as $$
declare v_auth uuid := auth.uid();
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not public.app_event_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  update public.event_core e set finalized = true, event_interaction_locked = true
  where e.event_id = p_event_id and e.is_cancelled = false
  returning e.event_id, e.finalized, e.event_interaction_locked into event_id, finalized, event_interaction_locked;
  if event_id is null then raise exception 'EVENT_NOT_FOUND_OR_CANCELLED'; end if;
  return next;
end;
$$;

create or replace function public.api_event_cancel(p_event_id text, p_reason text default '')
returns table (event_id text, refund_pending_rows integer, inbox_rows integer)
language plpgsql security definer set search_path = public as $$
declare v_auth uuid := auth.uid(); v_event public.event_core%rowtype; v_refunds integer; v_inbox integer;
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not public.app_event_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  select * into v_event from public.event_core where event_core.event_id = p_event_id for update;
  if not found then raise exception 'EVENT_NOT_FOUND'; end if;
  if v_event.finalized then raise exception 'FINALIZED_EVENT_CANNOT_BE_CANCELLED'; end if;
  update public.event_core set is_cancelled = true, event_interaction_locked = true
  where event_core.event_id = p_event_id;
  update public.event_payment_records set refund_status = 'PENDING', status = 'REFUND_PENDING',
    rejection_reason = coalesce(nullif(trim(p_reason), ''), 'EVENT_CANCELLED'), updated_at = now()
  where event_payment_records.event_id = p_event_id and status = 'VERIFIED' and refund_status <> 'COMPLETE';
  get diagnostics v_refunds = row_count;
  insert into public.app_inbox(uid, inbox_id, type, title, body, status, event_id, payload_json)
  select ps.uid, 'event_cancel_' || p_event_id, 'EVENT_CANCELLED',
    'Event Cancelled: ' || v_event.title,
    coalesce(nullif(trim(p_reason), ''), 'This event has been cancelled by the admin.'),
    'UNREAD', p_event_id, jsonb_build_object('event_id', p_event_id, 'reason', coalesce(p_reason, ''))
  from public.event_participants ep join public.app_profile_state ps on ps.student_id = ep.student_id
  where ep.event_id = p_event_id
  on conflict (uid, inbox_id) do update set status = 'UNREAD', body = excluded.body, updated_at = now();
  get diagnostics v_inbox = row_count;
  return query select p_event_id, v_refunds, v_inbox;
end;
$$;

grant execute on function public.api_event_set_interaction_locked(text) to authenticated;
grant execute on function public.api_event_finalize(text) to authenticated;
grant execute on function public.api_event_cancel(text,text) to authenticated;

commit;
