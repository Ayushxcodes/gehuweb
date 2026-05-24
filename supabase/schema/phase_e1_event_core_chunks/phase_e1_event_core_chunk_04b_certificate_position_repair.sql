-- Phase E1 / Chunk 04B
-- Repair reserved-word certificate column from early E1 draft.

begin;

alter table if exists public.event_certificates
  add column if not exists certificate_position text not null default '';

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'event_certificates'
      and column_name = 'position'
  ) then
    execute '
      update public.event_certificates
      set certificate_position = coalesce(nullif(certificate_position, ''''), "position")
      where coalesce(certificate_position, '''') = ''''
    ';
  end if;
end $$;

commit;
