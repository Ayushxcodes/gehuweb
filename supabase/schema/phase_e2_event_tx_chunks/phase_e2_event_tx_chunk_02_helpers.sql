-- Phase E2 / Chunk 02
-- Helpers shared by event transaction RPCs.

begin;

create or replace function public.app_event_is_visible_registration_status(p_status text)
returns boolean
language sql
immutable
as $$
  select coalesce(p_status, '') in ('REGISTERED','ACCEPTED','VERIFIED');
$$;

create or replace function public.app_event_payment_required(
  p_is_free boolean,
  p_fee_amount numeric
)
returns boolean
language sql
immutable
as $$
  select coalesce(p_is_free, true) = false and coalesce(p_fee_amount, 0) > 0;
$$;

create or replace function public.app_event_random_team_id()
returns text
language sql
volatile
as $$
  select 'team_' || substr(md5(random()::text || clock_timestamp()::text), 1, 20);
$$;

grant execute on function public.app_event_is_visible_registration_status(text) to authenticated;
grant execute on function public.app_event_payment_required(boolean,numeric) to authenticated;
grant execute on function public.app_event_random_team_id() to authenticated;

commit;
