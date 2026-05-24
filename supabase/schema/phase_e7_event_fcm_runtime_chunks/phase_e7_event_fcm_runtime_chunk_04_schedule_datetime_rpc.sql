-- Phase E7 / Chunk 04
-- Repairs schedule replacement RPC so web/admin schedule stages preserve date+time.

begin;

create or replace function public.api_event_replace_schedule(
  p_event_id text, p_stages jsonb, p_current_stage_index integer default 0
)
returns table (event_id text, stage_rows integer)
language plpgsql security definer set search_path = public as $$
declare
  v_auth uuid := auth.uid(); v_event public.event_core%rowtype; v_rows integer;
begin
  if v_auth is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not public.app_event_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  if jsonb_typeof(coalesce(p_stages, '[]'::jsonb)) <> 'array' then raise exception 'STAGES_MUST_BE_ARRAY'; end if;
  if jsonb_array_length(coalesce(p_stages, '[]'::jsonb)) > 50 then raise exception 'TOO_MANY_STAGES'; end if;

  select * into v_event from public.event_core where event_core.event_id = p_event_id for update;
  if not found then raise exception 'EVENT_NOT_FOUND'; end if;
  if v_event.event_interaction_locked or v_event.finalized or v_event.is_cancelled then raise exception 'EVENT_LOCKED'; end if;

  delete from public.event_schedule_stages s where s.event_id = p_event_id;
  insert into public.event_schedule_stages(
    event_id, stage_id, title, type, status,
    stage_order, starts_at, ends_at, is_public, payload_json
  )
  select p_event_id, 'stage_' || lpad(x.rn::text, 2, '0'),
    coalesce(nullif(trim(x.item->>'title'), ''), 'Stage ' || x.rn::text),
    coalesce(nullif(trim(x.item->>'type'), ''), 'CUSTOM'),
    case when (x.rn - 1) < greatest(0, p_current_stage_index) then 'COMPLETED'
         when (x.rn - 1) = greatest(0, p_current_stage_index) then 'ACTIVE'
         else 'UPCOMING' end,
    x.rn,
    nullif(x.item->>'starts_at', '')::timestamptz,
    nullif(x.item->>'ends_at', '')::timestamptz,
    coalesce((x.item->>'is_public')::boolean, true),
    x.item
  from jsonb_array_elements(coalesce(p_stages, '[]'::jsonb)) with ordinality x(item, rn);
  get diagnostics v_rows = row_count;
  return query select p_event_id, v_rows;
end;
$$;

grant execute on function public.api_event_replace_schedule(text,jsonb,integer) to authenticated;

commit;
