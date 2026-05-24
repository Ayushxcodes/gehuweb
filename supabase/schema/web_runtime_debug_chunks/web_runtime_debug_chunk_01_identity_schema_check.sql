-- Web Runtime Debug / Chunk 01
-- Confirms app_user_identity contract for web AuthContext.

select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'app_user_identity'
order by ordinal_position;

with desired(email) as (
  values
    ('admin@test.gehu'),
    ('student@test.gehu'),
    ('test1@gehu.ac.in'),
    ('test2@gehu.ac.in')
)
select
  d.email,
  u.id is not null as has_auth_user,
  ai.account_type,
  ai.is_active,
  ai.student_id,
  ai.employee_id
from desired d
left join auth.users u on lower(u.email) = lower(d.email)
left join public.app_user_identity ai on ai.auth_user_id = u.id
order by d.email;

