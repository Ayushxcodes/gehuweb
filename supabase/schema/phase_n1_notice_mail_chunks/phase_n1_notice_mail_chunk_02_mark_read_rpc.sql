-- Phase N1 / Chunk 02
-- Student notice read-state RPC.

begin;

create or replace function public.api_mark_notice_read(p_notice_id text)
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

  insert into public.app_notice_reads (uid, notice_id, read_at)
  values (v_uid, p_notice_id, now())
  on conflict (uid, notice_id) do update
    set read_at = excluded.read_at,
        updated_at = now();

  return true;
end;
$$;

grant execute on function public.api_mark_notice_read(text) to authenticated;

commit;
