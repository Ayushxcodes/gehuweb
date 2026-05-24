-- GEHU Connect auth stability schema smoke
-- Date: 2026-05-20
-- Purpose: read-only check for the columns required by Android/Web auth route stabilization.

select
  to_regclass('public.app_user_identity') is not null as has_identity_table,
  to_regclass('public.app_profile_state') is not null as has_profile_table,
  exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'app_user_identity'
      and column_name = 'auth_user_id'
  ) as identity_has_auth_user_id,
  exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'app_profile_state'
      and column_name = 'auth_user_id'
  ) as profile_has_auth_user_id;