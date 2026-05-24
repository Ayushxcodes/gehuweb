-- Verify phase 2 identity mapping foundation

select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name = 'app_user_identity';

select
  c.relname as table_name,
  c.relrowsecurity as rls_enabled
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname = 'app_user_identity';

select count(*) as identity_rows
from app_user_identity;
